import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trader_desk/data/local_store.dart';
import 'package:trader_desk/main.dart';
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
    temp = await Directory.systemTemp.createTemp('trader_desk_widget_');
    app = await AppController.create(
      store: LocalStore(documentsDirectory: () async => temp),
    );
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  testWidgets('opens accounts from a dedicated settings entry', (tester) async {
    await tester.pumpWidget(TraderDeskApp(controller: app));
    await tester.pumpAndSettle();
    expect(find.text('ملخص الأداء'), findsOneWidget);

    await tester.tap(find.text('الإعدادات').last);
    await tester.pumpAndSettle();
    expect(find.text('الحسابات'), findsOneWidget);
    expect(find.text('لا توجد حسابات بعد'), findsNothing);
    expect(find.text('نسخ النسخة الاحتياطية'), findsNothing);
    expect(find.text('جدول لجميع الحسابات لفتحه في Excel؛ لا يتضمن الصور.'), findsNothing);
    expect(find.text('استعادة بلصق نص JSON (بديل)'), findsNothing);
    expect(find.text('الخصوصية والتخزين'), findsNothing);

    await tester.tap(find.text('الحسابات').last);
    await tester.pumpAndSettle();
    expect(find.text('لا توجد حسابات بعد'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('لا توجد حسابات بعد'), findsNothing);
    expect(find.text('الحسابات'), findsOneWidget);
  });

  testWidgets('new trades start with an unrecorded mood, not an assumed one', (
    tester,
  ) async {
    final account = TradingAccount(
      id: 'mood-default-account',
      name: 'حساب تجريبي',
      type: AccountType.demo,
      startingBalance: 10000,
      currency: 'USD',
      createdAt: DateTime(2025, 1, 1),
    );
    app.accounts = [account];
    app.selectedAccountId = account.id;

    await tester.pumpWidget(
      AppScope(
        controller: app,
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: buildAppTheme(Brightness.dark),
          home: const TradeFormScreen(),
        ),
      ),
    );

    final formScroll = find
        .descendant(
          of: find.byType(TradeFormScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('حالة غير مسجلة'),
      240,
      scrollable: formScroll,
    );
    expect(find.text('حالة غير مسجلة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shows balance curve and opens trade form through app navigation',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final account = TradingAccount(
        id: 'account-route',
        name: 'حساب تجريبي',
        type: AccountType.demo,
        startingBalance: 10000,
        currency: 'USD',
        createdAt: DateTime(2025, 1, 1),
      );
      app.accounts = [account];
      app.selectedAccountId = account.id;
      app.trades = [
        Trade(
          id: 'trade-route',
          accountId: account.id,
          market: 'EURUSD',
          reason: 'Breakout',
          entrySetups: const [
            TradeEntrySetup(reason: 'Trend Line BUY', timeframe: '1H'),
            TradeEntrySetup(reason: 'RBS Touch 2', timeframe: '1H'),
          ],
          result: 125,
          riskPercent: 1,
          side: TradeSide.buy,
          confirmation: 'confirmTechnical',
          sequence: 'تأخرت في تأكيد الدخول',
          mood: 'moodCalm',
          executionJournal: const [
            TradeExecutionJournalEntry(
              status: TradeExecutionStatus.followedPlan,
            ),
            TradeExecutionJournalEntry(
              status: TradeExecutionStatus.avoidedEntryBecauseFear,
            ),
            TradeExecutionJournalEntry(
              status: TradeExecutionStatus.enteredEarly,
            ),
            TradeExecutionJournalEntry(
              status: TradeExecutionStatus.entryConditionsNotMet,
            ),
            TradeExecutionJournalEntry(
              status: TradeExecutionStatus.missedHigherTimeframeBounceArea,
            ),
            TradeExecutionJournalEntry(
              status: TradeExecutionStatus.missedLowerTimeframeBounceArea,
            ),
            TradeExecutionJournalEntry(
              status: TradeExecutionStatus.missedTrendlineFromCandleWicks,
            ),
            TradeExecutionJournalEntry(
              status: TradeExecutionStatus.hesitationPartialSize,
            ),
            TradeExecutionJournalEntry(status: TradeExecutionStatus.lateEntry),
            TradeExecutionJournalEntry(
              status: TradeExecutionStatus.stopLossMoved,
            ),
          ],
          tradedAt: DateTime(2025, 1, 2),
        ),
      ];
      await tester.pumpWidget(TraderDeskApp(controller: app));
      await tester.pump(const Duration(milliseconds: 450));

      expect(find.text('الأداء ونمو الرصيد'), findsOneWidget);
      expect(find.text('USD 10125.00'), findsWidgets);

      await tester.tap(find.text('الصفقات').last);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('EURUSD'), findsOneWidget);
      expect(find.text('Trend Line BUY 1H'), findsOneWidget);
      expect(find.text('RBS Touch 2 1H'), findsOneWidget);
      expect(find.text('Trend Line BUY · 1H'), findsNothing);
      expect(find.text('نوع التأكيد'), findsNothing);
      final animatedEmojiFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName.endsWith('.gif'),
      );
      expect(animatedEmojiFinder, findsNWidgets(10));
      expect(find.text('دخلت مبكراً'), findsNothing);
      final statusRegion = find.byKey(
        const ValueKey('trade-journal-icons-trade-route'),
      );
      final reasonRegion = find.byKey(
        const ValueKey('trade-entry-setups-trade-route'),
      );
      expect(statusRegion, findsOneWidget);
      expect(reasonRegion, findsOneWidget);
      final tradeCard = find.byKey(const ValueKey('trade-summary-trade-route'));
      final cardDivider = find.descendant(
        of: tradeCard,
        matching: find.byType(Divider),
      );
      expect(cardDivider, findsOneWidget);
      expect(
        tester.getRect(statusRegion).top,
        greaterThanOrEqualTo(tester.getRect(cardDivider).bottom),
      );
      expect(
        tester.getRect(statusRegion).right,
        lessThanOrEqualTo(tester.getRect(reasonRegion).left),
      );
      final statusIconFinder = find.descendant(
        of: statusRegion,
        matching: animatedEmojiFinder,
      );
      final statusIconTops = statusIconFinder
          .evaluate()
          .map((element) => tester.getTopLeft(find.byWidget(element.widget)).dy)
          .map((top) => top.round())
          .toList();
      expect(statusIconTops.toSet().length, lessThan(10));
      expect(
        statusIconTops.where((top) => top == statusIconTops.first).length,
        greaterThan(1),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('trade-summary-trade-route')));
      await tester.pumpAndSettle();
      expect(find.text('تفاصيل الصفقة'), findsOneWidget);
      expect(find.text('نوع التأكيد'), findsOneWidget);
      expect(find.text('الحالة النفسية'), findsOneWidget);
      expect(find.text('مخاطرة الحساب (%)'), findsOneWidget);
      expect(find.text('سبب الدخول'), findsOneWidget);
      expect(find.text('Trend Line BUY 1H'), findsOneWidget);
      expect(find.text('RBS Touch 2 1H'), findsOneWidget);
      expect(find.text('مدى الالتزام بالتنفيذ والأخطاء'), findsOneWidget);
      expect(find.text('دخلت مبكراً'), findsOneWidget);
      expect(find.text('دخلت مبكراً أو خارج الخطة'), findsNothing);
      expect(find.text('تأخرت في تأكيد الدخول'), findsOneWidget);
      expect(tester.takeException(), isNull);
      Navigator.of(tester.element(find.text('تفاصيل الصفقة'))).pop();
      await tester.pumpAndSettle();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      final addIcon = find.byIcon(Icons.add);
      expect(addIcon, findsOneWidget);
      final addButton = find
          .ancestor(of: addIcon, matching: find.byType(IconButton))
          .first;
      expect(tester.widget<IconButton>(addButton).onPressed, isNotNull);
      tester.widget<IconButton>(addButton).onPressed!.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      expect(tester.takeException(), isNull);
      expect(find.text('إضافة صفقة'), findsOneWidget);
      expect(find.text('السوق / الرمز'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is DropdownButtonFormField<String> &&
              widget.decoration.labelText == 'سبب الدخول',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'settings clearly lists full backup, CSV export and file restore',
    (tester) async {
      await tester.pumpWidget(TraderDeskApp(controller: app));
      await tester.pump(const Duration(milliseconds: 450));
      await tester.tap(find.text('الإعدادات').last);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('تصدير نسخة كاملة إلى ملف JSON'), findsOneWidget);
      expect(find.text('تصدير سجل الصفقات إلى CSV'), findsOneWidget);
      expect(find.text('استعادة من ملف JSON'), findsOneWidget);
    },
  );

  testWidgets(
    'expected loss becomes read-only for a negative trade result',
    (tester) async {
      final account = TradingAccount(
        id: 'loss-readonly-account',
        name: 'Demo test',
        type: AccountType.demo,
        startingBalance: 10000,
        currency: 'USD',
        createdAt: DateTime(2025, 1, 1),
      );
      app.accounts = [account];
      app.selectedAccountId = account.id;

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(Brightness.dark),
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: AppScope(controller: app, child: const TradeFormScreen()),
        ),
      );
      await tester.pump();

      final resultFinder = find.byKey(const ValueKey('trade-result-input'));
      final expectedLossFinder =
          find.byKey(const ValueKey('trade-expected-loss-input'));
      final riskFinder = find.byKey(const ValueKey('trade-risk-input'));
      final rewardRiskFinder =
          find.byKey(const ValueKey('trade-reward-risk-input'));

      await tester.enterText(expectedLossFinder, '100');
      await tester.pump();
      await tester.enterText(resultFinder, '-100');
      await tester.pump();

      var expectedLossField = tester.widget<TextFormField>(expectedLossFinder);
      expect(expectedLossField.readOnly, isTrue);
      expect(expectedLossField.controller!.text, isEmpty);
      expect(
        tester.widget<TextFormField>(riskFinder).controller!.text,
        '1.00',
      );
      expect(
        tester.widget<TextFormField>(rewardRiskFinder).controller!.text,
        '-1.00',
      );

      await tester.enterText(resultFinder, '200');
      await tester.pump();
      expectedLossField = tester.widget<TextFormField>(expectedLossFinder);
      expect(expectedLossField.readOnly, isFalse);
    },
  );

  testWidgets('trade form accepts a market', (tester) async {
    final account = TradingAccount(
      id: 'account-1',
      name: 'Demo test',
      type: AccountType.demo,
      startingBalance: 10000,
      currency: 'USD',
      createdAt: DateTime(2025, 1, 1),
    );
    app.accounts = [account];
    app.selectedAccountId = account.id;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: AppScope(controller: app, child: const TradeFormScreen()),
      ),
    );
    await tester.pump();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, 'EURUSD');
    await tester.pump();
    expect(find.text('EURUSD'), findsOneWidget);
  });
}
