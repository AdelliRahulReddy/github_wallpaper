import 'package:flutter/material.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';

class AppPageContent extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;

  const AppPageContent({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final tokens = context.surfaceTokens;
    return Padding(
      padding: padding ?? tokens.pagePaddingFor(width),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? tokens.contentMaxWidth,
          ),
          child: child,
        ),
      ),
    );
  }
}

class AppSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final AppSurfaceTone tone;
  final Color? accent;
  final Clip clipBehavior;

  const AppSurface({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.tone = AppSurfaceTone.standard,
    this.accent,
    this.clipBehavior = Clip.none,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? context.surfaceTokens.panelPadding,
      child: child,
    );

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        tone: tone,
        accent: accent,
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: clipBehavior,
        child: onTap == null
            ? content
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(
                  tone == AppSurfaceTone.poster
                      ? context.surfaceTokens.posterRadius
                      : context.surfaceTokens.panelRadius,
                ),
                child: content,
              ),
      ),
    );
  }
}

class AppPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool emphasize;

  const AppPill({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolvedColor = color ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing10,
        vertical: AppTheme.spacing6,
      ),
      decoration: AppTheme.surfaceDecoration(
        context,
        tone: emphasize ? AppSurfaceTone.emphasized : AppSurfaceTone.muted,
        accent: resolvedColor,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: resolvedColor),
            AppTheme.w6,
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: emphasize ? scheme.onSurface : resolvedColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const AppCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext c) {
    return AppSurface(
      padding: padding,
      onTap: onTap,
      child: child,
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const AppSectionHeader(
      {super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext c) {
    final s = Theme.of(c).colorScheme;
    final tt = Theme.of(c).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: tt.titleMedium?.copyWith(color: s.onSurface)),
              if (subtitle != null) ...[
                AppTheme.h8,
                Text(subtitle!,
                    style: tt.bodySmall?.copyWith(
                      color: s.onSurfaceVariant,
                    )),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[AppTheme.w12, trailing!],
      ],
    );
  }
}

class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? helper;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const MetricTile(
      {super.key,
      required this.label,
      required this.value,
      this.helper,
      required this.icon,
      this.iconColor,
      this.onTap});

  @override
  Widget build(BuildContext c) {
    final s = Theme.of(c).colorScheme;
    final tt = Theme.of(c).textTheme;
    final col = iconColor ?? s.primary;

    return AppCard(
      padding: AppTheme.pZero,
      onTap: onTap,
      child: ListTile(
        contentPadding: AppTheme.pAll16,
        leading: Icon(icon, color: col, size: AppTheme.iconMD),
        title: Text(value, style: tt.titleMedium),
        subtitle: Text(
          helper ?? label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: tt.bodySmall?.copyWith(color: s.onSurfaceVariant),
        ),
      ),
    );
  }
}

class HeroMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const HeroMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext c) {
    final s = Theme.of(c).colorScheme;
    final tt = Theme.of(c).textTheme;
    final col = color ?? s.primary;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: col, size: AppTheme.iconLG),
          AppTheme.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: tt.labelSmall?.copyWith(color: s.onSurfaceVariant)),
                AppTheme.h6,
                Text(value, style: tt.titleLarge),
                if (subtitle != null) ...[
                  AppTheme.h4,
                  Text(subtitle!,
                      style: tt.bodySmall?.copyWith(color: s.onSurfaceVariant)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
