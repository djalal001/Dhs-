import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/trade_ordering.dart';
import '../l10n/app_strings.dart';
import '../models/trade.dart';
import '../theme/app_theme.dart';
import 'common.dart';

enum _EquityRange { all, week, month, year, custom }

/// What the side axis and the pill beside the crosshair show.
enum _AxisMode { balance, percent }

class _EquityMenuAction {
  const _EquityMenuAction.range(this.range) : mode = null;
  const _EquityMenuAction.mode(this.mode) : range = null;

  final _EquityRange? range;
  final _AxisMode? mode;
}

const double _kEquityMenuWidth = 252;
const double _kEquityMenuHeight = 220;
const double _kEquityModeGroupWidth = 96;
const double _kEquityRangeRowHeight = 44;
const double _kAxisGutter = 60;
const double _kPlotTop = 12;
const double _kPlotBottom = 10;
const double _kChartHeight = 270;
const double _kMinVisiblePoints = 4;

/// Balance chart: one point per trade, drawn around the account's starting
/// balance. The line and its fill are green above the starting balance and red
/// below it. A crosshair can be dragged over the curve and the exact profit is
/// shown beside it; the chart can be zoomed and panned with two fingers.
class EquityCurve extends StatefulWidget {
  const EquityCurve({
    super.key,
    required this.trades,
    required this.currency,
    required this.startingBalance,
  });

  final List<Trade> trades;
  final String currency;
  final double startingBalance;

  @override
  State<EquityCurve> createState() => _EquityCurveState();
}

class _EquityCurveState extends State<EquityCurve> {
  _EquityRange _range = _EquityRange.all;
  DateTimeRange? _customRange;
  _AxisMode _mode = _AxisMode.balance;

  /// Selected point index; null means the latest point.
  int? _selectedIndex;

  /// Visible window in point-index units; null means the whole history.
  double? _viewStart;
  double? _viewEnd;

  final Map<int, Offset> _pointers = {};
  bool _pinching = false;
  double _pinchStartDistance = 1;
  double _pinchStartSpan = 1;
  double _pinchFocalIndex = 0;

  _EquityData? _cache;
  double? _cacheStarting;
  _EquityRange? _cacheRange;
  DateTime? _cacheDay;

  String _rangeLabel(BuildContext context, _EquityRange range) =>
      switch (range) {
        _EquityRange.all => tr(context, 'equityRangeAll'),
        _EquityRange.week => tr(context, 'equityRangeWeek'),
        _EquityRange.month => tr(context, 'equityRangeMonth'),
        _EquityRange.year => tr(context, 'equityRangeYear'),
        _EquityRange.custom => tr(context, 'equityRangeCustom'),
      };

  void _applyRange(_EquityRange range) {
    setState(() {
      _range = range;
      _cache = null;
      _selectedIndex = null;
      _viewStart = null;
      _viewEnd = null;
    });
  }

  Future<void> _chooseRange(_EquityRange range) async {
    if (range != _EquityRange.custom) {
      _applyRange(range);
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000, 1, 1),
      lastDate: today,
      initialDateRange: _customRange ??
          DateTimeRange(
            start: today.subtract(const Duration(days: 29)),
            end: today,
          ),
      helpText: tr(context, 'equitySelectRange'),
      cancelText: tr(context, 'cancel'),
      confirmText: tr(context, 'confirm'),
    );
    if (!mounted || picked == null) return;

    final start = DateTime(
      picked.start.year,
      picked.start.month,
      picked.start.day,
    );
    final end = DateTime(
      picked.end.year,
      picked.end.month,
      picked.end.day,
    );
    setState(() {
      _customRange = DateTimeRange(start: start, end: end);
      _range = _EquityRange.custom;
      _cache = null;
      _selectedIndex = null;
      _viewStart = null;
      _viewEnd = null;
    });
  }

  bool _sameTrades(List<Trade> a, List<Trade> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].result != b[i].result ||
          a[i].tradedAt != b[i].tradedAt) {
        return false;
      }
    }
    return true;
  }

  @override
  void didUpdateWidget(covariant EquityCurve oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameTrades(widget.trades, oldWidget.trades) ||
        widget.startingBalance != oldWidget.startingBalance) {
      _cache = null;
      _selectedIndex = null;
      _viewStart = null;
      _viewEnd = null;
    }
  }

  _EquityData _data() {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final cached = _cache;
    if (cached != null &&
        _cacheStarting == widget.startingBalance &&
        _cacheRange == _range &&
        _cacheDay == day) {
      return cached;
    }
    final data = _makeData(day);
    _cache = data;
    _cacheStarting = widget.startingBalance;
    _cacheRange = _range;
    _cacheDay = day;
    return data;
  }

  _EquityData _makeData(DateTime today) {
    final sorted = [...widget.trades]..sort(compareTradesAscending);
    final customRange = _range == _EquityRange.custom ? _customRange : null;
    final DateTime? startDay = customRange == null
        ? switch (_range) {
            _EquityRange.week => today.subtract(const Duration(days: 6)),
            _EquityRange.month => today.subtract(const Duration(days: 29)),
            _EquityRange.year => today.subtract(const Duration(days: 364)),
            _EquityRange.all || _EquityRange.custom => null,
          }
        : DateTime(
            customRange.start.year,
            customRange.start.month,
            customRange.start.day,
          );
    final endDay = customRange == null
        ? today
        : DateTime(
            customRange.end.year,
            customRange.end.month,
            customRange.end.day,
          );
    var opening = widget.startingBalance;
    final visible = <Trade>[];
    for (final trade in sorted) {
      final date = DateTime(
        trade.tradedAt.year,
        trade.tradedAt.month,
        trade.tradedAt.day,
      );
      if (date.isAfter(today) || date.isAfter(endDay)) continue;
      if (startDay != null && date.isBefore(startDay)) {
        opening += trade.result;
      } else {
        visible.add(trade);
      }
    }

    final points = <_EquityPoint>[
      _EquityPoint(
        balance: opening,
        result: 0,
        date: visible.isEmpty ? (startDay ?? today) : visible.first.tradedAt,
      ),
    ];
    var balance = opening;
    var peak = opening;
    var maxDrawdown = 0.0;
    var maxDrawdownPercent = 0.0;
    for (final trade in visible) {
      balance += trade.result;
      points.add(
        _EquityPoint(
          balance: balance,
          result: trade.result,
          date: trade.tradedAt,
        ),
      );
      if (balance > peak) peak = balance;
      final drawdown = peak - balance;
      if (drawdown > maxDrawdown) maxDrawdown = drawdown;
      final drawdownPercent = peak > 0 ? drawdown / peak * 100 : 0.0;
      if (drawdownPercent > maxDrawdownPercent) {
        maxDrawdownPercent = drawdownPercent;
      }
    }
    return _EquityData(
      points: points,
      baseline: widget.startingBalance,
      netChange: balance - opening,
      maxDrawdown: maxDrawdown,
      maxDrawdownPercent: maxDrawdownPercent,
      tradeCount: visible.length,
    );
  }

  // ---- view window (zoom / pan) -------------------------------------------

  ({double start, double end}) _window(double domainMax) {
    final minSpan = math.min(domainMax, _kMinVisiblePoints);
    final start = _viewStart ?? 0.0;
    final end = _viewEnd ?? domainMax;
    final span = (end - start).clamp(minSpan, domainMax).toDouble();
    final clampedStart = start.clamp(0.0, domainMax - span).toDouble();
    return (start: clampedStart, end: clampedStart + span);
  }

  void _setWindow(double start, double end, double domainMax) {
    final minSpan = math.min(domainMax, _kMinVisiblePoints);
    final span = (end - start).clamp(minSpan, domainMax).toDouble();
    final clampedStart = start.clamp(0.0, domainMax - span).toDouble();
    setState(() {
      if (span >= domainMax - 1e-9) {
        _viewStart = null;
        _viewEnd = null;
      } else {
        _viewStart = clampedStart;
        _viewEnd = clampedStart + span;
      }
    });
  }

  // ---- gestures ------------------------------------------------------------

  void _selectAt(double dx, double plotWidth, int count, double domainMax) {
    if (_pointers.length >= 2 || plotWidth <= 0 || count == 0) return;
    final window = _window(domainMax);
    final raw =
        window.start +
        (dx / plotWidth).clamp(0.0, 1.0) * (window.end - window.start);
    final index = math.min(math.max(raw.round(), 0), count - 1);
    if (_selectedIndex != index) setState(() => _selectedIndex = index);
  }

  void _onPointerDown(PointerDownEvent event, double plotWidth, double max) {
    _pointers[event.pointer] = event.localPosition;
    if (_pointers.length != 2 || plotWidth <= 0) return;
    final points = _pointers.values.toList();
    final window = _window(max);
    _pinchStartDistance = math.max((points[0] - points[1]).distance, 1.0);
    _pinchStartSpan = window.end - window.start;
    final focalX = ((points[0].dx + points[1].dx) / 2)
        .clamp(0.0, plotWidth)
        .toDouble();
    _pinchFocalIndex = window.start + focalX / plotWidth * _pinchStartSpan;
    _pinching = true;
  }

  void _onPointerMove(PointerMoveEvent event, double plotWidth, double max) {
    if (!_pointers.containsKey(event.pointer)) return;
    _pointers[event.pointer] = event.localPosition;
    if (!_pinching || _pointers.length != 2 || plotWidth <= 0) return;
    final points = _pointers.values.toList();
    final distance = math.max((points[0] - points[1]).distance, 1.0);
    final minSpan = math.min(max, _kMinVisiblePoints);
    final span = (_pinchStartSpan * _pinchStartDistance / distance)
        .clamp(minSpan, max)
        .toDouble();
    final focalX = ((points[0].dx + points[1].dx) / 2)
        .clamp(0.0, plotWidth)
        .toDouble();
    final start = _pinchFocalIndex - focalX / plotWidth * span;
    _setWindow(start, start + span, max);
  }

  void _onPointerEnd(PointerEvent event) {
    _pointers.remove(event.pointer);
    if (_pointers.length < 2) _pinching = false;
  }

  // ---- text helpers --------------------------------------------------------

  String _signedMoney(double value) {
    final text = money(value, widget.currency);
    return value > 0.000001 ? '+$text' : text;
  }

  String _signedPercent(double value) =>
      '${value > 0.000001 ? '+' : ''}${value.toStringAsFixed(2)}%';

  @override
  Widget build(BuildContext context) {
    final data = _data();
    final tokens = TdTokens.of(context);
    final count = data.points.length;
    final domainMax = math.max(1, count - 1).toDouble();
    final window = _window(domainMax);
    final zoomed = window.end - window.start < domainMax - 1e-9;
    final baseline = data.baseline;
    final mode = _mode == _AxisMode.percent && baseline <= 0
        ? _AxisMode.balance
        : _mode;
    final selected = math.min(math.max(_selectedIndex ?? count - 1, 0), count - 1);
    final point = data.points[selected];
    final profit = point.balance - baseline;
    final percent = baseline > 0 ? profit / baseline * 100 : 0.0;
    Color signColor(double value) => value > 0.005
        ? tokens.profit
        : value < -0.005
        ? tokens.loss
        : tokens.neutral;
    final profitColor = signColor(profit);
    final firstIndex = math.min(math.max(window.start.round(), 0), count - 1);
    final lastIndex = math.min(math.max(window.end.round(), 0), count - 1);
    final labelStyle = (Theme.of(context).textTheme.labelSmall ?? const TextStyle())
        .copyWith(
          color: tokens.text2,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        );
    final labelDirection = AppStrings.isArabic(context)
        ? TextDirection.rtl
        : TextDirection.ltr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                tr(context, 'balanceHistory'),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          key: const ValueKey('equity-period-selector-row'),
          children: [
            Expanded(
              child: PopupMenuButton<_EquityMenuAction>(
                key: const ValueKey('equity-period-menu'),
                tooltip: tr(context, 'equitySelectRange'),
                onSelected: (choice) {
                  final range = choice.range;
                  final selectedMode = choice.mode;
                  if (range != null) {
                    _chooseRange(range);
                  } else if (selectedMode != null &&
                      (selectedMode != _AxisMode.percent || baseline > 0)) {
                    setState(() => _mode = selectedMode);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem<_EquityMenuAction>(
                    enabled: false,
                    height: _kEquityMenuHeight,
                    padding: EdgeInsets.zero,
                    child: Builder(
                      builder: (popupContext) {
                        final popupTextDirection =
                            Directionality.of(popupContext);
                        return SizedBox(
                          key: const ValueKey('equity-period-popup-panel'),
                          width: _kEquityMenuWidth,
                          height: _kEquityMenuHeight,
                          child: Row(
                            textDirection: TextDirection.ltr,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: _kEquityModeGroupWidth,
                                height: _kEquityMenuHeight,
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 18),
                                    child: _EquityModeIconGroup(
                                      mode: mode,
                                      percentEnabled: baseline > 0,
                                      onSelected: (selectedMode) {
                                        Navigator.of(popupContext).pop(
                                          _EquityMenuAction.mode(selectedMode),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: _kEquityMenuHeight - 12,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                color: tokens.lineSubtle,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Directionality(
                                  textDirection: popupTextDirection,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (final range in _EquityRange.values)
                                        SizedBox(
                                          height: _kEquityRangeRowHeight,
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              key: ValueKey(
                                                'equity-range-${range.name}',
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              onTap: () {
                                                Navigator.of(popupContext).pop(
                                                  _EquityMenuAction.range(range),
                                                );
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    SizedBox(
                                                      width: 20,
                                                      child: range == _range
                                                          ? Icon(
                                                              Icons.check_rounded,
                                                              size: 17,
                                                              color: tokens.accent,
                                                            )
                                                          : null,
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Expanded(
                                                      child: Text(
                                                        _rangeLabel(
                                                          popupContext,
                                                          range,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        textAlign:
                                                            TextAlign.start,
                                                        style: Theme.of(
                                                          popupContext,
                                                        )
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                          color: range == _range
                                                              ? tokens.text1
                                                              : tokens.text2,
                                                          fontWeight:
                                                              range == _range
                                                              ? FontWeight.w700
                                                              : FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                child: Container(
                  key: const ValueKey('equity-period-selector'),
                  width: double.infinity,
                  padding: const EdgeInsetsDirectional.fromSTEB(11, 7, 9, 7),
                  decoration: BoxDecoration(
                    color: tokens.surface3,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: tokens.lineSubtle, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Text(
                          _rangeLabel(context, _range),
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                color: tokens.text1,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: tokens.text2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Exact numbers for the selected point, always visible.
        Container(
          key: const ValueKey('equity-readout'),
          width: double.infinity,
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: tokens.surface3,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: profitColor.withValues(alpha: 0.22),
              width: 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selected == 0
                          ? tr(context, 'chartStart')
                          : '${tr(context, 'chartTradeNumber')} $selected',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: tokens.text2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    shortDate(point.date),
                    textDirection: TextDirection.ltr,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: tokens.text3),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        _signedMoney(profit),
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: profitColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: profitColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _signedPercent(percent),
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: profitColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                tr(context, 'chartProfitVsBase'),
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: tokens.text3),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _ReadoutStat(
                      label: tr(context, 'chartModeBalance'),
                      value: money(point.balance, widget.currency),
                      color: tokens.text1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ReadoutStat(
                      label: tr(context, 'chartTradeResult'),
                      value: selected == 0
                          ? '—'
                          : _signedMoney(point.result),
                      color: selected == 0
                          ? tokens.text3
                          : signColor(point.result),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final plotWidth = math.max(1.0, constraints.maxWidth - _kAxisGutter);
            return Directionality(
              textDirection: TextDirection.ltr,
              child: SizedBox(
                height: _kChartHeight,
                child: RepaintBoundary(
                  child: Semantics(
                    key: const ValueKey('equity-chart-semantics'),
                    label: tr(context, 'equityTouchHint'),
                    value:
                        '${shortDate(point.date)} · ${_signedMoney(profit)} · ${money(point.balance, widget.currency)}',
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (event) =>
                          _onPointerDown(event, plotWidth, domainMax),
                      onPointerMove: (event) =>
                          _onPointerMove(event, plotWidth, domainMax),
                      onPointerUp: _onPointerEnd,
                      onPointerCancel: _onPointerEnd,
                      child: GestureDetector(
                        key: const ValueKey('equity-curve-canvas'),
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) => _selectAt(
                          details.localPosition.dx,
                          plotWidth,
                          count,
                          domainMax,
                        ),
                        onHorizontalDragStart: (details) => _selectAt(
                          details.localPosition.dx,
                          plotWidth,
                          count,
                          domainMax,
                        ),
                        onHorizontalDragUpdate: (details) => _selectAt(
                          details.localPosition.dx,
                          plotWidth,
                          count,
                          domainMax,
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CustomPaint(
                              size: Size.infinite,
                              painter: _BalancePainter(
                                balances: data.balances,
                                baseline: baseline,
                                viewStart: window.start,
                                viewEnd: window.end,
                                selectedIndex: selected,
                                mode: mode,
                                positive: tokens.profit,
                                negative: tokens.loss,
                                neutral: tokens.neutral,
                                gridColor: tokens.lineSubtle,
                                baselineColor: tokens.text3.withValues(
                                  alpha: 0.85,
                                ),
                                surfaceColor: tokens.surface1,
                                labelStyle: labelStyle,
                                baselineLabel: tr(context, 'chartBaseline'),
                                labelDirection: labelDirection,
                              ),
                            ),
                            if (data.tradeCount == 0)
                              IgnorePointer(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    right: _kAxisGutter,
                                  ),
                                  child: Center(
                                    child: Text(
                                      tr(context, 'chartNoTrades'),
                                      textDirection: labelDirection,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: tokens.text3),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (zoomed)
          Padding(
            padding: const EdgeInsets.only(right: _kAxisGutter, top: 4),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: _WindowScrubber(
                key: const ValueKey('equity-scrubber'),
                start: window.start,
                end: window.end,
                domainMax: domainMax,
                thumbColor: tokens.accent.withValues(alpha: 0.75),
                trackColor: tokens.lineSubtle,
                onStartChanged: (value) => _setWindow(
                  value,
                  value + (window.end - window.start),
                  domainMax,
                ),
              ),
            ),
          ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.only(right: _kAxisGutter, top: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    shortDate(data.points[firstIndex].date),
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: tokens.text3),
                  ),
                ),
                Text(
                  shortDate(data.points[lastIndex].date),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: tokens.text3),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _ChartStat(
                label: tr(context, 'equityNetChange'),
                value: money(data.netChange, widget.currency),
                color: signColor(data.netChange),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _ChartStat(
                label: tr(context, 'maxDrawdown'),
                value:
                    '${money(data.maxDrawdown, widget.currency)} · ${data.maxDrawdownPercent.toStringAsFixed(1)}%',
                color: data.maxDrawdown > 0 ? tokens.loss : null,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _ChartStat(
                label: tr(context, 'equityTrades'),
                value: '${data.tradeCount}',
                color: tokens.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EquityModeIconGroup extends StatelessWidget {
  const _EquityModeIconGroup({
    required this.mode,
    required this.percentEnabled,
    required this.onSelected,
  });

  final _AxisMode mode;
  final bool percentEnabled;
  final ValueChanged<_AxisMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface1,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: tokens.lineSubtle, width: 0.8),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        textDirection: TextDirection.ltr,
        mainAxisSize: MainAxisSize.min,
        children: [
          _EquityModeIconButton(
            semanticsKey: const ValueKey('equity-mode-balance'),
            icon: Icons.attach_money_rounded,
            label: tr(context, 'chartModeBalance'),
            selected: mode == _AxisMode.balance,
            enabled: true,
            onTap: () => onSelected(_AxisMode.balance),
          ),
          _EquityModeIconButton(
            semanticsKey: const ValueKey('equity-mode-percent'),
            icon: Icons.percent_rounded,
            label: tr(context, 'chartModePercent'),
            selected: mode == _AxisMode.percent,
            enabled: percentEnabled,
            onTap: percentEnabled ? () => onSelected(_AxisMode.percent) : null,
          ),
        ],
      ),
    );
  }
}

class _EquityModeIconButton extends StatelessWidget {
  const _EquityModeIconButton({
    this.semanticsKey,
    required this.icon,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final Key? semanticsKey;
  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    return Semantics(
      key: semanticsKey,
      button: true,
      selected: selected,
      enabled: enabled,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? tokens.surface3 : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? tokens.lineSubtle : Colors.transparent,
                  width: 0.8,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 21,
                color: !enabled
                    ? tokens.text3
                    : selected
                    ? tokens.text1
                    : tokens.text2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadoutStat extends StatelessWidget {
  const _ReadoutStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: tokens.text3),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

/// Thin overview bar shown when zoomed in; drag the thumb to pan.
class _WindowScrubber extends StatelessWidget {
  const _WindowScrubber({
    super.key,
    required this.start,
    required this.end,
    required this.domainMax,
    required this.thumbColor,
    required this.trackColor,
    required this.onStartChanged,
  });

  final double start;
  final double end;
  final double domainMax;
  final Color thumbColor;
  final Color trackColor;
  final ValueChanged<double> onStartChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final span = end - start;
      final free = math.max(domainMax - span, 1e-9);
      final thumbWidth = math.max(28.0, span / domainMax * width);
      final travel = math.max(1.0, width - thumbWidth);
      final left = (start / free).clamp(0.0, 1.0).toDouble() * travel;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) => onStartChanged(
          ((details.localPosition.dx - thumbWidth / 2) / travel)
                  .clamp(0.0, 1.0)
                  .toDouble() *
              free,
        ),
        onHorizontalDragUpdate: (details) =>
            onStartChanged(start + details.delta.dx / travel * free),
        child: SizedBox(
          height: 22,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 8,
                height: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Positioned(
                left: left,
                width: thumbWidth,
                top: 6,
                height: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: thumbColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ChartStat extends StatelessWidget {
  const _ChartStat({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.fromSTEB(9, 8, 7, 8),
    decoration: BoxDecoration(
      color: TdTokens.of(context).inset,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: TdTokens.of(context).lineSubtle, width: 0.8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: TdTokens.of(context).text3),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _EquityPoint {
  const _EquityPoint({
    required this.balance,
    required this.result,
    required this.date,
  });

  final double balance;
  final double result;
  final DateTime date;
}

class _EquityData {
  _EquityData({
    required this.points,
    required this.baseline,
    required this.netChange,
    required this.maxDrawdown,
    required this.maxDrawdownPercent,
    required this.tradeCount,
  }) : balances = List<double>.unmodifiable(
         points.map((point) => point.balance),
       );

  /// Point 0 is the balance before the first trade of the period; every other
  /// point is the balance right after one trade.
  final List<_EquityPoint> points;
  final List<double> balances;

  /// The account's starting balance: the line the chart is drawn around.
  final double baseline;
  final double netChange;
  final double maxDrawdown;
  final double maxDrawdownPercent;
  final int tradeCount;
}

// ---- axis maths -------------------------------------------------------------

double _toDisplay(double balance, double baseline, _AxisMode mode) =>
    switch (mode) {
      _AxisMode.balance => balance,
      _AxisMode.percent => (balance - baseline) / baseline * 100,
    };

double _fromDisplay(double value, double baseline, _AxisMode mode) =>
    switch (mode) {
      _AxisMode.balance => value,
      _AxisMode.percent => baseline + value / 100 * baseline,
    };

({List<double> ticks, double step}) _niceTicks(
  double low,
  double high,
  int target,
) {
  final span = high - low;
  if (!span.isFinite || span <= 0) return (ticks: [low], step: 1);
  final rawStep = span / target;
  final magnitude = math
      .pow(10, (math.log(rawStep) / math.ln10).floor())
      .toDouble();
  final residual = rawStep / magnitude;
  final fraction = residual <= 1
      ? 1
      : residual <= 2
      ? 2
      : residual <= 5
      ? 5
      : 10;
  final step = fraction * magnitude;
  final ticks = <double>[];
  var value = (low / step).ceil() * step;
  while (value <= high + step * 1e-9 && ticks.length < 14) {
    ticks.add(value.abs() < step * 1e-9 ? 0.0 : value);
    value += step;
  }
  return (ticks: ticks, step: step);
}

String _group(String digits) {
  final parts = digits.split('.');
  final whole = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return parts.length > 1 ? '$whole.${parts[1]}' : whole;
}

String _formatAxisValue(double value, double step, _AxisMode mode) {
  final signed = mode != _AxisMode.balance;
  final sign = value < 0 ? '-' : (signed && value > 0 ? '+' : '');
  final absolute = value.abs();
  if (mode == _AxisMode.percent) {
    final decimals = step >= 1
        ? 0
        : step >= 0.1
        ? 1
        : 2;
    return '$sign${absolute.toStringAsFixed(decimals)}%';
  }
  if (absolute >= 1e6) return '$sign${(absolute / 1e6).toStringAsFixed(2)}M';
  final decimals = step >= 1
      ? 0
      : math.min(4, math.max(1, (-(math.log(step) / math.ln10)).ceil()));
  return '$sign${_group(absolute.toStringAsFixed(decimals))}';
}

String _formatPill(double value, _AxisMode mode) {
  final absolute = value.abs();
  final sign = absolute < 0.005
      ? ''
      : value < 0
      ? '-'
      : (mode == _AxisMode.balance ? '' : '+');
  return mode == _AxisMode.percent
      ? '$sign${absolute.toStringAsFixed(2)}%'
      : '$sign${_group(absolute.toStringAsFixed(2))}';
}

TextPainter _layoutText(String text, TextStyle style, TextDirection direction) =>
    TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      maxLines: 1,
    )..layout();

class _BalancePainter extends CustomPainter {
  const _BalancePainter({
    required this.balances,
    required this.baseline,
    required this.viewStart,
    required this.viewEnd,
    required this.selectedIndex,
    required this.mode,
    required this.positive,
    required this.negative,
    required this.neutral,
    required this.gridColor,
    required this.baselineColor,
    required this.surfaceColor,
    required this.labelStyle,
    required this.baselineLabel,
    required this.labelDirection,
  });

  final List<double> balances;
  final double baseline;
  final double viewStart;
  final double viewEnd;
  final int selectedIndex;
  final _AxisMode mode;
  final Color positive;
  final Color negative;
  final Color neutral;
  final Color gridColor;
  final Color baselineColor;
  final Color surfaceColor;
  final TextStyle labelStyle;
  final String baselineLabel;
  final TextDirection labelDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(
      0,
      _kPlotTop,
      size.width - _kAxisGutter,
      size.height - _kPlotBottom,
    );
    if (balances.isEmpty || plot.width <= 1 || plot.height <= 1) return;
    final count = balances.length;
    final span = math.max(viewEnd - viewStart, 1e-6);
    final first = math.max(0, viewStart.floor());
    final last = math.min(count - 1, viewEnd.ceil());

    // Vertical range of what is visible; the starting balance is always in it
    // so the line the chart is drawn around never leaves the screen.
    var low = baseline;
    var high = baseline;
    for (var i = first; i <= last; i++) {
      final value = balances[i];
      if (value < low) low = value;
      if (value > high) high = value;
    }
    var range = high - low;
    if (range < 1e-9) range = math.max(baseline.abs() * 0.01, 1.0);
    final pad = range * 0.14;
    final minValue = low - pad;
    final maxValue = high + pad;
    double yFor(double value) =>
        plot.bottom - (value - minValue) / (maxValue - minValue) * plot.height;
    double xFor(num index) =>
        plot.left + (index - viewStart) / span * plot.width;
    final baseY = yFor(baseline);

    // Grid and side-axis labels.
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final axis = _niceTicks(
      _toDisplay(minValue, baseline, mode),
      _toDisplay(maxValue, baseline, mode),
      4,
    );
    for (final tick in axis.ticks) {
      final y = yFor(_fromDisplay(tick, baseline, mode));
      if (y < plot.top - 0.5 || y > plot.bottom + 0.5) continue;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      if ((y - baseY).abs() < 12) continue;
      final text = _layoutText(
        _formatAxisValue(tick, axis.step, mode),
        labelStyle,
        TextDirection.ltr,
      );
      text.paint(canvas, Offset(plot.right + 6, y - text.height / 2));
    }

    // The balance curve, split at the starting balance.
    final path = Path();
    for (var i = first; i <= last; i++) {
      final x = xFor(i);
      final y = yFor(balances[i]);
      if (i == first) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final fill = Path.from(path)
      ..lineTo(xFor(last), baseY)
      ..lineTo(xFor(first), baseY)
      ..close();
    Paint stroke(Color color) => Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    canvas.clipRect(plot);
    if (baseY > plot.top + 0.5) {
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(plot.left, plot.top, plot.right, baseY));
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              positive.withValues(alpha: 0.34),
              positive.withValues(alpha: 0.03),
            ],
          ).createShader(Rect.fromLTRB(plot.left, plot.top, plot.right, baseY)),
      );
      canvas.drawPath(path, stroke(positive));
      canvas.restore();
    }
    if (baseY < plot.bottom - 0.5) {
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(plot.left, baseY, plot.right, plot.bottom));
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              negative.withValues(alpha: 0.03),
              negative.withValues(alpha: 0.34),
            ],
          ).createShader(
            Rect.fromLTRB(plot.left, baseY, plot.right, plot.bottom),
          ),
      );
      canvas.drawPath(path, stroke(negative));
      canvas.restore();
    }
    canvas.restore();

    // Starting-balance line and its labels.
    _dashedLine(
      canvas,
      Offset(plot.left, baseY),
      Offset(plot.right, baseY),
      baselineColor,
    );
    final baseText = _layoutText(
      _formatAxisValue(_toDisplay(baseline, baseline, mode), 1, mode),
      labelStyle.copyWith(
        color: baselineColor,
        fontWeight: FontWeight.w800,
      ),
      TextDirection.ltr,
    );
    baseText.paint(canvas, Offset(plot.right + 6, baseY - baseText.height / 2));
    final baseTag = _layoutText(
      baselineLabel,
      labelStyle.copyWith(
        color: baselineColor,
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
      ),
      labelDirection,
    );
    baseTag.paint(canvas, Offset(plot.left + 4, baseY - baseTag.height - 2));

    // Point markers when zoomed in enough to tell them apart.
    if (last - first <= 60) {
      for (var i = first; i <= last; i++) {
        final x = xFor(i);
        if (x < plot.left - 1 || x > plot.right + 1) continue;
        canvas.drawCircle(
          Offset(x, yFor(balances[i])),
          2.4,
          Paint()..color = balances[i] >= baseline ? positive : negative,
        );
      }
    }

    // Draggable crosshair with the value pill on the side axis.
    if (selectedIndex >= 0 && selectedIndex < count) {
      final x = xFor(selectedIndex);
      if (x >= plot.left - 0.5 && x <= plot.right + 0.5) {
        final balance = balances[selectedIndex];
        final y = yFor(balance);
        final color = balance - baseline > 0.005
            ? positive
            : balance - baseline < -0.005
            ? negative
            : neutral;
        canvas.drawLine(
          Offset(x, plot.top),
          Offset(x, plot.bottom),
          Paint()
            ..color = color.withValues(alpha: 0.6)
            ..strokeWidth = 1.2,
        );
        canvas.drawLine(
          Offset(plot.left, y),
          Offset(plot.right, y),
          Paint()
            ..color = color.withValues(alpha: 0.3)
            ..strokeWidth = 1,
        );
        canvas.drawCircle(Offset(x, y), 6.5, Paint()..color = surfaceColor);
        canvas.drawCircle(Offset(x, y), 4.4, Paint()..color = color);

        final onColor = ThemeData.estimateBrightnessForColor(color) ==
                Brightness.dark
            ? Colors.white
            : const Color(0xFF0B1220);
        final pill = _layoutText(
          _formatPill(_toDisplay(balance, baseline, mode), mode),
          labelStyle.copyWith(color: onColor, fontWeight: FontWeight.w800),
          TextDirection.ltr,
        );
        final pillWidth = pill.width + 12;
        final pillHeight = pill.height + 6;
        final pillCenterY = math.min(
          math.max(y, plot.top + pillHeight / 2),
          plot.bottom - pillHeight / 2,
        );
        final rect = Rect.fromLTWH(
          size.width - pillWidth - 1,
          pillCenterY - pillHeight / 2,
          pillWidth,
          pillHeight,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(7)),
          Paint()..color = color,
        );
        pill.paint(canvas, Offset(rect.left + 6, rect.top + 3));
      }
    }
  }

  void _dashedLine(Canvas canvas, Offset start, Offset end, Color color) {
    final length = (end - start).distance;
    if (length == 0) return;
    final direction = (end - start) / length;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    for (var distance = 0.0; distance < length; distance += 8) {
      final stop = math.min(distance + 4, length).toDouble();
      canvas.drawLine(start + direction * distance, start + direction * stop, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BalancePainter oldDelegate) =>
      !identical(oldDelegate.balances, balances) ||
      oldDelegate.baseline != baseline ||
      oldDelegate.viewStart != viewStart ||
      oldDelegate.viewEnd != viewEnd ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.mode != mode ||
      oldDelegate.positive != positive ||
      oldDelegate.negative != negative ||
      oldDelegate.neutral != neutral ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.baselineColor != baselineColor ||
      oldDelegate.surfaceColor != surfaceColor ||
      oldDelegate.labelStyle != labelStyle ||
      oldDelegate.baselineLabel != baselineLabel ||
      oldDelegate.labelDirection != labelDirection;
}
