import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trader_desk/data/local_store.dart';
import 'package:trader_desk/models/trade.dart';
import 'package:trader_desk/models/trading_account.dart';
import 'package:trader_desk/screens/days_screen.dart';
import 'package:trader_desk/state/app_controller.dart';
import 'package:trader_desk/state/app_scope.dart';
import 'package:trader_desk/theme/app_theme.dart';

void main() {
  late Directory temp;
  late AppController app;
  late File beforeImage;
  late File afterImage;
  late File confirmationImage;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('trader_desk_calendar_');
    beforeImage = File('${temp.path}/trade_before.png');
    afterImage = File('${temp.path}/trade_after.png');
    confirmationImage = File('${temp.path}/trade_confirmation.png');
    await beforeImage.writeAsBytes(_tinyPng);
    await afterImage.writeAsBytes(_tinyPng);
    await confirmationImage.writeAsBytes(_tinyPng);
    app = await AppController.create(
      store: LocalStore(documentsDirectory: () async => temp),
    );
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  testWidgets(
    'monthly calendar navigates and aggregates trades by their actual trade date',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final now = DateTime.now();
      final tradeDate = DateTime(now.year, now.month, 8, 15);
      final account = TradingAccount(
        id: 'calendar-account',
        name: 'حساب التقويم',
        type: AccountType.demo,
        startingBalance: 10000,
        currency: 'USD',
        createdAt: DateTime(2025, 1, 1),
      );
      app.accounts = [account];
      app.selectedAccountId = account.id;
      app.trades = [
        _trade(
          id: 'calendar-win',
          accountId: account.id,
          date: tradeDate,
          result: 100,
          beforeImagePath: beforeImage.path,
          afterImagePath: afterImage.path,
          confirmationImagePath: confirmationImage.path,
        ),
        _trade(
          id: 'calendar-loss',
          accountId: account.id,
          date: tradeDate.add(const Duration(minutes: 30)),
          result: -25,
        ),
      ];

      await tester.pumpWidget(
        AppScope(
          controller: app,
          child: MaterialApp(
            theme: buildAppTheme(Brightness.dark),
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const Scaffold(body: DaysScreen()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('أحد'), findsOneWidget);
      expect(find.text('إثنين'), findsOneWidget);
      expect(find.text('سبت'), findsOneWidget);
      expect(find.textContaining('${now.year}'), findsWidgets);

      final currentMonthTitle = tester
          .widget<Text>(find.byKey(const ValueKey('calendar-month-title')))
          .data;
      await tester.tap(find.byTooltip('الشهر السابق'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('calendar-month-title')))
            .data,
        isNot(currentMonthTitle),
      );
      await tester.tap(find.byTooltip('الشهر التالي'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('calendar-month-title')))
            .data,
        currentMonthTitle,
      );

      await tester.tap(find.byKey(const ValueKey('calendar-go-today')));
      await tester.pumpAndSettle();
      final today = DateTime.now();
      final todayCell = find.byKey(
        ValueKey('calendar-day-${_dateLabel(today)}'),
      );
      expect(todayCell, findsOneWidget);
      expect(tester.getSize(todayCell).height, greaterThanOrEqualTo(96));

      final firstOfMonth = DateTime(now.year, now.month, 1);
      final leadingDays = firstOfMonth.weekday % 7;
      final expectedCellCount =
          ((leadingDays + DateUtils.getDaysInMonth(now.year, now.month) + 6) ~/
              7) *
          7;
      final visibleCalendarCells = find
          .byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith(
                  'calendar-day-',
                ),
          )
          .evaluate()
          .length;
      expect(visibleCalendarCells, expectedCellCount);

      final tradeDayCell = find.byKey(
        ValueKey('calendar-day-${_dateLabel(tradeDate)}'),
      );
      expect(tradeDayCell, findsOneWidget);
      await tester.tap(tradeDayCell);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('day-detail-date')), findsOneWidget);
      expect(find.text('2 صفقة/صفقات'), findsNWidgets(2));
      expect(find.text('USD 100.00'), findsNWidgets(2));
      expect(find.text('USD 25.00'), findsOneWidget);
      expect(find.text('-USD 25.00'), findsOneWidget);
      expect(find.text('USD 75.00'), findsNWidgets(2));
      expect(find.textContaining('EURUSD'), findsNWidgets(2));

      final beforePreview = find.byKey(
        ValueKey(
          'trade-image-preview-traderdesk_before_calendar-win-${beforeImage.path}',
        ),
      );
      final afterPreview = find.byKey(
        ValueKey(
          'trade-image-preview-traderdesk_after_calendar-win-${afterImage.path}',
        ),
      );
      final confirmationPreview = find.byKey(
        ValueKey(
          'trade-image-preview-traderdesk_confirmation_calendar-win-${confirmationImage.path}',
        ),
      );
      expect(beforePreview, findsOneWidget);
      expect(afterPreview, findsOneWidget);
      expect(confirmationPreview, findsOneWidget);
      expect(find.text('صورة قبل الدخول'), findsOneWidget);
      expect(find.text('صورة بعد الدخول'), findsOneWidget);
      expect(find.text('صورة تأكيد الدخول'), findsOneWidget);

      await tester.ensureVisible(beforePreview);
      await tester.tap(beforePreview);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('zoomable-trade-image')),
        findsOneWidget,
      );
      expect(find.byTooltip('حفظ الصورة'), findsOneWidget);
      Navigator.of(
        tester.element(find.byKey(const ValueKey('zoomable-trade-image'))),
      ).pop();
      await tester.pumpAndSettle();

      await tester.ensureVisible(afterPreview);
      await tester.tap(afterPreview);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('zoomable-trade-image')),
        findsOneWidget,
      );
      Navigator.of(
        tester.element(find.byKey(const ValueKey('zoomable-trade-image'))),
      ).pop();
      await tester.pumpAndSettle();

      await tester.ensureVisible(confirmationPreview);
      await tester.tap(confirmationPreview);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('zoomable-trade-image')),
        findsOneWidget,
      );
      Navigator.of(
        tester.element(find.byKey(const ValueKey('zoomable-trade-image'))),
      ).pop();
      await tester.pumpAndSettle();

      Navigator.of(
        tester.element(find.byKey(const ValueKey('day-detail-date'))),
      ).pop();
      await tester.pumpAndSettle();

      // Removing one trade, editing the remaining result, then removing all
      // trades must refresh the visible day without restarting the calendar.
      app.trades = [app.trades.first];
      app.notifyListeners();
      await tester.pump();
      expect(
        find.descendant(of: tradeDayCell, matching: find.text('+100')),
        findsOneWidget,
      );

      app.trades = [
        _trade(
          id: 'calendar-win',
          accountId: account.id,
          date: tradeDate,
          result: 80,
        ),
      ];
      app.notifyListeners();
      await tester.pump();
      expect(
        find.descendant(of: tradeDayCell, matching: find.text('+80')),
        findsOneWidget,
      );

      app.trades = [];
      app.notifyListeners();
      await tester.pump();
      expect(
        find.descendant(of: tradeDayCell, matching: find.text('+80')),
        findsNothing,
      );
    },
  );

  testWidgets('calendar stays responsive with 1000 trades in one month', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.now();
    final account = TradingAccount(
      id: 'calendar-large-account',
      name: 'Large journal',
      type: AccountType.demo,
      startingBalance: 10000,
      currency: 'USD',
      createdAt: DateTime(2025, 1, 1),
    );
    app.accounts = [account];
    app.selectedAccountId = account.id;
    app.trades = List<Trade>.generate(
      1000,
      (index) => _trade(
        id: 'calendar-large-$index',
        accountId: account.id,
        date: DateTime(now.year, now.month, index % 28 + 1, index % 24),
        result: index.isEven ? 1.25 : -0.75,
      ),
      growable: false,
    );

    await tester.pumpWidget(
      AppScope(
        controller: app,
        child: MaterialApp(
          theme: buildAppTheme(Brightness.dark),
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const Scaffold(body: DaysScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('monthly-calendar-grid')), findsOneWidget);
    expect(find.text('1000 صفقة/صفقات'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Trade _trade({
  required String id,
  required String accountId,
  required DateTime date,
  required double result,
  String? beforeImagePath,
  String? afterImagePath,
  String? confirmationImagePath,
}) => Trade(
  id: id,
  accountId: accountId,
  market: 'EURUSD',
  reason: 'تأكيد الاختراق',
  result: result,
  riskPercent: 1,
  side: TradeSide.buy,
  confirmation: 'confirmTechnical',
  sequence: '',
  mood: 'moodCalm',
  tradedAt: date,
  beforeImagePath: beforeImagePath,
  afterImagePath: afterImagePath,
  confirmationImagePath: confirmationImagePath,
);

String _dateLabel(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

const _tinyPng = <int>[
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  8,
  6,
  0,
  0,
  0,
  31,
  21,
  196,
  137,
  0,
  0,
  0,
  13,
  73,
  68,
  65,
  84,
  8,
  215,
  99,
  248,
  207,
  192,
  240,
  31,
  0,
  5,
  0,
  1,
  255,
  137,
  153,
  61,
  29,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
];
