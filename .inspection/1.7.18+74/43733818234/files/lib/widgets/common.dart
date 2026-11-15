import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

enum AppCardVariant { raised, hero, tint, well }

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.variant = AppCardVariant.raised,
    this.tintColor,
    this.tintBorderAlpha,
    this.sheen = true,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final AppCardVariant variant;
  final Color? tintColor;
  final double? tintBorderAlpha;
  final bool sheen;

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    final radius = BorderRadius.circular(
      variant == AppCardVariant.hero ? 28 : 20,
    );
    final tint = tintColor ?? tokens.accent;
    final gradient = switch (variant) {
      AppCardVariant.hero => tokens.heroGradient,
      AppCardVariant.raised => tokens.cardGradient,
      AppCardVariant.tint => LinearGradient(
        begin: AlignmentDirectional.centerStart,
        end: AlignmentDirectional.centerEnd,
        colors: [tint.withValues(alpha: 0.12), tokens.surface1],
      ),
      AppCardVariant.well => null,
    };
    final shadows = variant != AppCardVariant.well
        ? tokens.cardShadows
        : const <BoxShadow>[];
    final borderColor = variant == AppCardVariant.tint
        ? tint.withValues(alpha: tintBorderAlpha ?? 0.16)
        : variant == AppCardVariant.hero
        ? tokens.accent.withValues(alpha: 0.13)
        : tokens.lineSubtle;
    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? tokens.inset : null,
        gradient: gradient,
        borderRadius: radius,
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: shadows,
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: RoundedRectangleBorder(borderRadius: radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(borderRadius: radius),
          child: Stack(
            children: [
              if (sheen && variant != AppCardVariant.well)
                PositionedDirectional(
                  top: 0,
                  start: 16,
                  end: 16,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(
                            alpha:
                                Theme.of(context).brightness == Brightness.dark
                                ? 0.14
                                : 0.72,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class PageTitle extends StatelessWidget {
  const PageTitle(this.title, {super.key, this.subtitle, this.action});
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(10, 18, 10, 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: 5),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: TdTokens.of(context).text3,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    ),
  );
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.icon,
  });
  final String label;
  final String value;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    final semantic = color ?? tokens.accent;
    return AppCard(
      variant: color == null ? AppCardVariant.raised : AppCardVariant.tint,
      tintColor: semantic,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: semantic.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 17, color: semantic),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: tokens.text3),
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              maxLines: 1,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.detail,
    this.action,
  });
  final String title;
  final String detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: TdTokens.of(context).surface2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: TdTokens.of(context).lineSubtle,
              width: 0.8,
            ),
          ),
          child: Icon(
            Icons.inbox_outlined,
            size: 30,
            color: TdTokens.of(context).text3,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: TdTokens.of(context).text2),
        ),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}

class ImageAttachmentTile extends StatelessWidget {
  const ImageAttachmentTile({
    super.key,
    required this.label,
    required this.path,
    required this.onTap,
    this.onRemove,
  });
  final String label;
  final String? path;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = TdTokens.of(context);
    final exists = path != null && File(path!).existsSync();
    final radius = BorderRadius.circular(16);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Material(
          color: tokens.inset,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Container(
              height: 132,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: exists
                      ? tokens.lineSubtle
                      : tokens.lineStrong.withValues(alpha: 0.72),
                  width: 0.8,
                ),
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: exists
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(File(path!), fit: BoxFit.cover),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 48,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Color(0x59000000),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (onRemove != null)
                            PositionedDirectional(
                              end: 8,
                              bottom: 8,
                              child: TextButton.icon(
                                onPressed: onRemove,
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 17,
                                ),
                                label: Text(tr(context, 'removeImage')),
                                style: TextButton.styleFrom(
                                  foregroundColor: tokens.loss,
                                  backgroundColor: tokens.loss.withValues(
                                    alpha: 0.18,
                                  ),
                                  minimumSize: const Size(48, 38),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            color: const Color(0xFF9AA3AD),
                            size: 28,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tr(context, 'chooseImage'),
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: tokens.text2),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String money(double amount, String currency) => !amount.isFinite
    ? '${currency.toUpperCase()} —'
    : '${amount < 0 ? '-' : ''}${currency.toUpperCase()} ${amount.abs().toStringAsFixed(2)}';
String shortDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
