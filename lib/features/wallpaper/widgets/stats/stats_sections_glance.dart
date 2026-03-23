part of 'stats_sections.dart';

class StatsAtAGlanceGrid extends StatelessWidget {
  final int year;
  final int yearTotal;
  final List<ContributionDay> yearDays;
  final ContributionStats yearStats;
  final ContributionStats overallStats;
  final bool isCurrentYear;
  final bool canUseAdvancedStats;
  final VoidCallback onUnlockPro;

  const StatsAtAGlanceGrid({
    super.key,
    required this.year,
    required this.yearTotal,
    required this.yearDays,
    required this.yearStats,
    required this.overallStats,
    required this.isCurrentYear,
    required this.canUseAdvancedStats,
    required this.onUnlockPro,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    var activeDays = 0;
    var peakDay = 0;
    for (final d in yearDays) {
      if (d.contributionCount > 0) activeDays += 1;
      if (d.contributionCount > peakDay) peakDay = d.contributionCount;
    }

    final now = DateTime.now().toLocal();
    final yearStart = DateTime(year, 1, 1);
    final yearEnd = DateTime(year + 1, 1, 1);
    final effectiveEnd = isCurrentYear
        ? DateTime(now.year, now.month, now.day).add(const Duration(days: 1))
        : yearEnd;
    final measuredDays = effectiveEnd.difference(yearStart).inDays;
    final avgPerDay = measuredDays <= 0 ? 0 : yearTotal / measuredDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AT A GLANCE',
          style: tt.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        AppTheme.h12,
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppTheme.spacing12,
          crossAxisSpacing: AppTheme.spacing12,
          childAspectRatio: 1.0,
          children: [
            _AtAGlanceTile(
              icon: Icons.local_fire_department_outlined,
              color: scheme.primary,
              label: isCurrentYear ? 'Live Streak' : 'Year-end Streak',
              value:
                  '${isCurrentYear ? overallStats.currentStreak : yearStats.currentStreak}d',
            ),
            _AtAGlanceTile(
              icon: Icons.emoji_events_outlined,
              color: scheme.tertiary,
              label: 'Best in $year',
              value: '${yearStats.longestStreak}d',
              locked: !canUseAdvancedStats,
              onTap: onUnlockPro,
            ),
            _AtAGlanceTile(
              icon: Icons.calendar_month_outlined,
              color: AppTheme.primaryBlue,
              label: 'Active Days',
              value: '$activeDays',
            ),
            _AtAGlanceTile(
              icon: Icons.bolt_outlined,
              color: AppTheme.warningOrange,
              label: 'Peak Day',
              value: '$peakDay',
              locked: !canUseAdvancedStats,
              onTap: onUnlockPro,
            ),
            _AtAGlanceTile(
              icon: Icons.commit_rounded,
              color: scheme.primary,
              label: 'Total Commits',
              value: '$yearTotal',
            ),
            _AtAGlanceTile(
              icon: Icons.query_stats_outlined,
              color: scheme.secondary,
              label: 'Avg/Day',
              value: avgPerDay.toStringAsFixed(1),
              locked: !canUseAdvancedStats,
              onTap: onUnlockPro,
            ),
          ],
        ),
      ],
    );
  }
}

class _AtAGlanceTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool locked;
  final VoidCallback? onTap;

  const _AtAGlanceTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.locked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final tile = AppCard(
      padding: EdgeInsets.zero,
      child: Container(
        padding: AppTheme.pAll16,
        decoration: BoxDecoration(
          borderRadius: AppTheme.brLarge,
          border: Border.all(color: scheme.outlineVariant),
          color: color.withValues(alpha: 0.10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: AppTheme.iconMD, color: color),
            const Spacer(),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            AppTheme.h8,
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );

    if (!locked) {
      return tile;
    }

    return ClipRRect(
      borderRadius: AppTheme.brLarge,
      child: Stack(
        children: [
          IgnorePointer(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Opacity(
                opacity: 0.50,
                child: tile,
              ),
            ),
          ),
          Positioned.fill(
            child: Material(
              color: scheme.surface.withValues(alpha: 0.26),
              child: InkWell(
                onTap: onTap,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          size: AppTheme.iconSM,
                          color: scheme.primary,
                        ),
                        AppTheme.w6,
                        Text(
                          'Pro',
                          style: tt.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
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
