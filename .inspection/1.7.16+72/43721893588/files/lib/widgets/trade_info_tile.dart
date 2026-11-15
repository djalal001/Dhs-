import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TradeInfoTile extends StatelessWidget {
  const TradeInfoTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: tokens.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.lineSubtle.withValues(alpha: 0.72)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            softWrap: true,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: tokens.text3),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            softWrap: true,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: tokens.text1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
