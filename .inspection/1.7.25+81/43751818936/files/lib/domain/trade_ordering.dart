import '../models/trade.dart';

/// Provides a stable chronological order for charts, drawdown calculations,
/// exports, and the journal list when trades share the same timestamp.
int compareTradesAscending(Trade first, Trade second) {
  final byTime = first.tradedAt.compareTo(second.tradedAt);
  return byTime != 0 ? byTime : first.id.compareTo(second.id);
}

int compareTradesDescending(Trade first, Trade second) =>
    compareTradesAscending(second, first);
