import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trader_desk/data/local_store.dart';
import 'package:trader_desk/models/trade.dart';
import 'package:trader_desk/models/trading_account.dart';
import 'package:trader_desk/state/app_controller.dart';

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('trader_desk_test_');
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  LocalStore store() => LocalStore(documentsDirectory: () async => temp);

  test(
    'persists account/trade state and restores settings plus attached images',
    () async {
      final app = await AppController.create(store: store());
      final account = TradingAccount(
        id: 'acct-1',
        name: 'Demo',
        type: AccountType.demo,
        startingBalance: 5000,
        currency: 'USD',
        createdAt: DateTime(2025, 1, 1),
        profitTarget: 250,
      );
      await app.addAccount(account);

      final source = File('${temp.path}/evidence.png');
      await source.writeAsBytes([1, 2, 3, 4, 5]);
      final savedImage = await app.persistImage(source.path);
      final confirmationSource = File('${temp.path}/confirmation.png');
      await confirmationSource.writeAsBytes([6, 7, 8, 9]);
      final savedConfirmationImage = await app.persistImage(
        confirmationSource.path,
      );
      final trade = Trade(
        id: 'trade-1',
        accountId: account.id,
        market: 'EURUSD',
        reason: 'SBR',
        result: -25,
        riskPercent: 0.5,
        side: TradeSide.sell,
        confirmation: 'confirmTechnical',
        sequence: 'London open',
        mood: 'moodCalm',
        tradedAt: DateTime(2025, 1, 2),
        entryTimeframe: '1H',
        entrySetups: const [
          TradeEntrySetup(reason: 'SBR', timeframe: '1H'),
          TradeEntrySetup(reason: 'RBS Touch 2', timeframe: '30MIN'),
        ],
        confirmationSetups: const [
          TradeConfirmationSetup(
            type: 'confirmBearishEngulfing',
            timeframe: '5MIN',
          ),
          TradeConfirmationSetup(type: 'confirmHns', timeframe: '1H'),
        ],
        reverseSignalSetups: const [
          TradeEntryConditionSetup(
            optionKey: 'negativeCloseAgainstDirection',
            timeframe: '15MIN',
          ),
        ],
        bounceZoneSetups: const [
          TradeEntryConditionSetup(
            optionKey: 'bounceFromSrZone',
            timeframe: '1H',
          ),
          TradeEntryConditionSetup(
            optionKey: 'bounceFromTrendlineAndSupplyZone',
            timeframe: '30MIN',
            secondaryTimeframe: '5MIN',
          ),
        ],
        executionJournal: const [
          TradeExecutionJournalEntry(
            status: TradeExecutionStatus.avoidedEntryBecauseFear,
          ),
          TradeExecutionJournalEntry(status: TradeExecutionStatus.followedPlan),
          TradeExecutionJournalEntry(
            status: TradeExecutionStatus.entryConditionsNotMet,
          ),
        ],
        executionReviewKeys: const ['enteredEarly', 'fullPlanCompliance'],
        noEntryReasons: const ['fearRepeatLossAfterLoss'],
        beforeImagePath: savedImage,
        confirmationImagePath: savedConfirmationImage,
      );
      final legacyJson = Map<String, dynamic>.from(trade.toJson())
        ..remove('confirmationImagePath');
      expect(Trade.fromJson(legacyJson).confirmationImagePath, isNull);
      final previousVersionJson = Map<String, dynamic>.from(trade.toJson())
        ..remove('entrySetups');
      expect(Trade.fromJson(previousVersionJson).effectiveEntrySetups, const [
        TradeEntrySetup(reason: 'SBR', timeframe: '1H'),
      ]);
      final previousConfirmationJson = Map<String, dynamic>.from(trade.toJson())
        ..remove('confirmationSetups');
      expect(
        Trade.fromJson(previousConfirmationJson).effectiveConfirmationSetups,
        const [TradeConfirmationSetup(type: 'confirmTechnical', timeframe: '')],
      );
      final previousJournalJson = Map<String, dynamic>.from(trade.toJson())
        ..remove('executionJournal');
      expect(Trade.fromJson(previousJournalJson).executionJournal, isEmpty);
      final previousReviewSchema = Map<String, dynamic>.from(trade.toJson())
        ..remove('executionReviewKeys')
        ..remove('noEntryReasons');
      final migratedReviewSchema = Trade.fromJson(previousReviewSchema);
      expect(migratedReviewSchema.executionReviewKeys, isEmpty);
      expect(migratedReviewSchema.noEntryReasons, isEmpty);
      expect(migratedReviewSchema.executionJournal, trade.executionJournal);
      final legacyEarlyEntry = Map<String, dynamic>.from(trade.toJson())
        ..['executionJournal'] = [
          {'status': 'enteredEarlyOrOutsidePlan'},
        ];
      expect(Trade.fromJson(legacyEarlyEntry).executionJournal, const [
        TradeExecutionJournalEntry(status: TradeExecutionStatus.enteredEarly),
      ]);
      final allJournalStatuses = Trade.fromJson(
        Map<String, dynamic>.from(trade.toJson())
          ..['executionJournal'] = [
            for (final status in TradeExecutionStatus.values)
              {'status': status.name},
          ],
      );
      expect(allJournalStatuses.executionJournal, [
        for (final status in TradeExecutionStatus.values)
          TradeExecutionJournalEntry(status: status),
      ]);
      final phasedJournalJson = Map<String, dynamic>.from(trade.toJson())
        ..['executionJournal'] = [
          {'phase': 'before', 'status': 'followedPlan'},
          {'phase': 'during', 'status': 'followedPlan'},
          {'phase': 'after', 'status': 'enteredEarly'},
          {'phase': 'before', 'status': 'avoidedEntryBecauseFear'},
        ];
      expect(Trade.fromJson(phasedJournalJson).executionJournal, const [
        TradeExecutionJournalEntry(status: TradeExecutionStatus.followedPlan),
        TradeExecutionJournalEntry(status: TradeExecutionStatus.enteredEarly),
        TradeExecutionJournalEntry(
          status: TradeExecutionStatus.avoidedEntryBecauseFear,
        ),
      ]);
      expect(Trade.fromJson(previousJournalJson).sequence, 'London open');
      await app.addTrade(trade);
      await app.setDark(false);
      await app.setLanguage('en');
      await app.selectAccount(account.id);
      final backup = await app.createBackup();

      final restored = await AppController.create(store: store());
      await restored.restoreBackup(backup);
      final reopened = await AppController.create(store: store());
      expect(reopened.accounts.single.profitTarget, 250);
      expect(reopened.trades.single.market, 'EURUSD');
      expect(reopened.trades.single.reason, 'SBR');
      expect(reopened.trades.single.entryTimeframe, '1H');
      expect(reopened.trades.single.entrySetups, const [
        TradeEntrySetup(reason: 'SBR', timeframe: '1H'),
        TradeEntrySetup(reason: 'RBS Touch 2', timeframe: '30MIN'),
      ]);
      expect(reopened.trades.single.confirmationSetups, const [
        TradeConfirmationSetup(
          type: 'confirmBearishEngulfing',
          timeframe: '5MIN',
        ),
        TradeConfirmationSetup(type: 'confirmHns', timeframe: '1H'),
      ]);
      expect(reopened.trades.single.reverseSignalSetups, const [
        TradeEntryConditionSetup(
          optionKey: 'negativeCloseAgainstDirection',
          timeframe: '15MIN',
        ),
      ]);
      expect(reopened.trades.single.bounceZoneSetups, const [
        TradeEntryConditionSetup(
          optionKey: 'bounceFromSrZone',
          timeframe: '1H',
        ),
        TradeEntryConditionSetup(
          optionKey: 'bounceFromTrendlineAndSupplyZone',
          timeframe: '30MIN',
          secondaryTimeframe: '5MIN',
        ),
      ]);
      expect(reopened.trades.single.executionJournal, const [
        TradeExecutionJournalEntry(
          status: TradeExecutionStatus.avoidedEntryBecauseFear,
        ),
        TradeExecutionJournalEntry(status: TradeExecutionStatus.followedPlan),
        TradeExecutionJournalEntry(
          status: TradeExecutionStatus.entryConditionsNotMet,
        ),
      ]);
      expect(reopened.trades.single.executionReviewKeys, ['enteredEarly', 'fullPlanCompliance']);
      expect(reopened.trades.single.noEntryReasons, ['fearRepeatLossAfterLoss']);
      expect(reopened.trades.single.result, -25);
      expect(reopened.trades.single.beforeImagePath, isNot(savedImage));
      expect(
        reopened.trades.single.confirmationImagePath,
        isNot(savedConfirmationImage),
      );
      expect(
        await File(reopened.trades.single.beforeImagePath!).readAsBytes(),
        [1, 2, 3, 4, 5],
      );
      expect(
        await File(reopened.trades.single.confirmationImagePath!).readAsBytes(),
        [6, 7, 8, 9],
      );
      expect(reopened.isDark, isFalse);
      expect(reopened.languageCode, 'en');
      expect(reopened.selectedAccountId, account.id);

      app.dispose();
      restored.dispose();
      reopened.dispose();
    },
  );

  test(
    'migrates old saved light mode to dark without losing user data',
    () async {
      final account = TradingAccount(
        id: 'legacy-account',
        name: 'Legacy',
        type: AccountType.demo,
        startingBalance: 7500.0,
        currency: 'USD',
        createdAt: DateTime(2024, 1, 1),
      );
      final imagesDirectory = Directory('${temp.path}/trade_images');
      await imagesDirectory.create(recursive: true);
      final legacyImage = File('${imagesDirectory.path}/legacy-before.png');
      await legacyImage.writeAsBytes([9, 8, 7, 6], flush: true);
      final trade = Trade(
        id: 'legacy-trade',
        accountId: account.id,
        market: 'EURUSD',
        reason: 'SBR',
        result: 125.0,
        riskPercent: 0.5,
        side: TradeSide.buy,
        confirmation: 'confirmTechnical',
        sequence: 'London open',
        mood: 'moodCalm',
        tradedAt: DateTime(2024, 2, 1),
        beforeImagePath: legacyImage.path,
      );
      final legacyFile = File('${temp.path}/traderdesk_data.json');
      await legacyFile.writeAsString(
        jsonEncode({
          'formatVersion': 1,
          'accounts': [account.toJson()],
          'trades': [trade.toJson()],
          'isDark': false,
          'languageCode': 'en',
          'selectedAccountId': account.id,
        }),
        flush: true,
      );

      final app = await AppController.create(store: store());
      final migrated = jsonDecode(await legacyFile.readAsString())
          as Map<String, dynamic>;

      expect(app.isDark, isTrue);
      expect(app.accounts.single.name, 'Legacy');
      expect(app.accounts.single.startingBalance, 7500.0);
      expect(app.trades.single.id, 'legacy-trade');
      expect(app.trades.single.beforeImagePath, legacyImage.path);
      expect(await legacyImage.readAsBytes(), [9, 8, 7, 6]);
      expect(app.languageCode, 'en');
      expect(app.selectedAccountId, account.id);
      expect(
        migrated['appearanceMigrationVersion'],
        LocalStore.appearanceMigrationVersion,
      );
      expect(migrated['accounts'], hasLength(1));
      expect(migrated['trades'], hasLength(1));

      await app.setDark(false);
      final reopened = await AppController.create(store: store());
      expect(reopened.isDark, isFalse);

      app.dispose();
      reopened.dispose();
    },
  );

  test(
    'legacy backup cannot restore the old warm light palette',
    () async {
      final account = TradingAccount(
        id: 'backup-account',
        name: 'Backup',
        type: AccountType.demo,
        startingBalance: 3000.0,
        currency: 'USD',
        createdAt: DateTime(2024, 1, 1),
      );
      final app = await AppController.create(store: store());
      final legacyBackup = jsonEncode({
        'format': 'traderdesk-backup',
        'formatVersion': 1,
        'accounts': [account.toJson()],
        'trades': <Map<String, dynamic>>[],
        'preferences': {
          'isDark': false,
          'languageCode': 'ar',
          'selectedAccountId': account.id,
        },
        'imagesBase64': <String, String>{},
      });

      await app.restoreBackup(legacyBackup);
      expect(app.isDark, isTrue);
      expect(app.accounts.single.name, 'Backup');

      final currentBackup = jsonDecode(await app.createBackup())
          as Map<String, dynamic>;
      final preferences = currentBackup['preferences'] as Map<String, dynamic>;
      expect(
        preferences['appearanceMigrationVersion'],
        LocalStore.appearanceMigrationVersion,
      );

      app.dispose();
    },
  );

  test(
    'round-trips 1000 trades and recovers a damaged current data file',
    () async {
      final account = TradingAccount(
        id: 'large-account',
        name: 'Large history',
        type: AccountType.demo,
        startingBalance: 10000,
        currency: 'USD',
        createdAt: DateTime(2024, 1, 1),
      );
      final trades = List.generate(
        1000,
        (index) => Trade(
          id: 'stress-$index',
          accountId: account.id,
          market: 'EURUSD',
          reason: 'Breakout',
          result: index.isEven ? 10 : -5,
          riskPercent: 0.25,
          side: TradeSide.buy,
          confirmation: 'confirmTechnical',
          sequence: '',
          mood: index.isEven ? 'moodCalm' : 'moodConfident',
          tradedAt: DateTime(2024, 1, 1).add(Duration(minutes: index)),
        ),
      );
      final localStore = store();
      await localStore.write(
        accounts: [account],
        trades: trades,
        isDark: true,
        languageCode: 'ar',
        selectedAccountId: account.id,
      );

      final dataPath = '${temp.path}/traderdesk_data.json';
      final dataFile = File(dataPath);
      final goodData = await dataFile.readAsString();
      final recoveredFile = File('$dataPath.bak');
      await recoveredFile.writeAsString(goodData, flush: true);
      await dataFile.writeAsString('{ damaged', flush: true);

      final recovered = await localStore.read();
      expect(recovered, isNotNull);
      expect((recovered!['trades'] as List).length, 1000);
      expect((recovered['accounts'] as List).length, 1);
      expect(recovered['selectedAccountId'], account.id);
    },
  );
}
