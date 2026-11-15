import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trader_desk/data/local_store.dart';
import 'package:trader_desk/domain/trade_analytics.dart';
import 'package:trader_desk/models/trade.dart';
import 'package:trader_desk/state/app_controller.dart';

void main() {
  final backupPath = Platform.environment['TRADERDESK_LARGE_BACKUP'];
  test(
    'streams the user-sized synthetic 1000-trade backup',
    () async {
      final path = backupPath;
      if (path == null || path.isEmpty) return;
      final root = await Directory.systemTemp.createTemp(
        'traderdesk_large_import_',
      );
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });

      final backupFile = File(path);

      final controller = await AppController.create(
        store: LocalStore(documentsDirectory: () async => root),
      );
      final importTimer = Stopwatch()..start();
      var lastProgressReport = 0;
      await controller.restoreBackupStream(
        backupFile.openRead(),
        onProgress: (bytesRead) {
          if (bytesRead - lastProgressReport >= 50 * 1024 * 1024) {
            lastProgressReport = bytesRead;
            // ignore: avoid_print
            print('Streamed ${bytesRead ~/ (1024 * 1024)} MiB');
          }
        },
      );
      importTimer.stop();

      expect(controller.trades, hasLength(1000));
      final restoredTrades = controller.trades;
      final synthetic = restoredTrades
          .where((trade) => trade.id.startsWith('synthetic-'))
          .toList();
      expect(synthetic, hasLength(982));
      expect(synthetic.map((trade) => trade.id).toSet(), hasLength(982));
      expect(synthetic.map((trade) => trade.notes).toSet(), hasLength(982));
      expect(synthetic.map((trade) => trade.tradedAt).toSet(), hasLength(982));
      expect(synthetic.every((trade) => trade.accountId.isNotEmpty), isTrue);
      final validAccountIds = controller.accounts
          .map((account) => account.id)
          .toSet();
      expect(
        synthetic.every((trade) => validAccountIds.contains(trade.accountId)),
        isTrue,
      );
      expect(synthetic.every((trade) => trade.riskPercent > 0), isTrue);
      expect(
        synthetic.map((trade) => trade.riskPercent).toSet().length,
        greaterThan(50),
      );
      expect(
        synthetic.map((trade) => trade.mood).toSet().length,
        greaterThan(3),
      );
      expect(
        synthetic.map((trade) => trade.side).toSet(),
        containsAll(TradeSide.values),
      );
      expect(
        synthetic.map((trade) => trade.reason).toSet().length,
        greaterThan(5),
      );
      expect(
        synthetic
            .map((trade) => trade.confirmationSetups.first.type)
            .toSet()
            .length,
        greaterThan(4),
      );
      expect(
        synthetic
            .map((trade) => trade.executionJournal.first.status)
            .toSet()
            .length,
        greaterThan(5),
      );
      expect(
        synthetic.map((trade) => trade.result).toSet().length,
        greaterThan(50),
      );
      expect(
        synthetic.every(
          (trade) =>
              trade.beforeImagePath != null &&
              trade.afterImagePath != null &&
              trade.confirmationImagePath != null,
        ),
        isTrue,
      );
      final imageDirectory = Directory('${root.path}/trade_images');
      final restoredImageCount = await imageDirectory
          .list()
          .where((entity) => entity is File)
          .length;
      expect(restoredImageCount, 2994);
      final imagePaths = synthetic
          .expand(
            (trade) => [
              trade.beforeImagePath!,
              trade.afterImagePath!,
              trade.confirmationImagePath!,
            ],
          )
          .toSet();
      expect(imagePaths, hasLength(982 * 3));
      for (final imagePath in imagePaths) {
        expect(await File(imagePath).exists(), isTrue, reason: imagePath);
      }
      final analytics = TradeAnalytics.calculate(restoredTrades);
      final manualNet = restoredTrades.fold<double>(
        0,
        (sum, trade) => sum + trade.result,
      );
      expect(analytics.tradeCount, 1000);
      expect(analytics.wins + analytics.losses + analytics.breakEven, 1000);
      expect(analytics.netProfit, closeTo(manualNet, 0.000001));
      expect(analytics.maxDrawdownAmount.isFinite, isTrue);
      expect(analytics.maxDrawdownPercent.isFinite, isTrue);
      final saved = await LocalStore(
        documentsDirectory: () async => root,
      ).read();
      expect(saved!['trades'], hasLength(1000));

      // ignore: avoid_print
      print(
        'Backup ${backupFile.lengthSync()} bytes: '
        'streamed restore ${importTimer.elapsed}, images $restoredImageCount',
      );
    },
    skip: backupPath == null || backupPath.isEmpty
        ? 'Set TRADERDESK_LARGE_BACKUP to run the large fixture test.'
        : false,
    timeout: Timeout(Duration(minutes: 10)),
  );
}
