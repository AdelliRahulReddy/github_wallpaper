import 'dart:ui';

import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:github_wallpaper/data/models/app_models.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/features/settings/screens/membership_paywall_page.dart';
import 'package:github_wallpaper/features/wallpaper/screens/wrapped/wrapped_screen.dart';
import 'package:github_wallpaper/shared/widgets/app_components.dart';
import 'package:intl/intl.dart';


part 'stats_sections_glance.dart';
part 'stats_sections_heatmap.dart';
part 'stats_sections_time_breakdowns.dart';
part 'stats_sections_highlights.dart';
part 'stats_sections_rankings.dart';
part 'stats_sections_wrapped_cta.dart';
part 'stats_sections_monthly_trend.dart';

class StatsLockedPreview extends StatelessWidget {
  final Widget child;
  final String title;
  final String body;
  final VoidCallback onTap;

  const StatsLockedPreview({
    super.key,
    required this.child,
    required this.title,
    required this.body,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: AppTheme.brLarge,
      child: Stack(
        children: [
          IgnorePointer(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: Opacity(
                opacity: 0.50,
                child: child,
              ),
            ),
          ),
          Positioned.fill(
            child: Material(
              color: scheme.surface.withValues(alpha: 0.28),
              child: InkWell(
                onTap: onTap,
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    margin: AppTheme.pAll16,
                    padding: AppTheme.pAll16,
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.94),
                      borderRadius: AppTheme.brLarge,
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          color: scheme.primary,
                          size: AppTheme.iconMD,
                        ),
                        AppTheme.h10,
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        AppTheme.h8,
                        Text(
                          body,
                          textAlign: TextAlign.center,
                          style: tt.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                        AppTheme.h12,
                        FilledButton.tonal(
                          onPressed: onTap,
                          child: const Text('Unlock Pro'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
