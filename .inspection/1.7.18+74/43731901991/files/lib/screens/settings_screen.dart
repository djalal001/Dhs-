import 'package:flutter/material.dart';

import '../data/trade_file_service.dart';
import '../domain/trade_csv_exporter.dart';
import 'accounts_screen.dart';
import '../l10n/app_strings.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _exportBackupFile(BuildContext context) async {
    try {
      final contents = await AppScope.of(context).createBackup();
      final saved = await TradeFileService.saveBackup(contents);
      if (saved == null || !context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr(context, 'backupFileSaved'))));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr(context, 'operationFailed')}: $error')),
        );
      }
    }
  }

  Future<void> _exportTradesCsv(BuildContext context) async {
    try {
      final app = AppScope.of(context);
      if (app.trades.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, 'noTradesToExport'))),
        );
        return;
      }
      final csv = TradeCsvExporter.generate(
        accounts: app.accounts,
        trades: app.trades,
        translate: (key) => tr(context, key),
      );
      final saved = await TradeFileService.saveCsv(
        csv,
        fileName: TradeFileService.csvFileName(),
      );
      if (saved == null || !context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr(context, 'csvExported'))));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr(context, 'operationFailed')}: $error')),
        );
      }
    }
  }

  Future<void> _exportCurrentAccountCsv(BuildContext context) async {
    final app = AppScope.of(context);
    final account = app.accounts
        .where((item) => item.id == app.selectedAccountId)
        .firstOrNull;
    final accountTrades = account == null
        ? []
        : app.trades.where((trade) => trade.accountId == account.id).toList();
    if (accountTrades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'noTradesToExport'))),
      );
      return;
    }
    try {
      final csv = TradeCsvExporter.generate(
        accounts: app.accounts,
        trades: accountTrades,
        translate: (key) => tr(context, key),
      );
      final saved = await TradeFileService.saveCsv(
        csv,
        fileName: TradeFileService.csvFileName(),
      );
      if (saved == null || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'csvExported'))),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr(context, 'operationFailed')}: $error')),
        );
      }
    }
  }

  Future<void> _restoreFromFile(BuildContext context) async {
    try {
      final selected = await TradeFileService.pickBackup();
      if (selected == null || !context.mounted) return;
      final app = AppScope.of(context);
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(tr(context, 'confirmRestore')),
          content: Text('${tr(context, 'restoreWarning')}\n\n${selected.name}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(tr(context, 'cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(tr(context, 'restore')),
            ),
          ],
        ),
      );
      if (accepted != true || !context.mounted) return;

      final progress = ValueNotifier<double>(0);
      var restoreDialogClosed = false;
      final restoreDialog = showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (context, value, _) => AlertDialog(
            title: Text(tr(context, 'restore')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  selected.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: selected.sizeBytes == null || selected.sizeBytes == 0
                      ? null
                      : value,
                ),
                if (selected.sizeBytes != null && selected.sizeBytes! > 0) ...[
                  const SizedBox(height: 8),
                  Text('${(value * 100).round()}%'),
                ],
              ],
            ),
          ),
        ),
      );
      try {
        await app.restoreBackupStream(
          selected.openRead(),
          onProgress: (bytesRead) {
            final total = selected.sizeBytes;
            if (total != null && total > 0) {
              progress.value = (bytesRead / total).clamp(0.0, 1.0).toDouble();
            }
          },
        );
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          restoreDialogClosed = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr(context, 'restoreSuccess'))),
          );
        }
      } finally {
        progress.dispose();
        if (context.mounted && !restoreDialogClosed) {
          Navigator.of(context, rootNavigator: true).maybePop();
          restoreDialogClosed = true;
        }
        if (restoreDialogClosed) await restoreDialog;
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr(context, 'backupInvalid')}: $error')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final tokens = TdTokens.of(context);
    return Scaffold(
      backgroundColor: tokens.bgBase,
      appBar: AppBar(title: Text(tr(context, 'settings'))),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: _SettingsIcon(
                      icon: app.isDark
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                    ),
                    title: Text(
                      tr(context, app.isDark ? 'darkMode' : 'lightMode'),
                    ),
                    onTap: () => app.setDark(!app.isDark),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: _SettingsIcon(icon: Icons.language_outlined),
                    title: Text(tr(context, 'language')),
                    trailing: DropdownButton<String>(
                      value: app.languageCode,
                      underline: const SizedBox.shrink(),
                      items: [
                        DropdownMenuItem(
                          value: 'ar',
                          child: Text(tr(context, 'arabic')),
                        ),
                        DropdownMenuItem(
                          value: 'en',
                          child: Text(tr(context, 'english')),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) app.setLanguage(value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: AppCard(
              padding: EdgeInsets.zero,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AccountsScreen(),
                ),
              ),
              child: ListTile(
                leading: const _SettingsIcon(
                  icon: Icons.account_balance_wallet_outlined,
                ),
                title: Text(tr(context, 'accounts')),
                trailing: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left
                      : Icons.chevron_right,
                  color: tokens.text3,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 18, 10, 8),
            child: Text(
              tr(context, 'backup'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const _SettingsIcon(icon: Icons.save_alt),
                    title: Text(tr(context, 'exportBackupFile')),
                    onTap: () => _exportBackupFile(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const _SettingsIcon(
                      icon: Icons.table_view_outlined,
                    ),
                    title: Text(tr(context, 'exportTradesCsv')),
                    onTap: () => _exportTradesCsv(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const _SettingsIcon(
                      icon: Icons.file_download_outlined,
                    ),
                    title: Text(tr(context, 'exportCurrentAccountCsv')),
                    onTap: () => _exportCurrentAccountCsv(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const _SettingsIcon(icon: Icons.folder_open),
                    title: Text(tr(context, 'restoreBackupFile')),
                    onTap: () => _restoreFromFile(context),
                  ),
                ],
              ),
            ),
          ),
          if (app.storageError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Text(
                app.storageError!,
                style: TextStyle(color: tokens.loss),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: tokens.surface3.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: tokens.lineSubtle.withValues(alpha: 0.68),
          width: 0.8,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 19, color: tokens.text2),
    );
  }
}
