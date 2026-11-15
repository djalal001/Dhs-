import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trader_desk/data/local_store.dart';
import 'package:trader_desk/models/trade.dart';
import 'package:trader_desk/models/trading_account.dart';
import 'package:trader_desk/state/app_controller.dart';

void main() {
  late Directory temp;
  late Directory imageDirectory;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('trade_image_cleanup_');
    imageDirectory = Directory('${temp.path}/trade_images');
    await imageDirectory.create(recursive: true);
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  LocalStore store() => LocalStore(documentsDirectory: () async => temp);

  Future<String> image(String name, {int byteCount = 3}) async {
    final file = File('${imageDirectory.path}/$name');
    await file.writeAsBytes(List<int>.filled(byteCount, 1));
    return file.path;
  }

  Trade trade(
    String id, {
    String? before,
    String? after,
    String? confirmation,
  }) => Trade(
    id: id,
    accountId: 'account',
    market: 'NQ',
    reason: 'Trend line',
    result: 1,
    riskPercent: 1,
    side: TradeSide.buy,
    confirmation: '',
    sequence: '',
    mood: '',
    tradedAt: DateTime(2026, 1, 1),
    beforeImagePath: before,
    afterImagePath: after,
    confirmationImagePath: confirmation,
  );

  test('deleting a trade removes its three unshared stored images', () async {
    final app = await AppController.create(store: store());
    final before = await image('before.jpg');
    final after = await image('after.jpg');
    final confirmation = await image('confirmation.jpg');
    app.trades = [
      trade('one', before: before, after: after, confirmation: confirmation),
    ];

    await app.deleteTrade('one');

    expect(app.trades, isEmpty);
    expect(await File(before).exists(), isFalse);
    expect(await File(after).exists(), isFalse);
    expect(await File(confirmation).exists(), isFalse);
    final saved = await store().read();
    expect(saved!['trades'], isEmpty);
  });

  test('replacing an image removes the old file after saving the edit', () async {
    final app = await AppController.create(store: store());
    final oldImage = await image('old.jpg');
    final newImage = await image('new.jpg');
    app.trades = [trade('one', before: oldImage)];

    await app.updateTrade(trade('one', before: newImage));

    expect(await File(oldImage).exists(), isFalse);
    expect(await File(newImage).exists(), isTrue);
    final saved = await store().read();
    final savedTrade = Trade.fromJson(
      Map<String, dynamic>.from((saved!['trades'] as List).single as Map),
    );
    expect(savedTrade.beforeImagePath, newImage);
  });

  test('an image referenced by another trade is retained', () async {
    final app = await AppController.create(store: store());
    final shared = await image('shared.jpg');
    app.trades = [
      trade('one', before: shared),
      trade('two', confirmation: shared),
    ];

    await app.deleteTrade('one');

    expect(app.trades.map((item) => item.id), ['two']);
    expect(await File(shared).exists(), isTrue);
  });

  test('image deletion failures do not block deleting the trade', () async {
    final app = await AppController.create(store: store());
    final invalidImageFile = Directory('${imageDirectory.path}/not-a-file.jpg');
    await invalidImageFile.create();
    app.trades = [trade('one', before: invalidImageFile.path)];

    await expectLater(app.deleteTrade('one'), completes);

    expect(app.trades, isEmpty);
    expect(await invalidImageFile.exists(), isTrue);
  });

  test('an image is retained when saving the trade edit fails', () async {
    final failingStore = _FailingWriteStore(temp);
    final app = await AppController.create(store: failingStore);
    final oldImage = await image('old-after-failed-save.jpg');
    final newImage = await image('new-after-failed-save.jpg');
    app.trades = [trade('one', before: oldImage)];

    await app.updateTrade(trade('one', before: newImage));

    expect(await File(oldImage).exists(), isTrue);
    expect(app.trades.single.beforeImagePath, oldImage);
  });

  test('1000-trade history can be backed up, restored, and pruned safely', () async {
    final app = await AppController.create(store: store());
    final allImages = <String>[];
    final trades = <Trade>[];
    for (var index = 0; index < 1000; index++) {
      final suffix = index.toString().padLeft(4, '0');
      final before = await image('before-$suffix.jpg', byteCount: 4096);
      final after = await image('after-$suffix.jpg', byteCount: 4096);
      final confirmation = await image(
        'confirmation-$suffix.jpg',
        byteCount: 4096,
      );
      allImages.addAll([before, after, confirmation]);
      trades.add(
        trade(
          'trade-$suffix',
          before: before,
          after: after,
          confirmation: confirmation,
        ),
      );
    }
    app.trades = trades;

    final backupTimer = Stopwatch()..start();
    final backup = await app.createBackup();
    backupTimer.stop();
    final restoredRoot = Directory('${temp.path}/restored');
    await restoredRoot.create();
    final restored = await AppController.create(
      store: LocalStore(documentsDirectory: () async => restoredRoot),
    );
    final restoreTimer = Stopwatch()..start();
    await restored.restoreBackup(backup);
    restoreTimer.stop();
    expect(restored.trades, hasLength(1000));
    final restoredImage = restored.trades.first.beforeImagePath!;
    expect(await File(restoredImage).exists(), isTrue);

    final deleteTimer = Stopwatch()..start();
    await app.deleteTrade('trade-0000');
    deleteTimer.stop();
    expect(app.trades, hasLength(999));
    for (final removedImage in allImages.take(3)) {
      expect(await File(removedImage).exists(), isFalse);
    }
    expect(await File(allImages[3]).exists(), isTrue);
    final saved = await store().read();
    expect(saved!['trades'], hasLength(999));
    // Logged for performance review without imposing a hardware-specific limit.
    // ignore: avoid_print
    print(
      '1000 trades / 3000 images (4 KiB each): '
      'backup ${backupTimer.elapsed}, '
      'restore ${restoreTimer.elapsed}, '
      'delete ${deleteTimer.elapsed}',
    );
  }, timeout: Timeout(Duration(minutes: 10)));
}

class _FailingWriteStore extends LocalStore {
  _FailingWriteStore(Directory root)
    : super(documentsDirectory: () async => root);

  @override
  Future<void> write({
    required List<TradingAccount> accounts,
    required List<Trade> trades,
    required bool isDark,
    required String languageCode,
    required String? selectedAccountId,
  }) async {
    throw const FileSystemException('simulated write failure');
  }
}
