import 'package:flutter_test/flutter_test.dart';
import 'package:trader_desk/domain/trade_entry_catalog.dart';
import 'package:trader_desk/models/trade.dart';

void main() {
  test('includes RFS and SFR as direct timeframe-based entry reasons', () {
    final keys = tradeEntryReasons.map((option) => option.key).toSet();

    expect(keys, containsAll(['SBR', 'RBS', 'RFS', 'SFR']));
    expect(keys, isNot(contains('SBR Touch 2')));
    expect(keys, isNot(contains('RBS Touch 2')));
  });

  test('defines the two independent Entry Conditions option lists', () {
    expect(tradeReverseSignalOptions.map((item) => item.key), [
      'negativeCloseAgainstDirection',
      'strongRejectionWickAgainstDirection',
    ]);
    expect(tradeBounceZoneOptions.map((item) => item.key), [
      'bounceFromSrZone',
      'internalLiquiditySweep',
      'majorStructureLiquiditySweep',
      'bounceFromTrendline',
      'bounceFromTrendlineAndSupplyZone',
    ]);
  });


  test('formats entry-condition labels without separator dots or duplicated names', () {
    const combined = TradeEntryConditionSetup(
      optionKey: 'bounceFromTrendlineAndSupplyZone',
      timeframe: '30MIN',
      secondaryTimeframe: '5MIN',
    );
    expect(
      formatTradeEntryConditionSetupLabel(
        setup: combined,
        optionLabel: 'ارتداد من ترند لاين و Supply Zone',
        arabic: true,
      ),
      'ارتداد من Trend Line 30MIN - Supply Zone 5MIN',
    );
    const regular = TradeEntryConditionSetup(
      optionKey: 'bounceFromSrZone',
      timeframe: '15MIN',
    );
    expect(
      formatTradeEntryConditionSetupLabel(
        setup: regular,
        optionLabel: 'ارتداد من منطقة S/R',
        arabic: true,
      ),
      'ارتداد من منطقة S/R 15MIN',
    );
  });

  test('S/R bounce label follows direction only after a side is selected', () {
    const setup = TradeEntryConditionSetup(
      optionKey: 'bounceFromSrZone',
      timeframe: '15MIN',
    );

    expect(
      formatTradeEntryConditionSetupLabel(
        setup: setup,
        optionLabel: 'ارتداد من منطقة S/R',
        arabic: true,
      ),
      'ارتداد من منطقة S/R 15MIN',
    );
    expect(
      formatTradeEntryConditionSetupLabel(
        setup: setup,
        optionLabel: 'ارتداد من منطقة S/R',
        arabic: true,
        side: TradeSide.buy,
      ),
      'ارتداد من منطقة دعم 15MIN',
    );
    expect(
      formatTradeEntryConditionSetupLabel(
        setup: setup,
        optionLabel: 'ارتداد من منطقة S/R',
        arabic: true,
        side: TradeSide.sell,
      ),
      'ارتداد من منطقة مقاومة 15MIN',
    );
    expect(
      formatTradeEntryConditionSetupLabel(
        setup: setup,
        optionLabel: 'Bounce from an S/R zone',
        arabic: false,
        side: TradeSide.buy,
      ),
      'Bounce from support 15MIN',
    );
  });

  test(
    'entry reason and confirmation labels place timeframe with a plain space',
    () {
      expect(
        const TradeEntrySetup(reason: 'RBS Touch 2', timeframe: '5MIN').label,
        'RBS Touch 2 5MIN',
      );
      expect(
        const TradeConfirmationSetup(
          type: 'Breakout–Pullback',
          timeframe: '15MIN',
        ).label,
        'Breakout–Pullback 15MIN',
      );
    },
  );

  test('Touch 2 qualifier is supported only for SBR and RBS', () {
    expect(tradeEntryTouch2EligibleReasons, {'SBR', 'RBS'});
    expect(tradeEntryBaseReason('SBR Touch 2'), 'SBR');
    expect(tradeEntryBaseReason('RBS Touch 2'), 'RBS');
    expect(tradeEntryUsesTouch2('SBR Touch 2'), isTrue);
    expect(tradeEntryUsesTouch2('RBS'), isFalse);
    expect(tradeEntryReasonWithTouch2('SBR', true), 'SBR Touch 2');
    expect(tradeEntryReasonWithTouch2('RBS', false), 'RBS');
    expect(tradeEntryReasonWithTouch2('RFS', true), 'RFS');
    expect(tradeEntryReasonWithTouch2('SFR', true), 'SFR');
  });
}
