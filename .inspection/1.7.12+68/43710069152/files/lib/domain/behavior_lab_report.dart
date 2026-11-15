import '../models/trade.dart';
import 'trade_ordering.dart';

/// A descriptive, on-device summary of behaviors the trader explicitly logged.
/// It does not diagnose a person or infer a cause for a trade result.
class BehaviorLabReport {
  const BehaviorLabReport({
    required this.tradeCount,
    required this.moodRecordedTradeCount,
    required this.journalRecordedTradeCount,
    required this.followedPlanTradeCount,
    required this.deviationTradeCount,
    required this.mixedJournalTradeCount,
    required this.adherencePercent,
    required this.moodOutcomes,
    required this.scenarioOutcomes,
    required this.mistakePatterns,
    required this.riskAfterLoss,
  });

  static const minimumMoodSampleSize = 5;
  static const minimumRiskTransitionsPerGroup = 3;
  static const riskIncreaseThresholdPercentPoints = 0.05;

  final int tradeCount;
  final int moodRecordedTradeCount;
  final int journalRecordedTradeCount;
  final int followedPlanTradeCount;
  final int deviationTradeCount;
  final int mixedJournalTradeCount;

  /// Null means there are no clear, non-contradictory journal entries to score.
  final double? adherencePercent;
  final List<MoodOutcomePattern> moodOutcomes;
  final List<ScenarioMoodOutcomePattern> scenarioOutcomes;
  final List<ExecutionMistakePattern> mistakePatterns;
  final LossRiskResponse riskAfterLoss;

  int get adherenceSampleCount => followedPlanTradeCount + deviationTradeCount;

  double get moodCoveragePercent =>
      tradeCount == 0 ? 0 : moodRecordedTradeCount / tradeCount * 100;

  double get journalCoveragePercent =>
      tradeCount == 0 ? 0 : journalRecordedTradeCount / tradeCount * 100;

  factory BehaviorLabReport.calculate(
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

    final trades = <Trade>[];
    for (final trade in source) {
      final date = _dateOnly(trade.tradedAt);
      if ((start != null && date.isBefore(start)) ||
          (end != null && date.isAfter(end))) {
        continue;
      }
      if (!trade.result.isFinite || !trade.riskPercent.isFinite) {
        throw ArgumentError('Trade contains a non-finite financial value.');
      }
      trades.add(trade);
    }
    trades.sort(compareTradesAscending);

    var moodRecorded = 0;
    var journalRecorded = 0;
    var followedPlan = 0;
    var deviations = 0;
    var mixedJournal = 0;
    final moodGroups = <String, _MoodOutcomeAggregate>{};
    final scenarioGroups = <(String, String), _ScenarioOutcomeAggregate>{};
    final mistakeGroups = <TradeExecutionStatus, _MistakeAggregate>{};

    for (final trade in trades) {
      final moodKey = trade.mood.isEmpty ? 'moodUnknown' : trade.mood;
      if (moodKey != 'moodUnknown') moodRecorded++;
      final mood = moodGroups.putIfAbsent(moodKey, _MoodOutcomeAggregate.new);
      mood.tradeCount++;

      final statuses = trade.executionJournal
          .map((entry) => entry.status)
          .toSet();
      if (statuses.isNotEmpty) journalRecorded++;
      final hasPlan = statuses.contains(TradeExecutionStatus.followedPlan);
      final mistakeStatuses = statuses
          .where((status) => status != TradeExecutionStatus.followedPlan)
          .toList(growable: false);
      if (hasPlan && mistakeStatuses.isNotEmpty) {
        // Conflicting labels are visible, but excluded from the adherence rate.
        mixedJournal++;
      } else if (mistakeStatuses.isNotEmpty) {
        deviations++;
      } else if (hasPlan) {
        followedPlan++;
      }

      for (final status in mistakeStatuses) {
        mistakeGroups.putIfAbsent(status, _MistakeAggregate.new).tradeCount++;
      }

      // Missed or deliberately skipped entries do not have a realized trade
      // outcome. Keep their mood record visible, but exclude it from win rate.
      if (statuses.any(_isNoEntryStatus)) continue;
      mood.outcomeTradeCount++;
      final riskMultiple = _riskMultiple(trade);
      if (riskMultiple != null) mood.addRiskMultiple(riskMultiple);
      if (trade.result > 0) {
        mood.wins++;
        mood.netResult += trade.result;
      } else if (trade.result < 0) {
        mood.losses++;
        mood.netResult += trade.result;
      } else {
        mood.breakEven++;
      }
      final scenarios = trade.effectiveEntrySetups
          .map((setup) => setup.label.trim())
          .where((label) => label.isNotEmpty)
          .toSet();
      for (final scenario in scenarios) {
        scenarioGroups
            .putIfAbsent((moodKey, scenario), _ScenarioOutcomeAggregate.new)
            .add(trade.result, riskMultiple);
      }
    }

    final adherenceSample = followedPlan + deviations;
    final moodReports =
        moodGroups.entries.map((entry) {
          final value = entry.value;
          return MoodOutcomePattern(
            mood: entry.key,
            tradeCount: value.tradeCount,
            outcomeTradeCount: value.outcomeTradeCount,
            wins: value.wins,
            losses: value.losses,
            breakEven: value.breakEven,
            netResult: value.netResult,
            winRatePercent: value.outcomeTradeCount == 0
                ? 0
                : value.wins / value.outcomeTradeCount * 100,
            averageResultPerTrade: value.outcomeTradeCount == 0
                ? 0
                : value.netResult / value.outcomeTradeCount,
            riskUnitSampleCount: value.riskUnitSampleCount,
            averageRiskMultiple: value.averageRiskMultiple,
          );
        }).toList()..sort((a, b) {
          final byOutcomeCount = b.outcomeTradeCount.compareTo(
            a.outcomeTradeCount,
          );
          return byOutcomeCount != 0
              ? byOutcomeCount
              : a.mood.compareTo(b.mood);
        });

    if (moodReports.any(
      (mood) =>
          !mood.netResult.isFinite ||
          !mood.winRatePercent.isFinite ||
          !mood.averageResultPerTrade.isFinite ||
          (mood.averageRiskMultiple?.isFinite ?? true) == false,
    )) {
      throw ArgumentError('Mood outcomes exceed the supported numeric range.');
    }

    final scenarioReports =
        scenarioGroups.entries.map((entry) {
          final value = entry.value;
          return ScenarioMoodOutcomePattern(
            mood: entry.key.$1,
            entryScenario: entry.key.$2,
            outcomeTradeCount: value.tradeCount,
            wins: value.wins,
            losses: value.losses,
            breakEven: value.breakEven,
            netResult: value.netResult,
            winRatePercent: value.tradeCount == 0
                ? 0
                : value.wins / value.tradeCount * 100,
            averageResultPerTrade: value.tradeCount == 0
                ? 0
                : value.netResult / value.tradeCount,
            riskUnitSampleCount: value.riskUnitSampleCount,
            averageRiskMultiple: value.averageRiskMultiple,
          );
        }).toList()..sort((a, b) {
          final byCount = b.outcomeTradeCount.compareTo(a.outcomeTradeCount);
          if (byCount != 0) return byCount;
          final byMood = a.mood.compareTo(b.mood);
          return byMood != 0
              ? byMood
              : a.entryScenario.compareTo(b.entryScenario);
        });
    if (scenarioReports.any(
      (scenario) =>
          !scenario.netResult.isFinite ||
          !scenario.winRatePercent.isFinite ||
          !scenario.averageResultPerTrade.isFinite ||
          (scenario.averageRiskMultiple?.isFinite ?? true) == false,
    )) {
      throw ArgumentError(
        'Scenario outcomes exceed the supported numeric range.',
      );
    }

    final mistakes =
        mistakeGroups.entries.map((entry) {
          return ExecutionMistakePattern(
            status: entry.key,
            tradeCount: entry.value.tradeCount,
          );
        }).toList()..sort((a, b) {
          final byCount = b.tradeCount.compareTo(a.tradeCount);
          return byCount != 0
              ? byCount
              : a.status.name.compareTo(b.status.name);
        });

    final executedTrades = trades
        .where((trade) => !_hasNoEntryStatus(trade))
        .toList(growable: false);
    final riskResponse = _calculateRiskResponse(executedTrades);
    return BehaviorLabReport(
      tradeCount: trades.length,
      moodRecordedTradeCount: moodRecorded,
      journalRecordedTradeCount: journalRecorded,
      followedPlanTradeCount: followedPlan,
      deviationTradeCount: deviations,
      mixedJournalTradeCount: mixedJournal,
      adherencePercent: adherenceSample == 0
          ? null
          : followedPlan / adherenceSample * 100,
      moodOutcomes: List.unmodifiable(moodReports),
      scenarioOutcomes: List.unmodifiable(scenarioReports),
      mistakePatterns: List.unmodifiable(mistakes),
      riskAfterLoss: riskResponse,
    );
  }
}

class MoodOutcomePattern {
  const MoodOutcomePattern({
    required this.mood,
    required this.tradeCount,
    required this.outcomeTradeCount,
    required this.wins,
    required this.losses,
    required this.breakEven,
    required this.netResult,
    required this.winRatePercent,
    required this.averageResultPerTrade,
    required this.riskUnitSampleCount,
    required this.averageRiskMultiple,
  });

  final String mood;
  final int tradeCount;
  final int outcomeTradeCount;
  final int wins;
  final int losses;
  final int breakEven;
  final double netResult;
  final double winRatePercent;
  final double averageResultPerTrade;
  final int riskUnitSampleCount;
  final double? averageRiskMultiple;
}

class ScenarioMoodOutcomePattern {
  const ScenarioMoodOutcomePattern({
    required this.mood,
    required this.entryScenario,
    required this.outcomeTradeCount,
    required this.wins,
    required this.losses,
    required this.breakEven,
    required this.netResult,
    required this.winRatePercent,
    required this.averageResultPerTrade,
    required this.riskUnitSampleCount,
    required this.averageRiskMultiple,
  });

  final String mood;
  final String entryScenario;
  final int outcomeTradeCount;
  final int wins;
  final int losses;
  final int breakEven;
  final double netResult;
  final double winRatePercent;
  final double averageResultPerTrade;
  final int riskUnitSampleCount;
  final double? averageRiskMultiple;
}

class ExecutionMistakePattern {
  const ExecutionMistakePattern({
    required this.status,
    required this.tradeCount,
  });

  final TradeExecutionStatus status;
  final int tradeCount;
}

class LossRiskResponse {
  const LossRiskResponse({
    required this.afterLossTransitionCount,
    required this.afterLossRiskIncreasedCount,
    required this.afterOtherTransitionCount,
    required this.afterOtherRiskIncreasedCount,
    required this.averageRiskAfterLoss,
    required this.averageRiskAfterOther,
  });

  final int afterLossTransitionCount;
  final int afterLossRiskIncreasedCount;
  final int afterOtherTransitionCount;
  final int afterOtherRiskIncreasedCount;
  final double? averageRiskAfterLoss;
  final double? averageRiskAfterOther;

  bool get hasComparableSample =>
      afterLossTransitionCount >=
          BehaviorLabReport.minimumRiskTransitionsPerGroup &&
      afterOtherTransitionCount >=
          BehaviorLabReport.minimumRiskTransitionsPerGroup;

  double? get riskIncreaseRateAfterLoss => afterLossTransitionCount == 0
      ? null
      : afterLossRiskIncreasedCount / afterLossTransitionCount * 100;

  double? get riskIncreaseRateAfterOther => afterOtherTransitionCount == 0
      ? null
      : afterOtherRiskIncreasedCount / afterOtherTransitionCount * 100;
}

bool _isNoEntryStatus(TradeExecutionStatus status) => switch (status) {
  TradeExecutionStatus.avoidedEntryBecauseFear ||
  TradeExecutionStatus.entryConditionsNotMet ||
  TradeExecutionStatus.missedHigherTimeframeBounceArea ||
  TradeExecutionStatus.missedLowerTimeframeBounceArea ||
  TradeExecutionStatus.missedTrendlineFromCandleWicks ||
  TradeExecutionStatus.noBreakoutPositiveClose => true,
  _ => false,
};

bool _hasNoEntryStatus(Trade trade) =>
    trade.executionJournal.any((entry) => _isNoEntryStatus(entry.status));

LossRiskResponse _calculateRiskResponse(List<Trade> trades) {
  final afterLoss = _RiskTransitionAggregate();
  final afterOther = _RiskTransitionAggregate();
  for (var index = 1; index < trades.length; index++) {
    final previous = trades[index - 1];
    final next = trades[index];
    // Zero means the older record did not contain a usable risk percentage.
    if (previous.riskPercent <= 0 || next.riskPercent <= 0) continue;
    final aggregate = previous.result < 0 ? afterLoss : afterOther;
    aggregate.add(
      previousRisk: previous.riskPercent,
      nextRisk: next.riskPercent,
    );
  }
  return LossRiskResponse(
    afterLossTransitionCount: afterLoss.count,
    afterLossRiskIncreasedCount: afterLoss.increasedCount,
    afterOtherTransitionCount: afterOther.count,
    afterOtherRiskIncreasedCount: afterOther.increasedCount,
    averageRiskAfterLoss: _finiteAverage(afterLoss),
    averageRiskAfterOther: _finiteAverage(afterOther),
  );
}

double? _finiteAverage(_RiskTransitionAggregate aggregate) {
  if (aggregate.count == 0) return null;
  final average = aggregate.nextRiskTotal / aggregate.count;
  if (!average.isFinite) {
    throw ArgumentError('Risk transitions exceed the supported numeric range.');
  }
  return average;
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

class _MoodOutcomeAggregate {
  int tradeCount = 0;
  int outcomeTradeCount = 0;
  int wins = 0;
  int losses = 0;
  int breakEven = 0;
  double netResult = 0;
  int riskUnitSampleCount = 0;
  double riskMultipleTotal = 0;

  double? get averageRiskMultiple =>
      riskUnitSampleCount == 0 ? null : riskMultipleTotal / riskUnitSampleCount;

  void addRiskMultiple(double value) {
    riskUnitSampleCount++;
    riskMultipleTotal += value;
  }
}

class _MistakeAggregate {
  int tradeCount = 0;
}

class _ScenarioOutcomeAggregate {
  int tradeCount = 0;
  int wins = 0;
  int losses = 0;
  int breakEven = 0;
  double netResult = 0;
  int riskUnitSampleCount = 0;
  double riskMultipleTotal = 0;

  double? get averageRiskMultiple =>
      riskUnitSampleCount == 0 ? null : riskMultipleTotal / riskUnitSampleCount;

  void add(double result, double? riskMultiple) {
    tradeCount++;
    netResult += result;
    if (riskMultiple != null) {
      riskUnitSampleCount++;
      riskMultipleTotal += riskMultiple;
    }
    if (result > 0) {
      wins++;
    } else if (result < 0) {
      losses++;
    } else {
      breakEven++;
    }
  }
}

double? _riskMultiple(Trade trade) {
  final expectedLoss = trade.expectedLoss;
  if (expectedLoss == null || expectedLoss <= 0) return null;
  final multiple = trade.result / expectedLoss;
  return multiple.isFinite ? multiple : null;
}

class _RiskTransitionAggregate {
  int count = 0;
  int increasedCount = 0;
  double nextRiskTotal = 0;

  void add({required double previousRisk, required double nextRisk}) {
    count++;
    nextRiskTotal += nextRisk;
    if (nextRisk - previousRisk >
        BehaviorLabReport.riskIncreaseThresholdPercentPoints) {
      increasedCount++;
    }
  }
}
