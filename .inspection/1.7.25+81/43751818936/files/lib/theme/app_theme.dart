import 'package:flutter/material.dart';

// Compatibility colors for the few semantic constants used outside widgets.
// Widget colors should come from TdTokens so light mode remains accessible.
const Color accentBlue = Color(0xFF4C96FF);
const Color positiveTeal = Color(0xFF34D399);
const Color negativeRed = Color(0xFFFF6B7A);

@immutable
class TdTokens extends ThemeExtension<TdTokens> {
  const TdTokens({
    required this.bgBase,
    required this.surface1,
    required this.surface2,
    required this.surface3,
    required this.inset,
    required this.lineSubtle,
    required this.lineStrong,
    required this.text1,
    required this.text2,
    required this.text3,
    required this.accent,
    required this.accentBtnTop,
    required this.accentBtnBottom,
    required this.profit,
    required this.profitStrong,
    required this.profitDeep,
    required this.loss,
    required this.lossStrong,
    required this.lossDeep,
    required this.warn,
    required this.warnStrong,
    required this.neutral,
    required this.dangerBtnTop,
    required this.dangerBtnBottom,
    required this.cardTop,
    required this.cardBottom,
    required this.heroStart,
    required this.scrim,
    required this.cardGradient,
    required this.heroGradient,
    required this.primaryGradient,
    required this.dangerGradient,
    required this.cardShadows,
    required this.raisedShadows,
    required this.overlayShadows,
    required this.s1,
    required this.s2,
    required this.s3,
    required this.s4,
    required this.s5,
    required this.s6,
    required this.s7,
    required this.s8,
    required this.fast,
    required this.base,
    required this.slow,
    required this.page,
    required this.count,
    required this.instant,
    required this.chart,
    required this.standard,
    required this.emphasized,
    required this.accel,
    required this.spring,
    required this.linear,
  });

  final Color bgBase, surface1, surface2, surface3, inset;
  final Color lineSubtle, lineStrong, text1, text2, text3;
  final Color accent, accentBtnTop, accentBtnBottom;
  final Color profit, profitStrong, profitDeep;
  final Color loss, lossStrong, lossDeep;
  final Color warn, warnStrong, neutral;
  final Color dangerBtnTop, dangerBtnBottom, cardTop, cardBottom, heroStart;
  final Color scrim;
  final LinearGradient cardGradient,
      heroGradient,
      primaryGradient,
      dangerGradient;
  final List<BoxShadow> cardShadows, raisedShadows, overlayShadows;
  final double s1, s2, s3, s4, s5, s6, s7, s8;
  final Duration instant, fast, base, slow, page, count, chart;
  final Curve standard, emphasized, accel, spring, linear;

  static TdTokens of(BuildContext context) =>
      Theme.of(context).extension<TdTokens>()!;

  factory TdTokens.forBrightness(Brightness brightness) => _tokens(brightness);

  @override
  TdTokens copyWith({
    Color? bgBase,
    Color? surface1,
    Color? surface2,
    Color? surface3,
    Color? inset,
    Color? lineSubtle,
    Color? lineStrong,
    Color? text1,
    Color? text2,
    Color? text3,
    Color? accent,
    Color? accentBtnTop,
    Color? accentBtnBottom,
    Color? profit,
    Color? profitStrong,
    Color? profitDeep,
    Color? loss,
    Color? lossStrong,
    Color? lossDeep,
    Color? warn,
    Color? warnStrong,
    Color? neutral,
    Color? dangerBtnTop,
    Color? dangerBtnBottom,
    Color? cardTop,
    Color? cardBottom,
    Color? heroStart,
    Color? scrim,
    LinearGradient? cardGradient,
    LinearGradient? heroGradient,
    LinearGradient? primaryGradient,
    LinearGradient? dangerGradient,
    List<BoxShadow>? cardShadows,
    List<BoxShadow>? raisedShadows,
    List<BoxShadow>? overlayShadows,
  }) => TdTokens(
    bgBase: bgBase ?? this.bgBase,
    surface1: surface1 ?? this.surface1,
    surface2: surface2 ?? this.surface2,
    surface3: surface3 ?? this.surface3,
    inset: inset ?? this.inset,
    lineSubtle: lineSubtle ?? this.lineSubtle,
    lineStrong: lineStrong ?? this.lineStrong,
    text1: text1 ?? this.text1,
    text2: text2 ?? this.text2,
    text3: text3 ?? this.text3,
    accent: accent ?? this.accent,
    accentBtnTop: accentBtnTop ?? this.accentBtnTop,
    accentBtnBottom: accentBtnBottom ?? this.accentBtnBottom,
    profit: profit ?? this.profit,
    profitStrong: profitStrong ?? this.profitStrong,
    profitDeep: profitDeep ?? this.profitDeep,
    loss: loss ?? this.loss,
    lossStrong: lossStrong ?? this.lossStrong,
    lossDeep: lossDeep ?? this.lossDeep,
    warn: warn ?? this.warn,
    warnStrong: warnStrong ?? this.warnStrong,
    neutral: neutral ?? this.neutral,
    dangerBtnTop: dangerBtnTop ?? this.dangerBtnTop,
    dangerBtnBottom: dangerBtnBottom ?? this.dangerBtnBottom,
    cardTop: cardTop ?? this.cardTop,
    cardBottom: cardBottom ?? this.cardBottom,
    heroStart: heroStart ?? this.heroStart,
    scrim: scrim ?? this.scrim,
    cardGradient: cardGradient ?? this.cardGradient,
    heroGradient: heroGradient ?? this.heroGradient,
    primaryGradient: primaryGradient ?? this.primaryGradient,
    dangerGradient: dangerGradient ?? this.dangerGradient,
    cardShadows: cardShadows ?? this.cardShadows,
    raisedShadows: raisedShadows ?? this.raisedShadows,
    overlayShadows: overlayShadows ?? this.overlayShadows,
    s1: s1,
    s2: s2,
    s3: s3,
    s4: s4,
    s5: s5,
    s6: s6,
    s7: s7,
    s8: s8,
    fast: fast,
    base: base,
    slow: slow,
    page: page,
    count: count,
    instant: instant,
    chart: chart,
    standard: standard,
    emphasized: emphasized,
    accel: accel,
    spring: spring,
    linear: linear,
  );

  @override
  TdTokens lerp(ThemeExtension<TdTokens>? other, double t) => this;
}

TdTokens _tokens(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  // Dark palette: a restrained graphite ramp with small, deliberate steps.
  // The page canvas, cards, wells and inset controls belong to one neutral
  // family so no layer reads as a detached grey slab against pure black.
  final bg = dark ? const Color(0xFF0B0D10) : const Color(0xFFF1F4F9);
  final surface1 = dark ? const Color(0xFF101418) : const Color(0xFFFFFFFF);
  final surface2 = dark ? const Color(0xFF151A20) : const Color(0xFFF6F8FC);
  final surface3 = dark ? const Color(0xFF1B2128) : const Color(0xFFE9EEF6);
  final inset = dark ? const Color(0xFF0D1115) : const Color(0xFFEDF1F7);
  final lineSubtle = dark ? const Color(0xFF1A2026) : const Color(0xFFF0F2F5);
  final lineStrong = dark ? const Color(0xFF252D35) : const Color(0xFFE5E9EF);
  final text1 = dark ? const Color(0xFFF0F2F5) : const Color(0xFF121826);
  final text2 = dark ? const Color(0xFFA8B0BA) : const Color(0xFF46536B);
  final text3 = dark ? const Color(0xFF78828E) : const Color(0xFF5D6A80);
  final accent = dark ? const Color(0xFF7CA4D4) : const Color(0xFF1F5FE0);
  final profit = dark ? const Color(0xFF34D399) : const Color(0xFF087F58);
  final profitStrong = dark ? const Color(0xFF34D399) : const Color(0xFF066B4A);
  final profitDeep = dark ? const Color(0xFF1FB67F) : const Color(0xFF12A97A);
  final loss = dark ? const Color(0xFFFF6B7A) : const Color(0xFFD6243D);
  final lossStrong = dark ? const Color(0xFFFF6B7A) : const Color(0xFFB81D33);
  final lossDeep = dark ? const Color(0xFFEF4B5E) : const Color(0xFFE5484D);
  final warn = dark ? const Color(0xFFF5B84B) : const Color(0xFF8F5E00);
  final warnStrong = dark ? const Color(0xFFF5B84B) : const Color(0xFF7A5000);
  final cardTop = dark ? const Color(0xFF12171C) : const Color(0xFFFFFFFF);
  final cardBottom = dark ? const Color(0xFF0F1317) : const Color(0xFFF8FAFD);
  final accentTop = dark ? const Color(0xFF527BA9) : const Color(0xFF2F6FEF);
  final accentBottom = dark ? const Color(0xFF3B628F) : const Color(0xFF2158D6);
  final dangerTop = const Color(0xFFD63B45);
  final dangerBottom = const Color(0xFFC9303B);
  final shadows = dark
      ? <BoxShadow>[
          const BoxShadow(
            color: Color(0x66000000),
            offset: Offset(0, 8),
            blurRadius: 18,
            spreadRadius: -6,
          ),
          const BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
        ]
      : <BoxShadow>[
          const BoxShadow(
            color: Color(0x141B2B4B),
            offset: Offset(0, 8),
            blurRadius: 20,
            spreadRadius: -6,
          ),
          const BoxShadow(
            color: Color(0x0F1B2B4B),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
        ];
  return TdTokens(
    bgBase: bg,
    surface1: surface1,
    surface2: surface2,
    surface3: surface3,
    inset: inset,
    lineSubtle: lineSubtle,
    lineStrong: lineStrong,
    text1: text1,
    text2: text2,
    text3: text3,
    accent: accent,
    accentBtnTop: accentTop,
    accentBtnBottom: accentBottom,
    profit: profit,
    profitStrong: profitStrong,
    profitDeep: profitDeep,
    loss: loss,
    lossStrong: lossStrong,
    lossDeep: lossDeep,
    warn: warn,
    warnStrong: warnStrong,
    neutral: text2,
    dangerBtnTop: dangerTop,
    dangerBtnBottom: dangerBottom,
    cardTop: cardTop,
    cardBottom: cardBottom,
    heroStart: dark ? const Color(0xFF171D23) : const Color(0xFFEAF1FF),
    scrim: dark ? const Color(0x99000000) : const Color(0x730B0F16),
    cardGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [cardTop, cardBottom],
    ),
    heroGradient: LinearGradient(
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
      colors: [
        dark ? const Color(0xFF171D23) : const Color(0xFFEAF1FF),
        surface1,
      ],
    ),
    primaryGradient: LinearGradient(colors: [accentTop, accentBottom]),
    dangerGradient: LinearGradient(colors: [dangerTop, dangerBottom]),
    cardShadows: shadows,
    raisedShadows: dark
        ? const [
            BoxShadow(
              color: Color(0x73000000),
              offset: Offset(0, 6),
              blurRadius: 14,
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Color(0x40000000),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ]
        : const [
            BoxShadow(
              color: Color(0x101B2B4B),
              offset: Offset(0, 6),
              blurRadius: 14,
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Color(0x0C1B2B4B),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
    overlayShadows: dark
        ? const [
            BoxShadow(
              color: Color(0x99000000),
              offset: Offset(0, 20),
              blurRadius: 40,
              spreadRadius: -10,
            ),
            BoxShadow(
              color: Color(0x55000000),
              offset: Offset(0, 4),
              blurRadius: 10,
            ),
          ]
        : const [
            BoxShadow(
              color: Color(0x301B2B4B),
              offset: Offset(0, 20),
              blurRadius: 40,
              spreadRadius: -10,
            ),
            BoxShadow(
              color: Color(0x201B2B4B),
              offset: Offset(0, 4),
              blurRadius: 10,
            ),
          ],
    s1: 4,
    s2: 8,
    s3: 12,
    s4: 16,
    s5: 20,
    s6: 24,
    s7: 32,
    s8: 40,
    fast: const Duration(milliseconds: 140),
    base: const Duration(milliseconds: 220),
    slow: const Duration(milliseconds: 320),
    page: const Duration(milliseconds: 360),
    count: const Duration(milliseconds: 400),
    instant: const Duration(milliseconds: 90),
    chart: const Duration(milliseconds: 450),
    standard: Curves.easeOutCubic,
    emphasized: const Cubic(0.2, 0, 0, 1),
    accel: const Cubic(0.3, 0, 0.8, 0.15),
    spring: const Cubic(0.34, 1.4, 0.64, 1),
    linear: Curves.linear,
  );
}

class _TdPageTransitionsBuilder extends PageTransitionsBuilder {
  const _TdPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.isFirst) return child;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final curve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final offset = Offset(rtl ? -0.055 : 0.055, 0);
    return FadeTransition(
      opacity: reduce
          ? Tween<double>(begin: 0.65, end: 1).animate(curve)
          : curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: reduce ? Offset.zero : offset,
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }
}

ThemeData buildAppTheme(Brightness brightness) {
  final tokens = _tokens(brightness);
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: tokens.accent,
        brightness: brightness,
      ).copyWith(
        primary: tokens.accent,
        onPrimary: Colors.white,
        secondary: tokens.profit,
        error: tokens.loss,
        surface: tokens.surface1,
        onSurface: tokens.text1,
        outlineVariant: tokens.lineSubtle,
        surfaceContainerLow: tokens.surface2,
        surfaceContainerHighest: tokens.surface3,
        onSurfaceVariant: tokens.text2,
      );
  final textTheme =
      const TextTheme(
        displayLarge: TextStyle(
          fontSize: 34,
          height: 1.15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        displayMedium: TextStyle(
          fontSize: 26,
          height: 1.2,
          fontWeight: FontWeight.w700,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        headlineSmall: TextStyle(
          fontSize: 26,
          height: 1.3,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          height: 1.35,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          height: 1.45,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          fontSize: 15,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          height: 1.55,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.55,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.45,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          fontSize: 13,
          height: 1.3,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: TextStyle(
          fontSize: 11.5,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
      ).apply(
        fontFamily: 'IBMPlexSansArabic',
        bodyColor: tokens.text1,
        displayColor: tokens.text1,
      );

  OutlineInputBorder inputBorder(Color color, [double width = 0.78]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'IBMPlexSansArabic',
    colorScheme: scheme,
    extensions: [tokens],
    textTheme: textTheme,
    scaffoldBackgroundColor: tokens.bgBase,
    canvasColor: tokens.surface2,
    dividerColor: tokens.lineSubtle,
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: tokens.accent.withValues(alpha: 0.08),
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.bgBase,
      foregroundColor: tokens.text1,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
      iconTheme: IconThemeData(color: tokens.text2, size: 22),
    ),
    cardTheme: CardThemeData(
      color: tokens.surface1,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
      minVerticalPadding: 12,
      iconColor: tokens.text3,
      titleTextStyle: textTheme.bodyLarge?.copyWith(
        color: tokens.text1,
        fontWeight: FontWeight.w600,
      ),
      subtitleTextStyle: textTheme.labelMedium?.copyWith(color: tokens.text2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.inset,
      contentPadding: const EdgeInsetsDirectional.fromSTEB(14, 16, 14, 16),
      labelStyle: textTheme.labelLarge?.copyWith(color: tokens.text2),
      hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.text3),
      border: inputBorder(tokens.lineSubtle),
      enabledBorder: inputBorder(tokens.lineSubtle),
      focusedBorder: inputBorder(tokens.accent, 1.05),
      errorBorder: inputBorder(tokens.loss),
      focusedErrorBorder: inputBorder(tokens.loss, 1.05),
      disabledBorder: inputBorder(tokens.lineSubtle.withValues(alpha: 0.6)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        backgroundColor: WidgetStatePropertyAll(tokens.accentBtnBottom),
        textStyle: WidgetStatePropertyAll(
          textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        overlayColor: WidgetStatePropertyAll(
          Colors.white.withValues(alpha: 0.08),
        ),
        elevation: const WidgetStatePropertyAll(0),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        foregroundColor: WidgetStatePropertyAll(tokens.text1),
        side: WidgetStatePropertyAll(
          BorderSide(color: tokens.lineStrong, width: 0.8),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        overlayColor: WidgetStatePropertyAll(
          tokens.accent.withValues(alpha: 0.08),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
        foregroundColor: WidgetStatePropertyAll(tokens.accent),
        overlayColor: WidgetStatePropertyAll(
          tokens.accent.withValues(alpha: 0.08),
        ),
        textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        foregroundColor: WidgetStatePropertyAll(tokens.text2),
        overlayColor: WidgetStatePropertyAll(
          tokens.accent.withValues(alpha: 0.08),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: tokens.surface2,
      selectedColor: tokens.accent.withValues(alpha: dark ? 0.22 : 0.12),
      disabledColor: tokens.surface2.withValues(alpha: 0.5),
      side: BorderSide(color: tokens.lineStrong, width: 0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      labelStyle: textTheme.labelMedium?.copyWith(color: tokens.text2),
      secondaryLabelStyle: textTheme.labelMedium?.copyWith(
        color: tokens.accent,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      showCheckmark: false,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: tokens.surface2,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: tokens.lineSubtle, width: 0.8),
      ),
      titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 20),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: tokens.text2),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: tokens.surface1,
      modalBackgroundColor: tokens.surface1,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: tokens.text3.withValues(alpha: 0.5),
      dragHandleSize: const Size(36, 4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: tokens.surface2,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tokens.lineSubtle, width: 0.8),
      ),
      textStyle: textTheme.bodyMedium?.copyWith(color: tokens.text1),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: tokens.surface3,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: tokens.text1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tokens.lineStrong, width: 0.8),
      ),
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 78),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const Color(0xFFF5F8FF)
            : tokens.text3,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? tokens.accentBtnBottom
            : tokens.inset,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? tokens.accent
            : tokens.lineStrong,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: tokens.lineSubtle.withValues(alpha: 0.72),
      thickness: 0.8,
      space: 1,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: tokens.surface2,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: tokens.surface3,
      headerForegroundColor: tokens.text1,
      todayForegroundColor: WidgetStatePropertyAll(tokens.accent),
      todayBorder: BorderSide(color: tokens.accent),
      dayBackgroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? tokens.accent : null,
      ),
      dayForegroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? Colors.white : tokens.text1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: tokens.accent,
      linearTrackColor: tokens.inset,
      refreshBackgroundColor: tokens.surface2,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: tokens.surface3,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.lineStrong, width: 0.8),
      ),
      textStyle: textTheme.labelMedium?.copyWith(color: tokens.text1),
      waitDuration: const Duration(milliseconds: 450),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _TdPageTransitionsBuilder(),
        TargetPlatform.iOS: _TdPageTransitionsBuilder(),
        TargetPlatform.windows: _TdPageTransitionsBuilder(),
        TargetPlatform.macOS: _TdPageTransitionsBuilder(),
        TargetPlatform.linux: _TdPageTransitionsBuilder(),
      },
    ),
  );
}
