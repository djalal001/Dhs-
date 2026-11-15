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
import 'package:trader_desk/widgets/decision_option_emoji.dart';
import 'package:trader_desk/widgets/decision_section_logo.dart';

void main() {
  late Directory temp;
  late AppController app;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('trader_desk_entry_v150_');
    app = await AppController.create(
      store: LocalStore(documentsDirectory: () async => temp),
    );
    app.accounts = [
      TradingAccount(
        id: 'entry-account',
        name: 'Demo',
        type: AccountType.demo,
        startingBalance: 10000,
        currency: 'USD',
        createdAt: DateTime(2025, 1, 1),
      ),
    ];
    app.selectedAccountId = 'entry-account';
  });

  tearDown(() async {
    app.dispose();
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  testWidgets('adds Windows entry reason, custom confirmation and review selections', (tester) async {
    Trade? savedTrade;
    tester.view.setLogicalSize(const Size(420, 900));
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

    await tester.enterText(find.byKey(const ValueKey('trade-market-input')), 'EURUSD');
    await tester.tap(find.text('شراء').last);
    await tester.enterText(find.byKey(const ValueKey('trade-result-input')), '42.5');
    await tester.enterText(find.byKey(const ValueKey('trade-expected-loss-input')), '100');
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(find.byKey(const ValueKey('trade-risk-input'))).controller!.text, '1.00');
    expect(tester.widget<TextFormField>(find.byKey(const ValueKey('trade-reward-risk-input'))).controller!.text, '0.43');

    final addEntry = find.byKey(const ValueKey('add-entry-setup'));
    await tester.ensureVisible(addEntry);
    await tester.tap(addEntry);
    await tester.pumpAndSettle();
    expect(find.text('Supply Zone'), findsOneWidget);
    await tester.tap(find.text('SBR').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('touch2-choice-SBR')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch2-choice-SBR')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15MIN').last);
    await tester.pumpAndSettle();
    expect(find.text('SBR Touch 2 15MIN'), findsOneWidget);

    // RBS shows the optional Touch 2 step, and Skip continues to timeframes.
    await tester.ensureVisible(addEntry);
    await tester.tap(addEntry);
    await tester.pumpAndSettle();
    await tester.tap(find.text('RBS').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('touch2-choice-RBS')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('skip-touch2-RBS')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30MIN').last);
    await tester.pumpAndSettle();
    expect(find.text('RBS 30MIN'), findsOneWidget);

    // RFS and SFR go straight to the existing timeframe picker.
    await tester.ensureVisible(addEntry);
    await tester.tap(addEntry);
    await tester.pumpAndSettle();
    expect(find.text('RFS'), findsOneWidget);
    await tester.tap(find.text('RFS').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('touch2-choice-RFS')), findsNothing);
    await tester.tap(find.text('5MIN').last);
    await tester.pumpAndSettle();
    expect(find.text('RFS 5MIN'), findsOneWidget);

    await tester.ensureVisible(addEntry);
    await tester.tap(addEntry);
    await tester.pumpAndSettle();
    await tester.tap(find.text('SFR').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('touch2-choice-SFR')), findsNothing);
    await tester.tap(find.text('1H').last);
    await tester.pumpAndSettle();
    expect(find.text('SFR 1H'), findsOneWidget);

    // Editing a saved SBR Touch 2 keeps that qualifier preselected.
    final savedTouch2 = find.text('SBR Touch 2 15MIN');
    await tester.ensureVisible(savedTouch2);
    await tester.tap(savedTouch2);
    await tester.pumpAndSettle();
    await tester.tap(find.text('SBR').last);
    await tester.pumpAndSettle();
    final touch2Option = find.byKey(const ValueKey('touch2-choice-SBR'));
    expect(tester.widget<ListTile>(touch2Option).selected, isTrue);
    await tester.tap(touch2Option);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2MIN').last);
    await tester.pumpAndSettle();
    expect(find.text('SBR Touch 2 2MIN'), findsOneWidget);

    final addConfirmation = find.byKey(const ValueKey('add-confirmation-setup'));
    await tester.ensureVisible(addConfirmation);
    await tester.tap(addConfirmation);
    await tester.pumpAndSettle();
    expect(find.text('Reject ᴷᵉʸ ᴸᵉᵛᵉˡ'), findsOneWidget);
    await tester.tap(find.text('مخصص — اكتب النوع').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'ارتداد من مستوى يومي');
    await tester.tap(find.text('تأكيد').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2MIN').last);
    await tester.pumpAndSettle();
    expect(find.text('ارتداد من مستوى يومي 2MIN'), findsOneWidget);

    await tester.ensureVisible(find.text('القرارات'));
    await tester.tap(find.text('القرارات'));
    await tester.pumpAndSettle();
    expect(
      find.byType(DecisionSectionLogo),
      findsNothing,
      reason: 'the decisions mark is reserved for the saved trade details',
    );
    await tester.tap(find.byKey(const ValueKey('review-enteredEarly')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('review-art-enteredEarly')), findsOneWidget);

    await tester.ensureVisible(find.text('الالتزام'));
    await tester.tap(find.text('الالتزام'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('review-fullPlanCompliance')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('review-art-fullPlanCompliance')), findsOneWidget);
    expect(find.byType(TradeReviewOptionEmoji), findsNWidgets(20));

    await tester.ensureVisible(find.text('أسباب عدم الدخول'));
    await tester.tap(find.text('أسباب عدم الدخول'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('no-entry-fearRepeatLossAfterLoss')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('review-art-fearRepeatLossAfterLoss')), findsOneWidget);
    expect(find.byType(TradeReviewOptionEmoji), findsNWidgets(25));

    final save = find.byKey(const ValueKey('save-trade-button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(savedTrade, isNotNull);
    expect(savedTrade!.market, 'EURUSD');
    expect(savedTrade!.entrySetups, const [
      TradeEntrySetup(reason: 'SBR Touch 2', timeframe: '2MIN'),
      TradeEntrySetup(reason: 'RBS', timeframe: '30MIN'),
      TradeEntrySetup(reason: 'RFS', timeframe: '5MIN'),
      TradeEntrySetup(reason: 'SFR', timeframe: '1H'),
    ]);
    expect(savedTrade!.confirmationSetups, const [TradeConfirmationSetup(type: 'ارتداد من مستوى يومي', timeframe: '2MIN')]);
    expect(savedTrade!.executionReviewKeys, containsAll(['enteredEarly', 'fullPlanCompliance']));
    expect(savedTrade!.noEntryReasons, ['fearRepeatLossAfterLoss']);
    expect(savedTrade!.expectedLoss, 100);
    expect(savedTrade!.riskPercent, 1);
    expect(savedTrade!.result / savedTrade!.expectedLoss!, closeTo(.425, .001));
  });
}
