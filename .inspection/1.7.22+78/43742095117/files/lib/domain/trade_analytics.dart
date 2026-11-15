import '../models/trade.dart';
import 'trade_ordering.dart';

class TradeAnalytics {
  const TradeAnalytics({
    required this.tradeCount,
    required this.wins,
    required this.losses,
    required this.breakEven,
    required this.netProfit,
    required this.averageWin,
    required this.averageLoss,
    required this.winRatePercent,
    required this.maxDrawdownAmount,
    required this.maxDrawdownPercent,
  });

  final int tradeCount;
  final int wins;
  final int losses;
  final int breakEven;
  final double netProfit;
  final double averageWin;
  final double averageLoss;
  final double winRatePercent;
  final double maxDrawdownAmount;
  final double maxDrawdownPercent;

  factory TradeAnalytics.calculate(
    List<Trade> input, {
    double startingBalance = 0,
  }) {
    if (!startingBalance.isFinite) {
      throw ArgumentError.value(startingBalance, 'startingBalance');
    }
    final trades = [...input]..sort(compareTradesAscending);
    var wins = 0;
    var losses = 0;
    var breakEven = 0;
    var winTotal = 0.0;
    var lossTotal = 0.0;
    var net = 0.0;

    var equity = startingBalance;
    var peak = startingBalance;
    var maxDrawdown = 0.0;
    var maxDrawdownPercent = 0.0;
    for (final trade in trades) {
      final result = trade.result;
      if (!result.isFinite) throw ArgumentError.value(result, 'trade.result');
      net += result;
      if (result > 0) {
        wins++;
        winTotal += result;
      } else if (result < 0) {
        losses++;
        lossTotal += result.abs();
      } else {
        breakEven++;
      }
      equity += result;
      if (equity > peak) peak = equity;
      final drawdown = peak - equity;
      if (drawdown > maxDrawdown) maxDrawdown = drawdown;
      final drawdownPercent = peak > 0 ? drawdown / peak * 100 : 0.0;
      if (drawdownPercent > maxDrawdownPercent)
        maxDrawdownPercent = drawdownPercent;
    }
    if (![net, winTotal, lossTotal, equity].every((value) => value.isFinite)) {
      throw ArgumentError('Trade totals exceed the supported numeric range.');
    }
    final averageWin = wins == 0 ? 0.0 : winTotal / wins;
    final averageLoss = losses == 0 ? 0.0 : lossTotal / losses;

    return TradeAnalytics(
      tradeCount: trades.length,
      wins: wins,
      losses: losses,
      breakEven: breakEven,
      netProfit: net,
      averageWin: averageWin,
      averageLoss: averageLoss,
      winRatePercent: trades.isEmpty ? 0 : wins / trades.length * 100,
      maxDrawdownAmount: maxDrawdown,
      maxDrawdownPercent: maxDrawdownPercent,
    );
  }
}
