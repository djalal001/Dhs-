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
                builder: (_) => const SettingsScreen(),
              ),
            ),
            child: ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tokens.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tokens.lineSubtle, width: 0.8),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.settings_outlined, size: 19, color: tokens.text2),
              ),
              title: Text(tr(context, 'settings')),
              trailing: Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
                color: tokens.text3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
