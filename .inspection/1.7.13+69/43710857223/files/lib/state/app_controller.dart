import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/local_store.dart';
import '../domain/trade_ordering.dart';
import '../models/trade.dart';
import '../models/trading_account.dart';

class AppController extends ChangeNotifier {
  AppController._(this._store);
  final LocalStore _store;
  List<TradingAccount> accounts = [];
  List<Trade> trades = [];
  bool isDark = true;
  String languageCode = 'ar';
  String? selectedAccountId;
  bool isReady = false;
  String? storageError;

  /// Changes only when theme or language changes. Keeps MaterialApp from
  /// rebuilding for ordinary trade/account persistence notifications.
  final ValueNotifier<int> appearanceRevision = ValueNotifier<int>(0);

  static Future<AppController> create({LocalStore? store}) async {
    final controller = AppController._(store ?? LocalStore());
    try {
      final stored = await controller._store.read();
      if (stored != null) {
        controller.accounts = (stored['accounts'] as List? ?? [])
            .map(
              (item) => TradingAccount.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
        controller.trades = (stored['trades'] as List? ?? [])
            .map(
              (item) => Trade.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
        controller.isDark = stored['isDark'] as bool? ?? true;
        final appearanceVersion =
            (stored['appearanceMigrationVersion'] as num?)?.toInt() ?? 0;
        if (appearanceVersion < LocalStore.appearanceMigrationVersion) {
          // Existing installs may have a saved light-mode preference from an
          // older warm palette. Switch once to the requested neutral dark UI.
          // The version marker means a later manual light-mode choice remains.
          controller.isDark = true;
        }
        controller.languageCode = stored['languageCode'] as String? ?? 'ar';
        controller.selectedAccountId = stored['selectedAccountId'] as String?;
        if (appearanceVersion < LocalStore.appearanceMigrationVersion) {
          await controller._persist();
        }
      }
    } catch (error) {
      controller.storageError = error.toString();
    }
    if (!controller.accounts.any(
      (account) => account.id == controller.selectedAccountId,
    ))
      controller.selectedAccountId = controller.accounts.firstOrNull?.id;
    controller.isReady = true;
    return controller;
  }

  Future<bool> _persist() async {
    try {
      await _store.write(
        accounts: accounts,
        trades: trades,
        isDark: isDark,
        languageCode: languageCode,
        selectedAccountId: selectedAccountId,
      );
      storageError = null;
      notifyListeners();
      return true;
    } catch (error) {
      storageError = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> selectAccount(String id) async {
    final previousSelection = selectedAccountId;
    selectedAccountId = id;
    if (!await _persist()) {
      selectedAccountId = previousSelection;
      notifyListeners();
    }
  }

  Future<String> persistImage(String path) => _store.persistImage(path);
  Future<void> addTrade(Trade trade) async {
    final previousTrades = trades;
    trades = [trade, ...trades]..sort(compareTradesDescending);
    if (!await _persist()) {
      trades = previousTrades;
      notifyListeners();
    }
  }

  Future<void> updateTrade(Trade trade) async {
    final previousTrades = trades;
    final previous = trades.where((item) => item.id == trade.id).firstOrNull;
    trades = trades.map((item) => item.id == trade.id ? trade : item).toList()
      ..sort(compareTradesDescending);
    if (!await _persist()) {
      trades = previousTrades;
      notifyListeners();
      return;
    }
    if (previous != null) {
      await _store.deleteUnreferencedTradeImages(
        candidates: _tradeImagePaths(previous),
        remainingTrades: trades,
      );
    }
  }

  Future<void> deleteTrade(String id) async {
    final deleted = trades.where((trade) => trade.id == id).firstOrNull;
    if (deleted == null) return;
    final previousTrades = trades;
    trades = trades.where((trade) => trade.id != id).toList();
    if (!await _persist()) {
      trades = previousTrades;
      notifyListeners();
      return;
    }
    await _store.deleteUnreferencedTradeImages(
      candidates: _tradeImagePaths(deleted),
      remainingTrades: trades,
    );
  }

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

  Future<void> addAccount(TradingAccount account) async {
    final previousAccounts = accounts;
    final previousSelection = selectedAccountId;
    accounts = [...accounts, account];
    selectedAccountId ??= account.id;
    if (!await _persist()) {
      accounts = previousAccounts;
      selectedAccountId = previousSelection;
      notifyListeners();
    }
  }

  Future<void> updateAccount(TradingAccount account) async {
    final previousAccounts = accounts;
    accounts = accounts
        .map((item) => item.id == account.id ? account : item)
        .toList();
    if (!await _persist()) {
      accounts = previousAccounts;
      notifyListeners();
    }
  }

  bool canDeleteAccount(String id) =>
      trades.every((trade) => trade.accountId != id);
  Future<void> deleteAccount(String id) async {
    if (!canDeleteAccount(id)) return;
    final previousAccounts = accounts;
    final previousSelection = selectedAccountId;
    accounts = accounts.where((account) => account.id != id).toList();
    if (selectedAccountId == id) selectedAccountId = accounts.firstOrNull?.id;
    if (!await _persist()) {
      accounts = previousAccounts;
      selectedAccountId = previousSelection;
      notifyListeners();
    }
  }

  Future<void> setDark(bool value) async {
    if (isDark == value) return;
    final previousValue = isDark;
    isDark = value;
    if (!await _persist()) {
      isDark = previousValue;
      notifyListeners();
      return;
    }
    appearanceRevision.value++;
  }

  Future<void> setLanguage(String value) async {
    final nextValue = value == 'en' ? 'en' : 'ar';
    if (languageCode == nextValue) return;
    final previousValue = languageCode;
    languageCode = nextValue;
    if (!await _persist()) {
      languageCode = previousValue;
      notifyListeners();
      return;
    }
    appearanceRevision.value++;
  }

  Future<String> createBackup() => _store.createBackup(
    accounts: accounts,
    trades: trades,
    isDark: isDark,
    languageCode: languageCode,
    selectedAccountId: selectedAccountId,
  );
  Future<void> restoreBackup(String contents) async {
    final restored = await _store.parseBackup(contents);
    await _applyRestoredData(restored);
  }

  Future<void> restoreBackupStream(
    Stream<List<int>> contents, {
    void Function(int bytesRead)? onProgress,
  }) async {
    final restored = await _store.parseBackupStream(
      contents,
      onProgress: onProgress,
    );
    await _applyRestoredData(restored);
  }

  @override
  void dispose() {
    appearanceRevision.dispose();
    super.dispose();
  }

  Future<void> _applyRestoredData(RestoredData restored) async {
    final previousAccounts = accounts;
    final previousTrades = trades;
    final previousIsDark = isDark;
    final previousLanguageCode = languageCode;
    final previousSelectedAccountId = selectedAccountId;
    accounts = restored.accounts;
    trades = restored.trades..sort(compareTradesDescending);
    isDark = restored.appearanceMigrationVersion <
            LocalStore.appearanceMigrationVersion
        ? true
        : restored.isDark;
    languageCode = restored.languageCode == 'en' ? 'en' : 'ar';
    selectedAccountId =
        accounts.any((account) => account.id == restored.selectedAccountId)
        ? restored.selectedAccountId
        : accounts.firstOrNull?.id;
    if (!await _persist()) {
      final failedTrades = trades;
      accounts = previousAccounts;
      trades = previousTrades;
      isDark = previousIsDark;
      languageCode = previousLanguageCode;
      selectedAccountId = previousSelectedAccountId;
      notifyListeners();
      await _store.deleteUnreferencedTradeImages(
        candidates: failedTrades.expand(_tradeImagePaths),
        remainingTrades: previousTrades,
      );
      throw StateError('Unable to save the restored backup.');
    }
    if (previousIsDark != isDark || previousLanguageCode != languageCode) {
      appearanceRevision.value++;
    }
    await _store.deleteUnreferencedTradeImages(
      candidates: previousTrades.expand(_tradeImagePaths),
      remainingTrades: trades,
    );
  }
}
