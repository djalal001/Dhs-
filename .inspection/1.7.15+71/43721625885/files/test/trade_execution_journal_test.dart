import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trader_desk/models/trade.dart';
import 'package:trader_desk/theme/app_theme.dart';
import 'package:trader_desk/widgets/trade_execution_journal.dart';

void main() {
  testWidgets('selects any combination from the single flat status list', (
    tester,
  ) async {
    Set<TradeExecutionJournalEntry> selected = {};

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) => TradeExecutionJournalSelector(
                selectedEntries: selected,
                onChanged: (entries) => setState(() => selected = entries),
              ),
            ),
          ),
        ),
      ),
    );

    for (final status in TradeExecutionStatus.values) {
      final option = find.byKey(ValueKey('journal-option-${status.name}'));
      await tester.ensureVisible(option);
      await tester.tap(option);
      await tester.pumpAndSettle();
    }

    expect(selected, hasLength(12));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName.endsWith('.gif'),
      ),
      findsNWidgets(12),
    );
    for (final status in TradeExecutionStatus.values) {
      expect(selected, contains(TradeExecutionJournalEntry(status: status)));
    }
    expect(find.text('قبل الصفقة'), findsNothing);
    expect(find.text('أثناء تنفيذ الصفقة'), findsNothing);
    expect(find.text('بعد الصفقة'), findsNothing);
    expect(find.text('دخلت مبكراً'), findsOneWidget);
    expect(find.text('دخلت مبكراً أو خارج الخطة'), findsNothing);
    expect(find.text('بسبب تردد لم افتح صفقة بالحجم الكامل'), findsOneWidget);
    expect(find.text('دخلت متأخر'), findsOneWidget);
    expect(find.text('غيرت مكان وقف الخسارة'), findsOneWidget);
    expect(
      find.text('لم احترم الهدف خرجت مبكرا بسبب خوف ضياع الارباح'),
      findsOneWidget,
    );

    final firstOption = find.byKey(
      const ValueKey('journal-option-followedPlan'),
    );
    await tester.ensureVisible(firstOption);
    await tester.tap(firstOption);
    await tester.pumpAndSettle();
    expect(selected, hasLength(11));
    expect(
      selected,
      isNot(
        contains(
          const TradeExecutionJournalEntry(
            status: TradeExecutionStatus.followedPlan,
          ),
        ),
      ),
    );
  });
}
