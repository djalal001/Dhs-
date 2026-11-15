import 'package:flutter/material.dart';

import '../domain/trade_analytics.dart';
import '../l10n/app_strings.dart';
import '../models/trade.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/equity_curve.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final account =
        app.accounts
            .where((item) => item.id == app.selectedAccountId)
            .firstOrNull ??
        app.accounts.firstOrNull;
    final trades = account == null
        ? <Trade>[]
        : app.trades.where((trade) => trade.accountId == account.id).toList();
    final analytics = TradeAnalytics.calculate(
      trades,
      startingBalance: account?.startingBalance ?? 0,
    );
    final balance = (account?.startingBalance ?? 0) + analytics.netProfit;
    final currency = account?.currency ?? 'USD';
    final now = DateTime.now();
    final todayNet = trades
        .where(
          (trade) =>
              trade.tradedAt.year == now.year &&
              trade.tradedAt.month == now.month &&
              trade.tradedAt.day == now.day,
        )
        .fold<double>(0, (sum, trade) => sum + trade.result);
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        if (account == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: AppCard(
              child: EmptyState(
                title: tr(context, 'noAccounts'),
                detail: tr(context, 'addFirstAccount'),
              ),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
            child: AppCard(
              variant: AppCardVariant.hero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, 'currentBalance'),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: TdTokens.of(context).text2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      money(balance, currency),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: TdTokens.of(context).text1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${tr(context, 'startingBalance')}: ${money(account.startingBalance, currency)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: TdTokens.of(context).text3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  EquityCurve(
                    trades: trades,
                    currency: currency,
                    startingBalance: account.startingBalance,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                MetricCard(
                  label: tr(context, 'netProfit'),
                  value: money(analytics.netProfit, currency),
                  color: analytics.netProfit > 0
                      ? TdTokens.of(context).profit
                      : analytics.netProfit < 0
                      ? TdTokens.of(context).loss
                      : TdTokens.of(context).neutral,
                  icon: Icons.trending_up,
                ),
                MetricCard(
                  label: tr(context, 'winRate'),
                  value: '${analytics.winRatePercent.toStringAsFixed(1)}%',
                  icon: Icons.track_changes_outlined,
                ),
                MetricCard(
                  label: tr(context, 'tradeCount'),
                  value: '${analytics.tradeCount}',
                  icon: Icons.receipt_long_outlined,
                ),
                MetricCard(
                  label: tr(context, 'maxDrawdown'),
                  value:
                      '${money(analytics.maxDrawdownAmount, currency)} · ${analytics.maxDrawdownPercent.toStringAsFixed(2)}%',
                  color: analytics.maxDrawdownAmount > 0
                      ? TdTokens.of(context).loss
                      : null,
                  icon: Icons.south_east_rounded,
                ),
              ],
            ),
          ),
          if (account.profitTarget > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 0),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tr(context, 'profitTarget'),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          '${(analytics.netProfit / account.profitTarget * 100).clamp(0, 100).toStringAsFixed(1)}%',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (analytics.netProfit / account.profitTarget)
                          .clamp(0.0, 1.0)
                          .toDouble(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${money(analytics.netProfit, currency)} / ${money(account.profitTarget, currency)}',
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, 'summary'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _MetricRow(
                    label: tr(context, 'dailyResult'),
                    value: money(todayNet, currency),
                  ),
                  _MetricRow(
                    label: tr(context, 'wins'),
                    value: '${analytics.wins}',
                  ),
                  _MetricRow(
                    label: tr(context, 'losses'),
                    value: '${analytics.losses}',
                  ),
                  _MetricRow(
                    label: tr(context, 'breakeven'),
                    value: '${analytics.breakEven}',
                  ),
                  _MetricRow(
                    label: tr(context, 'averageWin'),
                    value: money(analytics.averageWin, currency),
                  ),
                  _MetricRow(
                    label: tr(context, 'averageLoss'),
                    value: money(analytics.averageLoss, currency),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (app.storageError != null)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Storage error: ${app.storageError}',
              style: TextStyle(color: TdTokens.of(context).loss),
            ),
          ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
