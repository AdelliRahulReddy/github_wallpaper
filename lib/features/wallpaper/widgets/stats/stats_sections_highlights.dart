part of 'stats_sections.dart';

class StatsStreakHistoryCard extends StatelessWidget {
  final int year;
  final List<ContributionDay> allDays;
  final List<ContributionDay> yearDays;
  final ContributionStats yearStats;
  final ContributionStats overallStats;
  final bool isCurrentYear;

  const StatsStreakHistoryCard({
    super.key,
    required this.year,
    required this.allDays,
    required this.yearDays,
    required this.yearStats,
    required this.overallStats,
    required this.isCurrentYear,
  });

  int _countStreaksOver(List<ContributionDay> days, int threshold) {
    final sorted = List<ContributionDay>.from(days)
      ..sort((a, b) => a.date.compareTo(b.date));
    var run = 0;
    DateTime? last;
    var count = 0;
    for (final d in sorted) {
      final date = DateTime(d.date.year, d.date.month, d.date.day);
      if (d.contributionCount > 0) {
        if (last == null || date.difference(last).inDays == 1) {
          run += 1;
        } else {
          if (run >= threshold) count += 1;
          run = 1;
        }
      } else {
        if (run >= threshold) count += 1;
        run = 0;
      }
      last = date;
    }
    if (run >= threshold) count += 1;
    return count;
  }

  (int, DateTime?) _bestStreak(List<ContributionDay> days) {
    final sorted = List<ContributionDay>.from(days)
      ..sort((a, b) => a.date.compareTo(b.date));
    var run = 0;
    var best = 0;
    DateTime? last;
    DateTime? bestEnd;
    for (final d in sorted) {
      final date = DateTime(d.date.year, d.date.month, d.date.day);
      if (d.contributionCount > 0) {
        if (last == null || date.difference(last).inDays == 1) {
          run += 1;
        } else {
          run = 1;
        }
        if (run > best) {
          best = run;
          bestEnd = date;
        }
      } else {
        run = 0;
      }
      last = date;
    }
    return (best, bestEnd);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final (bestEverLen, bestEverEnd) = _bestStreak(allDays);
    final (bestYearLen, bestYearEnd) = _bestStreak(yearDays);
    final streaks7 = _countStreaksOver(yearDays, 7);

    final bestEverSuffix = bestEverEnd == null
        ? ''
        : ' · ${DateFormat('MMM yyyy').format(bestEverEnd)}';
    final bestYearSuffix = bestYearEnd == null
        ? ''
        : ' · ${DateFormat('MMM yyyy').format(bestYearEnd)}';

    Widget row({
      required IconData icon,
      required Color iconColor,
      required String label,
      required String value,
      Widget? trailing,
    }) {
      return Padding(
        padding: AppTheme.pAll16,
        child: Row(
          children: [
            Icon(icon, size: AppTheme.iconMD, color: iconColor),
            AppTheme.w12,
            Expanded(
              child: Text(label,
                  style: tt.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  )),
            ),
            Text(value,
                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
            if (trailing != null) ...[
              AppTheme.w12,
              trailing,
            ]
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STREAK HISTORY',
          style: tt.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        AppTheme.h12,
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              row(
                icon: Icons.local_fire_department_outlined,
                iconColor: scheme.primary,
                label: isCurrentYear ? 'Live streak' : 'Ending streak',
                value:
                    '${isCurrentYear ? overallStats.currentStreak : yearStats.currentStreak} days',
                trailing: isCurrentYear
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: scheme.primary.withValues(alpha: 0.14),
                          border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          'running',
                          style: tt.bodySmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : null,
              ),
              Divider(height: 1, color: scheme.outlineVariant),
              row(
                icon: Icons.emoji_events_outlined,
                iconColor: scheme.tertiary,
                label: 'Best (last 12 months)',
                value:
                    '${max(overallStats.longestStreak, bestEverLen)} days$bestEverSuffix',
              ),
              Divider(height: 1, color: scheme.outlineVariant),
              row(
                icon: Icons.calendar_month_outlined,
                iconColor: AppTheme.primaryBlue,
                label: 'Best in $year',
                value: '$bestYearLen days$bestYearSuffix',
              ),
              Divider(height: 1, color: scheme.outlineVariant),
              Padding(
                padding: AppTheme.pAll16,
                child: Text(
                  isCurrentYear
                      ? "You've had $streaks7 streaks of 7+ days this year"
                      : "You had $streaks7 streaks of 7+ days in $year",
                  style: tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StatsMostActiveDaysCard extends StatelessWidget {
  final List<ContributionDay> yearDays;
  final int year;

  const StatsMostActiveDaysCard({
    super.key,
    required this.yearDays,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final totals = List<int>.filled(7, 0);
    for (final d in yearDays) {
      final w = d.date.toLocal().weekday - 1;
      totals[w] += d.contributionCount;
    }
    var best = 0;
    for (var i = 1; i < totals.length; i++) {
      if (totals[i] > totals[best]) best = i;
    }
    final hasActivity = totals.any((value) => value > 0);
    final maxV = hasActivity
        ? totals.fold<int>(1, (a, b) => max(a, b)).toDouble()
        : 1.0;
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MOST ACTIVE DAYS',
          style: tt.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        AppTheme.h12,
        AppCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 7; i++) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(labels[i],
                          style: tt.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: maxV <= 0 ? 0 : totals[i] / maxV,
                          minHeight: 8,
                          backgroundColor: scheme.surfaceContainerHighest,
                          color: hasActivity && i == best
                              ? scheme.primary
                              : scheme.primary.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    AppTheme.w10,
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${totals[i]}',
                        textAlign: TextAlign.right,
                        style: tt.bodySmall?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (hasActivity && i == best) ...[
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 14,
                        child: Icon(
                          Icons.emoji_events_rounded,
                          size: 14,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                if (i != 6) AppTheme.h10,
              ],
              if (!hasActivity) ...[
                AppTheme.h12,
                Text(
                  'No active weekdays in $year yet.',
                  style: tt.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
