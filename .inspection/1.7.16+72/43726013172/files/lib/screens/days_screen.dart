import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../l10n/app_strings.dart';
import '../models/trade.dart';
import '../domain/trade_ordering.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/trade_image_preview.dart';
import 'trades_screen.dart' show TradeDetailScreen;

class DaysScreen extends StatefulWidget {
  const DaysScreen({super.key});

  @override
  State<DaysScreen> createState() => _DaysScreenState();
}

class _DaysScreenState extends State<DaysScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _visibleMonth = DateTime(today.year, today.month);
    _selectedDate = DateTime(today.year, today.month, today.day);
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
      _selectedDate = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    });
  }

  void _goToToday() {
    final today = DateTime.now();
    setState(() {
      _visibleMonth = DateTime(today.year, today.month);
      _selectedDate = DateTime(today.year, today.month, today.day);
    });
  }

  Future<void> _selectDate(
    DateTime date,
    List<Trade> trades,
    String currency,
  ) async {
    setState(() => _selectedDate = DateTime(date.year, date.month, date.day));
    final selectedTrade = await showModalBottomSheet<Trade>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: TdTokens.of(context).surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) =>
          _DayDetailsSheet(date: date, trades: trades, currency: currency),
    );
    if (!mounted || selectedTrade == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            TradeDetailScreen(trade: selectedTrade, currency: currency),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final account = app.accounts
        .where((item) => item.id == app.selectedAccountId)
        .firstOrNull;
    final currency = account?.currency ?? 'USD';
    final grouped = <DateTime, List<Trade>>{};

    // Use the date stored on the trade itself, never today's date, to group it.
    if (account != null) {
      for (final trade in app.trades.where(
        (item) => item.accountId == account.id,
      )) {
        final tradeDate = trade.tradedAt;
        final date = DateTime(tradeDate.year, tradeDate.month, tradeDate.day);
        (grouped[date] ??= <Trade>[]).add(trade);
      }
    }

    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final leadingDays = firstOfMonth.weekday % 7; // Sunday-first calendar.
    final firstCell = firstOfMonth.subtract(Duration(days: leadingDays));
    final daysInMonth = DateUtils.getDaysInMonth(
      _visibleMonth.year,
      _visibleMonth.month,
    );
    final weekCount = ((leadingDays + daysInMonth + 6) ~/ 7).clamp(4, 6);
    final dates = List<DateTime>.generate(
      weekCount * 7,
      (index) => firstCell.add(Duration(days: index)),
      growable: false,
    );
    final monthEntries = grouped.entries
        .where(
          (entry) =>
              entry.key.year == _visibleMonth.year &&
              entry.key.month == _visibleMonth.month,
        )
        .toList(growable: false);
    final monthTrades = monthEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.value.length,
    );
    final monthNet = monthEntries.fold<double>(
      0,
      (sum, entry) =>
          sum +
          entry.value.fold<double>(0, (daySum, trade) => daySum + trade.result),
    );
    final monthMaxAbs = monthEntries
        .map(
          (entry) => entry.value
              .fold<double>(0, (sum, trade) => sum + trade.result)
              .abs(),
        )
        .fold<double>(0, (largest, value) => math.max(largest, value));
    final activeDays = monthEntries.length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        PageTitle(
          tr(context, 'dailyLedger'),
          subtitle: account?.name ?? tr(context, 'selectAccount'),
          action: account == null
              ? null
              : IconButton.filledTonal(
                  key: const ValueKey('calendar-go-today'),
                  tooltip: tr(context, 'goToToday'),
                  onPressed: _goToToday,
                  icon: const Icon(Icons.today_rounded),
                ),
        ),
        if (account == null)
          EmptyState(
            title: tr(context, 'noAccounts'),
            detail: tr(context, 'emptyHint'),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: AppCard(
              variant: AppCardVariant.well,
              sheen: false,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          minimumSize: const Size(46, 46),
                          maximumSize: const Size(46, 46),
                        ),
                        tooltip: tr(context, 'previousMonth'),
                        onPressed: () => _changeMonth(-1),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: Text(
                          _monthTitle(context, _visibleMonth),
                          key: const ValueKey('calendar-month-title'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          minimumSize: const Size(46, 46),
                          maximumSize: const Size(46, 46),
                        ),
                        tooltip: tr(context, 'nextMonth'),
                        onPressed: () => _changeMonth(1),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _MonthOverview(
                    monthTrades: monthTrades,
                    activeDays: activeDays,
                    monthNet: monthNet,
                    currency: currency,
                  ),
                  const SizedBox(height: 18),
                  _WeekdayHeader(),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = 4.0;
                      final cellWidth = (constraints.maxWidth - gap * 6) / 7;
                      final cellHeight = (cellWidth * 2.25).clamp(96.0, 108.0);
                      return GestureDetector(
                        onHorizontalDragEnd: (details) {
                          final velocity = details.primaryVelocity ?? 0;
                          if (velocity.abs() < 300) return;
                          _changeMonth(velocity < 0 ? 1 : -1);
                        },
                        child: AnimatedSwitcher(
                          key: const ValueKey('monthly-calendar-grid'),
                          duration: const Duration(milliseconds: 200),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.025),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          child: GridView.builder(
                            key: ValueKey(
                              'calendar-grid-${_visibleMonth.year}-${_visibleMonth.month}',
                            ),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: dates.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  crossAxisSpacing: gap,
                                  mainAxisSpacing: gap,
                                  mainAxisExtent: cellHeight,
                                ),
                            itemBuilder: (context, index) {
                              final date = dates[index];
                              final normalized = DateTime(
                                date.year,
                                date.month,
                                date.day,
                              );
                              final dayTrades =
                                  grouped[normalized] ?? const <Trade>[];
                              final inMonth =
                                  date.month == _visibleMonth.month &&
                                  date.year == _visibleMonth.year;
                              final isSelected = _sameDay(date, _selectedDate);
                              final isToday = _sameDay(date, DateTime.now());
                              return _CalendarDayCell(
                                date: date,
                                trades: dayTrades,
                                inMonth: inMonth,
                                isSelected: isSelected,
                                isToday: isToday,
                                monthMaxAbs: monthMaxAbs,
                                onTap: () {
                                  if (!inMonth) {
                                    setState(() {
                                      _visibleMonth = DateTime(
                                        date.year,
                                        date.month,
                                      );
                                      _selectedDate = normalized;
                                    });
                                  }
                                  _selectDate(normalized, dayTrades, currency);
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _CalendarLegend(),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      tr(context, 'weekdaySun'),
      tr(context, 'weekdayMon'),
      tr(context, 'weekdayTue'),
      tr(context, 'weekdayWed'),
      tr(context, 'weekdayThu'),
      tr(context, 'weekdayFri'),
      tr(context, 'weekdaySat'),
    ];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Center(
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: TdTokens.of(context).text3,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.trades,
    required this.inMonth,
    required this.isSelected,
    required this.isToday,
    required this.monthMaxAbs,
    required this.onTap,
  });

  final DateTime date;
  final List<Trade> trades;
  final bool inMonth;
  final bool isSelected;
  final bool isToday;
  final double monthMaxAbs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    final net = trades.fold<double>(0, (sum, trade) => sum + trade.result);
    final color = net > 0
        ? tokens.profitDeep
        : net < 0
        ? tokens.lossDeep
        : tokens.neutral;
    final surface = tokens.surface2;
    final intensity = monthMaxAbs <= 0
        ? 0.0
        : (net.abs() / monthMaxAbs).clamp(0.0, 1.0);
    final tintAlpha = trades.isEmpty
        ? 0.0
        : (0.085 + 0.12 * intensity) * (inMonth ? 1 : 0.55);
    final foreground = inMonth
        ? tokens.text1
        : tokens.text3.withValues(alpha: 0.68);
    final selectedBorder = isSelected
        ? tokens.accent
        : isToday
        ? tokens.accent.withValues(alpha: 0.72)
        : tokens.lineSubtle.withValues(alpha: inMonth ? 0.72 : 0.36);
    final baseColor = trades.isEmpty
        ? surface
        : Color.alphaBlend(color.withValues(alpha: tintAlpha), surface);
    final backgroundColor = isSelected
        ? Color.alphaBlend(tokens.accent.withValues(alpha: 0.16), baseColor)
        : baseColor;
    final radius = BorderRadius.circular(17);

    return Semantics(
      key: ValueKey('calendar-day-${shortDate(date)}'),
      button: true,
      selected: isSelected,
      label:
          '${shortDate(date)}, ${trades.length} ${tr(context, 'accountTrades')}, ${_compactAmount(net)}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: radius,
          border: Border.all(
            color: selectedBorder,
            width: isSelected
                ? 2
                : isToday
                ? 1.5
                : 0.9,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: tokens.accent.withValues(alpha: 0.10),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : const [],
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: RoundedRectangleBorder(borderRadius: radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            customBorder: RoundedRectangleBorder(borderRadius: radius),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 4, 2, 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? tokens.accent.withValues(alpha: 0.19)
                          : isToday
                          ? tokens.accent.withValues(alpha: 0.11)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: isToday || isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: foreground,
                      ),
                    ),
                  ),
                  if (trades.isNotEmpty) ...[
                    Flexible(
                      child: Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 1,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(
                            alpha: isSelected ? 0.16 : 0.10,
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _compactAmount(net),
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: inMonth
                                  ? color
                                  : color.withValues(alpha: 0.70),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: inMonth
                                ? color
                                : color.withValues(alpha: 0.52),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${trades.length}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: foreground.withValues(
                              alpha: inMonth ? 0.82 : 0.60,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else
                    const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthOverview extends StatelessWidget {
  const _MonthOverview({
    required this.monthTrades,
    required this.activeDays,
    required this.monthNet,
    required this.currency,
  });

  final int monthTrades;
  final int activeDays;
  final double monthNet;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    final resultColor = monthNet > 0
        ? tokens.profit
        : monthNet < 0
        ? tokens.loss
        : tokens.neutral;

    return Container(
      constraints: const BoxConstraints(minHeight: 94),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.lineSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.show_chart_rounded,
                      size: 17,
                      color: resultColor,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        tr(context, 'netResult'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: tokens.text3,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    money(monthNet, currency),
                    maxLines: 1,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: resultColor,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 48,
            margin: const EdgeInsetsDirectional.symmetric(horizontal: 11),
            color: tokens.lineStrong.withValues(alpha: 0.65),
          ),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MonthCount(
                  icon: Icons.receipt_long_rounded,
                  label: tr(context, 'tradesOfMonth'),
                  value: '$monthTrades ${tr(context, 'accountTrades')}',
                  color: tokens.accent,
                ),
                const SizedBox(height: 7),
                _MonthCount(
                  icon: Icons.event_available_rounded,
                  label: tr(context, 'daysWithTrades'),
                  value: '$activeDays',
                  color: tokens.neutral,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthCount extends StatelessWidget {
  const _MonthCount({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 5),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: TdTokens.of(context).text3,
                fontSize: 10,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: TdTokens.of(context).text1,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _CalendarLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 14,
    runSpacing: 4,
    children: [
      _LegendItem(
        color: TdTokens.of(context).profit,
        label: tr(context, 'wins'),
      ),
      _LegendItem(
        color: TdTokens.of(context).loss,
        label: tr(context, 'losses'),
      ),
      _LegendItem(
        color: TdTokens.of(context).accent,
        label: tr(context, 'selectedDay'),
      ),
    ],
  );
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}

class _DayDetailsSheet extends StatelessWidget {
  const _DayDetailsSheet({
    required this.date,
    required this.trades,
    required this.currency,
  });

  final DateTime date;
  final List<Trade> trades;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final grossWins = trades
        .where((trade) => trade.result > 0)
        .fold<double>(0, (sum, trade) => sum + trade.result);
    final grossLosses = trades
        .where((trade) => trade.result < 0)
        .fold<double>(0, (sum, trade) => sum + trade.result.abs());
    final net = grossWins - grossLosses;
    final sorted = [...trades]..sort(compareTradesDescending);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return SizedBox(
      height: maxHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _longDate(context, date),
                        key: const ValueKey('day-detail-date'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 21,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: TdTokens.of(context).surface2,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${trades.length} ${tr(context, 'accountTrades')}',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: TdTokens.of(context).text2,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: tr(context, 'close'),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SummaryMetric(
                    label: tr(context, 'grossProfit'),
                    value: money(grossWins, currency),
                    color: TdTokens.of(context).profit,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryMetric(
                    label: tr(context, 'grossLoss'),
                    value: money(grossLosses, currency),
                    color: TdTokens.of(context).loss,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryMetric(
                    label: tr(context, 'netResult'),
                    value: money(net, currency),
                    color: net > 0
                        ? TdTokens.of(context).profit
                        : net < 0
                        ? TdTokens.of(context).loss
                        : TdTokens.of(context).neutral,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 20,
                  color: TdTokens.of(context).accent,
                ),
                const SizedBox(width: 8),
                Text(
                  tr(context, 'tradesOfDay'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (sorted.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    tr(context, 'noTradesOnDay'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: sorted.length,
                  padding: const EdgeInsets.only(bottom: 8),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final trade = sorted[index];
                    final time =
                        '${trade.tradedAt.hour.toString().padLeft(2, '0')}:${trade.tradedAt.minute.toString().padLeft(2, '0')}';
                    final images =
                        <({String path, String label, String prefix})>[
                          if (trade.beforeImagePath != null)
                            (
                              path: trade.beforeImagePath!,
                              label: tr(context, 'beforeImage'),
                              prefix: 'traderdesk_before_${trade.id}',
                            ),
                          if (trade.confirmationImagePath != null)
                            (
                              path: trade.confirmationImagePath!,
                              label: tr(context, 'confirmationImage'),
                              prefix: 'traderdesk_confirmation_${trade.id}',
                            ),
                          if (trade.afterImagePath != null)
                            (
                              path: trade.afterImagePath!,
                              label: tr(context, 'afterImage'),
                              prefix: 'traderdesk_after_${trade.id}',
                            ),
                        ];
                    final resultColor = trade.result > 0
                        ? TdTokens.of(context).profit
                        : trade.result < 0
                        ? TdTokens.of(context).loss
                        : TdTokens.of(context).neutral;
                    return Material(
                      color: TdTokens.of(context).surface2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: TdTokens.of(context).lineSubtle,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              minVerticalPadding: 8,
                              onTap: () => Navigator.of(context).pop(trade),
                              title: Text(
                                '${trade.market} · ${tr(context, trade.side == TradeSide.buy ? 'buy' : 'sell')}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  '$time · ${trade.entrySetupSummary}',
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 104,
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        money(trade.result, currency),
                                        style: TextStyle(
                                          color: resultColor,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: TdTokens.of(context).text3,
                                  ),
                                ],
                              ),
                            ),
                            if (images.isNotEmpty)
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final width = (constraints.maxWidth - 8) / 2;
                                  return Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final image in images)
                                        SizedBox(
                                          width: width,
                                          child: TradeImagePreview(
                                            path: image.path,
                                            label: image.label,
                                            fileNamePrefix: image.prefix,
                                            height: 96,
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 76),
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(
      color: TdTokens.of(context).surface2,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: color.withValues(alpha: 0.26)),
    ),
    child: Column(
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: TdTokens.of(context).text3,
            fontSize: 10.5,
          ),
        ),
        const SizedBox(height: 5),
        FittedBox(
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    ),
  );
}

bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

String _compactAmount(double amount) {
  final absAmount = amount.abs();
  final sign = amount < 0
      ? '−'
      : amount > 0
      ? '+'
      : '';
  if (absAmount >= 1000000)
    return '$sign${(absAmount / 1000000).toStringAsFixed(1)}m';
  if (absAmount >= 10000)
    return '$sign${(absAmount / 1000).toStringAsFixed(0)}k';
  if (absAmount >= 1000)
    return '$sign${(absAmount / 1000).toStringAsFixed(1)}k';
  return '$sign${absAmount.toStringAsFixed(0)}';
}

String _monthTitle(BuildContext context, DateTime month) {
  final months = <String>[
    tr(context, 'monthJan'),
    tr(context, 'monthFeb'),
    tr(context, 'monthMar'),
    tr(context, 'monthApr'),
    tr(context, 'monthMay'),
    tr(context, 'monthJun'),
    tr(context, 'monthJul'),
    tr(context, 'monthAug'),
    tr(context, 'monthSep'),
    tr(context, 'monthOct'),
    tr(context, 'monthNov'),
    tr(context, 'monthDec'),
  ];
  return '${months[month.month - 1]} ${month.year}';
}

String _longDate(BuildContext context, DateTime date) {
  final weekdays = <String>[
    tr(context, 'weekdaySun'),
    tr(context, 'weekdayMon'),
    tr(context, 'weekdayTue'),
    tr(context, 'weekdayWed'),
    tr(context, 'weekdayThu'),
    tr(context, 'weekdayFri'),
    tr(context, 'weekdaySat'),
  ];
  final months = <String>[
    tr(context, 'monthJan'),
    tr(context, 'monthFeb'),
    tr(context, 'monthMar'),
    tr(context, 'monthApr'),
    tr(context, 'monthMay'),
    tr(context, 'monthJun'),
    tr(context, 'monthJul'),
    tr(context, 'monthAug'),
    tr(context, 'monthSep'),
    tr(context, 'monthOct'),
    tr(context, 'monthNov'),
    tr(context, 'monthDec'),
  ];
  return '${weekdays[date.weekday % 7]}، ${date.day} ${months[date.month - 1]} ${date.year}';
}
