import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trader_desk/data/local_store.dart';
import 'package:trader_desk/main.dart';
import 'package:trader_desk/state/app_controller.dart';

void main() {
  testWidgets('performance analysis section is removed from primary navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final directory = Directory.systemTemp.createTempSync(
      'trader_desk_navigation_',
    );
    final app = await tester.runAsync(
      () => AppController.create(
        store: LocalStore(documentsDirectory: () async => directory),
      ),
    );
    if (app == null) {
      throw StateError('Could not initialize test controller.');
    }

    await tester.pumpWidget(TraderDeskApp(controller: app));
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('تحليل الأداء'), findsNothing);
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('الصفقات'), findsOneWidget);
    expect(find.text('الأيام'), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => directory.delete(recursive: true));
  });
}
