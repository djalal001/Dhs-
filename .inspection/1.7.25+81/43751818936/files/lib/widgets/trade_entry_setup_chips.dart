import 'package:flutter/material.dart';

import '../models/trade.dart';
import '../theme/app_theme.dart';

class TradeEntrySetupChips extends StatelessWidget {
  const TradeEntrySetupChips({
    super.key,
    required this.label,
    required this.setups,
    this.compact = false,
    this.showLabel = true,
  });

  final String label;
  final List<TradeEntrySetup> setups;
  final bool compact;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = TdTokens.of(context);
    final chips = Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final setup in setups)
          Container(
            padding: EdgeInsetsDirectional.fromSTEB(
              compact ? 5 : 6,
              compact ? 5 : 8,
              compact ? 5 : 6,
              compact ? 5 : 8,
            ),
            decoration: BoxDecoration(
              color: tokens.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tokens.lineSubtle.withValues(alpha: 0.72),
                width: 0.8,
              ),
            ),
            child: Text(
              [
                setup.reason,
                if (setup.timeframe.isNotEmpty) setup.timeframe,
              ].join(' '),
              softWrap: true,
              style:
                  (compact
                          ? theme.textTheme.labelMedium
                          : theme.textTheme.bodyMedium)
                      ?.copyWith(
                        color: tokens.text1,
                        fontWeight: FontWeight.w600,
                      ),
            ),
          ),
      ],
    );
    if (!showLabel) return chips;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              (compact
                      ? theme.textTheme.labelSmall
                      : theme.textTheme.labelMedium)
                  ?.copyWith(color: tokens.text3),
        ),
        const SizedBox(height: 5),
        chips,
      ],
    );
  }
}
