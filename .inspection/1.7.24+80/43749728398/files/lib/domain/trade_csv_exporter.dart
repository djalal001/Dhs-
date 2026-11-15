import '../models/trade.dart';
import '../models/trading_account.dart';
import 'trade_ordering.dart';

class TradeCsvExporter {
  const TradeCsvExporter._();

  static String generate({
    required List<TradingAccount> accounts,
    required List<Trade> trades,
    required String Function(String key) translate,
  }) {
    final byId = {for (final account in accounts) account.id: account};
    final sorted = [...trades]..sort(compareTradesAscending);
    final rows = <List<Object?>>[
      const [
        'trade_id',
        'account_name',
        'account_type',
        'currency',
        'trade_at',
        'market',
        'direction',
        'result',
        'risk_percent',
        'expected_loss',
        'entry_reason',
        'entry_timeframe',
        'entry_setups',
        'confirmation',
        'confirmation_setups',
        'reverse_signals',
        'bounce_zone_conditions',
        'sequence',
        'execution_journal',
        'execution_review',
        'no_entry_reasons',
        'mood',
        'notes',
        'strategy_adherence',
      ],
      for (final trade in sorted)
        [
          _TextCell(trade.id),
          _TextCell(byId[trade.accountId]?.name ?? ''),
          _TextCell(
            byId[trade.accountId] == null
                ? ''
                : translate(
                    byId[trade.accountId]!.type == AccountType.demo
                        ? 'demoAccount'
                        : 'realAccount',
                  ),
          ),
          _TextCell(byId[trade.accountId]?.currency ?? ''),
          _TextCell(trade.tradedAt.toIso8601String()),
          _TextCell(trade.market),
          _TextCell(translate(trade.side == TradeSide.buy ? 'buy' : 'sell')),
          trade.result,
          trade.riskPercent,
          trade.expectedLoss,
          _TextCell(trade.reason),
          _TextCell(trade.entryTimeframe ?? ''),
          _TextCell(trade.entrySetupSummary),
          _TextCell(
            trade.confirmation.isEmpty ? '' : translate(trade.confirmation),
          ),
          _TextCell(
            trade.effectiveConfirmationSetups
                .map((setup) {
                  final type = translate(setup.type);
                  return setup.timeframe.isEmpty
                      ? type
                      : '$type ${setup.timeframe}';
                })
                .join('، '),
          ),
          _TextCell(
            trade.reverseSignalSetups
                .map((setup) => '${translate(setup.optionKey)} ${setup.timeframe}')
                .join('، '),
          ),
          _TextCell(
            trade.bounceZoneSetups
                .map((setup) => setup.secondaryTimeframe == null
                    ? '${translate(setup.optionKey)} ${setup.timeframe}'
                    : '${translate(setup.optionKey)} ${setup.timeframe} / Supply Zone ${setup.secondaryTimeframe}')
                .join('، '),
          ),
          _TextCell(trade.sequence),
          _TextCell(
            trade.executionJournal
                .map((entry) => translate('journalStatus_${entry.status.name}'))
                .join('، '),
          ),
          _TextCell(trade.executionReviewKeys.map(translate).join('، ')),
          _TextCell(trade.noEntryReasons.map(translate).join('، ')),
          _TextCell(trade.mood.isEmpty ? '' : translate(trade.mood)),
          _TextCell(trade.notes),
          _TextCell(
            trade.strategyAdherence == null
                ? ''
                : translate('strategy_${trade.strategyAdherence!.name}'),
          ),
        ],
    ];
    return '\uFEFF${rows.map((row) => row.map(_csvCell).join(',')).join('\r\n')}\r\n';
  }

  static String _csvCell(Object? value) {
    var text = value is _TextCell ? value.value : value?.toString() ?? '';
    if (value is _TextCell && RegExp(r'^[\t\r\n ]*[=+\-@]').hasMatch(text)) {
      text = "'$text";
    }
    return '"${text.replaceAll('"', '""')}"';
  }
}

class _TextCell {
  const _TextCell(this.value);
  final String value;
}
