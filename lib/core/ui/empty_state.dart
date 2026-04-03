import 'package:flutter/material.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/ui/app_components.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? ctaLabel;
  final VoidCallback? onCta;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.ctaLabel,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: AppPageContent(
        maxWidth: 460,
        child: AppCard(
          child: Column(
            key: const Key('app-empty-state'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppTheme.spacing48,
                height: AppTheme.spacing48,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: AppTheme.iconLG,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              AppTheme.h16,
              Text(
                title,
                textAlign: TextAlign.center,
                style: tt.titleLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              AppTheme.h8,
              Text(
                message,
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              if (ctaLabel != null && onCta != null) ...[
                AppTheme.h20,
                FilledButton.icon(
                  onPressed: onCta,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(ctaLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
