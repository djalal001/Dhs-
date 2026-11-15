import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/trading_account.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hasAccounts = AppScope.of(context).accounts.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'accounts'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: const [AccountsManagementSection()],
        ),
      ),
      floatingActionButton: hasAccounts
          ? FloatingActionButton(
              onPressed: () => _editAccount(context),
              tooltip: tr(context, 'startAccount'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

Future<void> _editAccount(
  BuildContext context, {
  TradingAccount? account,
}) async {
  final app = AppScope.of(context);
  final edited = await showDialog<TradingAccount>(
    context: context,
    builder: (_) => _AccountDialog(account: account),
  );
  if (edited != null) {
    if (account == null) {
      await app.addAccount(edited);
    } else {
      await app.updateAccount(edited);
    }
  }
}

class AccountsManagementSection extends StatelessWidget {
  const AccountsManagementSection({super.key});

  Future<void> _delete(BuildContext context, TradingAccount account) async {
    final app = AppScope.of(context);
    if (!app.canDeleteAccount(account.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'deleteAccountWarning'))),
      );
      return;
    }
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'deleteAccount')),
        content: Text('${tr(context, 'deleteAccount')} · ${account.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(context, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr(context, 'delete')),
          ),
        ],
      ),
    );
    if (yes == true) await app.deleteAccount(account.id);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (app.accounts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: EmptyState(
              title: tr(context, 'noAccounts'),
              detail: tr(context, 'addFirstAccount'),
              action: FilledButton.icon(
                onPressed: () => _editAccount(context),
                icon: const Icon(Icons.add),
                label: Text(tr(context, 'startAccount')),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                for (final account in app.accounts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AccountCard(
                      account: account,
                      onEdit: () => _editAccount(context, account: account),
                      onDelete: () => _delete(context, account),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.onEdit,
    required this.onDelete,
  });
  final TradingAccount account;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final tokens = TdTokens.of(context);
    final accountColor = account.type == AccountType.real
        ? tokens.warn
        : tokens.accent;
    final net = app.trades
        .where((trade) => trade.accountId == account.id)
        .fold<double>(0, (sum, trade) => sum + trade.result);
    return AppCard(
      onTap: () => app.selectAccount(account.id),
      variant: AppCardVariant.tint,
      tintColor: accountColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  account.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _Pill(
                text: tr(
                  context,
                  account.type == AccountType.demo
                      ? 'demoAccount'
                      : 'realAccount',
                ),
                isReal: account.type == AccountType.real,
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(tr(context, 'edit')),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(tr(context, 'delete')),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${tr(context, 'startingBalance')}: ${money(account.startingBalance, account.currency)}',
          ),
          const SizedBox(height: 4),
          Text(
            '${tr(context, 'currentBalance')}: ${money(account.startingBalance + net, account.currency)}',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: .68),
            ),
          ),
          if (account.profitTarget > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${tr(context, 'profitTarget')}: ${money(account.profitTarget, account.currency)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 6),
          Text(
            '${app.trades.where((trade) => trade.accountId == account.id).length} ${tr(context, 'accountTrades')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.isReal});
  final String text;
  final bool isReal;
  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    final color = isReal ? tokens.warn : tokens.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _AccountDialog extends StatefulWidget {
  const _AccountDialog({this.account});
  final TradingAccount? account;
  @override
  State<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<_AccountDialog> {
  late final TextEditingController _name;
  late final TextEditingController _balance;
  late final TextEditingController _currency;
  late final TextEditingController _target;
  late AccountType _type;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.account?.name ?? '');
    _balance = TextEditingController(
      text: widget.account?.startingBalance.toString() ?? '',
    );
    _currency = TextEditingController(text: widget.account?.currency ?? 'USD');
    _target = TextEditingController(
      text: widget.account?.profitTarget.toString() ?? '0',
    );
    _type = widget.account?.type ?? AccountType.demo;
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    _currency.dispose();
    _target.dispose();
    super.dispose();
  }

  void _save() {
    final value = double.tryParse(_balance.text.trim().replaceAll(',', '.'));
    final target = double.tryParse(_target.text.trim().replaceAll(',', '.'));
    if (_name.text.trim().isEmpty ||
        value == null ||
        !value.isFinite ||
        value < 0 ||
        target == null ||
        !target.isFinite ||
        target < 0 ||
        _currency.text.trim().isEmpty)
      return;
    Navigator.pop(
      context,
      TradingAccount(
        id:
            widget.account?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: _name.text.trim(),
        type: _type,
        startingBalance: value,
        profitTarget: target,
        currency: _currency.text.trim().toUpperCase(),
        createdAt: widget.account?.createdAt ?? DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(tr(context, widget.account == null ? 'startAccount' : 'edit')),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: tr(context, 'accountName')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _balance,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: tr(context, 'startingBalance'),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _currency,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: tr(context, 'currency')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _target,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: tr(context, 'profitTarget'),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<AccountType>(
            initialValue: _type,
            decoration: InputDecoration(labelText: tr(context, 'accountType')),
            items: [
              DropdownMenuItem(
                value: AccountType.demo,
                child: Text(tr(context, 'demoAccount')),
              ),
              DropdownMenuItem(
                value: AccountType.real,
                child: Text(tr(context, 'realAccount')),
              ),
            ],
            onChanged: (value) =>
                setState(() => _type = value ?? AccountType.demo),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(tr(context, 'cancel')),
      ),
      FilledButton(onPressed: _save, child: Text(tr(context, 'save'))),
    ],
  );
}
