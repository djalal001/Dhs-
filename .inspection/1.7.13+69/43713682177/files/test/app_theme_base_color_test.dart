import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trader_desk/theme/app_theme.dart';

void main() {
  test('dark-mode app background uses the exact approved neutral black', () {
    const expected = Color(0xFF151515);
    final tokens = TdTokens.forBrightness(Brightness.dark);
    final theme = buildAppTheme(Brightness.dark);

    expect(tokens.bgBase, expected);
    expect(theme.scaffoldBackgroundColor, expected);
    expect(theme.appBarTheme.backgroundColor, expected);
  });

  test('the four approved dark palette levels are exact', () {
    final tokens = TdTokens.forBrightness(Brightness.dark);

    expect(tokens.bgBase, const Color(0xFF151515));
    expect(tokens.surface1, const Color(0xFF1B1B1B));
    expect(tokens.surface2, const Color(0xFF222222));
    expect(tokens.surface3, const Color(0xFF2A2A2A));
    expect(tokens.cardTop, const Color(0xFF1B1B1B));
    expect(tokens.cardBottom, const Color(0xFF1B1B1B));
    expect(tokens.heroStart, const Color(0xFF222222));
    expect(tokens.cardGradient.colors, const [
      Color(0xFF1B1B1B),
      Color(0xFF1B1B1B),
    ]);
    expect(tokens.heroGradient.colors, const [
      Color(0xFF222222),
      Color(0xFF1B1B1B),
    ]);
    expect(tokens.primaryGradient.colors, const [
      Color(0xFFD0D0D0),
      Color(0xFFD0D0D0),
    ]);
  });

  test('dark support colors are neutral grayscale', () {
    final tokens = TdTokens.forBrightness(Brightness.dark);
    final neutralColors = <Color>[
      tokens.bgBase,
      tokens.surface1,
      tokens.surface2,
      tokens.surface3,
      tokens.inset,
      tokens.lineSubtle,
      tokens.lineStrong,
      tokens.text1,
      tokens.text2,
      tokens.text3,
      tokens.accent,
      tokens.accentBtnTop,
      tokens.accentBtnBottom,
      tokens.warn,
      tokens.warnStrong,
      tokens.cardTop,
      tokens.cardBottom,
      tokens.heroStart,
    ];

    for (final color in neutralColors) {
      expect(color.red, color.green);
      expect(color.green, color.blue);
    }
  });

  test('profit and loss semantic colors remain unchanged', () {
    final tokens = TdTokens.forBrightness(Brightness.dark);

    expect(tokens.profit, const Color(0xFF34D399));
    expect(tokens.profitStrong, const Color(0xFF34D399));
    expect(tokens.loss, const Color(0xFFFF6B7A));
    expect(tokens.lossStrong, const Color(0xFFFF6B7A));
  });

  test('light palette remains unchanged', () {
    final tokens = TdTokens.forBrightness(Brightness.light);
    final theme = buildAppTheme(Brightness.light);

    expect(tokens.bgBase, const Color(0xFFF3F0EB));
    expect(tokens.surface1, const Color(0xFFFFFEFC));
    expect(tokens.surface2, const Color(0xFFF8F5F0));
    expect(tokens.surface3, const Color(0xFFECE7DF));
    expect(tokens.inset, const Color(0xFFEDE8E0));
    expect(tokens.accent, const Color(0xFF786C5B));
    expect(tokens.cardGradient.colors, const [
      Color(0xFFFFFEFC),
      Color(0xFFF9F6F1),
    ]);
    expect(tokens.heroGradient.colors, const [
      Color(0xFFEAE3D8),
      Color(0xFFFFFEFC),
    ]);
    expect(tokens.primaryGradient.colors, const [
      Color(0xFF8B7D69),
      Color(0xFF746754),
    ]);
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF3F0EB));
  });
}
