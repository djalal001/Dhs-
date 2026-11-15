import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/trade.dart';
import '../theme/app_theme.dart';

const _statuses =
    <({TradeExecutionStatus status, String animatedAsset, Color color})>[
      (
        status: TradeExecutionStatus.followedPlan,
        animatedAsset: 'assets/emojis/emoji-executed-per-plan.gif',
        color: Color(0xFF18B77A),
      ),
      (
        status: TradeExecutionStatus.avoidedEntryBecauseFear,
        animatedAsset: 'assets/emojis/emoji-avoided-entry-fear.gif',
        color: negativeRed,
      ),
      (
        status: TradeExecutionStatus.enteredEarly,
        animatedAsset: 'assets/emojis/emoji-entered-early.gif',
        color: Color(0xFFFF8A24),
      ),
      (
        status: TradeExecutionStatus.entryConditionsNotMet,
        animatedAsset: 'assets/emojis/emoji-entry-conditions-not-met.gif',
        color: Color(0xFFAAA297),
      ),
      (
        status: TradeExecutionStatus.missedHigherTimeframeBounceArea,
        animatedAsset: 'assets/emojis/emoji-missed-htf-bounce-zone.gif',
        color: Color(0xFF41C79A),
      ),
      (
        status: TradeExecutionStatus.missedLowerTimeframeBounceArea,
        animatedAsset: 'assets/emojis/emoji-missed-ltf-bounce-zone.gif',
        color: Color(0xFFB8B0A5),
      ),
      (
        status: TradeExecutionStatus.missedTrendlineFromCandleWicks,
        animatedAsset: 'assets/emojis/emoji-missed-wick-trendline.gif',
        color: Color(0xFFFFC247),
      ),
      (
        status: TradeExecutionStatus.hesitationPartialSize,
        animatedAsset: 'assets/emojis/emoji-hesitation-partial-size.gif',
        color: Color(0xFFBA7517),
      ),
      (
        status: TradeExecutionStatus.lateEntry,
        animatedAsset: 'assets/emojis/emoji-late-entry.gif',
        color: Color(0xFFC73A3A),
      ),
      (
        status: TradeExecutionStatus.stopLossMoved,
        animatedAsset: 'assets/emojis/emoji-stop-loss-moved.gif',
        color: Color(0xFFC73A3A),
      ),
      (
        status: TradeExecutionStatus.noBreakoutPositiveClose,
        animatedAsset: 'assets/emojis/emoji-no-breakout-positive-close.gif',
        color: Color(0xFFFF4D5E),
      ),
      (
        status: TradeExecutionStatus.exitedEarlyBecauseFearOfLosingProfit,
        animatedAsset: 'assets/emojis/emoji-exited-early-target.gif',
        color: Color(0xFFFF4D5E),
      ),
    ];

Color _journalStatusColor(
  TradeExecutionStatus status,
  Color lightModeColor,
  bool isDark,
) {
  if (!isDark) return lightModeColor;
  return switch (status) {
    TradeExecutionStatus.followedPlan => const Color(0xFF39A982),
    TradeExecutionStatus.avoidedEntryBecauseFear => const Color(0xFFD96C76),
    TradeExecutionStatus.enteredEarly => const Color(0xFFA4A4A4),
    TradeExecutionStatus.entryConditionsNotMet => const Color(0xFFA4A4A4),
    TradeExecutionStatus.missedHigherTimeframeBounceArea =>
      const Color(0xFF4C9C7B),
    TradeExecutionStatus.missedLowerTimeframeBounceArea =>
      const Color(0xFFA4A4A4),
    TradeExecutionStatus.missedTrendlineFromCandleWicks =>
      const Color(0xFFA4A4A4),
    TradeExecutionStatus.hesitationPartialSize => const Color(0xFFA4A4A4),
    TradeExecutionStatus.lateEntry => const Color(0xFFD96C76),
    TradeExecutionStatus.stopLossMoved => const Color(0xFFD96C76),
    TradeExecutionStatus.noBreakoutPositiveClose => const Color(0xFFD96C76),
    TradeExecutionStatus.exitedEarlyBecauseFearOfLosingProfit =>
      const Color(0xFFD96C76),
  };
}

class TradeExecutionJournalSelector extends StatelessWidget {
  const TradeExecutionJournalSelector({
    super.key,
    required this.selectedEntries,
    required this.onChanged,
  });

  final Set<TradeExecutionJournalEntry> selectedEntries;
  final ValueChanged<Set<TradeExecutionJournalEntry>> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          for (var index = 0; index < _statuses.length; index++) ...[
            if (index > 0)
              Divider(
                height: 1,
                indent: 12,
                endIndent: 12,
                color: theme.dividerColor,
              ),
            _buildChoice(context, _statuses[index]),
          ],
        ],
      ),
    );
  }

  Widget _buildChoice(
    BuildContext context,
    ({TradeExecutionStatus status, String animatedAsset, Color color}) option,
  ) {
    final entry = TradeExecutionJournalEntry(status: option.status);
    final selected = selectedEntries.contains(entry);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _journalStatusColor(
      option.status,
      option.color,
      isDark,
    );
    final label = tr(context, 'journalStatus_${option.status.name}');

    void toggle() {
      final updated = {...selectedEntries};
      if (selected) {
        updated.remove(entry);
      } else {
        updated.add(entry);
      }
      onChanged(updated);
    }

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      key: ValueKey('journal-option-${option.status.name}'),
      button: true,
      checked: selected,
      label: label,
      child: AnimatedContainer(
        duration: reduceMotion
            ? const Duration(milliseconds: 120)
            : const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: selected
              ? statusColor.withValues(alpha: 0.09)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? statusColor.withValues(alpha: 0.28)
                : Colors.transparent,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: toggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 12, 8),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(
                        alpha: selected ? 0.16 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.22),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: _TradeJournalEmoji(
                      asset: option.animatedAsset,
                      width: 40,
                      height: 40,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: TdTokens.of(context).text1,
                        fontWeight: selected ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 22,
                    color: selected ? statusColor : TdTokens.of(context).text3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TradeExecutionJournalSummary extends StatelessWidget {
  const TradeExecutionJournalSummary({
    super.key,
    required this.entries,
    this.compact = false,
    this.showHeading = true,
    this.iconSize = 30,
  });

  final List<TradeExecutionJournalEntry> entries;
  final bool compact;
  final bool showHeading;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final selectedOptions = [
      for (final option in _statuses)
        if (entries.contains(TradeExecutionJournalEntry(status: option.status)))
          option,
    ];
    if (selectedOptions.isEmpty) return const SizedBox.shrink();

    if (compact) {
      return Wrap(
        key: key,
        alignment: WrapAlignment.start,
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final option in selectedOptions)
            Tooltip(
              message: tr(context, 'journalStatus_${option.status.name}'),
              child: Semantics(
                label: tr(context, 'journalStatus_${option.status.name}'),
                child: SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: _TradeJournalEmoji(
                    asset: option.animatedAsset,
                    width: iconSize,
                    height: iconSize,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeading) ...[
          Text(
            tr(context, 'sequence'),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
        ],
        for (final option in selectedOptions) ...[
          _SummaryTag(
            label: tr(context, 'journalStatus_${option.status.name}'),
            asset: option.animatedAsset,
            color: option.color,
            iconSize: 36,
          ),
          if (option != selectedOptions.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _SummaryTag extends StatelessWidget {
  const _SummaryTag({
    required this.label,
    required this.asset,
    required this.color,
    required this.iconSize,
  });

  final String label;
  final String asset;
  final Color color;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 14, 8),
      decoration: BoxDecoration(
        color: tokens.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          _TradeJournalEmoji(asset: asset, width: iconSize, height: iconSize),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              softWrap: true,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.text1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeJournalEmoji extends StatelessWidget {
  const _TradeJournalEmoji({
    required this.asset,
    required this.width,
    required this.height,
  });

  final String asset;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Image.asset(
        asset,
        width: width,
        height: height,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
      ),
    );
  }
}
