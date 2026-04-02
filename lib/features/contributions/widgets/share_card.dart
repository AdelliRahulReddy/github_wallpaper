import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/features/contributions/models/share_template_catalog.dart';
import 'package:github_wallpaper/features/wallpaper/models/theme_presets.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/features/contributions/services/contribution_metrics.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:intl/intl.dart';

export 'package:github_wallpaper/features/contributions/models/share_template_catalog.dart';

ShareCardFamily recommendShareCardFamily(
  CachedContributionData data,
  TrendSummary trend7d,
  TrendSummary trend30d,
) {
  return buildShareFamilySuggestions(data, trend7d, trend30d).first;
}

List<ShareCardFamily> buildShareFamilySuggestions(
  CachedContributionData data,
  TrendSummary trend7d,
  TrendSummary trend30d,
) {
  final suggestions = <ShareCardFamily>[];
  final monthStats = _MonthlySnapshotStats.fromData(data);

  if (_isStreakMilestone(data.currentStreak)) {
    suggestions.add(ShareCardFamily.streakMilestone);
  }
  if (_hasStrongRepoFocus(data)) {
    suggestions.add(ShareCardFamily.repoFocus);
  }
  if (_shouldSuggestMonthlySnapshot(monthStats, trend7d, trend30d)) {
    suggestions.add(ShareCardFamily.monthlySnapshot);
  }
  suggestions.add(ShareCardFamily.dailyFlex);
  for (final family in ShareTemplateCatalog.coreFamilies) {
    if (!suggestions.contains(family)) {
      suggestions.add(family);
    }
  }
  return suggestions;
}

Widget buildShareCardPreview({
  required ShareCardFamily family,
  required CachedContributionData data,
  required TrendSummary trend7d,
  required TrendSummary trend30d,
  bool showBranding = true,
  ShareExportFormat format = ShareExportFormat.story,
}) {
  return switch (family) {
    ShareCardFamily.dailyFlex => ShareExportFrame(
        format: format,
        child: ShareCard(
          data: data,
          trend7d: trend7d,
          trend30d: trend30d,
          showBranding: showBranding,
          format: format,
        ),
      ),
    ShareCardFamily.streakMilestone => ShareExportFrame(
        format: format,
        child: StreakMilestoneShareCard(
          data: data,
          showBranding: showBranding,
          format: format,
        ),
      ),
    ShareCardFamily.monthlySnapshot => ShareExportFrame(
        format: format,
        child: MonthlySnapshotShareCard(
          data: data,
          trend7d: trend7d,
          trend30d: trend30d,
          showBranding: showBranding,
          format: format,
        ),
      ),
    ShareCardFamily.wrapped => ShareExportFrame(
        format: format,
        child: WrappedShareCard(
          username: data.username,
          yearTotalContributions: data.totalContributions,
          activeDays: data.activeDaysCount,
          bestStreakDays: data.longestStreak,
          topRepoName: _topRepository(data)?.nameWithOwner ?? '',
          topLanguageName:
              data.topLanguages.isEmpty ? '' : data.topLanguages.first.name,
          showBranding: showBranding,
          format: format,
        ),
      ),
    ShareCardFamily.repoFocus => ShareExportFrame(
        format: format,
        child: RepoFocusShareCard(
          data: data,
          showBranding: showBranding,
          format: format,
        ),
      ),
  };
}

RepoContribution? _topRepository(CachedContributionData data) {
  final ranked = data.repositories
      .where((repository) => repository.commitCount > 0)
      .toList()
    ..sort((a, b) {
      final byCommits = b.commitCount.compareTo(a.commitCount);
      if (byCommits != 0) return byCommits;

      final byLanguageCount = b.languages.length.compareTo(a.languages.length);
      if (byLanguageCount != 0) return byLanguageCount;

      final aHasPrimaryLanguage =
          (a.primaryLanguageName?.trim().isNotEmpty ?? false) ? 1 : 0;
      final bHasPrimaryLanguage =
          (b.primaryLanguageName?.trim().isNotEmpty ?? false) ? 1 : 0;
      final byPrimaryLanguage = bHasPrimaryLanguage.compareTo(
        aHasPrimaryLanguage,
      );
      if (byPrimaryLanguage != 0) return byPrimaryLanguage;

      return a.nameWithOwner.compareTo(b.nameWithOwner);
    });
  return ranked.isEmpty ? null : ranked.first;
}

Color _repoAccentColor(RepoContribution repository, Color fallback) {
  return AppColorUtils.parseHexColor(repository.primaryLanguageColor) ??
      fallback;
}

bool _isStreakMilestone(int streak) {
  const milestones = [7, 14, 30, 50, 100];
  return milestones.contains(streak);
}

bool _shouldSuggestMonthlySnapshot(
  _MonthlySnapshotStats monthStats,
  TrendSummary trend7d,
  TrendSummary trend30d,
) {
  if (monthStats.monthTotal >= 12 || monthStats.activeDays >= 5) {
    return true;
  }
  if (trend30d.current > trend30d.previous && monthStats.monthTotal >= 6) {
    return true;
  }
  return trend7d.current >= 10 && monthStats.monthTotal >= 3;
}

bool _hasStrongRepoFocus(CachedContributionData data) {
  final topRepo = _topRepository(data);
  if (topRepo == null || data.totalContributions <= 0) {
    return false;
  }

  return topRepo.commitCount >= 15 ||
      topRepo.commitCount / data.totalContributions >= 0.25;
}

int? _nextStreakMilestone(int streak) {
  const milestones = [7, 14, 30, 50, 100];
  for (final milestone in milestones) {
    if (streak <= milestone) return milestone;
  }
  return milestones.last;
}

String _displayShareName(String username) {
  final normalized = username.trim();
  if (normalized.isEmpty) return 'GitWall';
  return normalized[0].toUpperCase() + normalized.substring(1);
}

String _formatShortDate(DateTime date) => DateFormat('MMM d').format(date);

String _shortWeekday(String weekday) {
  final normalized = weekday.trim();
  if (normalized.isEmpty) return '—';
  return normalized.length <= 3 ? normalized : normalized.substring(0, 3);
}

class _SharePalette {
  final Color accent;
  final Color accentSoft;
  final Color accentStrong;
  final Color secondaryAccent;
  final Color tertiaryAccent;
  final Color surface;
  final Color surfaceRaised;
  final Color border;
  final Color text;
  final Color textMuted;
  final List<Color> heatmapLevels;
  final Gradient frameGradient;

  const _SharePalette({
    required this.accent,
    required this.accentSoft,
    required this.accentStrong,
    required this.secondaryAccent,
    required this.tertiaryAccent,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.heatmapLevels,
    required this.frameGradient,
  });

  factory _SharePalette.fromContext(
    BuildContext context, {
    Color? accentOverride,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final wallpaperConfig = StorageService.getWallpaperConfig();
    final heatmapLevels = ThemePresets.levelsFor(
      wallpaperConfig.themeId,
      isDarkMode: wallpaperConfig.isDarkMode,
    );
    final accent =
        accentOverride ?? Color.lerp(scheme.primary, heatmapLevels[4], 0.6)!;
    final secondary = Color.lerp(scheme.secondary, heatmapLevels[3], 0.4)!;
    final tertiary = Color.lerp(scheme.tertiary, heatmapLevels[2], 0.35)!;

    return _SharePalette(
      accent: accent,
      accentSoft: accent.withValues(alpha: 0.12),
      accentStrong: Color.lerp(accent, Colors.black, 0.14)!,
      secondaryAccent: secondary,
      tertiaryAccent: tertiary,
      surface: scheme.surface.withValues(alpha: 0.95),
      surfaceRaised: scheme.surfaceContainerHighest.withValues(alpha: 0.90),
      border: scheme.outline.withValues(alpha: 0.28),
      text: scheme.onSurface,
      textMuted: scheme.onSurface.withValues(alpha: 0.68),
      heatmapLevels: heatmapLevels,
      frameGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withValues(alpha: 0.16),
          heatmapLevels[2].withValues(alpha: 0.10),
          scheme.surface,
          scheme.surfaceContainerHighest.withValues(alpha: 0.94),
        ],
      ),
    );
  }
}

BoxDecoration _surfaceDecoration(
  _SharePalette palette, {
  required ShareExportFormat format,
}) {
  return BoxDecoration(
    color: palette.surface,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: palette.border),
    boxShadow: [
      BoxShadow(
        color: palette.accent.withValues(alpha: 0.08),
        blurRadius: 26,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

BoxDecoration _panelDecoration(
  BuildContext context, {
  required _SharePalette palette,
  Color? tint,
}) {
  final scheme = Theme.of(context).colorScheme;
  final baseTint = tint ?? palette.accent;
  return BoxDecoration(
    color: scheme.surface.withValues(alpha: 0.74),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Color.lerp(palette.border, baseTint, 0.18)!.withValues(alpha: 0.5),
    ),
  );
}

class _TemplateSurface extends StatelessWidget {
  final ShareExportFormat format;
  final _SharePalette palette;
  final Widget child;

  const _TemplateSurface({
    required this.format,
    required this.palette,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _surfaceDecoration(
        palette,
        format: format,
      ),
      child: child,
    );
  }
}

class _HeatmapPanel extends StatelessWidget {
  final String title;
  final List<ContributionDay> days;
  final Quartiles quartiles;
  final List<Color> levels;
  final bool showLegend;
  final Widget? footer;
  final _SharePalette palette;
  final bool compact;
  final int? maxWeeks;
  final int minWeeks;
  final bool fillHeight;

  const _HeatmapPanel({
    required this.title,
    required this.days,
    required this.quartiles,
    required this.levels,
    required this.showLegend,
    required this.palette,
    this.footer,
    this.compact = false,
    this.maxWeeks,
    this.minWeeks = 10,
    this.fillHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    final heatmap = _MiniHeatmap(
      days: days,
      quartiles: quartiles,
      levels: levels,
      maxWeeks: maxWeeks,
      minWeeks: minWeeks,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 6 : 12),
      decoration: _panelDecoration(context, palette: palette),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: compact ? 10 : AppTheme.fontCaption,
              fontWeight: FontWeight.w800,
              color: palette.text.withValues(alpha: 0.82),
            ),
          ),
          SizedBox(height: compact ? 6 : 10),
          if (fillHeight)
            Expanded(child: heatmap)
          else
            heatmap,
          if (showLegend) ...[
            SizedBox(height: compact ? 4 : 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Less',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: palette.textMuted,
                  ),
                ),
                const SizedBox(width: 6),
                for (var i = 0; i < 5; i++) ...[
                  Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: levels[i],
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: palette.border.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
                Text(
                  'More',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ],
          if (footer != null) ...[
            SizedBox(height: compact ? 4 : 8),
            footer!,
          ],
        ],
      ),
    );
  }
}

class ShareCard extends StatelessWidget {
  final CachedContributionData data;
  final TrendSummary trend7d;
  final TrendSummary trend30d;
  final bool showBranding;
  final ShareExportFormat format;

  const ShareCard({
    super.key,
    required this.data,
    required this.trend7d,
    required this.trend30d,
    this.showBranding = true,
    this.format = ShareExportFormat.story,
  });

  @override
  Widget build(BuildContext context) {
    final username = _displayShareName(data.username);
    final lastSync = StorageService.getEffectiveLastSync() ?? data.lastUpdated;
    final lastSyncLabel =
        'Last synced ${PresentationFormatter.formatTimeAgoCompact(lastSync)}';
    final palette = _SharePalette.fromContext(context);

    return LayoutBuilder(
      builder: (context, _) => _buildStoryLayout(
        palette: palette,
        username: username,
        lastSyncLabel: lastSyncLabel,
      ),
    );
  }

  Widget _buildStoryLayout({
    required _SharePalette palette,
    required String username,
    required String lastSyncLabel,
  }) {
    final topLanguage = data.topLanguages.isEmpty ? null : data.topLanguages.first;
    final averagePerActiveDay = ContributionAnalyzer.averagePerActiveDay(
      data.days,
      countOf: (day) => day.contributionCount,
    );
    final peakDay = ContributionAnalyzer.findPeakDay<ContributionDay>(
      data.days,
      dateOf: (day) => day.date,
      countOf: (day) => day.contributionCount,
    );
    final heroUsesToday = data.todayCommits > 0;

    return _TemplateSurface(
      format: format,
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShareCardHeader(
            title: username,
            subtitle: lastSyncLabel,
            icon: Icons.grid_view_rounded,
            showBranding: showBranding,
            compact: false,
            accent: palette.accent,
          ),
          const SizedBox(height: 12),
          _HeroRow(
            label: heroUsesToday ? 'Today' : '7-day momentum',
            value: heroUsesToday
                ? '${data.todayCommits}'
                : PresentationFormatter.formatCompactNumber(trend7d.current),
            helper: heroUsesToday
                ? '${PresentationFormatter.formatCompactNumber(trend7d.current)} contributions in the last 7 days'
                : trend7d.deltaLabel,
            color: palette.accent,
            icon: heroUsesToday
                ? Icons.today_rounded
                : Icons.auto_graph_rounded,
          ),
          const SizedBox(height: 10),
          _MetricGroup(
            compact: false,
            children: [
              _MiniMetric(
                label: AppStrings.currentStreak,
                value: '${data.currentStreak}d',
                color: AppTheme.warningOrange,
                icon: Icons.local_fire_department_rounded,
              ),
              _MiniMetric(
                label: AppStrings.longestStreak,
                value: '${data.longestStreak}d',
                color: palette.secondaryAccent,
                icon: Icons.emoji_events_rounded,
              ),
              _MiniMetric(
                label: 'Avg / active',
                value: averagePerActiveDay.toStringAsFixed(1),
                color: AppTheme.successGreen,
                icon: Icons.insights_rounded,
                helper: '${data.activeDaysCount} active days',
              ),
              _MiniMetric(
                label: 'Top language',
                value: topLanguage?.name ?? '—',
                color: palette.tertiaryAccent,
                icon: Icons.code_rounded,
                helper: topLanguage == null
                    ? null
                    : '${(topLanguage.percent * 100).round()}% of repo mix',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _HeatmapPanel(
              title: 'Consistency heatmap',
              days: data.days,
              quartiles: data.quartiles,
              levels: palette.heatmapLevels,
              showLegend: false,
              palette: palette,
              compact: true,
              maxWeeks: 10,
              minWeeks: 10,
              fillHeight: true,
              footer: Text(
                peakDay == null
                    ? '7d ${PresentationFormatter.formatCompactNumber(trend7d.current)} • 30d ${PresentationFormatter.formatCompactNumber(trend30d.current)}'
                    : '7d ${PresentationFormatter.formatCompactNumber(trend7d.current)} • 30d ${PresentationFormatter.formatCompactNumber(trend30d.current)} • Peak ${peakDay.count} on ${_formatShortDate(peakDay.date)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: palette.textMuted,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String? helper;
  final IconData icon;

  const _HeroRow({
    required this.label,
    required this.value,
    required this.color,
    this.helper,
    this.icon = Icons.auto_graph_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
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
                    fontSize: AppTheme.fontHeadline,
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                    height: 1.0,
                  ),
                ),
                if (helper != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    helper!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppTheme.fontCaption,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1.1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RepoHeroCard extends StatelessWidget {
  final String repoName;
  final int commitCount;
  final int repoShare;
  final bool isPrivate;
  final Color accent;
  final bool compact;

  const _RepoHeroCard({
    required this.repoName,
    required this.commitCount,
    required this.repoShare,
    required this.isPrivate,
    required this.accent,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (compact) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accent.withValues(alpha: 0.22)),
                  ),
                  child: Icon(
                    Icons.folder_open_rounded,
                    size: 14,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    repoName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppTheme.fontBase + 1,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  isPrivate ? Icons.lock_outline_rounded : Icons.public_rounded,
                  size: 14,
                  color: scheme.onSurface.withValues(alpha: 0.62),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${PresentationFormatter.formatCompactNumber(commitCount)} commits • $repoShare% share',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (repoShare / 100).clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: scheme.surface.withValues(alpha: 0.78),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 26 : 30,
                height: compact ? 26 : 30,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(compact ? 8 : 10),
                  border: Border.all(color: accent.withValues(alpha: 0.22)),
                ),
                child: Icon(
                  Icons.folder_open_rounded,
                  size: compact ? 16 : 18,
                  color: accent,
                ),
              ),
              SizedBox(width: compact ? 8 : 10),
              Expanded(
                child: Text(
                  'Top repo',
                  style: TextStyle(
                    fontSize: compact ? 10 : AppTheme.fontCaption,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 10,
                  vertical: compact ? 5 : 6,
                ),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: scheme.outline.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPrivate
                          ? Icons.lock_outline_rounded
                          : Icons.public_rounded,
                      size: 12,
                      color: scheme.onSurface.withValues(alpha: 0.65),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isPrivate ? 'Private' : 'Public',
                      style: TextStyle(
                        fontSize: compact ? 10 : AppTheme.fontSmall,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            repoName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize:
                  compact ? AppTheme.fontTitle + 1 : AppTheme.fontHeadline,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface,
              height: 1.04,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            '${PresentationFormatter.formatCompactNumber(commitCount)} commits • $repoShare% of your total activity',
            style: TextStyle(
              fontSize: compact ? AppTheme.fontCaption : AppTheme.fontBase,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.75),
              height: 1.25,
            ),
          ),
          SizedBox(height: compact ? 10 : 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (repoShare / 100).clamp(0.0, 1.0),
              minHeight: compact ? 8 : 10,
              backgroundColor: scheme.surface.withValues(alpha: 0.78),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
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
  final String? helper;

  const _MiniMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
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
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Icon(icon, size: 12, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppTheme.fontSmall,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface.withValues(alpha: 0.7),
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppTheme.fontBase + 6,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface,
              height: 1.0,
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: 4),
            Text(
              helper!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppTheme.fontSmall,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.1,
              ),
            ),
          ],
        ],
      ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (children.length == 1) {
          return children.first;
        }

        final gap = compact ? 8.0 : 10.0;
        final itemWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
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
}

class _ShareCardHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool showBranding;
  final bool compact;
  final Color accent;

  const _ShareCardHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.showBranding,
    required this.compact,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconBoxSize = compact ? 36.0 : 44.0;
    final titleSize = compact ? AppTheme.fontBase + 1 : AppTheme.fontTitle - 1;
    final subtitleSize = compact ? 10.0 : AppTheme.fontSmall;

    Widget identity = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: iconBoxSize,
          height: iconBoxSize,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(compact ? 12 : 14),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, color: accent, size: compact ? 18 : 22),
        ),
        SizedBox(width: compact ? 10 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                  height: 1.1,
                ),
              ),
              SizedBox(height: compact ? 2 : 4),
              Text(
                subtitle,
                maxLines: compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: subtitleSize,
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
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: identity),
          const SizedBox(width: 10),
          _BrandChip(accent: accent),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: identity),
        const SizedBox(width: 12),
        _BrandChip(accent: accent),
      ],
    );
  }
}

class _BrandChip extends StatelessWidget {
  final Color accent;

  const _BrandChip({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Text(
        'GitWall',
        style: TextStyle(
          fontSize: AppTheme.fontSmall,
          fontWeight: FontWeight.w900,
          color: accent,
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
  final ShareExportFormat format;

  const WrappedShareCard({
    super.key,
    required this.username,
    required this.yearTotalContributions,
    required this.activeDays,
    required this.bestStreakDays,
    required this.topRepoName,
    required this.topLanguageName,
    this.showBranding = true,
    this.format = ShareExportFormat.story,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _SharePalette.fromContext(context);
    final displayName = username.trim().isEmpty
        ? 'GitWall'
        : username.trim()[0].toUpperCase() + username.trim().substring(1);
    final year = DateTime.now().year;

    return _TemplateSurface(
      format: format,
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _ShareCardHeader(
            title: displayName,
            subtitle: 'GitWall Wrapped • $year',
            icon: Icons.auto_awesome_rounded,
            showBranding: showBranding,
            compact: false,
            accent: palette.accent,
          ),
          const SizedBox(height: 16),
          _HeroRow(
            label: 'Year contributions',
            value: PresentationFormatter.formatCompactNumber(
              yearTotalContributions,
            ),
            color: palette.accent,
          ),
          const SizedBox(height: 14),
          _MetricGroup(
            compact: false,
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
                value: topLanguageName.trim().isEmpty ? '—' : topLanguageName,
                color: palette.tertiaryAccent,
                icon: Icons.code_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: _panelDecoration(context, palette: palette),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top repo',
                  style: TextStyle(
                    fontSize: AppTheme.fontCaption,
                    fontWeight: FontWeight.w800,
                    color: palette.text.withValues(alpha: 0.8),
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
                    color: palette.text,
                    height: 1.1,
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

class _MiniHeatmap extends StatelessWidget {
  final List<ContributionDay> days;
  final Quartiles quartiles;
  final List<Color> levels;
  final int? maxWeeks;
  final int minWeeks;
  const _MiniHeatmap({
    required this.days,
    required this.quartiles,
    required this.levels,
    this.maxWeeks,
    this.minWeeks = 10,
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
      final weekStart = DateTime(d.year, d.month, d.day)
          .subtract(Duration(days: d.weekday % 7));
      final key = AppDateUtils.formatDate(weekStart);
      weekKeyToSlots.putIfAbsent(key, () => List<int?>.filled(7, null));
      weekKeyToSlots[key]![d.weekday % 7] = day.contributionCount;
    }

    final sortedKeys = weekKeyToSlots.keys.toList()..sort();
    final weekWindow = maxWeeks ?? 14;
    final recentKeys = sortedKeys.length > weekWindow
        ? sortedKeys.sublist(sortedKeys.length - weekWindow)
        : sortedKeys;
    final targetWeeks = math.max(minWeeks, recentKeys.length);
    final visibleWeekKeys = <String?>[
      ...List<String?>.filled(
        math.max(0, targetWeeks - recentKeys.length),
        null,
      ),
      ...recentKeys,
    ];

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

        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 240.0;
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : double.infinity;
        final slotCount = visibleWeekKeys.length;
        final widthCellSize =
            (availableWidth - ((slotCount - 1) * columnGap)) / slotCount;
        final heightCellSize = availableHeight.isFinite
            ? (availableHeight - (6 * rowGap)) / 7
            : double.infinity;
        final cellSize = math.max(
          8.0,
          math.min(
            18.0,
            math.min(widthCellSize, heightCellSize),
          ),
        );
        final gridWidth = (slotCount * cellSize) + ((slotCount - 1) * columnGap);
        final gridHeight = (7 * cellSize) + (6 * rowGap);

        return Center(
          child: SizedBox(
            width: gridWidth,
            height: gridHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var wk = 0; wk < visibleWeekKeys.length; wk++) ...[
                  SizedBox(
                    width: cellSize,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var day = 0; day < 7; day++) ...[
                          SizedBox.square(
                            dimension: cellSize,
                            child: buildCell(
                              visibleWeekKeys[wk] == null
                                  ? null
                                  : weekKeyToSlots[visibleWeekKeys[wk]]![day],
                            ),
                          ),
                          if (day != 6) const SizedBox(height: rowGap),
                        ],
                      ],
                    ),
                  ),
                  if (wk != visibleWeekKeys.length - 1)
                    const SizedBox(width: columnGap),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class ShareExportFrame extends StatelessWidget {
  final ShareExportFormat format;
  final Widget child;

  const ShareExportFrame({
    super.key,
    required this.format,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _SharePalette.fromContext(context);

    return AspectRatio(
      aspectRatio: format.aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppTheme.brLarge,
          gradient: palette.frameGradient,
          border: Border.all(color: palette.border),
        ),
        child: Padding(
          padding: format.framePadding,
          child: child,
        ),
      ),
    );
  }
}

class StreakMilestoneShareCard extends StatelessWidget {
  final CachedContributionData data;
  final bool showBranding;
  final ShareExportFormat format;

  const StreakMilestoneShareCard({
    super.key,
    required this.data,
    required this.showBranding,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _SharePalette.fromContext(
      context,
      accentOverride: AppTheme.warningOrange,
    );
    final currentStreak = data.currentStreak;
    final milestone = _nextStreakMilestone(currentStreak);
    final achieved = milestone != null && currentStreak >= milestone;
    final remaining =
        milestone == null ? 0 : (milestone - currentStreak).clamp(0, milestone);
    final accent = palette.accent;
    final trend7d = data.days.isEmpty
        ? const TrendSummary(current: 0, previous: 0)
        : ContributionAnalyzer.computeTrend(
            data.days,
            window: 7,
            dateOf: (day) => day.date,
            countOf: (day) => day.contributionCount,
          );
    final peakDay = ContributionAnalyzer.findPeakDay<ContributionDay>(
      data.days,
      dateOf: (day) => day.date,
      countOf: (day) => day.contributionCount,
    );

    return _TemplateSurface(
      format: format,
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShareCardHeader(
            title: _displayShareName(data.username),
            subtitle: achieved
                ? '$milestone day streak unlocked'
                : '$remaining day${remaining == 1 ? '' : 's'} to ${milestone ?? 100}d',
            icon: Icons.local_fire_department_rounded,
            showBranding: showBranding,
            compact: false,
            accent: accent,
          ),
          const SizedBox(height: 12),
          _HeroRow(
            label: achieved ? 'Unlocked streak' : 'Current streak',
            value: '${data.currentStreak}d',
            helper: milestone == null
                ? 'Highest tracked checkpoint reached'
                : achieved
                    ? 'Checkpoint locked'
                    : '$remaining day${remaining == 1 ? '' : 's'} to go',
            color: accent,
            icon: Icons.local_fire_department_rounded,
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: milestone == null
                  ? 1.0
                  : (currentStreak / milestone).clamp(0.0, 1.0),
              minHeight: 9,
              backgroundColor: palette.border.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 10),
          _MetricGroup(
            compact: false,
            children: [
              _MiniMetric(
                label: 'Next goal',
                value: milestone == null ? '100d+' : '${milestone}d',
                color: accent,
                icon: Icons.flag_rounded,
                helper: achieved
                    ? 'Unlocked'
                    : '$remaining left',
              ),
              _MiniMetric(
                label: 'Longest streak',
                value: '${data.longestStreak}d',
                color: palette.tertiaryAccent,
                icon: Icons.emoji_events_rounded,
              ),
              _MiniMetric(
                label: 'Today',
                value: '${data.todayCommits}',
                color: palette.secondaryAccent,
                icon: Icons.today_rounded,
              ),
              _MiniMetric(
                label: '7-day momentum',
                value: PresentationFormatter.formatCompactNumber(trend7d.current),
                color: AppTheme.successGreen,
                icon: Icons.auto_graph_rounded,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _HeatmapPanel(
              title: 'Streak heatmap',
              days: data.days,
              quartiles: data.quartiles,
              levels: palette.heatmapLevels,
              showLegend: false,
              palette: palette,
              compact: true,
              maxWeeks: 10,
              minWeeks: 10,
              fillHeight: true,
              footer: Text(
                peakDay == null
                    ? '${data.activeDaysCount} active days • Best ${_shortWeekday(data.stats.mostActiveWeekday)}'
                    : '${data.activeDaysCount} active days • Best ${_shortWeekday(data.stats.mostActiveWeekday)} • Peak ${peakDay.count} on ${_formatShortDate(peakDay.date)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: palette.textMuted,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MonthlySnapshotShareCard extends StatelessWidget {
  final CachedContributionData data;
  final TrendSummary trend7d;
  final TrendSummary trend30d;
  final bool showBranding;
  final ShareExportFormat format;

  const MonthlySnapshotShareCard({
    super.key,
    required this.data,
    required this.trend7d,
    required this.trend30d,
    required this.showBranding,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    final month = _MonthlySnapshotStats.fromData(data);
    final palette = _SharePalette.fromContext(
      context,
      accentOverride: Theme.of(context).colorScheme.tertiary,
    );
    final topLanguage =
        month.topLanguageName.trim().isEmpty ? '—' : month.topLanguageName;
    final monthQuartiles = RenderUtils.calculateQuartiles(
      month.monthDays.map((day) => day.contributionCount).toList(),
    );
    final averagePerActive = month.activeDays == 0
        ? 0.0
        : month.monthTotal / month.activeDays;
    final peakDay = ContributionAnalyzer.findPeakDay<ContributionDay>(
      month.monthDays,
      dateOf: (day) => day.date,
      countOf: (day) => day.contributionCount,
    );

    return _TemplateSurface(
      format: format,
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShareCardHeader(
            title: _displayShareName(data.username),
            subtitle: month.monthLabel,
            icon: Icons.calendar_month_rounded,
            showBranding: showBranding,
            compact: false,
            accent: palette.accent,
          ),
          const SizedBox(height: 12),
          _HeroRow(
            label: 'Month total',
            value: PresentationFormatter.formatCompactNumber(month.monthTotal),
            helper: '${month.activeDays} active day${month.activeDays == 1 ? '' : 's'} this month',
            color: palette.accent,
            icon: Icons.calendar_month_rounded,
          ),
          const SizedBox(height: 10),
          _MetricGroup(
            compact: false,
            children: [
              _MiniMetric(
                label: 'Active days',
                value: '${month.activeDays}',
                color: AppTheme.successGreen,
                icon: Icons.calendar_today_rounded,
              ),
              _MiniMetric(
                label: 'Best week',
                value: PresentationFormatter.formatCompactNumber(
                  month.bestWeekTotal,
                ),
                color: palette.accent,
                icon: Icons.query_stats_rounded,
                helper: month.bestWeekLabel == '?'
                    ? 'No active week yet'
                    : month.bestWeekLabel,
              ),
              _MiniMetric(
                label: 'Avg / active',
                value: averagePerActive.toStringAsFixed(1),
                color: palette.secondaryAccent,
                icon: Icons.insights_rounded,
              ),
              _MiniMetric(
                label: 'Top language',
                value: topLanguage,
                color: palette.tertiaryAccent,
                icon: Icons.code_rounded,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _HeatmapPanel(
              title: 'Month heatmap',
              days: month.monthDays,
              quartiles: monthQuartiles,
              levels: palette.heatmapLevels,
              showLegend: false,
              palette: palette,
              compact: true,
              maxWeeks: 10,
              minWeeks: 10,
              fillHeight: true,
              footer: Text(
                peakDay == null
                    ? '7d ${PresentationFormatter.formatCompactNumber(month.trend7d.current)} • 30d ${PresentationFormatter.formatCompactNumber(month.trend30d.current)}'
                    : '7d ${PresentationFormatter.formatCompactNumber(month.trend7d.current)} • 30d ${PresentationFormatter.formatCompactNumber(month.trend30d.current)} • Peak ${peakDay.count} on ${_formatShortDate(peakDay.date)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: palette.textMuted,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RepoFocusShareCard extends StatelessWidget {
  final CachedContributionData data;
  final bool showBranding;
  final ShareExportFormat format;

  const RepoFocusShareCard({
    super.key,
    required this.data,
    required this.showBranding,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    final repo = _topRepository(data);
    if (repo == null) {
      return ShareCard(
        data: data,
        trend7d: data.days.isEmpty
            ? const TrendSummary(current: 0, previous: 0)
            : ContributionAnalyzer.computeTrend(
                data.days,
                window: 7,
                dateOf: (day) => day.date,
                countOf: (day) => day.contributionCount,
              ),
        trend30d: data.days.isEmpty
            ? const TrendSummary(current: 0, previous: 0)
            : ContributionAnalyzer.computeTrend(
                data.days,
                window: 30,
                dateOf: (day) => day.date,
                countOf: (day) => day.contributionCount,
              ),
        showBranding: showBranding,
        format: format,
      );
    }

    final accent =
        _repoAccentColor(repo, Theme.of(context).colorScheme.primary);
    final palette = _SharePalette.fromContext(
      context,
      accentOverride: accent,
    );
    final repoShare = data.totalContributions <= 0
        ? 0
        : ((repo.commitCount / data.totalContributions) * 100).round();
    final langName = repo.primaryLanguageName ??
        (repo.languages.isEmpty
            ? 'Mixed languages'
            : repo.languages.first.name);
    final remainingCommits = (data.totalContributions - repo.commitCount).clamp(
      0,
      data.totalContributions,
    );
    final activeRepoCount = data.activeRepositoriesCount;
    final trend7d = data.days.isEmpty
        ? const TrendSummary(current: 0, previous: 0)
        : ContributionAnalyzer.computeTrend(
            data.days,
            window: 7,
            dateOf: (day) => day.date,
            countOf: (day) => day.contributionCount,
          );
    final peakDay = ContributionAnalyzer.findPeakDay<ContributionDay>(
      data.days,
      dateOf: (day) => day.date,
      countOf: (day) => day.contributionCount,
    );
    return _TemplateSurface(
      format: format,
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShareCardHeader(
            title: _displayShareName(data.username),
            subtitle: activeRepoCount <= 1
                ? 'Repo focus'
                : 'Repo focus • $activeRepoCount active repos',
            icon: Icons.folder_open_rounded,
            showBranding: showBranding,
            compact: false,
            accent: accent,
          ),
          const SizedBox(height: 12),
          _RepoHeroCard(
            repoName: repo.nameWithOwner,
            commitCount: repo.commitCount,
            repoShare: repoShare,
            isPrivate: repo.isPrivate,
            accent: accent,
            compact: true,
          ),
          const SizedBox(height: 10),
          _MetricGroup(
            compact: false,
            children: [
              _MiniMetric(
                label: 'Repo commits',
                value: PresentationFormatter.formatCompactNumber(repo.commitCount),
                color: accent,
                icon: Icons.commit_rounded,
              ),
              _MiniMetric(
                label: 'Share of total',
                value: '$repoShare%',
                color: palette.secondaryAccent,
                icon: Icons.pie_chart_rounded,
              ),
              _MiniMetric(
                label: 'Language',
                value: langName,
                color: palette.tertiaryAccent,
                icon: Icons.code_rounded,
              ),
              _MiniMetric(
                label: 'Other repos',
                value: '${math.max(0, activeRepoCount - 1)}',
                color: accent,
                icon: Icons.account_tree_outlined,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _HeatmapPanel(
              title: 'Momentum heatmap',
              days: data.days,
              quartiles: data.quartiles,
              levels: palette.heatmapLevels,
              showLegend: false,
              palette: palette,
              compact: true,
              maxWeeks: 10,
              minWeeks: 10,
              fillHeight: true,
              footer: Text(
                peakDay == null
                    ? '7d ${PresentationFormatter.formatCompactNumber(trend7d.current)} • ${PresentationFormatter.formatCompactNumber(remainingCommits)} outside focus'
                    : '7d ${PresentationFormatter.formatCompactNumber(trend7d.current)} • ${PresentationFormatter.formatCompactNumber(remainingCommits)} outside focus • Peak ${peakDay.count} on ${_formatShortDate(peakDay.date)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: palette.textMuted,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlySnapshotStats {
  final String monthLabel;
  final int monthTotal;
  final int activeDays;
  final String bestWeekLabel;
  final int bestWeekTotal;
  final String topLanguageName;
  final List<ContributionDay> monthDays;
  final RepoContribution? topRepo;
  final TrendSummary trend7d;
  final TrendSummary trend30d;

  const _MonthlySnapshotStats({
    required this.monthLabel,
    required this.monthTotal,
    required this.activeDays,
    required this.bestWeekLabel,
    required this.bestWeekTotal,
    required this.topLanguageName,
    required this.monthDays,
    required this.topRepo,
    required this.trend7d,
    required this.trend30d,
  });

  factory _MonthlySnapshotStats.fromData(CachedContributionData data) {
    final now = DateTime.now().toLocal();
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);
    final monthDays = data.days.where((day) {
      final date = day.date.toLocal();
      return !date.isBefore(monthStart) && date.isBefore(nextMonthStart);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    var monthTotal = 0;
    var activeDays = 0;
    for (final day in monthDays) {
      monthTotal += day.contributionCount;
      if (day.contributionCount > 0) activeDays += 1;
    }

    final byKey = {
      for (final day in monthDays) day.dateKey: day.contributionCount
    };
    var bestWeekTotal = 0;
    DateTime? bestWeekStart;
    for (final anchor in monthDays) {
      final start =
          DateTime(anchor.date.year, anchor.date.month, anchor.date.day);
      var sum = 0;
      for (var offset = 0; offset < 7; offset++) {
        final date = start.add(Duration(days: offset));
        if (date.month != now.month || date.year != now.year) continue;
        sum += byKey[AppDateUtils.formatDate(date)] ?? 0;
      }
      if (sum >= bestWeekTotal) {
        bestWeekTotal = sum;
        bestWeekStart = start;
      }
    }

    final bestWeekLabel = bestWeekStart == null
        ? '?'
        : '${DateFormat('MMM d').format(bestWeekStart)} - ${DateFormat('MMM d').format(bestWeekStart.add(const Duration(days: 6)))}';

    return _MonthlySnapshotStats(
      monthLabel: DateFormat('MMMM yyyy').format(now),
      monthTotal: monthTotal,
      activeDays: activeDays,
      bestWeekLabel: bestWeekLabel,
      bestWeekTotal: bestWeekTotal,
      topLanguageName:
          data.topLanguages.isEmpty ? '' : data.topLanguages.first.name,
      monthDays: monthDays,
      topRepo: _topRepository(data),
      trend7d: ContributionAnalyzer.computeTrend(
        monthDays,
        window: 7,
        dateOf: (day) => day.date,
        countOf: (day) => day.contributionCount,
      ),
      trend30d: ContributionAnalyzer.computeTrend(
        monthDays,
        window: 30,
        dateOf: (day) => day.date,
        countOf: (day) => day.contributionCount,
      ),
    );
  }
}
