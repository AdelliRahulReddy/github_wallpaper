import 'package:flutter/material.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/features/wallpaper/models/theme_presets.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/features/contributions/services/contribution_metrics.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';



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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 340;
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
                  _ShareCardHeader(
                    title: username,
                    subtitle: lastSyncLabel,
                    icon: Icons.grid_view_rounded,
                    showBranding: showBranding,
                    compact: isCompact,
                  ),
                  const SizedBox(height: 16),
                  _HeroRow(
                    label: AppStrings.totalContributions,
                    value: PresentationFormatter.formatCompactNumber(
                      data.totalContributions,
                    ),
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 14),
                  _MetricGroup(
                    compact: isCompact,
                    children: [
                      _MiniMetric(
                        label: AppStrings.currentStreak,
                        value: '${data.currentStreak}d',
                        color: AppTheme.warningOrange,
                        icon: Icons.local_fire_department_rounded,
                      ),
                      _MiniMetric(
                        label: AppStrings.today,
                        value: '${data.todayCommits}',
                        color: scheme.secondary,
                        icon: Icons.today_rounded,
                      ),
                      _MiniMetric(
                        label: AppStrings.longestStreak,
                        value: '${data.longestStreak}d',
                        color: AppTheme.accentViolet,
                        icon: Icons.emoji_events_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _MetricGroup(
                    compact: isCompact,
                    children: [
                      _TrendMetric(
                        label: AppStrings.trend7d,
                        value: PresentationFormatter.formatCompactNumber(
                          trend7d.current,
                        ),
                        helper: trend7d.deltaLabel,
                        color: scheme.primary,
                      ),
                      _TrendMetric(
                        label: AppStrings.trend30d,
                        value: PresentationFormatter.formatCompactNumber(
                          trend30d.current,
                        ),
                        helper: trend30d.deltaLabel,
                        color: scheme.primary,
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
                                    color:
                                        scheme.outline.withValues(alpha: 0.25),
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
      },
    );
  }
}

class _HeroRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeroRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_graph_rounded, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTheme.fontCaption,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppTheme.fontHeadline + 2,
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppTheme.fontLarge,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendMetric extends StatelessWidget {
  final String label;
  final String value;
  final String helper;
  final Color color;

  const _TrendMetric({
    required this.label,
    required this.value,
    required this.helper,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 150;
        final helperChip = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Text(
            helper,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        );

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              if (isNarrow) ...[
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppTheme.fontLarge,
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                helperChip,
              ] else
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppTheme.fontLarge,
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurface,
                          height: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(child: helperChip),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricGroup extends StatelessWidget {
  final List<Widget> children;
  final bool compact;

  const _MetricGroup({
    required this.children,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (children.length == 1) {
            return children.first;
          }

          final itemWidth = (constraints.maxWidth - 10) / 2;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final child in children)
                SizedBox(
                  width: itemWidth,
                  child: child,
                ),
            ],
          );
        },
      );
    }

    return Row(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          Expanded(child: children[index]),
          if (index != children.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _ShareCardHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool showBranding;
  final bool compact;

  const _ShareCardHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.showBranding,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget identity = Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, color: scheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
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
                subtitle,
                maxLines: compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppTheme.fontCaption,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (!showBranding) {
      return identity;
    }

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          identity,
          const SizedBox(height: 12),
          const _BrandChip(),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: identity),
        const SizedBox(width: 12),
        const _BrandChip(),
      ],
    );
  }
}

class _BrandChip extends StatelessWidget {
  const _BrandChip();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
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
    );
  }
}

class WrappedShareCard extends StatelessWidget {
  final String username;
  final int yearTotalContributions;
  final int activeDays;
  final int bestStreakDays;
  final String topRepoName;
  final String topLanguageName;
  final bool showBranding;

  const WrappedShareCard({
    super.key,
    required this.username,
    required this.yearTotalContributions,
    required this.activeDays,
    required this.bestStreakDays,
    required this.topRepoName,
    required this.topLanguageName,
    this.showBranding = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final displayName = username.trim().isEmpty
        ? 'GitWall'
        : username.trim()[0].toUpperCase() + username.trim().substring(1);
    final year = DateTime.now().year;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 340;
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
                  _ShareCardHeader(
                    title: displayName,
                    subtitle: 'GitWall Wrapped • $year',
                    icon: Icons.auto_awesome_rounded,
                    showBranding: showBranding,
                    compact: isCompact,
                  ),
                  const SizedBox(height: 16),
                  _HeroRow(
                    label: 'Year contributions',
                    value: PresentationFormatter.formatCompactNumber(
                      yearTotalContributions,
                    ),
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 14),
                  _MetricGroup(
                    compact: isCompact,
                    children: [
                      _MiniMetric(
                        label: 'Active days',
                        value: '$activeDays',
                        color: AppTheme.successGreen,
                        icon: Icons.calendar_today_rounded,
                      ),
                      _MiniMetric(
                        label: 'Best streak',
                        value: '${bestStreakDays}d',
                        color: AppTheme.warningOrange,
                        icon: Icons.local_fire_department_rounded,
                      ),
                      _MiniMetric(
                        label: 'Top language',
                        value:
                            topLanguageName.trim().isEmpty ? '—' : topLanguageName,
                        color: AppTheme.accentViolet,
                        icon: Icons.code_rounded,
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
                          'Top repo',
                          style: TextStyle(
                            fontSize: AppTheme.fontCaption,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          topRepoName.trim().isEmpty ? '—' : topRepoName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppTheme.fontBase,
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniHeatmap extends StatelessWidget {
  final List<ContributionDay> days;
  final Quartiles quartiles;
  final List<Color> levels;
  const _MiniHeatmap({
    required this.days,
    required this.quartiles,
    required this.levels,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (days.isEmpty) {
      return Center(
        child: Text(
          AppStrings.noRecentActivity,
          style: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final normalized = List<ContributionDay>.from(days)
      ..sort((a, b) => a.date.compareTo(b.date));
    final displayDays = normalized.length > 98
        ? normalized.sublist(normalized.length - 98)
        : normalized;

    final weekKeyToSlots = <String, List<int?>>{};
    for (final day in displayDays) {
      final d = DateTime(day.date.year, day.date.month, day.date.day);
      final weekStart =
          DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday % 7));
      final key = AppDateUtils.formatDate(weekStart);
      weekKeyToSlots.putIfAbsent(key, () => List<int?>.filled(7, null));
      weekKeyToSlots[key]![d.weekday % 7] = day.contributionCount;
    }

    final sortedKeys = weekKeyToSlots.keys.toList()..sort();
    final recentKeys = sortedKeys.length > 14
        ? sortedKeys.sublist(sortedKeys.length - 14)
        : sortedKeys;

    return LayoutBuilder(
      builder: (context, constraints) {
        const columnGap = 4.0;
        const rowGap = 4.0;

        Widget buildCell(int? count) {
          if (count == null) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.outline.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }

          final level =
              RenderUtils.getContributionLevel(count, quartiles: quartiles);
          final color = levels[level.clamp(0, levels.length - 1)];
          return DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: scheme.outline.withValues(alpha: 0.18),
              ),
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var wk = 0; wk < recentKeys.length; wk++) ...[
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var day = 0; day < 7; day++) ...[
                      AspectRatio(
                        aspectRatio: 1,
                        child: buildCell(
                          weekKeyToSlots[recentKeys[wk]]![day],
                        ),
                      ),
                      if (day != 6) const SizedBox(height: rowGap),
                    ],
                  ],
                ),
              ),
              if (wk != recentKeys.length - 1) const SizedBox(width: columnGap),
            ],
          ],
        );
      },
    );
  }
}


