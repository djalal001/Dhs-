import 'package:flutter_test/flutter_test.dart';
import 'package:trader_desk/domain/trade_csv_exporter.dart';
import 'package:trader_desk/models/trade.dart';
import 'package:trader_desk/models/trading_account.dart';

void main() {
  test('exports complete trade rows as quoted UTF-8 CSV cells', () {
    final account = TradingAccount(
      id: 'a1',
      name: 'حساب "رئيسي"',
      type: AccountType.demo,
      startingBalance: 10000,
      currency: 'USD',
      createdAt: DateTime(2025, 1, 1),
    );
    final trade = Trade(
      id: 't1',
      accountId: account.id,
      market: 'EUR,USD',
      reason: 'breakout\nconfirmation',
      result: -25.5,
      riskPercent: 1.25,
      side: TradeSide.sell,
      confirmation: 'confirmTechnical',
      sequence: 'B',
      mood: 'moodCalm',
      tradedAt: DateTime.utc(2025, 2, 3, 4, 5),
      entryTimeframe: '30MIN',
      entrySetups: const [
        TradeEntrySetup(reason: 'SBR', timeframe: '15MIN'),
        TradeEntrySetup(reason: 'Trend Line SELL', timeframe: '30MIN'),
      ],
      confirmationSetups: const [
        TradeConfirmationSetup(
          type: 'confirmBearishEngulfing',
          timeframe: '5MIN',
        ),
        TradeConfirmationSetup(
          type: 'confirmBullishEngulfing',
          timeframe: '30MIN',
        ),
      ],
      reverseSignalSetups: const [
        TradeEntryConditionSetup(
          optionKey: 'negativeCloseAgainstDirection',
          timeframe: '15MIN',
        ),
      ],
      bounceZoneSetups: const [
        TradeEntryConditionSetup(
          optionKey: 'bounceFromTrendlineAndSupplyZone',
          timeframe: '1H',
          secondaryTimeframe: '5MIN',
        ),
      ],
      executionJournal: const [
        TradeExecutionJournalEntry(status: TradeExecutionStatus.followedPlan),
        TradeExecutionJournalEntry(status: TradeExecutionStatus.enteredEarly),
      ],
      executionReviewKeys: const ['enteredEarly', 'fullPlanCompliance'],
      noEntryReasons: const ['fearRepeatLossAfterLoss'],
      notes: '=HYPERLINK("https://example.com")',
    );

    final csv = TradeCsvExporter.generate(
      accounts: [account],
      trades: [trade],
      translate: (key) => switch (key) {
        'demoAccount' => 'تجريبي',
        'sell' => 'بيع',
        'confirmTechnical' => 'تأكيد فني',
        'confirmBearishEngulfing' => 'Bearish engulfing',
        'confirmBullishEngulfing' => 'Bullish Engulfing',
        'negativeCloseAgainstDirection' => 'Negative close against direction',
        'bounceFromTrendlineAndSupplyZone' => 'Bounce from Trendline and Supply Zone',
        'moodCalm' => 'هادئ',
        'journalStatus_followedPlan' => 'Followed the plan',
        'journalStatus_enteredEarly' => 'Entered early',
        'enteredEarly' => 'Entered early.',
        'fullPlanCompliance' => 'Followed the complete plan without deviation.',
        'fearRepeatLossAfterLoss' => 'Fear of repeating a loss after a previous losing trade.',
        _ => key,
      },
    );

    expect(csv.startsWith('\uFEFF'), isTrue);
    expect(csv, contains('"trade_id","account_name","account_type"'));
    expect(csv, contains('"حساب ""رئيسي"""'));
    expect(csv, contains('"EUR,USD"'));
    expect(csv, contains('"breakout\nconfirmation"'));
    expect(
      csv,
      contains(
        '"entry_reason","entry_timeframe","entry_setups","confirmation","confirmation_setups"',
      ),
    );
    expect(csv, contains('"30MIN"'));
    expect(csv, contains('"SBR 15MIN، Trend Line SELL 30MIN"'));
    expect(csv, contains('"Negative close against direction 15MIN"'));
    expect(csv, contains('"Bounce from Trendline and Supply Zone 1H / Supply Zone 5MIN"'));
    expect(
      csv,
      contains('"Bearish engulfing 5MIN، Bullish Engulfing 30MIN"'),
    );
    expect(csv, contains('"Followed the plan، Entered early"'));
    expect(csv, contains('"Entered early.، Followed the complete plan without deviation."'));
    expect(csv, contains('"Fear of repeating a loss after a previous losing trade."'));
    expect(csv, contains('"-25.5"'));
    expect(csv, contains("\"'=HYPERLINK"));
  });
}
