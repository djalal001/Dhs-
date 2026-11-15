import 'package:flutter/material.dart';

/// Artwork copied from the matching Windows Trader Labs decision catalog.
/// Keep one compact visual per decision key so labels and artwork never drift.
const decisionOptionEmojiAssets = <String, String>{
  'enteredEarly': 'assets/emojis/decisions/decision-enteredEarly.gif',
  'hesitationPartialSize':
      'assets/emojis/decisions/decision-hesitationPartialSize.gif',
  'lateEntry': 'assets/emojis/decisions/decision-lateEntry.gif',
  'stopLossReducedWithoutReason':
      'assets/emojis/decisions/decision-stopLossReducedWithoutReason.webp',
  'stopLossIncreasedWithoutReason':
      'assets/emojis/decisions/decision-stopLossIncreasedWithoutReason.webp',
  'exitedEarlyBecauseFearOfLosingProfit':
      'assets/emojis/decisions/decision-exitedEarlyBecauseFearOfLosingProfit.gif',
  'missedHigherTimeframeBounceArea':
      'assets/emojis/decisions/decision-missedHigherTimeframeBounceArea.gif',
  'missedLowerTimeframeBounceArea':
      'assets/emojis/decisions/decision-missedLowerTimeframeBounceArea.gif',
  'missedTrendlineFromCandleWicks':
      'assets/emojis/decisions/decision-missedTrendlineFromCandleWicks.gif',
  'noBreakoutPositiveClose':
      'assets/emojis/decisions/decision-noBreakoutPositiveClose.gif',
  'noTrendlineSupportsEntryZone':
      'assets/emojis/decisions/decision-noTrendlineSupportsEntryZone.webp',
  'missedHigherTimeframeTrendlineIntegration':
      'assets/emojis/decisions/decision-missedHigherTimeframeTrendlineIntegration.webp',
  'stopLossIncreasedForLiquiditySafety':
      'assets/emojis/decisions/decision-stopLossIncreasedForLiquiditySafety.webp',
  'stopLossReducedForNegativeClose':
      'assets/emojis/decisions/decision-stopLossReducedForNegativeClose.webp',
  'partialSizeAwaitingDeepCorrection':
      'assets/emojis/decisions/decision-partialSizeAwaitingDeepCorrection.webp',
};

class DecisionOptionEmoji extends StatelessWidget {
  const DecisionOptionEmoji({super.key, required this.optionKey});

  final String optionKey;

  static const double size = 28;

  @override
  Widget build(BuildContext context) {
    final asset = decisionOptionEmojiAssets[optionKey];
    if (asset == null) return const SizedBox.shrink();

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}


/// Complete review artwork from the Windows Trader Labs reference:
/// 15 decision illustrations + 5 commitment illustrations + 5 no-entry illustrations.
const tradeReviewOptionEmojiAssets = <String, String>{
  ...decisionOptionEmojiAssets,
  'breakevenStopToEntry':
      'assets/emojis/commitment/breakevenStopToEntry.webp',
  'manualExitNearTarget':
      'assets/emojis/commitment/manualExitNearTarget.webp',
  'autoExitAtTarget': 'assets/emojis/commitment/autoExitAtTarget.webp',
  'enteredDespiteFear': 'assets/emojis/commitment/enteredDespiteFear.webp',
  'fullPlanCompliance': 'assets/emojis/commitment/fullPlanCompliance.webp',
  'fearRepeatLossAfterLoss':
      'assets/emojis/no_entry/fearRepeatLossAfterLoss.webp',
  'fearGivingBackProfit':
      'assets/emojis/no_entry/fearGivingBackProfit.webp',
  'fearLossNoHistory': 'assets/emojis/no_entry/fearLossNoHistory.webp',
  'hesitationUnclearScenario':
      'assets/emojis/no_entry/hesitationUnclearScenario.webp',
  'waitedDeeperRetestDespiteConfirmation':
      'assets/emojis/no_entry/waitedDeeperRetestDespiteConfirmation.webp',
};

/// Compact Windows-matched illustration used in saved trade-review chips.
class TradeReviewOptionEmoji extends StatelessWidget {
  const TradeReviewOptionEmoji({super.key, required this.optionKey, this.size = 26});

  final String optionKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = tradeReviewOptionEmojiAssets[optionKey];
    if (asset == null) return const SizedBox.shrink();

    return RepaintBoundary(
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            asset,
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}
