import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trader_desk/data/local_store.dart';
import 'package:trader_desk/main.dart';
import 'package:trader_desk/models/trade.dart';
import 'package:trader_desk/models/trading_account.dart';
import 'package:trader_desk/state/app_controller.dart';
import 'package:trader_desk/theme/app_theme.dart';
import 'package:trader_desk/widgets/common.dart';

void main() {
  late Directory temp;
  late AppController app;
  late TradingAccount account;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('trader_desk_large_ui_');
    app = await AppController.create(
      store: LocalStore(documentsDirectory: () async => temp),
    );
    account = TradingAccount(
      id: 'large-ui-account',
      name: 'Stress account',
      type: AccountType.demo,
      startingBalance: 10000,
      currency: 'USD',
      createdAt: DateTime(2024, 1, 1),
    );
    app.accounts = [account];
    app.selectedAccountId = account.id;
    app.trades = List.generate(
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
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  void usePhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('interactive equity chart renders 1000 trades without errors', (
    tester,
  ) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(TraderDeskApp(controller: app));
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('ملخص الأداء'), findsNothing);
    expect(find.text('Stress account'), findsNothing);
    expect(find.byIcon(Icons.account_balance_wallet_outlined), findsNothing);
    expect(find.byIcon(Icons.swap_horiz_rounded), findsNothing);

    final chart = find.byKey(const ValueKey('equity-curve-canvas'));
    expect(chart, findsOneWidget);
    final chartTheme = Theme.of(tester.element(chart));
    final tokens = chartTheme.extension<TdTokens>();
    expect(tokens?.bgBase, const Color(0xFF050607));
    expect(chartTheme.scaffoldBackgroundColor, const Color(0xFF050607));
    final activeHomeIcon = tester.widget<Icon>(
      find.byIcon(Icons.space_dashboard_rounded),
    );
    expect(activeHomeIcon.color, Colors.white);
    await tester.ensureVisible(chart);
    await tester.pump();
    await tester.tapAt(tester.getRect(chart).center);
    await tester.pump();
    expect(find.byKey(const ValueKey('equity-readout')), findsOneWidget);
    expect(tester.takeException(), isNull);

    expect(find.byKey(const ValueKey('equity-zoom-in')), findsNothing);
    expect(find.byKey(const ValueKey('equity-zoom-out')), findsNothing);
    expect(find.byKey(const ValueKey('equity-zoom-reset')), findsNothing);
    expect(find.byIcon(Icons.zoom_in), findsNothing);
    expect(find.byIcon(Icons.zoom_out), findsNothing);

    // Pinch gestures are the only chart zoom controls. Spreading two pointers
    // zooms in and exposes the overview scrubber; pinching back out restores it.
    final chartRect = tester.getRect(chart);
    final firstPointer = await tester.startGesture(
      chartRect.center - const Offset(30, 0),
      pointer: 11,
    );
    final secondPointer = await tester.startGesture(
      chartRect.center + const Offset(30, 0),
      pointer: 12,
    );
    await tester.pump();
    await firstPointer.moveTo(chartRect.center - const Offset(110, 0));
    await secondPointer.moveTo(chartRect.center + const Offset(110, 0));
    await tester.pump();
    expect(find.byKey(const ValueKey('equity-scrubber')), findsOneWidget);
    await firstPointer.moveTo(chartRect.center - const Offset(5, 0));
    await secondPointer.moveTo(chartRect.center + const Offset(5, 0));
    await tester.pump();
    expect(find.byKey(const ValueKey('equity-scrubber')), findsNothing);
    await firstPointer.up();
    await secondPointer.up();
    await tester.pump();
    expect(tester.takeException(), isNull);

    final periodMenu = find.byKey(const ValueKey('equity-period-menu'));
    await tester.ensureVisible(periodMenu);
    await tester.tap(periodMenu);
    await tester.pumpAndSettle();
    expect(find.text('أسبوع'), findsOneWidget);
    expect(find.text('شهر'), findsOneWidget);
    expect(find.text('3 أشهر'), findsNothing);
    expect(find.text('سنة'), findsOneWidget);
    expect(find.text('الكل'), findsWidgets);
    expect(find.text('فترة مخصصة'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('equity-range-month')));
    await tester.pumpAndSettle();
    final closedPeriodSelector = find.byKey(
      const ValueKey('equity-period-selector'),
    );
    expect(
      tester.widget<Text>(
        find.descendant(
          of: closedPeriodSelector,
          matching: find.byType(Text),
        ),
      ).data,
      'شهر',
    );
    // The closed period control stays compact and shows the active metric icon
    // beside the selected period rather than stretching across the chart.
    final compactSelectorRect = tester.getRect(closedPeriodSelector);
    expect(compactSelectorRect.width, lessThan(180));
    expect(compactSelectorRect.height, lessThan(52));
    expect(
      find.descendant(
        of: closedPeriodSelector,
        matching: find.byKey(
          const ValueKey('equity-period-selected-mode-icon'),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: closedPeriodSelector,
        matching: find.byIcon(Icons.attach_money_rounded),
      ),
      findsOneWidget,
    );

    // The balance and percent icon controls belong inside the opened period
    // menu, not beside the closed period selector.
    final modePanel = find.byKey(const ValueKey('equity-period-popup-panel'));
    final periodSelector = find.byKey(
      const ValueKey('equity-period-selector'),
    );
    final balanceMode = find.byKey(const ValueKey('equity-mode-balance'));
    final percentMode = find.byKey(const ValueKey('equity-mode-percent'));
    expect(
      find.byKey(const ValueKey('equity-period-selector-row')),
      findsOneWidget,
    );
    expect(balanceMode, findsNothing);
    expect(percentMode, findsNothing);

    await tester.tap(periodMenu);
    await tester.pumpAndSettle();
    expect(modePanel, findsOneWidget);
    expect(balanceMode, findsOneWidget);
    expect(percentMode, findsOneWidget);
    final balanceRect = tester.getRect(balanceMode);
    final percentRect = tester.getRect(percentMode);
    expect(balanceRect.center.dy, closeTo(percentRect.center.dy, 1));
    expect(balanceRect.center.dx, lessThan(percentRect.center.dx));
    final popupRect = tester.getRect(modePanel);
    expect(popupRect.contains(balanceRect.center), isTrue);
    expect(popupRect.contains(percentRect.center), isTrue);
    final allRange = find.byKey(const ValueKey('equity-range-all'));
    expect(allRange, findsOneWidget);
    final allRangeRect = tester.getRect(allRange);
    expect(popupRect.contains(allRangeRect.center), isTrue);
    expect(balanceRect.center.dx, lessThan(allRangeRect.center.dx));
    expect(
      find.descendant(
        of: balanceMode,
        matching: find.byIcon(Icons.attach_money_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: percentMode,
        matching: find.byIcon(Icons.percent_rounded),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<Semantics>(balanceMode).properties.selected,
      isTrue,
    );
    expect(
      tester.widget<Semantics>(percentMode).properties.selected,
      isFalse,
    );

    await tester.tap(percentMode);
    await tester.pumpAndSettle();
    expect(modePanel, findsNothing);
    expect(
      tester.widget<Text>(
        find.descendant(
          of: periodSelector,
          matching: find.byType(Text),
        ),
      ).data,
      'شهر',
    );
    expect(
      find.descendant(
        of: periodSelector,
        matching: find.byIcon(Icons.percent_rounded),
      ),
      findsOneWidget,
    );

    await tester.tap(periodMenu);
    await tester.pumpAndSettle();
    expect(
      tester.widget<Semantics>(percentMode).properties.selected,
      isTrue,
    );
    await tester.tap(balanceMode);
    await tester.pumpAndSettle();
    expect(modePanel, findsNothing);

    await tester.ensureVisible(periodMenu);
    await tester.tap(periodMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('equity-range-custom')));
    await tester.pumpAndSettle();
    expect(find.text('اختر الفترة الزمنية'), findsOneWidget);
    await tester.tap(find.text('إلغاء').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('1000-trade list builds rows lazily and can reach oldest trade', (
    tester,
  ) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(TraderDeskApp(controller: app));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.tap(find.text('الصفقات').last);
    await tester.pump(const Duration(milliseconds: 450));

    expect(
      find.byKey(const ValueKey('trade-summary-stress-999')),
      findsWidgets,
    );
    expect(find.byKey(const ValueKey('trade-summary-stress-0')), findsNothing);
    final builtTradeCards = find.byWidgetPredicate(
      (widget) =>
          widget is AppCard &&
          widget.key is ValueKey<String> &&
          (widget.key as ValueKey<String>).value.startsWith('trade-summary-'),
    );
    expect(builtTradeCards.evaluate().length, lessThan(20));
    expect(tester.takeException(), isNull);

    final verticalTradeList = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          widget.axisDirection == AxisDirection.down &&
          widget.physics is! NeverScrollableScrollPhysics,
    );
    expect(verticalTradeList, findsOneWidget);
    final listState = tester.state<ScrollableState>(verticalTradeList);
    expect(listState.position.maxScrollExtent, greaterThan(0));
    final oldestTrade = find.byKey(const ValueKey('trade-summary-stress-0'));
    for (
      var attempt = 0;
      attempt < 100 && oldestTrade.evaluate().isEmpty;
      attempt++
    ) {
      listState.position.jumpTo(listState.position.maxScrollExtent);
      await tester.pump();
    }
    expect(oldestTrade, findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
