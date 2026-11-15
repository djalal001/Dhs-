import 'package:flutter_test/flutter_test.dart';
import 'package:trader_desk/domain/behavior_lab_report.dart';
import 'package:trader_desk/models/trade.dart';

void main() {
  group('BehaviorLabReport', () {
    test('counts clear adherence and unique repeated behaviors by trade', () {
      final report = BehaviorLabReport.calculate([
        _trade(
          id: 'mixed',
          date: DateTime(2026, 1, 1),
          mood: 'moodCalm',
          result: 100,
          statuses: [
            TradeExecutionStatus.followedPlan,
            TradeExecutionStatus.enteredEarly,
            TradeExecutionStatus.enteredEarly,
          ],
        ),
        _trade(
          id: 'deviation',
          date: DateTime(2026, 1, 2),
          mood: 'moodAnxious',
          result: -50,
          statuses: [
            TradeExecutionStatus.enteredEarly,
            TradeExecutionStatus.exitedEarlyBecauseFearOfLosingProfit,
          ],
        ),
        _trade(
          id: 'plan',
          date: DateTime(2026, 1, 3),
          mood: 'moodCalm',
          result: -20,
          statuses: [TradeExecutionStatus.followedPlan],
        ),
        _trade(
          id: 'unlogged',
          date: DateTime(2026, 1, 4),
          mood: 'moodUnknown',
          result: 0,
        ),
      ]);

      expect(report.tradeCount, 4);
      expect(report.journalRecordedTradeCount, 3);
      expect(report.followedPlanTradeCount, 1);
      expect(report.deviationTradeCount, 1);
      expect(report.mixedJournalTradeCount, 1);
      expect(report.adherenceSampleCount, 2);
      expect(report.adherencePercent, 50);
      expect(
        report.mistakePatterns.first.status,
        TradeExecutionStatus.enteredEarly,
      );
      expect(report.mistakePatterns.first.tradeCount, 2);
      expect(
        report.mistakePatterns
            .firstWhere(
              (pattern) =>
                  pattern.status ==
                  TradeExecutionStatus.exitedEarlyBecauseFearOfLosingProfit,
            )
            .tradeCount,
        1,
      );
      expect(report.moodRecordedTradeCount, 3);
    });

    test('excludes explicitly missed entries from realized mood outcomes', () {
      final report = BehaviorLabReport.calculate([
        _trade(
          id: 'missed',
          date: DateTime(2026, 1, 1),
          mood: 'moodAnxious',
          result: 0,
          statuses: [TradeExecutionStatus.avoidedEntryBecauseFear],
        ),
        _trade(
          id: 'executed',
          date: DateTime(2026, 1, 2),
          mood: 'moodAnxious',
          result: -25,
        ),
      ]);

      final anxious = report.moodOutcomes.single;
      expect(anxious.tradeCount, 2);
      expect(anxious.outcomeTradeCount, 1);
      expect(anxious.losses, 1);
      expect(anxious.netResult, -25);
      expect(anxious.winRatePercent, 0);
    });

    test('normalizes outcomes by expected loss and tracks R coverage', () {
      final report = BehaviorLabReport.calculate([
        _trade(
          id: 'calm-large',
          date: DateTime(2026, 1, 1),
          mood: 'moodCalm',
          result: 100,
          expectedLoss: 100,
        ),
        _trade(
          id: 'calm-small',
          date: DateTime(2026, 1, 2),
          mood: 'moodCalm',
          result: 50,
          expectedLoss: 50,
        ),
        _trade(
          id: 'anxious-normalized',
          date: DateTime(2026, 1, 3),
          mood: 'moodAnxious',
          result: 10,
          expectedLoss: 5,
        ),
        _trade(
          id: 'anxious-no-risk-data',
          date: DateTime(2026, 1, 4),
          mood: 'moodAnxious',
          result: 20,
          expectedLoss: null,
        ),
        _trade(
          id: 'anxious-skipped',
          date: DateTime(2026, 1, 5),
          mood: 'moodAnxious',
          result: 0,
          expectedLoss: 3,
          statuses: [TradeExecutionStatus.avoidedEntryBecauseFear],
        ),
      ]);

      final calm = report.moodOutcomes.singleWhere(
        (pattern) => pattern.mood == 'moodCalm',
      );
      final anxious = report.moodOutcomes.singleWhere(
        (pattern) => pattern.mood == 'moodAnxious',
      );
      expect(calm.averageResultPerTrade, 75);
      expect(calm.riskUnitSampleCount, 2);
      expect(calm.averageRiskMultiple, 1);
      expect(anxious.tradeCount, 3);
      expect(anxious.outcomeTradeCount, 2);
      expect(anxious.riskUnitSampleCount, 1);
      expect(anxious.averageRiskMultiple, 2);
    });

    test('compares risk increases after losses with non-loss transitions', () {
      const List<double> results = [-10, -10, 10, -10, 10, 10, -10, 10, 10];
      const List<double> risks = [0.5, 0.8, 1.0, 0.4, 0.8, 0.4, 0.5, 0.8, 0.8];
      final report = BehaviorLabReport.calculate([
        for (var index = 0; index < results.length; index++)
          _trade(
            id: 'risk-$index',
            date: DateTime(2026, 1, 1).add(Duration(days: index)),
            result: results[index],
            risk: risks[index],
          ),
      ]);

      final response = report.riskAfterLoss;
      expect(response.afterLossTransitionCount, 4);
      expect(response.afterLossRiskIncreasedCount, 4);
      expect(response.afterOtherTransitionCount, 4);
      expect(response.afterOtherRiskIncreasedCount, 1);
      expect(response.hasComparableSample, isTrue);
      expect(response.riskIncreaseRateAfterLoss, 100);
      expect(response.riskIncreaseRateAfterOther, 25);
    });

    test(
      'does not compare risk groups until both reach the minimum sample',
      () {
        final report = BehaviorLabReport.calculate([
          _trade(id: 'a', date: DateTime(2026, 1, 1), result: -10, risk: 0.5),
          _trade(id: 'b', date: DateTime(2026, 1, 2), result: 10, risk: 0.8),
          _trade(id: 'c', date: DateTime(2026, 1, 3), result: 10, risk: 0.6),
        ]);

        expect(report.riskAfterLoss.afterLossTransitionCount, 1);
        expect(report.riskAfterLoss.hasComparableSample, isFalse);
      },
    );

    test(
      'compares mood and entry reason plus timeframe without double counting',
      () {
        final report = BehaviorLabReport.calculate([
          for (var index = 0; index < 5; index++)
            _trade(
              id: 'scenario-$index',
              date: DateTime(2026, 2, 1).add(Duration(days: index)),
              mood: 'moodCalm',
              result: 10,
              reason: 'SBR',
              entrySetups: const [
                TradeEntrySetup(reason: 'SBR', timeframe: '1H'),
              ],
            ),
          _trade(
            id: 'multi-scenario',
            date: DateTime(2026, 2, 6),
            mood: 'moodConfident',
            result: -20,
            entrySetups: const [
              TradeEntrySetup(reason: 'HNS', timeframe: '15MIN'),
              TradeEntrySetup(reason: 'RBS', timeframe: '1H'),
              TradeEntrySetup(reason: 'RBS', timeframe: '1H'),
            ],
          ),
        ]);

        final strongest = report.scenarioOutcomes.first;
        expect(strongest.mood, 'moodCalm');
        expect(strongest.entryScenario, 'SBR 1H');
        expect(strongest.outcomeTradeCount, 5);
        expect(strongest.netResult, 50);
        expect(strongest.averageResultPerTrade, 10);
        expect(strongest.averageRiskMultiple, 1);
        final confident = report.scenarioOutcomes
            .where((scenario) => scenario.mood == 'moodConfident')
            .toList();
        expect(confident, hasLength(2));
        expect(
          confident.every((scenario) => scenario.outcomeTradeCount == 1),
          isTrue,
        );
      },
    );

    test('cash size does not determine the strongest scenario outcome', () {
      final report = BehaviorLabReport.calculate([
        for (var index = 0; index < 5; index++)
          _trade(
            id: 'one-r-$index',
            date: DateTime(2026, 3, 1).add(Duration(days: index)),
            mood: 'moodCalm',
            result: 10,
            expectedLoss: 10,
            entrySetups: const [
              TradeEntrySetup(reason: 'SBR', timeframe: '1H'),
            ],
          ),
        for (var index = 0; index < 5; index++)
          _trade(
            id: 'cash-heavy-$index',
            date: DateTime(2026, 3, 6).add(Duration(days: index)),
            mood: 'moodConfident',
            result: 1000,
            expectedLoss: 10000,
            entrySetups: const [
              TradeEntrySetup(reason: 'Trend', timeframe: '1H'),
            ],
          ),
      ]);

      final highestCash = report.scenarioOutcomes.reduce(
        (a, b) => a.averageResultPerTrade > b.averageResultPerTrade ? a : b,
      );
      final highestR = report.scenarioOutcomes.reduce(
        (a, b) => a.averageRiskMultiple! > b.averageRiskMultiple! ? a : b,
      );
      expect(highestCash.mood, 'moodConfident');
      expect(highestR.mood, 'moodCalm');
      expect(highestR.averageRiskMultiple, 1);
    });

    test('applies inclusive date filters and rejects reversed ranges', () {
      final trades = [
        _trade(id: 'before', date: DateTime(2026, 1, 1)),
        _trade(id: 'start', date: DateTime(2026, 1, 2, 23)),
        _trade(id: 'end', date: DateTime(2026, 1, 3, 23)),
        _trade(id: 'after', date: DateTime(2026, 1, 4)),
      ];
      final report = BehaviorLabReport.calculate(
        trades,
        startDate: DateTime(2026, 1, 2),
        endDate: DateTime(2026, 1, 3),
      );

      expect(report.tradeCount, 2);
      expect(
        () => BehaviorLabReport.calculate(
          trades,
          startDate: DateTime(2026, 1, 4),
          endDate: DateTime(2026, 1, 2),
        ),
        throwsArgumentError,
      );
    });
  });
}

Trade _trade({
  required String id,
  required DateTime date,
  String mood = 'moodUnknown',
  double result = 0,
  double risk = 1,
  double? expectedLoss = 10,
  String reason = 'Trend Line',
  List<TradeEntrySetup> entrySetups = const [],
  List<TradeExecutionStatus> statuses = const [],
}) => Trade(
  id: id,
  accountId: 'account',
  market: 'NQ',
  reason: reason,
  entrySetups: entrySetups,
  result: result,
  riskPercent: risk,
  expectedLoss: expectedLoss,
  side: TradeSide.buy,
  confirmation: '',
  sequence: '',
  mood: mood,
  tradedAt: date,
  executionJournal: [
    for (final status in statuses) TradeExecutionJournalEntry(status: status),
  ],
);
