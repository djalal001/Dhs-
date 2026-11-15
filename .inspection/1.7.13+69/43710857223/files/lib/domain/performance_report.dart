import '../models/trade.dart';

class MoodPerformance {
  const MoodPerformance({
    required this.mood,
    required this.tradeCount,
    required this.wins,
    required this.losses,
    required this.breakEven,
    required this.grossProfit,
    required this.grossLoss,
    required this.netProfit,
    required this.winRatePercent,
  });

  final String mood;
  final int tradeCount;
  final int wins;
  final int losses;
  final int breakEven;
  final double grossProfit;
  final double grossLoss;
  final double netProfit;
  final double winRatePercent;
}

class PerformanceReport {
  const PerformanceReport({
    required this.tradeCount,
    required this.wins,
    required this.losses,
    required this.breakEven,
    required this.grossProfit,
    required this.grossLoss,
    required this.netProfit,
    required this.winRatePercent,
    required this.averageWin,
    required this.averageLoss,
    required this.averageRiskPercent,
    required this.profitFactor,
    required this.moods,
  });

  final int tradeCount;
  final int wins;
  final int losses;
  final int breakEven;
  final double grossProfit;
  final double grossLoss;
  final double netProfit;
  final double winRatePercent;
  final double averageWin;
  final double averageLoss;
  final double averageRiskPercent;
  final double? profitFactor;
  final List<MoodPerformance> moods;

  factory PerformanceReport.calculate(
    Iterable<Trade> source, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final start = startDate == null ? null : _dateOnly(startDate);
    final end = endDate == null ? null : _dateOnly(endDate);
    if (start != null && end != null && end.isBefore(start)) {
      throw ArgumentError.value(
        endDate,
        'endDate',
        'Must not precede startDate.',
      );
    }

    var tradeCount = 0;
    var wins = 0;
    var losses = 0;
    var breakEven = 0;
    var grossProfit = 0.0;
    var grossLoss = 0.0;
    var riskTotal = 0.0;
    final byMood = <String, _MoodAggregate>{};
    for (final trade in source) {
      final date = _dateOnly(trade.tradedAt);
      if ((start != null && date.isBefore(start)) ||
          (end != null && date.isAfter(end))) {
        continue;
      }
      if (!trade.result.isFinite || !trade.riskPercent.isFinite) {
        throw ArgumentError('Trade contains a non-finite financial value.');
      }
      tradeCount++;
      riskTotal += trade.riskPercent;
      final moodKey = trade.mood.isEmpty ? 'moodUnknown' : trade.mood;
      final mood = byMood.putIfAbsent(moodKey, _MoodAggregate.new);
      mood.tradeCount++;
      if (trade.result > 0) {
        wins++;
        grossProfit += trade.result;
        mood.wins++;
        mood.grossProfit += trade.result;
      } else if (trade.result < 0) {
        losses++;
        grossLoss += trade.result.abs();
        mood.losses++;
        mood.grossLoss += trade.result.abs();
      } else {
        breakEven++;
        mood.breakEven++;
      }
    }
    final netProfit = grossProfit - grossLoss;
    final moodReports =
        byMood.entries.map((entry) {
          final mood = entry.value;
          return MoodPerformance(
            mood: entry.key,
            tradeCount: mood.tradeCount,
            wins: mood.wins,
            losses: mood.losses,
            breakEven: mood.breakEven,
            grossProfit: mood.grossProfit,
            grossLoss: mood.grossLoss,
            netProfit: mood.grossProfit - mood.grossLoss,
            winRatePercent: mood.tradeCount == 0
                ? 0
                : mood.wins / mood.tradeCount * 100,
          );
        }).toList()..sort((a, b) {
          final byCount = b.tradeCount.compareTo(a.tradeCount);
          return byCount != 0 ? byCount : a.mood.compareTo(b.mood);
        });
    final numericTotals = [grossProfit, grossLoss, netProfit, riskTotal];
    if (!numericTotals.every((value) => value.isFinite) ||
        moodReports.any(
          (mood) =>
              !mood.grossProfit.isFinite ||
              !mood.grossLoss.isFinite ||
              !mood.netProfit.isFinite,
        )) {
      throw ArgumentError('Trade totals exceed the supported numeric range.');
    }
    final averageWin = wins == 0 ? 0.0 : grossProfit / wins;
    final averageLoss = losses == 0 ? 0.0 : grossLoss / losses;

    return PerformanceReport(
      tradeCount: tradeCount,
      wins: wins,
      losses: losses,
      breakEven: breakEven,
      grossProfit: grossProfit,
      grossLoss: grossLoss,
      netProfit: netProfit,
      winRatePercent: tradeCount == 0 ? 0 : wins / tradeCount * 100,
      averageWin: averageWin,
      averageLoss: averageLoss,
      averageRiskPercent: tradeCount == 0 ? 0 : riskTotal / tradeCount,
      profitFactor: grossLoss == 0 ? null : grossProfit / grossLoss,
      moods: moodReports,
    );
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

class _MoodAggregate {
  int tradeCount = 0;
  int wins = 0;
  int losses = 0;
  int breakEven = 0;
  double grossProfit = 0;
  double grossLoss = 0;
}
