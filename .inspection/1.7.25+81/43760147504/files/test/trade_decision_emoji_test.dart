import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trader_desk/domain/trade_entry_catalog.dart';
import 'package:trader_desk/widgets/decision_option_emoji.dart';

void main() {
  test('all 15 Windows decision options have a matching emoji asset', () {
    final decisionKeys = tradeReviewGroups
        .expand((group) => group.options)
        .map((option) => option.key)
        .toSet();

    expect(decisionKeys, hasLength(15));
    expect(decisionOptionEmojiAssets.keys.toSet(), decisionKeys);
  });

  test('every decision emoji asset is bundled in the project', () {
    for (final asset in decisionOptionEmojiAssets.values) {
      expect(File(asset).existsSync(), isTrue, reason: asset);
    }
  });
  test('all 25 saved review options have a matching Windows illustration', () {
    final decisionKeys = tradeReviewGroups
        .expand((group) => group.options)
        .map((option) => option.key)
        .toSet();
    final commitmentKeys = tradeCommitmentOptions.map((option) => option.key).toSet();
    final noEntryKeys = tradeNoEntryOptions.map((option) => option.key).toSet();
    final expectedKeys = {...decisionKeys, ...commitmentKeys, ...noEntryKeys};

    expect(expectedKeys, hasLength(25));
    expect(tradeReviewOptionEmojiAssets.keys.toSet(), expectedKeys);
  });

  test('every commitment and no-entry illustration is bundled', () {
    for (final entry in tradeReviewOptionEmojiAssets.entries) {
      expect(File(entry.value).existsSync(), isTrue, reason: '${entry.key}: ${entry.value}');
    }
  });

  test('all 17 Windows SVG illustrations use animated WebP with alpha', () {
    final animatedKeys = {
      'stopLossReducedWithoutReason',
      'stopLossIncreasedWithoutReason',
      'noTrendlineSupportsEntryZone',
      'missedHigherTimeframeTrendlineIntegration',
      'stopLossIncreasedForLiquiditySafety',
      'stopLossReducedForNegativeClose',
      'partialSizeAwaitingDeepCorrection',
      ...tradeCommitmentOptions.map((option) => option.key),
      ...tradeNoEntryOptions.map((option) => option.key),
    };
    expect(animatedKeys, hasLength(17));

    for (final key in animatedKeys) {
      final asset = tradeReviewOptionEmojiAssets[key]!;
      expect(asset, endsWith('.webp'), reason: key);
      final bytes = File(asset).readAsBytesSync();
      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF', reason: key);
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WEBP', reason: key);
      var frameCount = 0;
      for (var i = 12; i + 3 < bytes.length; i++) {
        if (bytes[i] == 0x41 &&
            bytes[i + 1] == 0x4E &&
            bytes[i + 2] == 0x4D &&
            bytes[i + 3] == 0x46) {
          frameCount++;
        }
      }
      expect(frameCount, greaterThanOrEqualTo(10), reason: '$key should animate');
      final extendedHeader = <int>[
        for (var i = 12; i + 8 < bytes.length; i++)
          if (bytes[i] == 0x56 &&
              bytes[i + 1] == 0x50 &&
              bytes[i + 2] == 0x38 &&
              bytes[i + 3] == 0x58)
            bytes[i + 8],
      ];
      expect(extendedHeader, isNotEmpty, reason: '$key needs an extended WebP header');
      expect(extendedHeader.first & 0x10, isNot(0), reason: '$key must have alpha');
    }
  });

}
