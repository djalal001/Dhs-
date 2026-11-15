import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trader_desk/data/local_store.dart';
import 'package:trader_desk/models/trade.dart';
import 'package:trader_desk/models/trading_account.dart';
import 'package:trader_desk/screens/trade_form_screen.dart';
import 'package:trader_desk/state/app_controller.dart';
import 'package:trader_desk/state/app_scope.dart';
import 'package:trader_desk/theme/app_theme.dart';

void main() {
  late Directory temp;
  late AppController app;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('trader_desk_conditions_');
    app = await AppController.create(
      store: LocalStore(documentsDirectory: () async => temp),
    );
    app.accounts = [
      TradingAccount(
        id: 'conditions-account',
        name: 'Demo',
        type: AccountType.demo,
        startingBalance: 10000,
        currency: 'USD',
        createdAt: DateTime(2025, 1, 1),
      ),
    ];
    app.selectedAccountId = 'conditions-account';
  });

  tearDown(() async {
    app.dispose();
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  testWidgets('keeps market and direction compact and stores both entry-condition lists', (tester) async {
    Trade? savedTrade;
    tester.view.setLogicalSize(const Size(360, 800));
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      AppScope(
        controller: app,
        child: MaterialApp(
          theme: buildAppTheme(Brightness.dark),
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    savedTrade = await Navigator.of(context).push<Trade>(
                      MaterialPageRoute(builder: (_) => const TradeFormScreen()),
                    );
                  },
                  child: const Text('فتح النموذج'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('فتح النموذج'));
    await tester.pumpAndSettle();

    final marketField = find.byKey(const ValueKey('trade-market-input'));
    final directionSelector = find.byKey(const ValueKey('trade-direction-selector'));
    await tester.ensureVisible(marketField);
    final marketRect = tester.getRect(marketField);
    final directionRect = tester.getRect(directionSelector);
    expect(
      (directionRect.top - marketRect.top).abs(),
      lessThan(20),
      reason: 'direction should share the compact market row, not move below it',
    );
    expect(
      directionRect.left >= marketRect.right || marketRect.left >= directionRect.right,
      isTrue,
      reason: 'direction and market fields should be horizontally adjacent',
    );
    expect(directionRect.width, lessThan(marketRect.width));

    await tester.enterText(marketField, 'EURUSD');
    final buySegment = find.byKey(const ValueKey('trade-direction-buy'));
    await tester.tap(buySegment);
    await tester.pumpAndSettle();
    expect(tester.getSize(buySegment).height, 40);
    await tester.enterText(find.byKey(const ValueKey('trade-result-input')), '42.5');
    await tester.enterText(find.byKey(const ValueKey('trade-expected-loss-input')), '100');
    await tester.pumpAndSettle();

    final addEntry = find.byKey(const ValueKey('add-entry-setup'));
    await tester.ensureVisible(addEntry);
    await tester.tap(addEntry);
    await tester.pumpAndSettle();
    await tester.tap(find.text('RFS').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('15MIN').last);
    await tester.pumpAndSettle();

    final addConfirmation = find.byKey(const ValueKey('add-confirmation-setup'));
    await tester.ensureVisible(addConfirmation);
    await tester.tap(addConfirmation);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bearish engulfing').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('5MIN').last);
    await tester.pumpAndSettle();

    final addReverse = find.byKey(const ValueKey('add-reverse-signal-setup'));
    final reverseHeader = find.text('إشارات عكسية');
    await tester.ensureVisible(reverseHeader);
    await tester.tap(reverseHeader);
    await tester.pumpAndSettle();
    await tester.ensureVisible(addReverse);
    await tester.tap(addReverse);
    await tester.pumpAndSettle();
    expect(find.text('تشكل اغلاق سلبي لا يدعم الصفقة قبل الارتداد من منطقه الدخول'), findsOneWidget);
    await tester.tap(find.text('تشكل اغلاق سلبي لا يدعم الصفقة قبل الارتداد من منطقه الدخول'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30MIN').last);
    await tester.pumpAndSettle();

    final addBounce = find.byKey(const ValueKey('add-bounce-zone-setup'));
    final bounceHeader = find.text('منطقة الارتداد');
    await tester.ensureVisible(bounceHeader);
    await tester.tap(bounceHeader);
    await tester.pumpAndSettle();
    await tester.ensureVisible(addBounce);
    await tester.tap(addBounce);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ارتداد من ترند لاين و Supply Zone'));
    await tester.pumpAndSettle();
    expect(find.text('فريم ترند لاين'), findsOneWidget);
    await tester.tap(find.text('1H').last);
    await tester.pumpAndSettle();
    expect(find.text('فريم Supply Zone'), findsOneWidget,
        reason: 'the Supply Zone timeframe picker should open automatically');
    await tester.tap(find.text('5MIN').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('ارتداد من Trend Line 1H - Supply Zone 5MIN'), findsOneWidget);

    await tester.ensureVisible(addBounce);
    await tester.tap(addBounce);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ارتداد من منطقة S/R'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15MIN').last);
    await tester.pumpAndSettle();
    expect(find.text('ارتداد من منطقة دعم 15MIN'), findsOneWidget);

    // Tapping the selected direction again keeps the original clear-selection
    // behavior; the S/R choice returns to its generic label until reselected.
    await tester.tap(buySegment);
    await tester.pumpAndSettle();
    expect(find.text('ارتداد من منطقة S/R 15MIN'), findsOneWidget);
    await tester.tap(buySegment);
    await tester.pumpAndSettle();
    expect(find.text('ارتداد من منطقة دعم 15MIN'), findsOneWidget);

    final save = find.byKey(const ValueKey('save-trade-button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(savedTrade, isNotNull);
    expect(savedTrade!.reverseSignalSetups, const [
      TradeEntryConditionSetup(
        optionKey: 'negativeCloseAgainstDirection',
        timeframe: '30MIN',
      ),
    ]);
    expect(savedTrade!.bounceZoneSetups, const [
      TradeEntryConditionSetup(
        optionKey: 'bounceFromTrendlineAndSupplyZone',
        timeframe: '1H',
        secondaryTimeframe: '5MIN',
      ),
      TradeEntryConditionSetup(
        optionKey: 'bounceFromSrZone',
        timeframe: '15MIN',
      ),
    ]);
    expect(savedTrade!.entrySetups.single, const TradeEntrySetup(reason: 'RFS', timeframe: '15MIN'));
    expect(savedTrade!.confirmationSetups.single, const TradeConfirmationSetup(type: 'confirmBearishEngulfing', timeframe: '5MIN'));
  });

  test('new conditions remain backward compatible with existing trade JSON', () {
    final legacy = <String, dynamic>{
      'id': 'legacy',
      'accountId': 'conditions-account',
      'market': 'EURUSD',
      'reason': 'SBR',
      'result': 5,
      'riskPercent': .5,
      'side': 'buy',
      'confirmation': 'confirmBearishEngulfing',
      'sequence': '',
      'mood': 'moodCalm',
      'tradedAt': DateTime(2025, 1, 2).toIso8601String(),
    };
    final restored = Trade.fromJson(legacy);
    expect(restored.reverseSignalSetups, isEmpty);
    expect(restored.bounceZoneSetups, isEmpty);
  });
}
