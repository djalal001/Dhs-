import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trader_desk/models/trade.dart';
import 'package:trader_desk/screens/trades_screen.dart';
import 'package:trader_desk/theme/app_theme.dart';

void main() {
  testWidgets('trade review keeps decisions, commitment and no-entry grouped', (
    tester,
  ) async {
    final trade = Trade(
      id: 'review-test',
      accountId: 'account-test',
      market: 'US100',
      reason: 'RBS',
      result: 12,
      riskPercent: 1,
      side: TradeSide.buy,
      confirmation: 'Breakout–Pullback',
      sequence: '',
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
        home: Scaffold(
          body: ListView(children: [TradeBehaviorSummary(trade: trade)]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('مراجعة الصفقة'), findsOneWidget);
    expect(find.text('القرارات'), findsOneWidget);
    expect(find.text('الالتزام'), findsOneWidget);
    expect(find.text('أسباب عدم الدخول'), findsOneWidget);
    expect(find.text('مخالفات التنفيذ'), findsOneWidget);
    expect(find.text('جودة التحليل والإعداد'), findsOneWidget);
    expect(find.text('قرارات الدخول وإدارة المخاطرة'), findsOneWidget);
    expect(find.text('دخلت مبكرًا.'), findsOneWidget);
    expect(find.text('التزمت بالخطة كاملة دون مخالفة.'), findsOneWidget);
    expect(find.text('الخوف من الخسارة دون وجود ربح أو خسارة سابقة.'), findsOneWidget);
  });
}
