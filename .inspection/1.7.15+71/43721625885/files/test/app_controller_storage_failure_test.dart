import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trader_desk/data/local_store.dart';
import 'package:trader_desk/models/trade.dart';
import 'package:trader_desk/models/trading_account.dart';
import 'package:trader_desk/state/app_controller.dart';

class _ControllableStore extends LocalStore {
  _ControllableStore(Directory directory)
    : super(documentsDirectory: () async => directory);

  bool failWrites = false;

  @override
  Future<void> write({
    required List<TradingAccount> accounts,
    required List<Trade> trades,
    required bool isDark,
    required String languageCode,
    required String? selectedAccountId,
  }) async {
    if (failWrites) {
      throw const FileSystemException('Simulated storage write failure.');
    }
    await super.write(
      accounts: accounts,
      trades: trades,
      isDark: isDark,
      languageCode: languageCode,
      selectedAccountId: selectedAccountId,
    );
  }
}

void main() {
  late Directory temporaryDirectory;
  late _ControllableStore store;
  late AppController app;

  TradingAccount account(String id, String name) => TradingAccount(
    id: id,
    name: name,
    type: AccountType.demo,
    startingBalance: 10000,
    currency: 'USD',
    createdAt: DateTime(2025, 1, 1),
  );

  Trade trade({String market = 'EURUSD', double result = 10}) => Trade(
    id: 'trade-1',
    accountId: 'account-1',
    market: market,
    reason: 'SBR',
    result: result,
    riskPercent: 1,
    side: TradeSide.buy,
    confirmation: 'Reject Key Level',
    sequence: '',
    mood: 'moodCalm',
    tradedAt: DateTime(2025, 1, 2),
  );

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'trader_desk_storage_failure_',
    );
    store = _ControllableStore(temporaryDirectory);
    app = await AppController.create(store: store);
    await app.addAccount(account('account-1', 'Primary'));
    await app.addAccount(account('account-2', 'Secondary'));
  });

  tearDown(() async {
    app.dispose();
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('failed account and preference writes roll back in-memory state', () async {
    await app.selectAccount('account-2');
    expect(app.selectedAccountId, 'account-2');
    store.failWrites = true;

    await app.addAccount(account('account-3', 'Unsaved'));
    expect(app.accounts.map((item) => item.id), ['account-1', 'account-2']);

    await app.selectAccount('account-1');
    expect(app.selectedAccountId, 'account-2');

    await app.updateAccount(account('account-1', 'Renamed but not saved'));
    expect(app.accounts.first.name, 'Primary');

    await app.deleteAccount('account-2');
    expect(app.accounts.map((item) => item.id), ['account-1', 'account-2']);
    expect(app.selectedAccountId, 'account-2');

    await app.setDark(false);
    expect(app.isDark, isTrue);

    await app.setLanguage('en');
    expect(app.languageCode, 'ar');
    expect(app.storageError, isNotNull);
  });

  test('failed trade writes do not leave phantom trades or edits', () async {
    await app.addTrade(trade());
    expect(app.trades, hasLength(1));

    store.failWrites = true;
    await app.addTrade(trade(market: 'GBPUSD'));
    expect(app.trades, hasLength(1));
    expect(app.trades.single.market, 'EURUSD');

    await app.updateTrade(trade(market: 'USDJPY'));
    expect(app.trades.single.market, 'EURUSD');

    await app.deleteTrade('trade-1');
    expect(app.trades, hasLength(1));
    expect(app.trades.single.market, 'EURUSD');
    expect(app.storageError, isNotNull);
  });
}

