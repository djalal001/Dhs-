import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trader_desk/models/trade.dart';
import 'package:trader_desk/screens/trades_screen.dart';
import 'package:trader_desk/theme/app_theme.dart';
import 'package:trader_desk/widgets/decision_option_emoji.dart';
import 'package:trader_desk/widgets/decision_section_logo.dart';

void main() {
  testWidgets('saved trade details preserve the Windows panel separation and review art', (
    tester,
  ) async {
    final trade = Trade(
      id: 'detail-layout-test',
      accountId: 'account-test',
      market: 'US100',
      reason: 'RBS Touch 2',
      result: 12.5,
      expectedLoss: 5,
      riskPercent: 1.25,
      side: TradeSide.buy,
      confirmation: 'confirmBreakoutPullback',
      entrySetups: const [
        TradeEntrySetup(reason: 'RBS Touch 2', timeframe: '5MIN'),
        TradeEntrySetup(reason: 'SBR Touch 2', timeframe: '1MIN'),
      ],
      confirmationSetups: const [
        TradeConfirmationSetup(type: 'confirmBreakoutPullback', timeframe: '15MIN'),
      ],
      reverseSignalSetups: const [
        TradeEntryConditionSetup(
          optionKey: 'strongRejectionWickAgainstDirection',
          timeframe: '5MIN',
        ),
      ],
      bounceZoneSetups: const [
        TradeEntryConditionSetup(
          optionKey: 'bounceFromTrendlineAndSupplyZone',
          timeframe: '1H',
          secondaryTimeframe: '15MIN',
        ),
        TradeEntryConditionSetup(
          optionKey: 'bounceFromSrZone',
          timeframe: '30MIN',
        ),
      ],
      sequence: 'Session opening',
      mood: 'moodCalm',
      tradedAt: DateTime(2026, 11, 5, 11, 21),
      executionReviewKeys: const [
        'enteredEarly',
        'missedHigherTimeframeBounceArea',
        'stopLossIncreasedForLiquiditySafety',
        'fullPlanCompliance',
      ],
      noEntryReasons: const ['fearLossNoHistory'],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: TradeDetailScreen(trade: trade, currency: 'USD'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('trade-detail-result-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('trade-detail-data-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('trade-detail-result-expected-loss-pair')), findsOneWidget);
    expect(find.byKey(const ValueKey('trade-detail-risk-reward-pair')), findsOneWidget);
    expect(find.byKey(const ValueKey('trade-detail-review-panel')), findsOneWidget);
    final reviewSurface = tester.widget<Container>(
      find.byKey(const ValueKey('trade-detail-review-panel-surface')),
    );
    expect(
      (reviewSurface.decoration as BoxDecoration).color,
      const Color(0xFF292B36),
      reason: 'the collapsed review panel must have a filled surface, not only a purple outline',
    );
    expect(find.text('النتيجة والمخاطرة'), findsOneWidget);
    expect(find.text('بيانات الصفقة'), findsOneWidget);
    expect(find.text('مراجعة الصفقة'), findsOneWidget);
    final resultToggle = find.byKey(
      const ValueKey('trade-detail-result-panel-toggle'),
    );
    await tester.tap(resultToggle);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('trade-detail-result-value')), findsNothing);
    await tester.tap(resultToggle);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('trade-detail-result-value')), findsOneWidget);
    expect(find.text('US100'), findsNothing, reason: 'trade data starts folded');
    expect(find.text('مخالفات التنفيذ'), findsNothing, reason: 'review starts folded');
    final reviewToggle = find.byKey(
      const ValueKey('trade-detail-review-panel-toggle'),
    );
    await tester.ensureVisible(reviewToggle);
    await tester.tap(reviewToggle);
    await tester.pumpAndSettle();
    expect(find.text('مخالفات التنفيذ'), findsOneWidget);
    expect(find.text('جودة التحليل والإعداد'), findsOneWidget);
    expect(find.text('قرارات الدخول وإدارة المخاطرة'), findsOneWidget);
    expect(find.text('الالتزام'), findsOneWidget);
    expect(find.text('أسباب عدم الدخول'), findsOneWidget);
    expect(find.byType(TradeReviewOptionEmoji), findsNWidgets(5));
    expect(find.byType(DecisionSectionLogo), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('trade-review-group-decisions')),
        matching: find.byIcon(Icons.rule_rounded),
      ),
      findsOneWidget,
      reason: 'saved decisions use a distinct rule icon rather than the opposing-signal warning icon',
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('trade-review-group-decisions')),
        matching: find.byIcon(Icons.warning_amber_rounded),
      ),
      findsNothing,
    );
    final decisionsGroupRect = tester.getRect(
      find.byKey(const ValueKey('trade-review-group-decisions')),
    );
    final selectedDecisionRect = tester.getRect(
      find.byKey(const ValueKey('trade-review-option-tile-enteredEarly')),
    );
    expect(
      selectedDecisionRect.width,
      greaterThan(decisionsGroupRect.width - 20),
      reason: 'review option tiles should retain only a slim left and right inset',
    );
    final commitmentToggle = find.byKey(
      const ValueKey('trade-review-group-commitment-toggle'),
    );
    await tester.tap(commitmentToggle);
    await tester.pumpAndSettle();
    expect(find.text('التزمت بالخطة كاملة دون مخالفة.'), findsNothing);
    expect(find.text('أسباب عدم الدخول'), findsOneWidget);
    await tester.tap(commitmentToggle);
    await tester.pumpAndSettle();
    expect(find.text('التزمت بالخطة كاملة دون مخالفة.'), findsOneWidget);

    final dataToggle = find.byKey(
      const ValueKey('trade-detail-data-panel-toggle'),
    );
    await tester.ensureVisible(dataToggle);
    await tester.tap(dataToggle);
    await tester.pumpAndSettle();
    expect(find.text('US100'), findsOneWidget);
    expect(find.byKey(const ValueKey('trade-detail-market-direction-pair')), findsOneWidget);
    expect(find.byKey(const ValueKey('trade-detail-entry-reasons')), findsOneWidget);
    expect(find.byKey(const ValueKey('trade-detail-confirmations')), findsOneWidget);
    expect(find.text('RBS Touch 2 5MIN'), findsOneWidget);
    expect(find.text('SBR Touch 2 1MIN'), findsOneWidget);
    expect(find.text('Breakout–Pullback 15MIN'), findsOneWidget);

    final conditionsToggle = find.byKey(
      const ValueKey('trade-detail-entry-conditions-toggle'),
    );
    await tester.ensureVisible(conditionsToggle);
    await tester.tap(conditionsToggle);
    await tester.pumpAndSettle();
    expect(find.text('إشارات عكسية'), findsOneWidget);
    expect(find.text('منطقة الارتداد'), findsOneWidget);
    expect(find.textContaining('5MIN'), findsWidgets);
    expect(find.text('ارتداد من Trend Line 1H - Supply Zone 15MIN'), findsOneWidget);
    expect(find.text('ارتداد من منطقة دعم 30MIN'), findsOneWidget);

    final conditionsPanelRect = tester.getRect(
      find.byKey(const ValueKey('trade-detail-entry-conditions-panel')),
    );
    final reverseFieldRect = tester.getRect(
      find.byKey(const ValueKey('trade-detail-reverse-signals')),
    );
    expect(
      reverseFieldRect.width,
      greaterThan(conditionsPanelRect.width - 20),
      reason: 'entry-condition text fields should use the panel width with only a slim inset',
    );

    // Compact metric/identity fields occupy half-width slots instead of full rows.
    final resultWidth = tester.getSize(
      find.byKey(const ValueKey('trade-detail-result-value')),
    ).width;
    final expectedLossWidth = tester.getSize(
      find.byKey(const ValueKey('trade-detail-expected-loss-value')),
    ).width;
    final marketWidth = tester.getSize(
      find.byKey(const ValueKey('trade-detail-data-row-0')),
    ).width;
    final directionWidth = tester.getSize(
      find.byKey(const ValueKey('trade-detail-data-row-1')),
    ).width;
    expect((resultWidth - expectedLossWidth).abs(), lessThan(1));
    expect((marketWidth - directionWidth).abs(), lessThan(1));

    final detailList = tester.widget<ListView>(
      find.byKey(const ValueKey('trade-detail-scroll-view')),
    );
    expect(detailList.padding, const EdgeInsetsDirectional.fromSTEB(8, 10, 8, 24));

    // The main trade-data panel can be folded with one tap and restored
    // without losing any of the saved detail values.
    await tester.tap(dataToggle);
    await tester.pumpAndSettle();
    expect(find.text('بيانات الصفقة'), findsOneWidget);
    expect(find.text('US100'), findsNothing);
    await tester.tap(dataToggle);
    await tester.pumpAndSettle();
    expect(find.text('US100'), findsOneWidget);
    expect(find.text('RBS Touch 2 5MIN'), findsOneWidget);
  });

  testWidgets(
    'saved sell trade presents the S/R bounce as resistance',
    (tester) async {
      final trade = Trade(
        id: 'detail-sell-sr-test',
        accountId: 'account-test',
        market: 'EURUSD',
        reason: 'RFS',
        result: -10,
        riskPercent: 1,
        side: TradeSide.sell,
        confirmation: 'confirmBearishEngulfing',
        bounceZoneSetups: const [
          TradeEntryConditionSetup(
            optionKey: 'bounceFromSrZone',
            timeframe: '15MIN',
          ),
        ],
        mood: 'moodCalm',
        tradedAt: DateTime(2026, 11, 14, 10),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(Brightness.dark),
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: TradeDetailScreen(trade: trade, currency: 'USD'),
        ),
      );
      await tester.pumpAndSettle();
      final conditionsToggle = find.byKey(
        const ValueKey('trade-detail-entry-conditions-toggle'),
      );
      await tester.tap(conditionsToggle);
      await tester.pumpAndSettle();
      expect(find.text('ارتداد من منطقة مقاومة 15MIN'), findsOneWidget);
      expect(find.text('ارتداد من منطقة S/R 15MIN'), findsNothing);
    },
  );
}
