import 'package:flutter/material.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const AppCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext c) {
    final theme = Theme.of(c);
    final shape = theme.cardTheme.shape;
    final BorderRadius borderRadius = shape is RoundedRectangleBorder
        ? shape.borderRadius.resolve(Directionality.of(c))
        : BorderRadius.circular(AppTheme.radiusMedium);

    final content = Padding(
      padding: padding ?? AppTheme.pAll20,
      child: child,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: onTap == null
          ? content
          : InkWell(
              borderRadius: borderRadius,
              onTap: onTap,
              child: content,
            ),
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
              Text(title,
                  style: tt.titleMedium?.copyWith(color: s.onSurface)),
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
                Text(title, style: tt.labelSmall?.copyWith(color: s.onSurfaceVariant)),
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

