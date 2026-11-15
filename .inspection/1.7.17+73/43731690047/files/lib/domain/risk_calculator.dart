class RiskCalculation {
  const RiskCalculation({
    required this.riskCash,
    required this.stopDistance,
    required this.units,
    required this.targetCash,
    required this.rewardToRisk,
  });

  final double riskCash;
  final double stopDistance;
  final double units;
  final double? targetCash;
  final double? rewardToRisk;
}

class RiskCalculator {
  /// Generic linear-instrument estimate. Units = cash risk / price distance.
  /// It does not convert pip values, lot sizes, currencies, fees, or slippage.
  static RiskCalculation calculate({
    required double accountBalance,
    required double riskPercent,
    required double entryPrice,
    required double stopLossPrice,
    double? takeProfitPrice,
  }) {
    if (!accountBalance.isFinite ||
        !riskPercent.isFinite ||
        !entryPrice.isFinite ||
        !stopLossPrice.isFinite ||
        (takeProfitPrice != null && !takeProfitPrice.isFinite)) {
      throw ArgumentError('Inputs must be finite numbers.');
    }
    if (accountBalance <= 0)
      throw ArgumentError('accountBalance must be positive');
    if (riskPercent <= 0 || riskPercent > 100)
      throw ArgumentError('riskPercent must be between 0 and 100');
    if (entryPrice <= 0 || stopLossPrice <= 0)
      throw ArgumentError('prices must be positive');
    final distance = (entryPrice - stopLossPrice).abs();
    if (distance == 0) throw ArgumentError('entry and stop-loss must differ');
    if (takeProfitPrice != null && takeProfitPrice <= 0)
      throw ArgumentError('take-profit must be positive');

    final riskCash = accountBalance * riskPercent / 100;
    final units = riskCash / distance;
    final rewardDistance = takeProfitPrice == null
        ? null
        : (takeProfitPrice - entryPrice).abs();
    final targetCash = rewardDistance == null ? null : rewardDistance * units;
    final rewardToRisk = rewardDistance == null
        ? null
        : rewardDistance / distance;
    if (!riskCash.isFinite ||
        !units.isFinite ||
        (targetCash != null && !targetCash.isFinite) ||
        (rewardToRisk != null && !rewardToRisk.isFinite)) {
      throw ArgumentError('The calculated values exceed the supported range.');
    }
    return RiskCalculation(
      riskCash: riskCash,
      stopDistance: distance,
      units: units,
      targetCash: targetCash,
      rewardToRisk: rewardToRisk,
    );
  }
}
