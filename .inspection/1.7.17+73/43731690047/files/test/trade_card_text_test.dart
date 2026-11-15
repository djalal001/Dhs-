import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trader_desk/theme/app_theme.dart';
import 'package:trader_desk/widgets/trade_info_tile.dart';

void main() {
  testWidgets('displays the full long trade detail without tapping to expand', (
    tester,
  ) async {
    final value = List.filled(
      12,
      'هذا سياق طويل للصفقة يشرح الأخطاء والتحليل والخطوات بالتفصيل',
    ).join(' — ');
    const label = 'مدى الالتزام بالتنفيذ والأخطاء';

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: ListView(
            children: [
              Center(
                child: SizedBox(
                  width: 220,
                  child: TradeInfoTile(label: label, value: value),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(label), findsOneWidget);
    expect(find.text(value), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.widget<Text>(find.text(value)).maxLines, isNull);
  });
}
