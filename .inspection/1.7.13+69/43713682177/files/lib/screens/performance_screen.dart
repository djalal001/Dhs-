import 'package:flutter/material.dart';

import '../domain/performance_report.dart';
import '../domain/behavior_lab_report.dart';
import '../l10n/app_strings.dart';
import '../models/trade.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/behavior_lab_section.dart';

enum _PeriodPreset { week, month, last7Days, last30Days, all, custom }

enum _PerformanceView { financial, behavior }

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  _PeriodPreset _preset = _PeriodPreset.week;
  _PerformanceView _view = _PerformanceView.financial;
  DateTimeRange? _customRange;

  Future<void> _chooseCustomRange() async {
    final today = _dateOnly(DateTime.now());
    final initial =
        _customRange ??
        DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        );
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: initial,
      helpText: tr(context, 'chooseDateRange'),
      saveText: tr(context, 'confirm'),
    );
    if (!mounted || range == null) return;
    setState(() {
      _preset = _PeriodPreset.custom;
      _customRange = DateTimeRange(
        start: _dateOnly(range.start),
        end: _dateOnly(range.end),
      );
    });
  }

  DateTimeRange? _rangeFor(DateTime now) {
    final today = _dateOnly(now);
    switch (_preset) {
      case _PeriodPreset.week:
        final start = today.subtract(Duration(days: today.weekday - 1));
        return DateTimeRange(start: start, end: today);
      case _PeriodPreset.month:
        return DateTimeRange(
          start: DateTime(today.year, today.month),
          end: today,
        );
      case _PeriodPreset.last7Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        );
      case _PeriodPreset.last30Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 29)),
          end: today,
        );
      case _PeriodPreset.all:
        return null;
      case _PeriodPreset.custom:
        return _customRange;
    }
  }

  String _periodLabel(BuildContext context, DateTimeRange? range) {
    if (_preset == _PeriodPreset.custom && range != null) {
      return '${shortDate(range.start)} – ${shortDate(range.end)}';
    }
    return switch (_preset) {
      _PeriodPreset.week => tr(context, 'periodThisWeek'),
      _PeriodPreset.month => tr(context, 'periodThisMonth'),
      _PeriodPreset.last7Days => tr(context, 'periodLast7Days'),
      _PeriodPreset.last30Days => tr(context, 'periodLast30Days'),
      _PeriodPreset.all => tr(context, 'periodAll'),
      _PeriodPreset.custom => tr(context, 'periodCustom'),
    };
  }

  String _presetTitle(BuildContext context, _PeriodPreset preset) =>
      switch (preset) {
        _PeriodPreset.week => tr(context, 'periodThisWeek'),
        _PeriodPreset.month => tr(context, 'periodThisMonth'),
        _PeriodPreset.last7Days => tr(context, 'periodLast7Days'),
        _PeriodPreset.last30Days => tr(context, 'periodLast30Days'),
        _PeriodPreset.all => tr(context, 'periodAll'),
        _PeriodPreset.custom => tr(context, 'periodCustom'),
      };

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final account =
        app.accounts
            .where((item) => item.id == app.selectedAccountId)
            .firstOrNull ??
        app.accounts.firstOrNull;
    final range = _rangeFor(DateTime.now());
    final trades = account == null
        ? const <Trade>[]
        : app.trades.where((trade) => trade.accountId == account.id);
    final report = PerformanceReport.calculate(
      trades,
      startDate: range?.start,
      endDate: range?.end,
    );
    final behaviorReport = _view == _PerformanceView.behavior
        ? BehaviorLabReport.calculate(
            trades,
            startDate: range?.start,
            endDate: range?.end,
          )
        : null;
    final currency = account?.currency ?? 'USD';
    final totalGross = report.grossProfit + report.grossLoss;
    final profitShare = totalGross == 0
        ? 0
        : (report.grossProfit / totalGross * 1000).round().clamp(1, 999);

    return ListView(
      padding: const EdgeInsets.only(bottom: 30),
      children: [
        PageTitle(
          tr(context, 'performance'),
          subtitle: account == null
              ? null
              : '${account.name} · ${_periodLabel(context, range)}',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(context, 'performanceFilters'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                if (account != null)
                  DropdownButtonFormField<String>(
                    key: ValueKey('performance-account-filter-${account.id}'),
                    initialValue: account.id,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: tr(context, 'account'),
                      prefixIcon: const Icon(
                        Icons.account_balance_wallet_outlined,
                      ),
                    ),
                    items: [
                      for (final item in app.accounts)
                        DropdownMenuItem(
                          value: item.id,
                          child: Text(
                            '${item.name} · ${item.currency}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) async {
                      if (value != null) await app.selectAccount(value);
                    },
                  )
                else
                  Text(tr(context, 'noAccounts')),
                const SizedBox(height: 14),
                Text(
                  tr(context, 'periodLabel'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final preset in [
                      _PeriodPreset.week,
                      _PeriodPreset.month,
                      _PeriodPreset.last7Days,
                      _PeriodPreset.last30Days,
                      _PeriodPreset.all,
                    ])
                      ChoiceChip(
                        key: ValueKey('performance-period-${preset.name}'),
                        label: Text(_presetTitle(context, preset)),
                        selected: _preset == preset,
                        onSelected: (_) => setState(() => _preset = preset),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: const ValueKey('performance-custom-range'),
                    onPressed: _chooseCustomRange,
                    child: Row(
                      children: [
                        const Icon(Icons.date_range_outlined),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _preset == _PeriodPreset.custom
                                ? _periodLabel(context, range)
                                : tr(context, 'periodCustom'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (range != null) ...[
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 15,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${tr(context, 'fromDate')}: ${shortDate(range.start)}  ·  ${tr(context, 'toDate')}: ${shortDate(range.end)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
          child: _PerformanceModeSelector(
            selected: _view,
            onSelected: (value) => setState(() => _view = value),
          ),
        ),
        if (account == null)
          EmptyState(
            title: tr(context, 'noAccounts'),
            detail: tr(context, 'addFirstAccount'),
          )
        else if (_view == _PerformanceView.behavior)
          BehaviorLabSection(report: behaviorReport!, currency: currency)
        else if (report.tradeCount == 0)
          EmptyState(
            title: tr(context, 'noTradesInPeriod'),
            detail: tr(context, 'adjustPeriod'),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 0),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.72,
              children: [
                MetricCard(
                  key: const ValueKey('performance-total-trades'),
                  label: tr(context, 'tradeCount'),
                  value: report.tradeCount.toString(),
                  color: TdTokens.of(context).accent,
                  icon: Icons.receipt_long_outlined,
                ),
                MetricCard(
                  key: const ValueKey('performance-win-rate'),
                  label: tr(context, 'winRate'),
                  value: '${report.winRatePercent.toStringAsFixed(1)}%',
                  color: TdTokens.of(context).profit,
                  icon: Icons.track_changes_outlined,
                ),
                MetricCard(
                  key: const ValueKey('performance-net-result'),
                  label: tr(context, 'netResult'),
                  value: money(report.netProfit, currency),
                  color: report.netProfit > 0
                      ? TdTokens.of(context).profit
                      : report.netProfit < 0
                      ? TdTokens.of(context).loss
                      : TdTokens.of(context).neutral,
                  icon: report.netProfit >= 0
                      ? Icons.trending_up
                      : Icons.trending_down,
                ),
                MetricCard(
                  label: tr(context, 'profitFactor'),
                  value: report.profitFactor == null
                      ? (report.grossProfit > 0 ? '∞' : '—')
                      : report.profitFactor!.toStringAsFixed(2),
                  color: TdTokens.of(context).accent,
                  icon: Icons.balance_outlined,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeading(
                    icon: Icons.account_balance_outlined,
                    title: tr(context, 'resultDistribution'),
                  ),
                  const SizedBox(height: 12),
                  _AmountRow(
                    label: tr(context, 'grossProfit'),
                    value: money(report.grossProfit, currency),
                    color: TdTokens.of(context).profit,
                  ),
                  const Divider(height: 18),
                  _AmountRow(
                    label: tr(context, 'grossLoss'),
                    value: money(-report.grossLoss, currency),
                    color: TdTokens.of(context).loss,
                  ),
                  const Divider(height: 18),
                  _AmountRow(
                    label: tr(context, 'netResult'),
                    value: money(report.netProfit, currency),
                    color: report.netProfit > 0
                        ? TdTokens.of(context).profit
                        : report.netProfit < 0
                        ? TdTokens.of(context).loss
                        : TdTokens.of(context).neutral,
                    emphasize: true,
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: Row(
                      children: [
                        if (totalGross == 0)
                          Expanded(
                            child: Container(
                              height: 8,
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          )
                        else ...[
                          Flexible(
                            flex: profitShare,
                            child: Container(
                              height: 8,
                              color: TdTokens.of(context).profit,
                            ),
                          ),
                          Flexible(
                            flex: 1000 - profitShare,
                            child: Container(
                              height: 8,
                              color: TdTokens.of(context).loss,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeading(
                    icon: Icons.analytics_outlined,
                    title: tr(context, 'performanceDetails'),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = (constraints.maxWidth - 10) / 2;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: width,
                            child: _DetailValue(
                              label: tr(context, 'wins'),
                              value: report.wins.toString(),
                              color: TdTokens.of(context).profit,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _DetailValue(
                              label: tr(context, 'losses'),
                              value: report.losses.toString(),
                              color: TdTokens.of(context).loss,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _DetailValue(
                              label: tr(context, 'breakeven'),
                              value: report.breakEven.toString(),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _DetailValue(
                              label: tr(context, 'averageWin'),
                              value: money(report.averageWin, currency),
                              color: TdTokens.of(context).profit,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _DetailValue(
                              label: tr(context, 'averageLoss'),
                              value: money(-report.averageLoss, currency),
                              color: TdTokens.of(context).loss,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _DetailValue(
                              label: tr(context, 'averageRisk'),
                              value:
                                  '${report.averageRiskPercent.toStringAsFixed(2)}%',
                              color: TdTokens.of(context).accent,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 0, 2, 9),
                  child: _SectionHeading(
                    icon: Icons.psychology_alt_outlined,
                    title: tr(context, 'moodBreakdown'),
                  ),
                ),
                for (final mood in report.moods)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _MoodCard(mood: mood, currency: currency),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PerformanceModeSelector extends StatelessWidget {
  const _PerformanceModeSelector({
    required this.selected,
    required this.onSelected,
  });

  final _PerformanceView selected;
  final ValueChanged<_PerformanceView> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    return Container(
      key: const ValueKey('performance-view-switch'),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tokens.surface2,
        border: Border.all(color: tokens.lineSubtle),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _PerformanceModeButton(
            title: tr(context, 'financialAnalysis'),
            mode: _PerformanceView.financial,
            selected: selected,
            onSelected: onSelected,
          ),
          const SizedBox(width: 4),
          _PerformanceModeButton(
            title: tr(context, 'behaviorLab'),
            mode: _PerformanceView.behavior,
            selected: selected,
            onSelected: onSelected,
          ),
        ],
      ),
    );
  }
}

class _PerformanceModeButton extends StatelessWidget {
  const _PerformanceModeButton({
    required this.title,
    required this.mode,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final _PerformanceView mode;
  final _PerformanceView selected;
  final ValueChanged<_PerformanceView> onSelected;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == mode;
    final tokens = TdTokens.of(context);
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: title,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onSelected(mode),
            child: AnimatedContainer(
              duration: tokens.fast,
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? tokens.accent.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  title,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected ? tokens.accent : tokens.text2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    required this.color,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool emphasize;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}

class _DetailValue extends StatelessWidget {
  const _DetailValue({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({required this.mood, required this.currency});

  final MoodPerformance mood;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final netColor = mood.netProfit > 0
        ? TdTokens.of(context).profit
        : mood.netProfit < 0
        ? TdTokens.of(context).loss
        : TdTokens.of(context).neutral;
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tr(context, mood.mood),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                money(mood.netProfit, currency),
                style: TextStyle(color: netColor, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${mood.tradeCount} ${tr(context, 'tradesCount')}  ·  ${tr(context, 'wins')}: ${mood.wins}  ·  ${tr(context, 'losses')}: ${mood.losses}  ·  ${tr(context, 'breakeven')}: ${mood.breakEven}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: mood.winRatePercent / 100,
              minHeight: 7,
              color: TdTokens.of(context).profit,
              backgroundColor: TdTokens.of(
                context,
              ).loss.withValues(alpha: 0.25),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '${tr(context, 'moodWinRate')}: ${mood.winRatePercent.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
