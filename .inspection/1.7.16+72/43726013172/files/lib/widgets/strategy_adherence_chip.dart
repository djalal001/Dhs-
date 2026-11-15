import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../models/trade.dart';
import '../theme/app_theme.dart';

/// Small chip shown beside the market / direction badge on a trade card.
///
/// Before the trader answers it reads "الالتزام بالاستراتيجية" in a neutral
/// outline. Tapping it opens a two-item menu (followed / did not follow); once
/// chosen, the chip shows the answer in green (followed) or amber (did not
/// follow). Amber is used instead of red so it never blends with the red tint
/// of a losing-trade card or gets confused with profit/loss colors.
class StrategyAdherenceChip extends StatelessWidget {
  const StrategyAdherenceChip({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final StrategyAdherence? value;
  final ValueChanged<StrategyAdherence> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    final followed = value == StrategyAdherence.followed;
    final answered = value != null;
    final color = !answered
        ? tokens.text2
        : followed
        ? tokens.profit
        : tokens.warn;
    final label = answered
        ? tr(context, 'strategy_${value!.name}')
        : tr(context, 'strategyAdherence');
    final icon = !answered
        ? Icons.fact_check_outlined
        : followed
        ? Icons.check_circle_rounded
        : Icons.error_outline_rounded;

    return PopupMenuButton<StrategyAdherence>(
      tooltip: tr(context, 'strategyAdherence'),
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      onOpened: HapticFeedback.selectionClick,
      onSelected: (selected) {
        HapticFeedback.lightImpact();
        if (selected != value) onChanged(selected);
      },
      itemBuilder: (_) => [
        _item(context, StrategyAdherence.followed, tokens.profit),
        _item(context, StrategyAdherence.notFollowed, tokens.warn),
      ],
      // Extra transparent padding keeps the tap target comfortable even though
      // the visible chip is small.
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Container(
          key: const ValueKey('strategy-adherence-chip'),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: answered
                ? color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: answered
                  ? color.withValues(alpha: 0.38)
                  : tokens.lineStrong,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: color),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<StrategyAdherence> _item(
    BuildContext context,
    StrategyAdherence option,
    Color color,
  ) {
    final selected = option == value;
    return PopupMenuItem<StrategyAdherence>(
      value: option,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            option == StrategyAdherence.followed
                ? Icons.check_circle_rounded
                : Icons.error_outline_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Text(
            tr(context, 'strategy_${option.name}'),
            style: TextStyle(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          if (selected) ...[
            const SizedBox(width: 10),
            Icon(Icons.done_rounded, size: 16, color: color),
          ],
        ],
      ),
    );
  }
}
