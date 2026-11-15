import 'package:flutter_test/flutter_test.dart';
import 'package:trader_desk/models/trade.dart';

Trade _trade({StrategyAdherence? adherence}) => Trade(
  id: 't1',
  accountId: 'a1',
  market: 'NQ',
  reason: 'SBR',
  result: -4.55,
  riskPercent: 1,
  side: TradeSide.sell,
  confirmation: '',
  sequence: '',
  mood: 'moodCalm',
  tradedAt: DateTime(2026, 11, 4, 15, 42),
  notes: 'note',
  strategyAdherence: adherence,
);

void main() {
  test('old trades without the field load with no answer', () {
    final json = _trade().toJson()..remove('strategyAdherence');
    expect(Trade.fromJson(json).strategyAdherence, isNull);
  });

  test('strategy adherence survives a JSON round trip', () {
    for (final value in StrategyAdherence.values) {
      final restored = Trade.fromJson(_trade(adherence: value).toJson());
      expect(restored.strategyAdherence, value);
    }
  });

  test('unknown stored value is ignored instead of crashing', () {
    final json = _trade().toJson()..['strategyAdherence'] = 'something-else';
    expect(Trade.fromJson(json).strategyAdherence, isNull);
  });

  test('withStrategyAdherence keeps every other field', () {
    final original = _trade();
    final updated = original.withStrategyAdherence(
      StrategyAdherence.notFollowed,
    );
    expect(updated.strategyAdherence, StrategyAdherence.notFollowed);
    expect(updated.id, original.id);
    expect(updated.result, original.result);
    expect(updated.notes, original.notes);
    expect(updated.tradedAt, original.tradedAt);
  });
}
