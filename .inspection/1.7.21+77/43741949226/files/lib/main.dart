import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

import 'l10n/app_strings.dart';
import 'screens/days_screen.dart';
import 'screens/home_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/trades_screen.dart';
import 'state/app_controller.dart';
import 'state/app_scope.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final controller = await AppController.create();
  runApp(TraderDeskApp(controller: controller));
}

class TraderDeskApp extends StatefulWidget {
  const TraderDeskApp({super.key, required this.controller});
  final AppController controller;

  @override
  State<TraderDeskApp> createState() => _TraderDeskAppState();
}

class _TraderDeskAppState extends State<TraderDeskApp> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return AppScope(
      controller: controller,
      child: ValueListenableBuilder<int>(
        valueListenable: controller.appearanceRevision,
        builder: (context, _, _) {
          final locale = Locale(controller.languageCode);
          final dark = controller.isDark;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Trader Desk',
            locale: locale,
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: buildAppTheme(Brightness.light),
            darkTheme: buildAppTheme(Brightness.dark),
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: dark
                    ? Brightness.light
                    : Brightness.dark,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarIconBrightness: dark
                    ? Brightness.light
                    : Brightness.dark,
                systemNavigationBarDividerColor: Colors.transparent,
                systemNavigationBarContrastEnforced: false,
              ),
              child: Directionality(
                textDirection: controller.languageCode == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
            home: const AppShell(),
          );
        },
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      HomeScreen(),
      TradesScreen(),
      DaysScreen(),
      MenuScreen(),
    ];
    final nav = [
      'home',
      'trades',
      'days',
      'menu',
    ];
    final icons = [
      Icons.space_dashboard_outlined,
      Icons.menu_book_outlined,
      Icons.calendar_month_outlined,
      Icons.menu_rounded,
    ];
    final selected = [
      Icons.space_dashboard_rounded,
      Icons.menu_book_rounded,
      Icons.calendar_month_rounded,
      Icons.menu_open_rounded,
    ];
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: IndexedStack(index: _index, children: pages),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _TdNavBar(
        selectedIndex: _index,
        keys: nav,
        icons: icons,
        selectedIcons: selected,
        onSelected: (value) => setState(() => _index = value),
      ),
    );
  }
}

class _TdNavBar extends StatelessWidget {
  const _TdNavBar({
    required this.selectedIndex,
    required this.keys,
    required this.icons,
    required this.selectedIcons,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<String> keys;
  final List<IconData> icons;
  final List<IconData> selectedIcons;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      key: const ValueKey('td-bottom-navigation'),
      // Intentionally transparent: destinations sit directly on the page
      // background instead of inside a separately colored navigation strip.
      height: 52 + safeBottom,
      padding: EdgeInsetsDirectional.only(bottom: safeBottom),
      child: Row(
        children: [
          for (var index = 0; index < keys.length; index++)
            Expanded(
              child: _TdNavItem(
                label: tr(context, keys[index]),
                icon: icons[index],
                selectedIcon: selectedIcons[index],
                selected: selectedIndex == index,
                duration: reduceMotion
                    ? const Duration(milliseconds: 120)
                    : const Duration(milliseconds: 220),
                onTap: () => onSelected(index),
              ),
            ),
        ],
      ),
    );
  }
}

class _TdNavItem extends StatelessWidget {
  const _TdNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.duration,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    final iconColor = selected ? Colors.white : tokens.text3;
    final labelColor = selected ? tokens.text1 : tokens.text3;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 44,
                height: 24,
                child: Center(
                  child: AnimatedScale(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    scale: selected ? 1.04 : 1,
                    child: Icon(
                      selected ? selectedIcon : icon,
                      size: 19,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: labelColor,
                      fontSize: 9.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
