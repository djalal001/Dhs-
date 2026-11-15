import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trader_desk/theme/app_theme.dart';

void main() {
  test('dark-mode app background matches the reference screenshot', () {
    const expected = Color(0xFF151515);
    final tokens = TdTokens.forBrightness(Brightness.dark);
    final theme = buildAppTheme(Brightness.dark);

    expect(tokens.bgBase, expected);
    expect(theme.scaffoldBackgroundColor, expected);
    expect(theme.appBarTheme.backgroundColor, expected);
  });


  test('dark surfaces and supporting UI colors are neutral grayscale', () {
    final tokens = TdTokens.forBrightness(Brightness.dark);
    final darkTheme = buildAppTheme(Brightness.dark);
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
      tokens.cardTop,
      tokens.cardBottom,
      tokens.heroStart,
    ];

    for (final color in neutralColors) {
      expect(color.red, color.green);
      expect(color.green, color.blue);
    }
    expect(tokens.bgBase, const Color(0xFF151515));
    expect(tokens.surface1, const Color(0xFF1B1B1B));
    expect(tokens.surface2, const Color(0xFF222222));
    expect(tokens.surface3, const Color(0xFF2A2A2A));
    expect(darkTheme.scaffoldBackgroundColor, const Color(0xFF151515));

    final lightTokens = TdTokens.forBrightness(Brightness.light);
    expect(lightTokens.bgBase, const Color(0xFFF3F0EB));
    expect(lightTokens.surface1, const Color(0xFFFFFEFC));
    expect(lightTokens.surface2, const Color(0xFFF8F5F0));
  });
}
