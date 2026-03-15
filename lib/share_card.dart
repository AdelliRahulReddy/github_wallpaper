import 'package:flutter/material.dart';
import 'package:github_wallpaper/app_models.dart';
import 'package:github_wallpaper/app_services.dart';
import 'package:github_wallpaper/app_state.dart';
import 'package:github_wallpaper/app_theme.dart';
import 'package:github_wallpaper/app_utils.dart';

class ShareCard extends StatelessWidget {
  final CachedContributionData data;
  final TrendSummary trend7d;
  final TrendSummary trend30d;

  const ShareCard({
    super.key,
    required this.data,
    required this.trend7d,
    required this.trend30d,
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surface,
            scheme.surfaceContainerHighest,
          ],
        ),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.45)),
        boxShadow: AppTheme.shadow(scheme.shadow, opacity: 0.12),
      ),
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
                  border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
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
              Container(
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
              ),
            ],
          ),
          const SizedBox(height: 16),
          _HeroRow(
            label: AppStrings.totalContributions,
            value: PresentationFormatter.formatCompactNumber(data.totalContributions),
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
                  value: PresentationFormatter.formatCompactNumber(trend7d.current),
                  helper: trend7d.deltaLabel,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TrendMetric(
                  label: AppStrings.trend30d,
                  value: PresentationFormatter.formatCompactNumber(trend30d.current),
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
              border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last 30 days',
                  style: TextStyle(
                    fontSize: AppTheme.fontCaption,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 56,
                  child: _Bars(values: _last30(data)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<int> _last30(CachedContributionData data) {
    final days = data.days;
    if (days.isEmpty) return const [];
    final sorted = List<ContributionDay>.from(days)
      ..sort((a, b) => a.date.compareTo(b.date));
    final start = (sorted.length - 30).clamp(0, sorted.length);
    return sorted.sublist(start).map((d) => d.contributionCount).toList();
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
              Container(
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bars extends StatelessWidget {
  final List<int> values;
  const _Bars({required this.values});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (values.isEmpty) {
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
    final maxV = values.reduce((a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final v in values) ...[
          Expanded(
            child: Container(
              height: maxV <= 0 ? 2 : (54 * (v / maxV)).clamp(2, 54).toDouble(),
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: v == 0
                    ? scheme.outline.withValues(alpha: 0.25)
                    : scheme.primary.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
