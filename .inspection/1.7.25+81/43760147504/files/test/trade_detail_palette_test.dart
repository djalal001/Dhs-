import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trader_desk/theme/app_theme.dart';
import 'package:trader_desk/theme/trade_detail_palette.dart';

void main() {
  test('trade data panel preserves the original 1.7.17+73 colors', () {
    expect(TradeDetailPalette.dataTone, const Color(0xFF8AB4D9));
    expect(TradeDetailPalette.dataSurfaceDark, const Color(0xFF2B3B4C));
    expect(TradeDetailPalette.dataFieldDark, const Color(0xFF243140));
    expect(TradeDetailPalette.dataFieldEdge, const Color(0xFF425569));
  });

  test('trade review panel preserves the original 1.7.17+73 colors', () {
    expect(TradeDetailPalette.reviewTone, const Color(0xFFB7A6F2));
    expect(TradeDetailPalette.reviewOuterDark, const Color(0xFF292B36));
    expect(TradeDetailPalette.reviewDecisionDark, const Color(0xFF242526));
    expect(TradeDetailPalette.reviewCommitmentDark, const Color(0xFF172F2F));
    expect(TradeDetailPalette.reviewNoEntryDark, const Color(0xFF2A2635));
    expect(TradeDetailPalette.reviewDecisionOptionDark, const Color(0xFF383638));
    expect(TradeDetailPalette.reviewCommitmentOptionDark, const Color(0xFF203B39));
    expect(TradeDetailPalette.reviewNoEntryOptionDark, const Color(0xFF373047));
  });

  test('dark theme uses a restrained graphite ramp rather than pure black', () {
    final tokens = TdTokens.forBrightness(Brightness.dark);
    expect(tokens.bgBase, const Color(0xFF0B0D10));
    expect(tokens.surface1, const Color(0xFF101418));
    expect(tokens.surface2, const Color(0xFF151A20));
    expect(tokens.surface3, const Color(0xFF1B2128));
    expect(tokens.inset, const Color(0xFF0D1115));
    expect(tokens.bgBase, isNot(const Color(0xFF000000)));
    expect(tokens.surface1.computeLuminance(), greaterThan(tokens.bgBase.computeLuminance()));
    expect(tokens.surface2.computeLuminance(), greaterThan(tokens.surface1.computeLuminance()));
    expect(tokens.surface3.computeLuminance(), greaterThan(tokens.surface2.computeLuminance()));
  });
}
