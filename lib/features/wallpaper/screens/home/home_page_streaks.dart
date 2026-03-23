part of 'home_page.dart';

class _HomeWeeklyGoalCard extends StatelessWidget {
  final CachedContributionData data;
  final int weeklyGoal;

  const _HomeWeeklyGoalCard({required this.data, required this.weeklyGoal});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: today.weekday - 1));
    final weeklyTotal = data.days.where((d) {
      final dt = d.date.toLocal();
      final day = DateTime(dt.year, dt.month, dt.day);
      return !day.isBefore(start) && !day.isAfter(today);
    }).fold<int>(0, (s, d) => s + d.contributionCount);

    final safeWeeklyGoal = weeklyGoal.clamp(5, 100);
    final progress = (weeklyTotal / safeWeeklyGoal).clamp(0.0, 1.0);
    final remaining = (safeWeeklyGoal - weeklyTotal).clamp(0, safeWeeklyGoal);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Container(
        padding: AppTheme.pAll20,
        decoration: BoxDecoration(
          borderRadius: AppTheme.brLarge,
          border: Border.all(color: scheme.outlineVariant),
          color: scheme.primary.withValues(alpha: 0.10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events_outlined,
                    size: 18, color: scheme.primary),
                AppTheme.w12,
                Expanded(
                  child: Text('WEEKLY GOAL',
                      style: tt.labelSmall?.copyWith(
                        color: scheme.primary,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w800,
                      )),
                ),
                Text('$weeklyTotal/$safeWeeklyGoal commits',
                    style: tt.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
            AppTheme.h12,
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            AppTheme.h12,
            Text(
              remaining == 0
                  ? 'Goal hit this week! 💪'
                  : '$remaining more commits to hit your goal! 💪',
              style: tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeCurrentStreakCard extends StatelessWidget {
  final CachedContributionData data;

  const _HomeCurrentStreakCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final current = data.stats.currentStreak;
    final best = data.stats.longestStreak;
    final progress = best <= 0 ? 0.0 : (current / best).clamp(0.0, 1.0);
    final remaining = (best - current).clamp(0, best);
    final helperText = best <= 0
        ? 'Start your first streak today.'
        : remaining == 0
            ? 'You matched your best!'
            : '$remaining days away from your best!';

    return AppCard(
      padding: AppTheme.pAll20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Current Streak 🔥',
                  style: tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              Text('Best',
                  style:
                      tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              AppTheme.w8,
              Text('${best}d',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          AppTheme.h12,
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$current',
                style: tt.displaySmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              AppTheme.w8,
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('days',
                    style: tt.titleMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ),
            ],
          ),
          AppTheme.h12,
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: scheme.surfaceContainerHighest,
              color: scheme.primary,
            ),
          ),
          AppTheme.h12,
          Text(
            helperText,
            style: tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _HomeJourneySnapshotCard extends StatelessWidget {
  final CachedContributionData data;

  const _HomeJourneySnapshotCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final metrics = [
      (
        label: 'Total',
        value: PresentationFormatter.formatCompactNumber(
          data.totalContributions,
        ),
      ),
      (
        label: 'Active Days',
        value: '${data.stats.activeDaysCount}',
      ),
      (
        label: 'Peak Day',
        value: '${data.stats.peakDayContributions}',
      ),
    ];

    return AppCard(
      padding: AppTheme.pAll20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'JOURNEY SNAPSHOT',
            style: tt.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          AppTheme.h12,
          Row(
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                Expanded(
                  child: _SnapshotMetric(
                    label: metrics[i].label,
                    value: metrics[i].value,
                  ),
                ),
                if (i != metrics.length - 1) ...[
                  SizedBox(
                    height: AppTheme.spacing32,
                    child: VerticalDivider(
                      color: scheme.outlineVariant,
                      thickness: AppTheme.borderWidthHairline,
                    ),
                  ),
                  AppTheme.w8,
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SnapshotMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SnapshotMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        AppTheme.h8,
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _HomeWeekStripSection extends StatelessWidget {
  final CachedContributionData data;
  final void Function(ContributionDay day) onDayTap;

  const _HomeWeekStripSection({required this.data, required this.onDayTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final levels = AppThemeExt.of(context).heatmapLevels;

    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final byKey = {for (final d in data.days) d.dateKey: d};
    final weekDates = List.generate(
      7,
      (i) => today.subtract(Duration(days: 6 - i)),
    );
    final activeDays = weekDates.where((d) {
      final key = AppDateUtils.formatDate(d);
      return (byKey[key]?.contributionCount ?? 0) > 0;
    }).length;

    final labels = weekDates.map((d) => DateFormat('EEE').format(d)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THIS WEEK',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
        ),
        AppTheme.h12,
        AppCard(
          padding: AppTheme.pAll20,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < weekDates.length; i++)
                    _WeekDayCell(
                      date: weekDates[i],
                      label: labels[i],
                      day: byKey[AppDateUtils.formatDate(weekDates[i])],
                      levels: levels,
                      quartiles: data.quartiles,
                      onTap: onDayTap,
                    ),
                ],
              ),
              AppTheme.h12,
              Text(
                '$activeDays of 7 days active',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
