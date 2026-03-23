import 'package:flutter/material.dart';
import 'package:github_wallpaper/data/models/app_models.dart';
import 'package:github_wallpaper/data/models/theme_presets.dart';
import 'package:github_wallpaper/data/datasources/local/storage_service.dart';
import 'package:github_wallpaper/shared/state/app_state.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';

part 'share_card_metrics.dart';
part 'wrapped_share_card.dart';

part 'share_card_heatmap.dart';

class ShareCard extends StatelessWidget {
  final CachedContributionData data;
  final TrendSummary trend7d;
  final TrendSummary trend30d;
  final bool showBranding;

  const ShareCard({
    super.key,
    required this.data,
    required this.trend7d,
    required this.trend30d,
    this.showBranding = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final username = data.username.isEmpty
        ? 'GitWall'
        : data.username[0].toUpperCase() + data.username.substring(1);
    final lastSync = StorageService.getEffectiveLastSync() ?? data.lastUpdated;
    final lastSyncLabel =
        'Last synced ${PresentationFormatter.formatTimeAgoCompact(lastSync)}';
    final wallpaperConfig = StorageService.getWallpaperConfig();
    final heatmapLevels = ThemePresets.levelsFor(
      wallpaperConfig.themeId,
      isDarkMode: wallpaperConfig.isDarkMode,
    );

    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: AppTheme.pAll20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.25)),
                    ),
                    child: Icon(Icons.grid_view_rounded, color: scheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppTheme.fontTitle,
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lastSyncLabel,
                          style: TextStyle(
                            fontSize: AppTheme.fontCaption,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showBranding)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        'GitWall',
                        style: TextStyle(
                          fontSize: AppTheme.fontSmall,
                          fontWeight: FontWeight.w900,
                          color: scheme.primary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _HeroRow(
                label: AppStrings.totalContributions,
                value: PresentationFormatter.formatCompactNumber(
                    data.totalContributions),
                color: scheme.primary,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MiniMetric(
                      label: AppStrings.currentStreak,
                      value: '${data.currentStreak}d',
                      color: AppTheme.warningOrange,
                      icon: Icons.local_fire_department_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetric(
                      label: AppStrings.today,
                      value: '${data.todayCommits}',
                      color: scheme.secondary,
                      icon: Icons.today_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetric(
                      label: AppStrings.longestStreak,
                      value: '${data.longestStreak}d',
                      color: AppTheme.accentViolet,
                      icon: Icons.emoji_events_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _TrendMetric(
                      label: AppStrings.trend7d,
                      value: PresentationFormatter.formatCompactNumber(
                          trend7d.current),
                      helper: trend7d.deltaLabel,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TrendMetric(
                      label: AppStrings.trend30d,
                      value: PresentationFormatter.formatCompactNumber(
                          trend30d.current),
                      helper: trend30d.deltaLabel,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: scheme.outline.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Heatmap',
                      style: TextStyle(
                        fontSize: AppTheme.fontCaption,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _MiniHeatmap(
                      days: data.days,
                      quartiles: data.quartiles,
                      levels: heatmapLevels,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Less',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                        const SizedBox(width: 6),
                        for (var i = 0; i < 5; i++) ...[
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: heatmapLevels[i],
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                color: scheme.outline.withValues(alpha: 0.25),
                              ),
                            ),
                          ),
                        ],
                        Text(
                          'More',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
