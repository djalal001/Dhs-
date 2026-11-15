import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

import 'l10n/app_strings.dart';
import 'screens/days_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
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
          final tokens = TdTokens.forBrightness(
            dark ? Brightness.dark : Brightness.light,
          );
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Trader Desk',
            locale: locale,
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: buildAppTheme(Brightness.light),
            darkTheme: buildAppTheme(Brightness.dark),
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            scrollBehavior: const _TraderDeskScrollBehavior(),
            builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: dark
                    ? Brightness.light
                    : Brightness.dark,
                systemNavigationBarColor: tokens.bgBase,
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

class _TraderDeskScrollBehavior extends ScrollBehavior {
  const _TraderDeskScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
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
      SettingsScreen(),
    ];
    final nav = [
      'home',
      'trades',
      'days',
      'settings',
    ];
    final icons = [
      Icons.space_dashboard_outlined,
      Icons.menu_book_outlined,
      Icons.calendar_month_outlined,
      Icons.settings_outlined,
    ];
    final selected = [
      Icons.space_dashboard_rounded,
      Icons.menu_book_rounded,
      Icons.calendar_month_rounded,
      Icons.settings_rounded,
    ];
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          PositionedDirectional(
            top: -120,
            end: -120,
            width: 420,
            height: 420,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: AlignmentDirectional(0.9, -1.15),
                    radius: 1.1,
                    colors: [
                      TdTokens.of(context).accent.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.10
                            : 0.06,
                      ),
                      TdTokens.of(context).accent.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
    final tokens = TdTokens.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      height: 64 + safeBottom,
      padding: EdgeInsetsDirectional.only(bottom: safeBottom),
      decoration: BoxDecoration(
        gradient: tokens.cardGradient,
        border: Border(top: BorderSide(color: tokens.lineSubtle)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.45
                  : 0.12,
            ),
            offset: const Offset(0, -6),
            blurRadius: 18,
            spreadRadius: -6,
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            top: 0,
            start: 28,
            end: 28,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(
                      alpha: Theme.of(context).brightness == Brightness.dark
                          ? 0.14
                          : 0.65,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Row(
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
    final iconColor = selected ? tokens.accent : tokens.text3;
    final labelColor = selected ? tokens.text2 : tokens.text3;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: duration,
                curve: Curves.easeOutCubic,
                width: 42,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: tokens.accent.withValues(alpha: 0.24),
                            blurRadius: 12,
                            spreadRadius: -5,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: AnimatedScale(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    scale: selected ? 1.10 : 1,
                    child: Icon(
                      selected ? selectedIcon : icon,
                      size: 23,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: labelColor,
                      fontSize: 10.5,
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
