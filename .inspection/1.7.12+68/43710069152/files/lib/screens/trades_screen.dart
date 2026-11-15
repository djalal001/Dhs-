import 'package:flutter/material.dart';

import '../data/trade_file_service.dart';
import '../domain/trade_analytics.dart';
import '../domain/trade_ordering.dart';
import '../domain/trade_csv_exporter.dart';
import '../domain/trade_entry_catalog.dart';
import '../l10n/app_strings.dart';
import '../models/trade.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/trade_image_preview.dart';
import '../widgets/trade_execution_journal.dart';
import '../widgets/decision_option_emoji.dart';
import '../widgets/trade_entry_setup_chips.dart';
import '../widgets/strategy_adherence_chip.dart';
import 'trade_form_screen.dart';

class TradesScreen extends StatefulWidget {
  const TradesScreen({super.key});
  @override
  State<TradesScreen> createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen> {
  bool? _winsOnly;
  Future<void> _openForm({Trade? trade}) async {
    final app = AppScope.of(context);
    final result = await Navigator.of(context).push<Trade>(
      MaterialPageRoute(builder: (_) => TradeFormScreen(trade: trade)),
    );
    if (result != null) {
      if (trade == null) {
        await app.addTrade(result);
      } else {
        await app.updateTrade(result);
      }
    }
  }

  Future<void> _openDetails(Trade trade, String currency) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => TradeDetailScreen(trade: trade, currency: currency),
        ),
      );

  Future<void> _delete(Trade trade) async {
    final app = AppScope.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'deleteTrade')),
        content: Text(tr(context, 'deleteTradePrompt')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(context, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr(context, 'delete')),
          ),
        ],
      ),
    );
    if (yes == true) await app.deleteTrade(trade.id);
  }

  Future<void> _exportAccountCsv(List<Trade> trades) async {
    if (trades.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr(context, 'noTradesToExport'))));
      return;
    }
    try {
      final app = AppScope.of(context);
      final csv = TradeCsvExporter.generate(
        accounts: app.accounts,
        trades: trades,
        translate: (key) => tr(context, key),
      );
      final saved = await TradeFileService.saveCsv(
        csv,
        fileName: TradeFileService.csvFileName(),
      );
      if (saved == null || !mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr(context, 'csvExported'))));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr(context, 'operationFailed')}: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final account = app.accounts
        .where((item) => item.id == app.selectedAccountId)
        .firstOrNull;
    final accountTrades = account == null
        ? <Trade>[]
        : app.trades.where((trade) => trade.accountId == account.id).toList();
    final visible = accountTrades.where((trade) {
      return _winsOnly == null ||
          (_winsOnly! ? trade.result > 0 : trade.result < 0);
    }).toList()..sort(compareTradesDescending);
    final metrics = TradeAnalytics.calculate(accountTrades);
    final currency = account?.currency ?? 'USD';
    final header = <Widget>[
      PageTitle(
        tr(context, 'trades'),
        subtitle: account?.name ?? tr(context, 'selectAccount'),
        action: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: account == null || accountTrades.isEmpty
                  ? null
                  : () => _exportAccountCsv(accountTrades),
              icon: const Icon(Icons.download_outlined),
              tooltip: tr(context, 'exportCurrentAccountCsv'),
            ),
            IconButton.filled(
              onPressed: account == null ? null : () => _openForm(),
              icon: const Icon(Icons.add),
              tooltip: tr(context, 'addTrade'),
            ),
          ],
        ),
      ),
    ];
    if (account == null) {
      header.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: EmptyState(
            title: tr(context, 'noAccounts'),
            detail: tr(context, 'addFirstAccount'),
          ),
        ),
      );
    } else {
      header.addAll([
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.65,
            children: [
              MetricCard(
                label: tr(context, 'netProfit'),
                value: money(metrics.netProfit, currency),
                color: metrics.netProfit > 0
                    ? TdTokens.of(context).profit
                    : metrics.netProfit < 0
                    ? TdTokens.of(context).loss
                    : TdTokens.of(context).neutral,
              ),
              MetricCard(
                label: tr(context, 'winRate'),
                value: '${metrics.winRatePercent.toStringAsFixed(1)}%',
              ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            children: [
              _FilterChip(
                label: tr(context, 'all'),
                selected: _winsOnly == null,
                onTap: () => setState(() => _winsOnly = null),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: tr(context, 'wins'),
                selected: _winsOnly == true,
                onTap: () => setState(() => _winsOnly = true),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: tr(context, 'losses'),
                selected: _winsOnly == false,
                onTap: () => setState(() => _winsOnly = false),
              ),
            ],
          ),
        ),
      ]);
    }

    final visibleCount = account == null
        ? 0
        : visible.isEmpty
        ? 1
        : visible.length;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 28),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: header.length + visibleCount,
      itemBuilder: (context, index) {
        if (index < header.length) return header[index];
        if (visible.isEmpty) {
          return EmptyState(
            title: tr(context, 'noTrades'),
            detail: tr(context, 'addFirstTrade'),
            action: FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: Text(tr(context, 'addTrade')),
            ),
          );
        }
        final trade = visible[index - header.length];
        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
          child: _TradeSummaryCard(
            trade: trade,
            currency: currency,
            onOpen: () => _openDetails(trade, currency),
            onEdit: () => _openForm(trade: trade),
            onDelete: () => _delete(trade),
            onStrategyAdherenceChanged: (value) =>
                app.updateTrade(trade.withStrategyAdherence(value)),
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
  );
}

class _TradeSummaryCard extends StatelessWidget {
  const _TradeSummaryCard({
    required this.trade,
    required this.currency,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.onStrategyAdherenceChanged,
  });

  final Trade trade;
  final String currency;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<StrategyAdherence> onStrategyAdherenceChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    final resultColor = trade.result > 0
        ? tokens.profit
        : trade.result < 0
        ? tokens.loss
        : tokens.neutral;
    final resultDeep = trade.result > 0
        ? tokens.profitDeep
        : trade.result < 0
        ? tokens.lossDeep
        : tokens.text3;
    final tradedTime = TimeOfDay.fromDateTime(trade.tradedAt).format(context);
    final confirmation = trade.effectiveConfirmationSetups
        .map((setup) {
          final type = tr(context, setup.type);
          return setup.timeframe.isEmpty ? type : '$type ${setup.timeframe}';
        })
        .join('، ');
    final info = <(String, String)>[
      if (confirmation.isNotEmpty) (tr(context, 'confirmation'), confirmation),
      if (trade.mood.isNotEmpty) (tr(context, 'mood'), tr(context, trade.mood)),
    ];
    return AppCard(
      key: ValueKey('trade-summary-${trade.id}'),
      onTap: onOpen,
      padding: EdgeInsets.zero,
      variant: AppCardVariant.tint,
      tintColor: resultColor,
      tintBorderAlpha: .18,
      child: Stack(
        children: [
          PositionedDirectional(
            start: 0,
            top: 14,
            bottom: 14,
            width: 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [resultDeep, resultDeep.withValues(alpha: 0.4)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                trade.market,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              _DirectionBadge(side: trade.side),
                              StrategyAdherenceChip(
                                value: trade.strategyAdherence,
                                onChanged: onStrategyAdherenceChanged,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${shortDate(trade.tradedAt)} · $tradedTime',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: tokens.text3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 132),
                      child: Container(
                        height: 34,
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          8,
                          0,
                          9,
                          0,
                        ),
                        decoration: BoxDecoration(
                          color: resultColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: resultColor.withValues(alpha: 0.20),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                trade.result > 0
                                    ? Icons.arrow_upward_rounded
                                    : trade.result < 0
                                    ? Icons.arrow_downward_rounded
                                    : Icons.remove_rounded,
                                size: 15,
                                color: resultColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                money(trade.result, currency),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: resultColor,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      iconSize: 22,
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(tr(context, 'edit')),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(tr(context, 'delete')),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 18),
                if (trade.executionJournal.isNotEmpty ||
                    trade.effectiveEntrySetups.isNotEmpty)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (trade.executionJournal.isNotEmpty &&
                          trade.effectiveEntrySetups.isNotEmpty) {
                        final journalWidth = (constraints.maxWidth * 0.42)
                            .clamp(108.0, 150.0);
                        return Row(
                          textDirection: TextDirection.ltr,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              key: ValueKey('trade-journal-icons-${trade.id}'),
                              width: journalWidth,
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: TradeExecutionJournalSummary(
                                  entries: trade.executionJournal,
                                  compact: true,
                                  iconSize: 32,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                key: ValueKey('trade-entry-setups-${trade.id}'),
                                child: TradeEntrySetupChips(
                                  label: tr(context, 'entryReason'),
                                  setups: trade.effectiveEntrySetups,
                                  compact: true,
                                  showLabel: false,
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      if (trade.executionJournal.isNotEmpty) {
                        return SizedBox(
                          key: ValueKey('trade-journal-icons-${trade.id}'),
                          width: double.infinity,
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: TradeExecutionJournalSummary(
                              entries: trade.executionJournal,
                              compact: true,
                              iconSize: 32,
                            ),
                          ),
                        );
                      }
                      return SizedBox(
                        key: ValueKey('trade-entry-setups-${trade.id}'),
                        width: double.infinity,
                        child: TradeEntrySetupChips(
                          label: tr(context, 'entryReason'),
                          setups: trade.effectiveEntrySetups,
                          compact: true,
                          showLabel: false,
                        ),
                      );
                    },
                  ),
                if (info.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final (label, value) in info)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          Text(
                            '$label: ',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: tokens.text3),
                          ),
                          Expanded(
                            child: Text(
                              value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: tokens.text1),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TradeDetailScreen extends StatelessWidget {
  const TradeDetailScreen({
    super.key,
    required this.trade,
    required this.currency,
  });

  final Trade trade;
  final String currency;

  String _entryConditionLabel(
    BuildContext context,
    TradeEntryConditionSetup setup,
    List<TradeEntryOption> options,
  ) {
    final arabic = AppStrings.isArabic(context);
    final label = options
        .where((option) => option.key == setup.optionKey)
        .map((option) => arabic ? option.ar : option.en)
        .firstOrNull ?? setup.optionKey;
    return formatTradeEntryConditionSetupLabel(
      setup: setup,
      optionLabel: label,
      arabic: arabic,
      side: trade.side,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    final softenedTokens = tokens.copyWith(
      lineSubtle: tokens.lineSubtle.withValues(alpha: .78),
      lineStrong: tokens.lineStrong.withValues(alpha: .68),
    );
    final arabic = AppStrings.isArabic(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resultColor = trade.result > 0
        ? tokens.profit
        : trade.result < 0
        ? tokens.loss
        : tokens.neutral;
    final expectedLoss = trade.expectedLoss;
    final rewardRisk = expectedLoss != null && expectedLoss > 0
        ? '${(trade.result / expectedLoss).toStringAsFixed(2)}R'
        : '—';
    final tradedTime = TimeOfDay.fromDateTime(trade.tradedAt).format(context);
    final entryReasonLabels = trade.effectiveEntrySetups
        .map((setup) => setup.label)
        .where((label) => label.trim().isNotEmpty)
        .toList(growable: false);
    final reverseSignalLabels = trade.reverseSignalSetups
        .map((setup) => _entryConditionLabel(context, setup, tradeReverseSignalOptions))
        .toList(growable: false);
    final bounceZoneLabels = trade.bounceZoneSetups
        .map((setup) => _entryConditionLabel(context, setup, tradeBounceZoneOptions))
        .toList(growable: false);
    final confirmationLabels = trade.effectiveConfirmationSetups
        .map((setup) {
          final type = tr(context, setup.type);
          return setup.timeframe.isEmpty ? type : '$type ${setup.timeframe}';
        })
        .where((label) => label.trim().isNotEmpty)
        .toList(growable: false);
    final dataRows = <({String label, String value, IconData icon, bool ltr})>[
      (
        label: arabic ? 'السوق / الرمز' : 'Market / symbol',
        value: trade.market,
        icon: Icons.candlestick_chart_outlined,
        ltr: true,
      ),
      (
        label: arabic ? 'الاتجاه' : 'Direction',
        value: tr(context, trade.side == TradeSide.buy ? 'buy' : 'sell'),
        icon: Icons.swap_vert_rounded,
        ltr: false,
      ),
      if (trade.mood.isNotEmpty && trade.mood != 'moodUnknown')
        (
          label: tr(context, 'mood'),
          value: tr(context, trade.mood),
          icon: Icons.psychology_alt_outlined,
          ltr: false,
        ),
      if (trade.sequence.isNotEmpty)
        (
          label: tr(context, 'sequence'),
          value: trade.sequence,
          icon: Icons.timeline_rounded,
          ltr: false,
        ),
      (
        label: arabic ? 'تاريخ ووقت الصفقة' : 'Trade date & time',
        value: '${shortDate(trade.tradedAt)} · $tradedTime',
        icon: Icons.calendar_month_outlined,
        ltr: false,
      ),
      if (trade.strategyAdherence != null)
        (
          label: arabic ? 'الالتزام بالخطة' : 'Plan adherence',
          value: trade.strategyAdherence == StrategyAdherence.followed
              ? (arabic ? 'ملتزم' : 'Followed')
              : (arabic ? 'لم ألتزم' : 'Not followed'),
          icon: Icons.verified_user_outlined,
          ltr: false,
        ),
    ];
    final images = <({String path, String label, String prefix})>[
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

    final resultTone = isDark ? const Color(0xFFC4C4C4) : const Color(0xFFB8B0A5);
    final dataTone = isDark ? const Color(0xFFBEBEBE) : const Color(0xFFC5BDB1);
    final imageTone = isDark ? const Color(0xFFA5A5A5) : const Color(0xFFA9A197);
    const resultSurface = Color(0xFF2B2B2B);
    const resultField = Color(0xFF222222);
    const dataSurface = Color(0xFF292929);
    const dataField = Color(0xFF222222);

    final dataPanelChildren = <Widget>[];
    void appendDataField(Widget field) {
      if (dataPanelChildren.isNotEmpty) {
        dataPanelChildren.add(const SizedBox(height: 8));
      }
      dataPanelChildren.add(field);
    }

    Widget dataRowWidget(int index) => _TradeDetailRow(
      key: ValueKey('trade-detail-data-row-$index'),
      label: dataRows[index].label,
      value: dataRows[index].value,
      icon: dataRows[index].icon,
      fill: dataField,
      edge: isDark ? const Color(0xFF484848) : const Color(0xFF514A40),
      labelTone: dataTone,
      valueLtr: dataRows[index].ltr,
    );

    // The two compact identity fields share one row, matching the entry form.
    // Longer narrative/setup fields below remain full width for readability.
    if (dataRows.length >= 2) {
      appendDataField(
        _TradeDetailPair(
          key: const ValueKey('trade-detail-market-direction-pair'),
          first: dataRowWidget(0),
          second: dataRowWidget(1),
        ),
      );
    }

    for (var index = 2; index < dataRows.length; index++) {
      if (index == 2 && entryReasonLabels.isNotEmpty) {
        appendDataField(
          _TradeDetailChipField(
            key: const ValueKey('trade-detail-entry-reasons'),
            label: tr(context, 'entryReason'),
            values: entryReasonLabels,
            icon: Icons.gps_fixed_rounded,
            fill: dataField,
            edge: isDark ? const Color(0xFF484848) : const Color(0xFF514A40),
            tone: dataTone,
          ),
        );
      }
      if (index == 2 && confirmationLabels.isNotEmpty) {
        appendDataField(
          _TradeDetailChipField(
            key: const ValueKey('trade-detail-confirmations'),
            label: tr(context, 'confirmation'),
            values: confirmationLabels,
            icon: Icons.verified_outlined,
            fill: dataField,
            edge: isDark ? const Color(0xFF484848) : const Color(0xFF514A40),
            tone: dataTone,
          ),
        );
      }
      appendDataField(dataRowWidget(index));
    }

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: softenedTokens.lineSubtle,
        extensions: [softenedTokens],
      ),
      child: Scaffold(
        appBar: AppBar(title: Text(tr(context, 'tradeDetails'))),
        body: ListView(
          key: const ValueKey('trade-detail-scroll-view'),
          padding: const EdgeInsetsDirectional.fromSTEB(8, 10, 8, 24),
          children: [
            _TradeDetailPanel(
              key: const ValueKey('trade-detail-result-panel'),
              title: arabic ? 'النتيجة والمخاطرة' : 'Result & risk',
              icon: Icons.tune_rounded,
              tone: resultTone,
              darkSurface: resultSurface,
              collapsible: true,
              toggleKey: const ValueKey('trade-detail-result-panel-toggle'),
              summary: '${money(trade.result, currency)} · ${trade.riskPercent.toStringAsFixed(2)}% · $rewardRisk',
              child: Column(
                children: [
                  if (expectedLoss != null)
                    _TradeDetailPair(
                      key: const ValueKey('trade-detail-result-expected-loss-pair'),
                      first: _TradeDetailRow(
                        key: const ValueKey('trade-detail-result-value'),
                        label: tr(context, 'result'),
                        value: money(trade.result, currency),
                        icon: Icons.calculate_outlined,
                        fill: resultField,
                        edge: isDark ? const Color(0xFF484848) : const Color(0xFF514A40),
                        labelTone: resultTone,
                        valueColor: resultColor,
                        valueLtr: true,
                      ),
                      second: _TradeDetailRow(
                        key: const ValueKey('trade-detail-expected-loss-value'),
                        label: tr(context, 'expectedLoss'),
                        value: money(expectedLoss, currency),
                        icon: Icons.south_rounded,
                        fill: resultField,
                        edge: isDark ? const Color(0xFF484848) : const Color(0xFF514A40),
                        labelTone: resultTone,
                        valueLtr: true,
                      ),
                    )
                  else
                    _TradeDetailRow(
                      key: const ValueKey('trade-detail-result-value'),
                      label: tr(context, 'result'),
                      value: money(trade.result, currency),
                      icon: Icons.calculate_outlined,
                      fill: resultField,
                      edge: isDark ? const Color(0xFF484848) : const Color(0xFF514A40),
                      labelTone: resultTone,
                      valueColor: resultColor,
                      valueLtr: true,
                    ),
                  const SizedBox(height: 8),
                  _TradeDetailPair(
                    key: const ValueKey('trade-detail-risk-reward-pair'),
                    first: _TradeDetailRow(
                      key: const ValueKey('trade-detail-risk-percent-value'),
                      label: tr(context, 'riskPercent'),
                      value: '${trade.riskPercent.toStringAsFixed(2)}%',
                      icon: Icons.pie_chart_outline_rounded,
                      fill: resultField,
                      edge: isDark ? const Color(0xFF484848) : const Color(0xFF514A40),
                      labelTone: resultTone,
                      valueLtr: true,
                    ),
                    second: _TradeDetailRow(
                      key: const ValueKey('trade-detail-reward-risk-value'),
                      label: tr(context, 'rewardRisk'),
                      value: rewardRisk,
                      icon: Icons.flag_outlined,
                      fill: resultField,
                      edge: isDark ? const Color(0xFF484848) : const Color(0xFF514A40),
                      labelTone: resultTone,
                      valueColor: expectedLoss != null && expectedLoss > 0
                          ? (trade.result / expectedLoss >= 1
                                ? const Color(0xFF79C9A4)
                                : const Color(0xFFE3A0A0))
                          : tokens.text2,
                      valueLtr: true,
                    ),
                  ),
                ],
              ),
            ),
            if (images.isNotEmpty) ...[
              const SizedBox(height: 10),
              _TradeDetailPanel(
                title: arabic ? 'صور الصفقة' : 'Trade images',
                icon: Icons.photo_library_outlined,
                tone: imageTone,
                darkSurface: const Color(0xFF292929),
                collapsible: true,
                initiallyExpanded: true,
                toggleKey: const ValueKey('trade-detail-images-panel-toggle'),
                summary: '${images.length} ${arabic ? 'صور' : 'images'}',
                child: LayoutBuilder(
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
                              height: 128,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 10),
            _TradeDetailPanel(
              key: const ValueKey('trade-detail-data-panel'),
              title: arabic ? 'بيانات الصفقة' : 'Trade details',
              icon: Icons.receipt_long_outlined,
              tone: dataTone,
              darkSurface: dataSurface,
              collapsible: true,
              initiallyExpanded: false,
              toggleKey: const ValueKey('trade-detail-data-panel-toggle'),
              summary: '${trade.market} · ${tr(context, trade.side == TradeSide.buy ? 'buy' : 'sell')}',
              child: Column(children: dataPanelChildren),
            ),
            if (reverseSignalLabels.isNotEmpty || bounceZoneLabels.isNotEmpty) ...[
              const SizedBox(height: 10),
              _TradeDetailPanel(
                key: const ValueKey('trade-detail-entry-conditions-panel'),
                title: arabic ? 'ظروف الدخول' : 'Entry conditions',
                icon: Icons.radar_rounded,
                tone: isDark ? const Color(0xFFB0B0B0) : const Color(0xFFA9A196),
                darkSurface: const Color(0xFF282828),
                collapsible: true,
                initiallyExpanded: false,
                horizontalPadding: 6,
                toggleKey: const ValueKey('trade-detail-entry-conditions-toggle'),
                summary: '${reverseSignalLabels.length + bounceZoneLabels.length} ${arabic ? 'اختيارات' : 'selections'}',
                child: Column(
                  children: [
                    if (reverseSignalLabels.isNotEmpty)
                      _TradeDetailChipField(
                        key: const ValueKey('trade-detail-reverse-signals'),
                        label: arabic ? 'إشارات عكسية' : 'Opposing signals',
                        values: reverseSignalLabels,
                        icon: Icons.warning_amber_rounded,
                        fill: dataField,
                        edge: isDark ? const Color(0xFF484848) : const Color(0xFF514A40),
                        tone: isDark ? const Color(0xFF929292) : const Color(0xFF928A7F),
                      ),
                    if (reverseSignalLabels.isNotEmpty && bounceZoneLabels.isNotEmpty)
                      const SizedBox(height: 8),
                    if (bounceZoneLabels.isNotEmpty)
                      _TradeDetailChipField(
                        key: const ValueKey('trade-detail-bounce-zone'),
                        label: arabic ? 'منطقة الارتداد' : 'Bounce area',
                        values: bounceZoneLabels,
                        icon: Icons.my_location_rounded,
                        fill: dataField,
                        edge: isDark ? const Color(0xFF484848) : const Color(0xFF514A40),
                        tone: isDark ? const Color(0xFF808080) : const Color(0xFF81796E),
                      ),
                  ],
                ),
              ),
            ],
            if (trade.executionJournal.isNotEmpty) ...[
              const SizedBox(height: 10),
              _TradeDetailPanel(
                key: const ValueKey('trade-detail-execution-panel'),
                title: arabic ? 'سجل التنفيذ' : 'Execution log',
                icon: Icons.track_changes_outlined,
                tone: isDark ? const Color(0xFFAFAFAF) : const Color(0xFFAAA297),
                darkSurface: const Color(0xFF282828),
                collapsible: true,
                initiallyExpanded: false,
                toggleKey: const ValueKey('trade-detail-execution-panel-toggle'),
                summary: '${trade.executionJournal.length} ${arabic ? 'إجراءات' : 'entries'}',
                child: TradeExecutionJournalSummary(
                  entries: trade.executionJournal,
                  showHeading: false,
                  iconSize: 34,
                ),
              ),
            ],
            if (trade.executionReviewKeys.isNotEmpty ||
                trade.noEntryReasons.isNotEmpty) ...[
              const SizedBox(height: 10),
              TradeBehaviorSummary(trade: trade, initiallyExpanded: false),
            ],
            if (trade.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              _TradeDetailPanel(
                key: const ValueKey('trade-detail-notes-panel'),
                title: tr(context, 'notes'),
                icon: Icons.notes_rounded,
                tone: isDark ? const Color(0xFFAFAFAF) : const Color(0xFFAAA297),
                darkSurface: const Color(0xFF292929),
                collapsible: true,
                initiallyExpanded: false,
                toggleKey: const ValueKey('trade-detail-notes-panel-toggle'),
                summary: trade.notes.replaceAll('\n', ' '),
                child: _TradeTextBlock(value: trade.notes),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TradeDetailPanel extends StatefulWidget {
  const _TradeDetailPanel({
    super.key,
    required this.title,
    required this.icon,
    required this.tone,
    required this.darkSurface,
    required this.child,
    this.collapsible = false,
    this.initiallyExpanded = true,
    this.toggleKey,
    this.summary,
    this.horizontalPadding = 6,
    this.surfaceKey,
  });

  final String title;
  final IconData icon;
  final Color tone;
  final Color darkSurface;
  final Widget child;
  final bool collapsible;
  final bool initiallyExpanded;
  final Key? toggleKey;
  final String? summary;
  final double horizontalPadding;
  final Key? surfaceKey;

  @override
  State<_TradeDetailPanel> createState() => _TradeDetailPanelState();
}

class _TradeDetailPanelState extends State<_TradeDetailPanel> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  void didUpdateWidget(covariant _TradeDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _expanded = widget.initiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final surface = isDark
        ? widget.darkSurface
        : Color.alphaBlend(widget.tone.withValues(alpha: .075), tokens.surface1);

    final header = Semantics(
      button: widget.collapsible,
      expanded: widget.collapsible ? _expanded : null,
      label: widget.title,
      child: InkWell(
        key: widget.collapsible
            ? (widget.toggleKey ?? const ValueKey('trade-detail-panel-toggle'))
            : null,
        onTap: widget.collapsible
            ? () => setState(() => _expanded = !_expanded)
            : null,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widget.collapsible ? 2 : 0,
            vertical: widget.collapsible ? 3 : 0,
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 21, color: widget.tone),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: tokens.text1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (widget.collapsible && !_expanded &&
                        (widget.summary?.trim().isNotEmpty ?? false)) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.summary!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: tokens.text3,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.collapsible) ...[
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _expanded ? .5 : 0,
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 23,
                    color: widget.tone,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, color: widget.tone.withValues(alpha: .16)),
        const SizedBox(height: 10),
        widget.child,
      ],
    );

    return Container(
      key: widget.surfaceKey,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: widget.horizontalPadding,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.tone.withValues(alpha: isDark ? .24 : .18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (widget.collapsible)
            AnimatedSize(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 190),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: _expanded ? body : const SizedBox.shrink(),
            )
          else ...[
            const SizedBox(height: 10),
            body,
          ],
        ],
      ),
    );
  }
}

class _TradeDetailPair extends StatelessWidget {
  const _TradeDetailPair({
    super.key,
    required this.first,
    required this.second,
  });

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 8),
        Expanded(child: second),
      ],
    );
  }
}

class _TradeDetailRow extends StatelessWidget {
  const _TradeDetailRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.fill,
    required this.edge,
    required this.labelTone,
    this.valueColor,
    this.valueLtr = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color fill;
  final Color edge;
  final Color labelTone;
  final Color? valueColor;
  final bool valueLtr;

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? fill
        : Color.alphaBlend(labelTone.withValues(alpha: .045), tokens.surface2);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsetsDirectional.fromSTEB(11, 10, 11, 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: edge.withValues(alpha: isDark ? .52 : .30)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 178;
          final labelWidget = Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: tokens.text2,
              fontWeight: FontWeight.w600,
            ),
          );
          final valueWidget = Directionality(
            textDirection: valueLtr
                ? TextDirection.ltr
                : Directionality.of(context),
            child: Text(
              value,
              textAlign: TextAlign.end,
              softWrap: true,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor ?? tokens.text1,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 17, color: labelTone),
                    const SizedBox(width: 7),
                    Expanded(child: labelWidget),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: valueWidget,
                ),
              ],
            );
          }

          return Row(
            children: [
              Icon(icon, size: 18, color: labelTone),
              const SizedBox(width: 9),
              Expanded(child: labelWidget),
              const SizedBox(width: 10),
              Flexible(flex: 2, child: valueWidget),
            ],
          );
        },
      ),
    );
  }
}


class _TradeDetailChipField extends StatelessWidget {
  const _TradeDetailChipField({
    super.key,
    required this.label,
    required this.values,
    required this.icon,
    required this.fill,
    required this.edge,
    required this.tone,
  });

  final String label;
  final List<String> values;
  final IconData icon;
  final Color fill;
  final Color edge;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(6, 10, 6, 11),
      decoration: BoxDecoration(
        color: isDark
            ? fill
            : Color.alphaBlend(tone.withValues(alpha: .045), tokens.surface2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: edge.withValues(alpha: isDark ? .52 : .30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: tone),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.text2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 7,
              runSpacing: 7,
              alignment: WrapAlignment.start,
              children: [
                for (final value in values)
                  Container(
                    key: ValueKey('trade-detail-entry-condition-value-$value'),
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth,
                    ),
                    padding: const EdgeInsetsDirectional.fromSTEB(6, 7, 6, 7),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF292929) : const Color(0xFFECE7DF),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: tone.withValues(alpha: .16)),
                    ),
                    child: Text(
                      value,
                      softWrap: true,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: tokens.text1,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TradeBehaviorSummary extends StatelessWidget {
  const TradeBehaviorSummary({
    super.key,
    required this.trade,
    this.initiallyExpanded = true,
  });
  final Trade trade;
  final bool initiallyExpanded;

  static const _decisionTone = Color(0xFFC8C8C8);
  static const _commitmentTone = Color(0xFFB0B0B0);
  static const _noEntryTone = Color(0xFF929292);

  @override
  Widget build(BuildContext context) {
    final arabic = AppStrings.isArabic(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final decisionTone = isDark ? _decisionTone : const Color(0xFFBDB3A4);
    final commitmentTone = isDark ? _commitmentTone : const Color(0xFFA9A197);
    final noEntryTone = isDark ? _noEntryTone : const Color(0xFF9B9286);
    final reviewKeys = trade.executionReviewKeys.toSet();
    final decisionCatalog = tradeReviewGroups
        .expand((group) => group.options)
        .map((option) => option.key)
        .toSet();
    final commitmentCatalog = tradeCommitmentOptions
        .map((option) => option.key)
        .toSet();
    final knownDecisionKeys = {...decisionCatalog, ...commitmentCatalog};
    final selectedDecisionCount = reviewKeys
        .where((key) => decisionCatalog.contains(key) || !knownDecisionKeys.contains(key))
        .length;
    final selectedCommitments = tradeCommitmentOptions
        .where((option) => reviewKeys.contains(option.key))
        .toList(growable: false);
    final unknownDecisionKeys = reviewKeys
        .where((key) => !knownDecisionKeys.contains(key))
        .toList(growable: false);
    final noEntryKeys = trade.noEntryReasons.toSet();
    final knownNoEntry = tradeNoEntryOptions.map((option) => option.key).toSet();
    final selectedNoEntry = tradeNoEntryOptions
        .where((option) => noEntryKeys.contains(option.key))
        .toList(growable: false);
    final unknownNoEntry = noEntryKeys
        .where((key) => !knownNoEntry.contains(key))
        .toList(growable: false);
    final selectedNoEntryCount = selectedNoEntry.length + unknownNoEntry.length;
    if (selectedDecisionCount == 0 &&
        selectedCommitments.isEmpty &&
        selectedNoEntryCount == 0) {
      return const SizedBox.shrink();
    }

    final outerFill = isDark ? const Color(0xFF292929) : const Color(0xFFEDE7DE);
    final decisionSurface = isDark ? const Color(0xFF222222) : const Color(0xFFFAF6F0);
    final commitmentSurface = isDark ? const Color(0xFF292929) : const Color(0xFFEDE7DE);
    final noEntrySurface = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3EEE6);

    Widget optionTiles(List<String> keys, Color tone, Color itemFill) => Column(
      children: [
        for (var index = 0; index < keys.length; index++) ...[
          if (index > 0) const SizedBox(height: 6),
          _ReviewOptionTile(
            optionKey: keys[index],
            label: tradeEntryLabel(keys[index], arabic: arabic),
            tone: tone,
            fill: itemFill,
            isDark: isDark,
          ),
        ],
      ],
    );

    Widget subgroup({
      required String title,
      required List<String> keys,
      String? note,
    }) {
      if (keys.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsetsDirectional.only(top: 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isDark ? const Color(0xFFC8C8C8) : const Color(0xFFC8BDAA),
                fontWeight: FontWeight.w800,
              ),
            ),
            if (note != null) ...[
              const SizedBox(height: 3),
              Text(
                note,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? const Color(0xFFB8B8B8) : const Color(0xFF6D6257),
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 6),
            optionTiles(keys, decisionTone, isDark ? const Color(0xFF303030) : const Color(0xFFF0ECE6)),
          ],
        ),
      );
    }

    Widget reviewGroup({
      required String sectionKey,
      required String title,
      required List<String> keys,
      required Color tone,
      required Color surface,
      required IconData icon,
      Widget? leading,
      required Widget content,
    }) {
      if (keys.isEmpty) return const SizedBox.shrink();
      return _TradeReviewGroupPanel(
        key: ValueKey('trade-review-group-$sectionKey'),
        toggleKey: ValueKey('trade-review-group-$sectionKey-toggle'),
        title: title,
        count: keys.length,
        tone: tone,
        surface: surface,
        icon: icon,
        leading: leading,
        child: content,
      );
    }

    final decisionContent = <Widget>[];
    for (final category in tradeReviewGroups) {
      final keys = category.options
          .where((option) => reviewKeys.contains(option.key))
          .map((option) => option.key)
          .toList(growable: false);
      if (keys.isNotEmpty) {
        decisionContent.add(
          subgroup(
            title: arabic ? category.titleAr : category.titleEn,
            keys: keys,
            note: category.noteAr == null
                ? null
                : (arabic ? category.noteAr! : category.noteEn!),
          ),
        );
      }
    }
    if (unknownDecisionKeys.isNotEmpty) {
      decisionContent.add(
        subgroup(
          title: arabic ? 'عناصر محفوظة من إصدار سابق' : 'Items from an earlier version',
          keys: unknownDecisionKeys,
        ),
      );
    }

    final noEntryKeysOrdered = [
      ...selectedNoEntry.map((option) => option.key),
      ...unknownNoEntry,
    ];

    final reviewSelectionCount =
        selectedDecisionCount + selectedCommitments.length + selectedNoEntryCount;

    return _TradeDetailPanel(
      key: const ValueKey('trade-detail-review-panel'),
      title: arabic ? 'مراجعة الصفقة' : 'Trade review',
      icon: Icons.fact_check_outlined,
      tone: isDark ? const Color(0xFFB8B8B8) : const Color(0xFFB7AFA3),
      darkSurface: outerFill,
      collapsible: true,
      initiallyExpanded: initiallyExpanded,
      horizontalPadding: 6,
      toggleKey: const ValueKey('trade-detail-review-panel-toggle'),
      summary: '$reviewSelectionCount ${arabic ? 'اختيارات' : 'selections'}',
      surfaceKey: const ValueKey('trade-detail-review-panel-surface'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          reviewGroup(
            sectionKey: 'decisions',
            title: arabic ? 'القرارات' : 'Decisions',
            keys: [
              ...reviewKeys.where(decisionCatalog.contains),
              ...unknownDecisionKeys,
            ],
            tone: decisionTone,
            surface: decisionSurface,
            icon: Icons.rule_rounded,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: decisionContent,
            ),
          ),
          reviewGroup(
            sectionKey: 'commitment',
            title: arabic ? 'الالتزام' : 'Commitment',
            keys: selectedCommitments.map((option) => option.key).toList(),
            tone: commitmentTone,
            surface: commitmentSurface,
            icon: Icons.verified_user_outlined,
            content: optionTiles(
              selectedCommitments.map((option) => option.key).toList(),
              commitmentTone,
              isDark ? const Color(0xFF303030) : const Color(0xFFF0ECE6),
            ),
          ),
          reviewGroup(
            sectionKey: 'no-entry',
            title: arabic ? 'أسباب عدم الدخول' : 'Reasons for not entering',
            keys: noEntryKeysOrdered,
            tone: noEntryTone,
            surface: noEntrySurface,
            icon: Icons.block_outlined,
            content: optionTiles(
              noEntryKeysOrdered,
              noEntryTone,
              isDark ? const Color(0xFF303030) : const Color(0xFFEFE8DF),
            ),
          ),
        ],
      ),
    );
  }
}


class _TradeReviewGroupPanel extends StatefulWidget {
  const _TradeReviewGroupPanel({
    super.key,
    required this.toggleKey,
    required this.title,
    required this.count,
    required this.tone,
    required this.surface,
    required this.icon,
    this.leading,
    required this.child,
  });

  final Key toggleKey;
  final String title;
  final int count;
  final Color tone;
  final Color surface;
  final IconData icon;
  final Widget? leading;
  final Widget child;

  @override
  State<_TradeReviewGroupPanel> createState() => _TradeReviewGroupPanelState();
}

class _TradeReviewGroupPanelState extends State<_TradeReviewGroupPanel> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      color: widget.tone,
      fontWeight: FontWeight.w800,
    );
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 9),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      decoration: BoxDecoration(
        color: widget.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.tone.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? .34 : .24,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _expanded,
            label: widget.title,
            child: InkWell(
              key: widget.toggleKey,
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    widget.leading ?? Icon(widget.icon, size: 18, color: widget.tone),
                    const SizedBox(width: 8),
                    Expanded(child: Text(widget.title, style: titleStyle)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: widget.tone.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.count}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: widget.tone,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    AnimatedRotation(
                      turns: _expanded ? .5 : 0,
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 160),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 21,
                        color: widget.tone,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: widget.child,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ReviewOptionTile extends StatelessWidget {
  const _ReviewOptionTile({
    required this.optionKey,
    required this.label,
    required this.tone,
    required this.fill,
    required this.isDark,
  });

  final String optionKey;
  final String label;
  final Color tone;
  final Color fill;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    final hasArtwork = tradeReviewOptionEmojiAssets.containsKey(optionKey);
    return Container(
      key: ValueKey('trade-review-option-tile-$optionKey'),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsetsDirectional.fromSTEB(6, 7, 6, 7),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tone.withValues(alpha: isDark ? .22 : .18)),
      ),
      child: Row(
        children: [
          if (hasArtwork)
            TradeReviewOptionEmoji(optionKey: optionKey, size: 28)
          else
            Icon(Icons.label_outline_rounded, size: 23, color: tone),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              softWrap: true,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tokens.text1,
                height: 1.48,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionBadge extends StatelessWidget {
  const _DirectionBadge({required this.side});
  final TradeSide side;

  @override
  Widget build(BuildContext context) {
    final isBuy = side == TradeSide.buy;
    final tokens = TdTokens.of(context);
    final color = isBuy ? tokens.profit : tokens.loss;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBuy ? Icons.north_east_rounded : Icons.south_east_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            tr(context, isBuy ? 'buy' : 'sell'),
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeTextBlock extends StatelessWidget {
  const _TradeTextBlock({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 1, 4, 2),
      child: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: tokens.text1,
          height: 1.55,
        ),
      ),
    );
  }
}
