import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'streaming_backup_decoder.dart';
import '../models/trade.dart';
import '../models/trading_account.dart';

class RestoredData {
  const RestoredData({
    required this.accounts,
    required this.trades,
    required this.isDark,
    required this.languageCode,
    required this.selectedAccountId,
  });
  final List<TradingAccount> accounts;
  final List<Trade> trades;
  final bool isDark;
  final String languageCode;
  final String? selectedAccountId;
}

class LocalStore {
  LocalStore({Future<Directory> Function()? documentsDirectory})
    : _documentsDirectory =
          documentsDirectory ?? getApplicationDocumentsDirectory;

  static const _storeName = 'traderdesk_data.json';
  final Future<Directory> Function() _documentsDirectory;
  Future<Directory> _root() => _documentsDirectory();

  Future<Map<String, dynamic>?> read() async {
    final root = await _root();
    final file = File('${root.path}/$_storeName');
    final backup = File('${file.path}.bak');
    if (!await file.exists()) {
      if (!await backup.exists()) return null;
      return _readObject(backup);
    }
    try {
      return await _readObject(file);
    } catch (_) {
      if (!await backup.exists()) rethrow;
      return _readObject(backup);
    }
  }

  Future<Map<String, dynamic>> _readObject(File file) async {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid local data file.');
    }
    return decoded;
  }

  Future<void> write({
    required List<TradingAccount> accounts,
    required List<Trade> trades,
    required bool isDark,
    required String languageCode,
    required String? selectedAccountId,
  }) async {
    final root = await _root();
    final file = File('${root.path}/$_storeName');
    final temp = File('${file.path}.tmp');
    final backup = File('${file.path}.bak');
    final json = jsonEncode({
      'formatVersion': 1,
      'accounts': accounts.map((item) => item.toJson()).toList(),
      'trades': trades.map((item) => item.toJson()).toList(),
      'isDark': isDark,
      'languageCode': languageCode,
      'selectedAccountId': selectedAccountId,
    });
    await temp.writeAsString(json, flush: true);
    var movedExistingFile = false;
    try {
      if (await backup.exists()) await backup.delete();
      if (await file.exists()) {
        await file.rename(backup.path);
        movedExistingFile = true;
      }
      await temp.rename(file.path);
      if (await backup.exists()) await backup.delete();
    } catch (_) {
      if (movedExistingFile && !await file.exists() && await backup.exists()) {
        await backup.rename(file.path);
      }
      rethrow;
    } finally {
      if (await temp.exists()) await temp.delete();
    }
  }

  Future<String> persistImage(String sourcePath) async {
    final root = await _root();
    final images = Directory('${root.path}/trade_images');
    await images.create(recursive: true);
    final source = File(sourcePath);
    final extension = sourcePath.contains('.')
        ? sourcePath.substring(sourcePath.lastIndexOf('.'))
        : '.jpg';
    final destination = File(
      '${images.path}/${DateTime.now().microsecondsSinceEpoch}$extension',
    );
    await source.copy(destination.path);
    return destination.path;
  }

  /// Removes image files no longer referenced by any saved trade.
  /// Only files inside the app's trade_images directory are eligible.
  /// Cleanup is best-effort so an I/O failure never blocks a trade save/delete.
  Future<void> deleteUnreferencedTradeImages({
    required Iterable<String?> candidates,
    required Iterable<Trade> remainingTrades,
  }) async {
    try {
      final imagesDirectory = Directory('${(await _root()).path}/trade_images');
      if (!await imagesDirectory.exists()) return;
      final imageRoot = await imagesDirectory.resolveSymbolicLinks();
      final referenced = <String>{};
      for (final trade in remainingTrades) {
        for (final path in _tradeImagePaths(trade)) {
          final resolved = await _resolveStoredImagePath(path, imageRoot);
          if (resolved != null) referenced.add(_comparisonPath(resolved));
        }
      }

      final visited = <String>{};
      for (final path in candidates) {
        if (path == null || path.isEmpty) continue;
        try {
          final resolved = await _resolveStoredImagePath(path, imageRoot);
          if (resolved == null) continue;
          final key = _comparisonPath(resolved);
          if (!visited.add(key) || referenced.contains(key)) continue;
          await File(resolved).delete();
        } catch (_) {
          // Image cleanup is intentionally non-blocking and silent.
        }
      }
    } catch (_) {
      // A missing or inaccessible image directory must not affect trade data.
    }
  }

  Future<String?> _resolveStoredImagePath(String path, String imageRoot) async {
    try {
      final resolved = await File(path).resolveSymbolicLinks();
      final prefix = '$imageRoot${Platform.pathSeparator}';
      final comparableResolved = _comparisonPath(resolved);
      final comparablePrefix = _comparisonPath(prefix);
      if (!comparableResolved.startsWith(comparablePrefix)) return null;
      return resolved;
    } catch (_) {
      return null;
    }
  }

  String _comparisonPath(String path) =>
      Platform.isWindows ? path.toLowerCase() : path;

  Iterable<String> _tradeImagePaths(Trade trade) sync* {
    final paths = [
      trade.beforeImagePath,
      trade.afterImagePath,
      trade.confirmationImagePath,
    ];
    for (final path in paths) {
      if (path != null && path.isNotEmpty) yield path;
    }
  }

  Future<String> createBackup({
    required List<TradingAccount> accounts,
    required List<Trade> trades,
    required bool isDark,
    required String languageCode,
    required String? selectedAccountId,
  }) async {
    final imageData = <String, String>{};
    for (final trade in trades) {
      for (final path in [
        trade.beforeImagePath,
        trade.afterImagePath,
        trade.confirmationImagePath,
      ]) {
        if (path == null || path.isEmpty || imageData.containsKey(path))
          continue;
        final file = File(path);
        if (await file.exists())
          imageData[path] = base64Encode(await file.readAsBytes());
      }
    }
    return jsonEncode({
      'format': 'traderdesk-backup',
      'formatVersion': 1,
      'accounts': accounts.map((item) => item.toJson()).toList(),
      'trades': trades.map((item) => item.toJson()).toList(),
      'preferences': {
        'isDark': isDark,
        'languageCode': languageCode,
        'selectedAccountId': selectedAccountId,
      },
      'imagesBase64': imageData,
    });
  }

  Future<RestoredData> parseBackup(String source) async {
    final decoded = jsonDecode(source);
    final root = await _root();
    final images = Directory('${root.path}/trade_images');
    await images.create(recursive: true);
    final remapped = <String, String>{};
    try {
      if (decoded is Map<String, dynamic> &&
          decoded['imagesBase64'] is Map<String, dynamic>) {
        final encodedImages = decoded['imagesBase64'] as Map<String, dynamic>;
        for (final entry in encodedImages.entries) {
          if (entry.value is! String) continue;
          final destination = _newRestoredImage(
            images,
            entry.key,
            remapped.length,
          );
          await destination.writeAsBytes(
            base64Decode(entry.value as String),
            flush: true,
          );
          remapped[entry.key] = destination.path;
        }
      }
      return _buildRestoredData(decoded, remapped);
    } catch (_) {
      await _removeCreatedImages(remapped.values);
      rethrow;
    }
  }

  Future<RestoredData> parseBackupStream(
    Stream<List<int>> source, {
    void Function(int bytesRead)? onProgress,
  }) async {
    final root = await _root();
    final images = Directory('${root.path}/trade_images');
    await images.create(recursive: true);
    final remapped = <String, String>{};
    try {
      final decoded = await decodeBackupStream(
        source,
        onProgress: onProgress,
        writeImage: (original, pump) async {
          final destination = _newRestoredImage(
            images,
            original,
            remapped.length,
          );
          final output = destination.openWrite();
          final decoder = base64.decoder.startChunkedConversion(output);
          try {
            await pump(decoder.add);
            decoder.close();
            await output.close();
            remapped[original] = destination.path;
          } catch (_) {
            await output.close();
            if (await destination.exists()) await destination.delete();
            rethrow;
          }
        },
      );
      return _buildRestoredData(decoded, remapped);
    } catch (_) {
      await _removeCreatedImages(remapped.values);
      rethrow;
    }
  }

  File _newRestoredImage(Directory directory, String original, int index) {
    final slash = original.lastIndexOf(RegExp(r'[/\\]'));
    final dot = original.lastIndexOf('.');
    final extension = dot > slash ? original.substring(dot) : '.jpg';
    return File(
      '${directory.path}/restore_${DateTime.now().microsecondsSinceEpoch}_${index}$extension',
    );
  }

  Future<void> _removeCreatedImages(Iterable<String> paths) async {
    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Restore rollback is best-effort for files created by this attempt.
      }
    }
  }

  RestoredData _buildRestoredData(
    dynamic decoded,
    Map<String, String> remapped,
  ) {
    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != 'traderdesk-backup' ||
        decoded['formatVersion'] != 1) {
      throw const FormatException('Unsupported backup format.');
    }
    final accountJson = decoded['accounts'];
    final tradeJson = decoded['trades'];
    if (accountJson is! List || tradeJson is! List) {
      throw const FormatException('Backup is missing accounts or trades.');
    }
    final accounts = accountJson
        .map(
          (value) =>
              TradingAccount.fromJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList();
    final trades = tradeJson.map((value) {
      final trade = Trade.fromJson(Map<String, dynamic>.from(value as Map));
      return Trade(
        id: trade.id,
        accountId: trade.accountId,
        market: trade.market,
        reason: trade.reason,
        result: trade.result,
        riskPercent: trade.riskPercent,
        side: trade.side,
        confirmation: trade.confirmation,
        sequence: trade.sequence,
        mood: trade.mood,
        tradedAt: trade.tradedAt,
        entryTimeframe: trade.entryTimeframe,
        entrySetups: trade.effectiveEntrySetups,
        confirmationSetups: trade.confirmationSetups,
        reverseSignalSetups: trade.reverseSignalSetups,
        bounceZoneSetups: trade.bounceZoneSetups,
        executionJournal: trade.executionJournal,
        executionReviewKeys: trade.executionReviewKeys,
        noEntryReasons: trade.noEntryReasons,
        beforeImagePath:
            remapped[trade.beforeImagePath] ?? trade.beforeImagePath,
        afterImagePath: remapped[trade.afterImagePath] ?? trade.afterImagePath,
        confirmationImagePath:
            remapped[trade.confirmationImagePath] ??
            trade.confirmationImagePath,
        expectedLoss: trade.expectedLoss,
        notes: trade.notes,
        strategyAdherence: trade.strategyAdherence,
      );
    }).toList();
    final preferences = decoded['preferences'] is Map
        ? Map<String, dynamic>.from(decoded['preferences'] as Map)
        : <String, dynamic>{};
    return RestoredData(
      accounts: accounts,
      trades: trades,
      isDark: preferences['isDark'] as bool? ?? true,
      languageCode: preferences['languageCode'] as String? ?? 'ar',
      selectedAccountId: preferences['selectedAccountId'] as String?,
    );
  }
}
