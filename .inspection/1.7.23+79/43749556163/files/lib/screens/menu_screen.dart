import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'settings_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    final settingsTitle = tr(context, 'settings');
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        PageTitle(tr(context, 'menu')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: AppCard(
            padding: EdgeInsets.zero,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: Text(settingsTitle)),
                  body: const SettingsScreen(showPageTitle: false),
                ),
              ),
            ),
            child: ListTile(
              leading: const _MenuIcon(icon: Icons.settings_outlined),
              title: Text(settingsTitle),
              trailing: Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: tokens.text3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuIcon extends StatelessWidget {
  const _MenuIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: tokens.surface3.withValues(alpha: .78),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.lineSubtle.withValues(alpha: .68), width: .8),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 19, color: tokens.text2),
    );
  }
}
