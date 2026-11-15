import 'package:flutter/material.dart';

import '../domain/behavior_lab_report.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'common.dart';

class BehaviorLabSection extends StatelessWidget {
  const BehaviorLabSection({
    super.key,
    required this.report,
    required this.currency,
  });

  final BehaviorLabReport report;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (report.tradeCount == 0) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 18, 10, 0),
        child: EmptyState(
          title: tr(context, 'behaviorLabEmptyTitle'),
          detail: tr(context, 'behaviorLabEmptyDetail'),
        ),
      );
    }

    final tokens = TdTokens.of(context);
    final primaryPattern = report.mistakePatterns.firstOrNull;
    final tipKey = primaryPattern == null
        ? (report.journalRecordedTradeCount == 0
              ? 'behaviorTipStart'
              : 'behaviorTip_followedPlan')
        : 'behaviorTip_${primaryPattern.status.name}';

    return Column(
      key: const ValueKey('behavior-lab-root'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 0),
          child: AppCard(
            variant: AppCardVariant.hero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology_alt_outlined, color: tokens.accent),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        tr(context, 'behaviorLabIntro'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${tr(context, 'tradeCount')}: ${report.tradeCount}',
                  key: const ValueKey('behavior-trade-count'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: tokens.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.72,
            children: [
              MetricCard(
                label: tr(context, 'behaviorMoodCoverage'),
                value:
                    '${report.moodRecordedTradeCount} / ${report.tradeCount}',
                color: tokens.accent,
                icon: Icons.mood_outlined,
              ),
              MetricCard(
                label: tr(context, 'behaviorExecutionCoverage'),
                value:
                    '${report.journalRecordedTradeCount} / ${report.tradeCount}',
                color: tokens.warn,
                icon: Icons.fact_check_outlined,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
          child: _AdherenceCard(report: report),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
          child: _MistakePatternsCard(report: report),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
          child: _MoodOutcomesCard(report: report, currency: currency),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
          child: _ScenarioMoodOutcomesCard(report: report, currency: currency),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
          child: _LossRiskCard(response: report.riskAfterLoss),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
          child: AppCard(
            variant: AppCardVariant.tint,
            tintColor: tokens.accent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeading(
                  icon: Icons.flag_outlined,
                  title: tr(context, 'behaviorTrainingStep'),
                ),
                const SizedBox(height: 9),
                if (primaryPattern != null) ...[
                  Text(
                    tr(context, 'journalStatus_${primaryPattern.status.name}'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: tokens.accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
                Text(
                  tr(context, tipKey),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AdherenceCard extends StatelessWidget {
  const _AdherenceCard({required this.report});

  final BehaviorLabReport report;

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    final percent = report.adherencePercent;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            icon: Icons.rule_rounded,
            title: tr(context, 'behaviorAdherence'),
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                percent == null ? '—' : '${percent.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: percent == null ? tokens.text3 : tokens.accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${report.followedPlanTradeCount} ${tr(context, 'behaviorFollowedCount')} · ${report.deviationTradeCount} ${tr(context, 'behaviorDeviationCount')}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: tokens.text2),
                  ),
                ),
              ),
            ],
          ),
          if (percent == null) ...[
            const SizedBox(height: 7),
            Text(
              tr(context, 'behaviorAdherenceNoData'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tokens.text3,
              ),
            ),
          ],
          if (report.mixedJournalTradeCount > 0) ...[
            const SizedBox(height: 7),
            Text(
              '${tr(context, 'behaviorMixedRecords')}: ${report.mixedJournalTradeCount}',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: tokens.warn),
            ),
          ],
        ],
      ),
    );
  }
}

class _MistakePatternsCard extends StatelessWidget {
  const _MistakePatternsCard({required this.report});

  final BehaviorLabReport report;

  @override
  Widget build(BuildContext context) {
    final patterns = report.mistakePatterns;
    final tokens = TdTokens.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            icon: Icons.manage_search_rounded,
            title: tr(context, 'behaviorPatterns'),
          ),
          const SizedBox(height: 9),
          if (report.journalRecordedTradeCount == 0)
            Text(
              tr(context, 'behaviorNoJournal'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tokens.text2,
                height: 1.45,
              ),
            )
          else if (patterns.isEmpty)
            Text(
              tr(context, 'behaviorPatternsEmpty'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: tokens.text2),
            )
          else ...[
            if (!patterns.any((pattern) => pattern.tradeCount >= 2))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  tr(context, 'behaviorPatternNoRepeat'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: tokens.text3),
                ),
              ),
            for (final pattern in patterns.take(3))
              _PatternRow(
                pattern: pattern,
                totalLogs: report.journalRecordedTradeCount,
              ),
            if (patterns.length > 3) ...[
              const Divider(height: 16),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  tr(context, 'behaviorShowAll'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                children: [
                  for (final pattern in patterns.skip(3))
                    _PatternRow(
                      pattern: pattern,
                      totalLogs: report.journalRecordedTradeCount,
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _PatternRow extends StatelessWidget {
  const _PatternRow({required this.pattern, required this.totalLogs});

  final ExecutionMistakePattern pattern;
  final int totalLogs;

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    final fraction = totalLogs == 0
        ? 0.0
        : (pattern.tradeCount / totalLogs).clamp(0.0, 1.0);
    final countText = tr(context, 'behaviorPatternCount')
        .replaceAll('{count}', pattern.tradeCount.toString())
        .replaceAll('{total}', totalLogs.toString());
    final repeated = pattern.tradeCount >= 2;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tr(context, 'journalStatus_${pattern.status.name}'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                repeated
                    ? tr(context, 'behaviorRepeated')
                    : tr(context, 'behaviorRecordedOnce'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: repeated ? tokens.warn : tokens.text3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            countText,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: tokens.text3),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 5,
              color: tokens.warn,
              backgroundColor: tokens.warn.withValues(alpha: 0.16),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodOutcomesCard extends StatelessWidget {
  const _MoodOutcomesCard({required this.report, required this.currency});

  final BehaviorLabReport report;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final patterns = report.moodOutcomes;
    final tokens = TdTokens.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            icon: Icons.mood_outlined,
            title: tr(context, 'behaviorMoodOutcomes'),
          ),
          const SizedBox(height: 10),
          if (!patterns.any((pattern) => pattern.outcomeTradeCount > 0))
            Text(
              tr(context, 'behaviorMoodNoOutcomes'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: tokens.text2),
            )
          else
            for (final pattern in patterns.where(
              (pattern) => pattern.tradeCount > 0,
            ))
              _MoodOutcomeRow(pattern: pattern, currency: currency),
        ],
      ),
    );
  }
}

class _MoodOutcomeRow extends StatelessWidget {
  const _MoodOutcomeRow({required this.pattern, required this.currency});

  final MoodOutcomePattern pattern;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    final resultColor = pattern.netResult > 0
        ? tokens.profit
        : pattern.netResult < 0
        ? tokens.loss
        : tokens.neutral;
    final sampleKey =
        pattern.outcomeTradeCount < BehaviorLabReport.minimumMoodSampleSize
        ? 'behaviorSampleEarly'
        : 'behaviorSampleThreshold';
    final ratio = tr(context, 'behaviorMoodSampleCount')
        .replaceAll('{eligible}', pattern.outcomeTradeCount.toString())
        .replaceAll('{recorded}', pattern.tradeCount.toString());
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.inset,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tokens.lineSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr(context, pattern.mood),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  money(pattern.netResult, currency),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: resultColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              '$ratio · ${tr(context, sampleKey)}',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: tokens.text3),
            ),
            if (pattern.outcomeTradeCount > 0) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 5,
                children: [
                  Text(
                    '${tr(context, 'winRate')}: ${pattern.winRatePercent.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${tr(context, 'behaviorAveragePerTrade')}: ${money(pattern.averageResultPerTrade, currency)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: resultColor),
                  ),
                  Text(
                    '${_riskUnitSampleLabel(context, pattern.riskUnitSampleCount)} · ${tr(context, 'behaviorAverageR')}: ${_formatRiskMultiple(pattern.averageRiskMultiple)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: pattern.averageRiskMultiple == null
                          ? tokens.text3
                          : tokens.accent,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScenarioMoodOutcomesCard extends StatelessWidget {
  const _ScenarioMoodOutcomesCard({
    required this.report,
    required this.currency,
  });

  final BehaviorLabReport report;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final scenarios = report.scenarioOutcomes;
    final eligible =
        scenarios
            .where(
              (scenario) =>
                  scenario.riskUnitSampleCount >=
                      BehaviorLabReport.minimumMoodSampleSize &&
                  scenario.averageRiskMultiple != null,
            )
            .toList()
          ..sort(
            (a, b) => b.averageRiskMultiple!.compareTo(a.averageRiskMultiple!),
          );
    final best = eligible.firstOrNull;
    final remaining = best == null
        ? scenarios
        : scenarios.where((scenario) => !identical(scenario, best)).toList();
    final tokens = TdTokens.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            icon: Icons.account_tree_outlined,
            title: tr(context, 'behaviorScenarios'),
          ),
          const SizedBox(height: 10),
          if (scenarios.isEmpty)
            Text(
              tr(context, 'behaviorScenarioNoData'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: tokens.text2),
            )
          else ...[
            if (best != null) ...[
              Text(
                tr(context, 'behaviorScenarioBest'),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: tokens.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              _ScenarioMoodOutcomeRow(
                pattern: best,
                currency: currency,
                highlight: true,
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  tr(context, 'behaviorScenarioNeedMore'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: tokens.text3),
                ),
              ),
            for (final scenario in remaining.take(3))
              _ScenarioMoodOutcomeRow(pattern: scenario, currency: currency),
            if (remaining.length > 3) ...[
              const Divider(height: 16),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  tr(context, 'behaviorShowAll'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                children: [
                  for (final scenario in remaining.skip(3))
                    _ScenarioMoodOutcomeRow(
                      pattern: scenario,
                      currency: currency,
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ScenarioMoodOutcomeRow extends StatelessWidget {
  const _ScenarioMoodOutcomeRow({
    required this.pattern,
    required this.currency,
    this.highlight = false,
  });

  final ScenarioMoodOutcomePattern pattern;
  final String currency;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    final resultColor = pattern.netResult > 0
        ? tokens.profit
        : pattern.netResult < 0
        ? tokens.loss
        : tokens.neutral;
    final sampleKey =
        pattern.outcomeTradeCount < BehaviorLabReport.minimumMoodSampleSize
        ? 'behaviorSampleEarly'
        : 'behaviorSampleThreshold';
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: highlight
              ? tokens.accent.withValues(alpha: 0.08)
              : tokens.inset,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: highlight
                ? tokens.accent.withValues(alpha: 0.32)
                : tokens.lineSubtle,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${tr(context, pattern.mood)} · ${pattern.entryScenario}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '${pattern.outcomeTradeCount} ${tr(context, 'behaviorMoodSample')} · ${tr(context, sampleKey)}',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: tokens.text3),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                Text(
                  '${tr(context, 'winRate')}: ${pattern.winRatePercent.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${tr(context, 'behaviorAveragePerTrade')}: ${money(pattern.averageResultPerTrade, currency)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: resultColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${_riskUnitSampleLabel(context, pattern.riskUnitSampleCount)} · ${tr(context, 'behaviorAverageR')}: ${_formatRiskMultiple(pattern.averageRiskMultiple)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: pattern.averageRiskMultiple == null
                        ? tokens.text3
                        : tokens.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _riskUnitSampleLabel(BuildContext context, int count) =>
    tr(context, 'behaviorRiskUnitSamples').replaceAll('{count}', '$count');

String _formatRiskMultiple(double? value) {
  if (value == null) return '—';
  final prefix = value > 0 ? '+' : '';
  return '$prefix${value.toStringAsFixed(2)}R';
}

class _LossRiskCard extends StatelessWidget {
  const _LossRiskCard({required this.response});

  final LossRiskResponse response;

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            icon: Icons.trending_up_rounded,
            title: tr(context, 'behaviorRiskAfterLoss'),
          ),
          const SizedBox(height: 10),
          if (response.hasComparableSample) ...[
            _RiskTransitionRow(
              label: tr(context, 'behaviorAfterLoss'),
              count: response.afterLossRiskIncreasedCount,
              total: response.afterLossTransitionCount,
              rate: response.riskIncreaseRateAfterLoss!,
            ),
            const SizedBox(height: 8),
            _RiskTransitionRow(
              label: tr(context, 'behaviorAfterOther'),
              count: response.afterOtherRiskIncreasedCount,
              total: response.afterOtherTransitionCount,
              rate: response.riskIncreaseRateAfterOther!,
            ),
          ] else ...[
            Text(
              '${tr(context, 'behaviorAfterLoss')}: ${response.afterLossTransitionCount} · ${tr(context, 'behaviorAfterOther')}: ${response.afterOtherTransitionCount}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 5),
            Text(
              tr(context, 'behaviorRiskSampleSmall'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: tokens.text3),
            ),
          ],
        ],
      ),
    );
  }
}

class _RiskTransitionRow extends StatelessWidget {
  const _RiskTransitionRow({
    required this.label,
    required this.count,
    required this.total,
    required this.rate,
  });

  final String label;
  final int count;
  final int total;
  final double rate;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label)),
      Text(
        '$count / $total (${rate.toStringAsFixed(0)}%)',
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 19, color: TdTokens.of(context).accent),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}
