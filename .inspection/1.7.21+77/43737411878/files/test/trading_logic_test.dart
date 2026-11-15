import 'package:flutter_test/flutter_test.dart';
import 'package:trader_desk/domain/risk_calculator.dart';
import 'package:trader_desk/domain/trade_analytics.dart';
import 'package:trader_desk/models/trade.dart';

Trade trade(
  String id,
  double result,
  DateTime date, {
  String mood = 'moodCalm',
  double risk = 1,
  double? expectedLoss,
}) => Trade(
  id: id,
  accountId: 'a',
  market: 'EURUSD',
  reason: 'test',
  result: result,
  riskPercent: risk,
  expectedLoss: expectedLoss,
  side: TradeSide.buy,
  confirmation: 'confirmTechnical',
  sequence: '',
  mood: mood,
  tradedAt: date,
);

void main() {
  group('TradeAnalytics', () {
    test('calculates net, win rate, averages and peak-to-trough drawdown', () {
      final analytics = TradeAnalytics.calculate([
        trade('1', 100, DateTime(2025, 1, 1)),
        trade('2', -50, DateTime(2025, 1, 2)),
        trade('3', 0, DateTime(2025, 1, 3)),
        trade('4', 50, DateTime(2025, 1, 4)),
      ], startingBalance: 1000);
      expect(analytics.netProfit, 100);
      expect(analytics.tradeCount, 4);
      expect(analytics.wins, 2);
      expect(analytics.losses, 1);
      expect(analytics.breakEven, 1);
      expect(analytics.winRatePercent, 50);
      expect(analytics.averageWin, 75);
      expect(analytics.averageLoss, 50);
      expect(analytics.maxDrawdownAmount, 50);
      expect(analytics.maxDrawdownPercent, closeTo(50 / 1100 * 100, 1e-9));
    });

    test('does not add expected loss to a negative realized result', () {
      final losingTrade = trade(
        'same-loss-value',
        -25,
        DateTime(2025, 1, 2),
        expectedLoss: 25,
      );

      final analytics = TradeAnalytics.calculate([losingTrade]);

      expect(analytics.netProfit, -25);
      expect(analytics.averageLoss, 25);
    });

    test('returns zero-safe statistics for an empty journal', () {
      final analytics = TradeAnalytics.calculate([]);
      expect(analytics.tradeCount, 0);
      expect(analytics.winRatePercent, 0);
      expect(analytics.averageWin, 0);
      expect(analytics.maxDrawdownAmount, 0);
    });

    test('tracks maximum drawdown amount and percentage independently', () {
      final analytics = TradeAnalytics.calculate([
        trade('1', -20, DateTime(2025, 1, 1)),
        trade('2', 120, DateTime(2025, 1, 2)),
        trade('3', -30, DateTime(2025, 1, 3)),
      ], startingBalance: 100);

      expect(analytics.maxDrawdownAmount, 30);
      expect(analytics.maxDrawdownPercent, 20);
    });

    test('aggregates a 1000-trade history without losing count or totals', () {
      final trades = List.generate(
        1000,
        (index) => trade(
          'trade-$index',
          index.isEven ? 10 : -5,
          DateTime(2024, 1, 1).add(Duration(minutes: index)),
          risk: 0.25,
        ),
      );

      final analytics = TradeAnalytics.calculate(
        trades,
        startingBalance: 10000,
      );

      expect(analytics.tradeCount, 1000);
      expect(analytics.wins, 500);
      expect(analytics.losses, 500);
      expect(analytics.netProfit, 2500);
      expect(analytics.averageWin, 10);
      expect(analytics.averageLoss, 5);
      expect(analytics.maxDrawdownAmount, 5);
      expect(analytics.maxDrawdownPercent, closeTo(5 / 10010 * 100, 1e-9));
    });

    test('rejects non-finite results and an overflowing aggregate', () {
      expect(
        () => TradeAnalytics.calculate([
          trade('nan', double.nan, DateTime(2025, 1, 1)),
        ]),
        throwsArgumentError,
      );
      expect(
        () => TradeAnalytics.calculate([
          trade('1', 1e308, DateTime(2025, 1, 1)),
          trade('2', 1e308, DateTime(2025, 1, 2)),
        ]),
        throwsArgumentError,
      );
    });
  });


  group('RiskCalculator', () {
    test('calculates cash risk, generic units and reward-to-risk', () {
      final output = RiskCalculator.calculate(
        accountBalance: 10000,
        riskPercent: 1,
        entryPrice: 100,
        stopLossPrice: 98,
        takeProfitPrice: 104,
      );
      expect(output.riskCash, 100);
      expect(output.stopDistance, 2);
      expect(output.units, 50);
      expect(output.targetCash, 200);
      expect(output.rewardToRisk, 2);
    });

    test('rejects a zero stop distance and invalid risk', () {
      expect(
        () => RiskCalculator.calculate(
          accountBalance: 1000,
          riskPercent: 1,
          entryPrice: 10,
          stopLossPrice: 10,
        ),
        throwsArgumentError,
      );
      expect(
        () => RiskCalculator.calculate(
          accountBalance: 1000,
          riskPercent: 101,
          entryPrice: 10,
          stopLossPrice: 9,
        ),
        throwsArgumentError,
      );
    });
  });
}
