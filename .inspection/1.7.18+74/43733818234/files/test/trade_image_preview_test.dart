import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trader_desk/theme/app_theme.dart';
import 'package:trader_desk/widgets/trade_image_preview.dart';

void main() {
  late Directory temp;
  late File imageFile;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('trader_desk_image_view_');
    imageFile = File('${temp.path}/before.png');
    await imageFile.writeAsBytes(_tinyPng);
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  testWidgets('tap opens a zoomable image with a save action in the top bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 250,
              child: TradeImagePreview(
                path: imageFile.path,
                label: 'صورة قبل الدخول',
                fileNamePrefix: 'traderdesk_before_test',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        ValueKey(
          'trade-image-preview-traderdesk_before_test-${imageFile.path}',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final viewer = find.byKey(const ValueKey('zoomable-trade-image'));
    expect(viewer, findsOneWidget);
    expect(find.byTooltip('حفظ الصورة'), findsOneWidget);
    expect(
      tester.widget<InteractiveViewer>(viewer).transformationController,
      isNotNull,
    );

    await tester.doubleTap(
      find.byKey(const ValueKey('trade-image-viewer-gestures')),
    );
    await tester.pumpAndSettle();
    final zoomController =
        tester.widget<InteractiveViewer>(viewer).transformationController!;
    expect(zoomController.value.getMaxScaleOnAxis(), closeTo(2.5, 0.001));

    await tester.doubleTap(
      find.byKey(const ValueKey('trade-image-viewer-gestures')),
    );
    await tester.pumpAndSettle();
    expect(zoomController.value.getMaxScaleOnAxis(), closeTo(1, 0.001));
  });
}

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
