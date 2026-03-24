import 'dart:ui';

import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/features/membership/pages/membership_paywall_page.dart';
import 'package:github_wallpaper/features/contributions/pages/wrapped_page.dart';
import 'package:github_wallpaper/core/ui/app_components.dart';
import 'package:intl/intl.dart';



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

class StatsYearHeatmapCard extends StatelessWidget {
  final CachedContributionData data;
  final int year;
  final ValueChanged<ContributionDay> onDayTap;

  const StatsYearHeatmapCard({
    super.key,
    required this.data,
    required this.year,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final levels = AppThemeExt.of(context).heatmapLevels;
    final yearDays = [
      for (final day in data.days)
        if (day.date.toLocal().year == year) day,
    ];
    final yearQuartiles = RenderUtils.calculateQuartiles(
      yearDays.map((day) => day.contributionCount).toList(),
    );
    final yearStart = DateTime(year, 1, 1);
    final yearEnd = DateTime(year, 12, 31);
    final gridStart =
        yearStart.subtract(Duration(days: yearStart.weekday - 1));
    final gridEnd = yearEnd.add(Duration(days: DateTime.daysPerWeek - yearEnd.weekday));
    final totalGridDays = gridEnd.difference(gridStart).inDays + 1;
    final weekCount = (totalGridDays / DateTime.daysPerWeek).ceil();
    final byKey = {for (final day in data.days) day.dateKey: day};

    var yearTotal = 0;
    var activeDays = 0;
    for (final day in data.days) {
      final date = day.date.toLocal();
      if (date.year != year) continue;
      yearTotal += day.contributionCount;
      if (day.contributionCount > 0) activeDays += 1;
    }

    const cellSize = 13.0;
    const cellGap = 4.0;
    const labelWidth = 26.0;
    final columnWidth = cellSize + cellGap;
    final gridWidth = weekCount * columnWidth;

    final monthHeaders = <Widget>[];
    for (var week = 0; week < weekCount; week++) {
      final weekStart = gridStart.add(Duration(days: week * 7));
      String label = '';
      for (var offset = 0; offset < 7; offset++) {
        final date = weekStart.add(Duration(days: offset));
        if (date.year == year && date.day == 1) {
          label = DateFormat('MMM').format(date);
          break;
        }
      }
      monthHeaders.add(
        SizedBox(
          width: columnWidth,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: tt.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YEAR HEATMAP',
          style: tt.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        AppTheme.h12,
        AppCard(
          padding: AppTheme.pAll16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$activeDays active days',
                      style: tt.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '$yearTotal commits',
                    style: tt.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              AppTheme.h12,
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: labelWidth + gridWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: labelWidth),
                          ...monthHeaders,
                        ],
                      ),
                      AppTheme.h8,
                      for (var weekday = 0; weekday < 7; weekday++) ...[
                        Row(
                          children: [
                            SizedBox(
                              width: labelWidth,
                              child: Text(
                                weekday.isEven
                                    ? DateFormat('EEE').format(
                                        DateTime(2024, 1, weekday + 1),
                                      )
                                    : '',
                                style: tt.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            for (var week = 0; week < weekCount; week++)
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: cellGap,
                                  bottom: cellGap,
                                ),
                                child: _StatsHeatCell(
                                  size: cellSize,
                                  date: gridStart.add(
                                    Duration(days: week * 7 + weekday),
                                  ),
                                  year: year,
                                  quartiles: yearQuartiles,
                                  levels: levels,
                                  dayOf: (date) =>
                                      byKey[AppDateUtils.formatDate(date)],
                                  onTap: onDayTap,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              AppTheme.h8,
              Row(
                children: [
                  Text(
                    'Less',
                    style: tt.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  AppTheme.w8,
                  for (var i = 0; i < levels.length; i++) ...[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: levels[i],
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                    ),
                    if (i != levels.length - 1) AppTheme.w6,
                  ],
                  AppTheme.w8,
                  Text(
                    'More',
                    style: tt.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsHeatCell extends StatelessWidget {
  final double size;
  final DateTime date;
  final int year;
  final Quartiles quartiles;
  final List<Color> levels;
  final ContributionDay? Function(DateTime date) dayOf;
  final ValueChanged<ContributionDay> onTap;

  const _StatsHeatCell({
    required this.size,
    required this.date,
    required this.year,
    required this.quartiles,
    required this.levels,
    required this.dayOf,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (date.year != year) {
      return SizedBox(width: size, height: size);
    }

    final day = dayOf(date);
    final count = day?.contributionCount ?? 0;
    final level = count <= 0
        ? 0
        : RenderUtils.getContributionLevel(count, quartiles: quartiles)
            .clamp(0, levels.length - 1);

    final cell = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: levels[level],
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: scheme.outlineVariant),
      ),
    );

    if (day == null) return cell;
    return Tooltip(
      message:
          '${DateFormat('d MMM yyyy').format(date)}: ${day.contributionCount} contribution${day.contributionCount == 1 ? '' : 's'}',
      child: InkWell(
        borderRadius: BorderRadius.circular(3),
        onTap: () => onTap(day),
        child: cell,
      ),
    );
  }
}

class StatsWeeklyBreakdownCard extends StatelessWidget {
  final CachedContributionData data;
  final int year;

  const StatsWeeklyBreakdownCard(
      {super.key, required this.data, required this.year});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final now = DateTime.now().toLocal();
    final isCurrentYear = year == now.year;
    final end = year == now.year
        ? DateTime(now.year, now.month, now.day)
        : DateTime(year, 12, 31);
    final endWeekStart = end.subtract(Duration(days: end.weekday - 1));

    final weekStarts = List.generate(
      8,
      (i) => endWeekStart.subtract(Duration(days: (7 - i) * 7)),
    );

    final values = <int>[];
    for (final ws in weekStarts) {
      var sum = 0;
      for (var i = 0; i < 7; i++) {
        sum += data.getContributionsForDate(ws.add(Duration(days: i)));
      }
      values.add(sum);
    }

    var bestIndex = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[bestIndex]) bestIndex = i;
    }
    final bestStart = weekStarts[bestIndex];
    final bestEnd = bestStart.add(const Duration(days: 6));
    final bestLabel =
        '${DateFormat('MMM d').format(bestStart)}–${DateFormat('MMM d').format(bestEnd)}';
    final bestValue = values[bestIndex];

    final maxY = values.fold<int>(1, (a, b) => max(a, b)).toDouble();

    final groups = <BarChartGroupData>[
      for (var i = 0; i < values.length; i++)
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: values[i].toDouble(),
              width: 10,
              color: i == bestIndex
                  ? scheme.primary
                  : scheme.primary.withValues(alpha: 0.35),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
          ],
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isCurrentYear ? 'LAST 8 WEEKS' : 'LAST 8 WEEKS OF $year',
          style: tt.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        AppTheme.h12,
        AppCard(
          padding: AppTheme.pAll16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 210,
                child: BarChart(
                  BarChartData(
                    maxY: maxY <= 0 ? 1 : maxY,
                    minY: 0,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: groups,
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (v, meta) {
                            final i = v.toInt();
                            if (i < 0 || i >= weekStarts.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('MMM d').format(weekStarts[i]),
                                style: tt.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AppTheme.h12,
              Text(
                isCurrentYear
                    ? '🏆 Best recent week: $bestLabel with $bestValue commits'
                    : '🏆 Strongest late-year week: $bestLabel with $bestValue commits',
                style: tt.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppTheme.h8,
              Text(
                isCurrentYear
                    ? 'Shows the latest 8 weeks ending today.'
                    : 'Shows the last 8 weeks of $year, not the full year.',
                style: tt.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

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

class StatsTopLanguagesCard extends StatelessWidget {
  final List<LanguageUsage> langs;

  const StatsTopLanguagesCard({super.key, required this.langs});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final list = langs.take(7).toList();
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT TOP LANGUAGES',
          style: tt.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        AppTheme.h12,
        AppCard(
          padding: AppTheme.pAll16,
          child: Column(
            children: [
              for (var i = 0; i < list.length; i++) ...[
                _LangRow(lang: list[i]),
                if (i != list.length - 1)
                  Divider(height: 20, color: scheme.outlineVariant),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LangRow extends StatelessWidget {
  final LanguageUsage lang;

  const _LangRow({required this.lang});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = AppColorUtils.parseHexColor(lang.color) ?? scheme.primary;
    final pct = (lang.percent * 100).clamp(0, 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            AppTheme.w12,
            Expanded(
              child: Text(lang.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            Text('$pct%',
                style: tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
        AppTheme.h10,
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: lang.percent.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: scheme.surfaceContainerHighest,
            color: color,
          ),
        ),
      ],
    );
  }
}

class StatsTopReposCard extends StatelessWidget {
  final List<RepoContribution> repos;

  const StatsTopReposCard({super.key, required this.repos});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final list = repos.where((r) => r.commitCount > 0).toList()
      ..sort((a, b) => b.commitCount.compareTo(a.commitCount));
    final top = list.take(6).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT TOP REPOS',
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
              for (var i = 0; i < top.length; i++) ...[
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColorUtils.parseHexColor(
                              top[i].primaryLanguageColor) ??
                          scheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  title: Row(
                    children: [
                      if (top[i].isPrivate) ...[
                        Icon(Icons.lock_outline_rounded,
                            size: AppTheme.iconSM,
                            color: scheme.onSurfaceVariant),
                        AppTheme.w6,
                      ],
                      Expanded(
                        child: Text(
                          top[i].nameWithOwner,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: top[i].primaryLanguageName == null
                      ? null
                      : Text(top[i].primaryLanguageName!,
                          style: tt.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                  trailing: Text(
                    '${top[i].commitCount}',
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (i != top.length - 1)
                  Divider(height: 1, color: scheme.outlineVariant),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class StatsYearWrappedCtaCard extends StatelessWidget {
  final CachedContributionData data;
  final bool locked;

  const StatsYearWrappedCtaCard({
    super.key,
    required this.data,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final now = DateTime.now().toLocal();
    final from = now.subtract(const Duration(days: 365));
    final totals = <DateTime, int>{};
    for (final d in data.days) {
      final dt = d.date.toLocal();
      if (dt.isBefore(from) || dt.isAfter(now)) continue;
      final key = DateTime(dt.year, dt.month, 1);
      totals[key] = (totals[key] ?? 0) + d.contributionCount;
    }
    DateTime? bestMonthKey;
    for (final entry in totals.entries) {
      if (bestMonthKey == null ||
          entry.value > (totals[bestMonthKey] ?? 0)) {
        bestMonthKey = entry.key;
      }
    }
    final bestMonth =
        bestMonthKey == null ? '—' : DateFormat('MMMM').format(bestMonthKey);
    final topLang =
        data.topLanguages.isEmpty ? '—' : data.topLanguages.first.name;
    final longest = '${data.stats.longestStreak}d';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT WRAPPED',
          style: tt.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        AppTheme.h12,
        AppCard(
          padding: EdgeInsets.zero,
          child: Container(
            padding: AppTheme.pAll20,
            decoration: BoxDecoration(
              borderRadius: AppTheme.brLarge,
              border: Border.all(color: scheme.outlineVariant),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary.withValues(alpha: 0.18),
                  scheme.surfaceContainerHighest,
                ],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        locked ? 'Wrapped Preview' : 'Last 365 Days',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (locked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Locked',
                          style: tt.labelSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                AppTheme.h16,
                Row(
                  children: [
                    Expanded(
                      child: _TeaserStat(
                        label: 'Best Month',
                        value: bestMonth,
                      ),
                    ),
                    AppTheme.w12,
                    Expanded(
                      child: _TeaserStat(
                        label: 'Top Lang',
                        value: topLang,
                      ),
                    ),
                    AppTheme.w12,
                    Expanded(
                      child: _TeaserStat(
                        label: 'Longest',
                        value: longest,
                      ),
                    ),
                  ],
                ),
                AppTheme.h16,
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => locked
                              ? const MembershipPaywallPage(
                                  featureName: 'Wrapped',
                                  featureDescription:
                                      'GitWall Wrapped is a Pro feature with the yearly recap and share flow.',
                                )
                              : WrappedPage(
                                  data: data,
                                  username: data.username,
                                ),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      padding: AppTheme.pSymV16,
                    ),
                    child: Text(locked ? 'Unlock Wrapped' : 'View My Wrapped'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TeaserStat extends StatelessWidget {
  final String label;
  final String value;

  const _TeaserStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        AppTheme.h6,
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class StatsRecentActivityFeedCard extends StatelessWidget {
  final List<ContributionDay> days;

  const StatsRecentActivityFeedCard({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = MaterialLocalizations.of(context);

    final sorted = List<ContributionDay>.from(days)
      ..sort((a, b) => b.date.compareTo(a.date));
    final active =
        sorted.where((d) => d.contributionCount > 0).take(10).toList();
    if (active.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Activity feed',
          subtitle: 'Your latest active days',
        ),
        AppTheme.h12,
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < active.length; i++) ...[
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: Icon(Icons.bolt_outlined,
                      size: AppTheme.iconMD, color: scheme.secondary),
                  title: Text(loc.formatShortMonthDay(active[i].date),
                      style: tt.bodyMedium),
                  trailing: Text(
                    '${active[i].contributionCount}',
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (i != active.length - 1)
                  Divider(color: Theme.of(context).dividerColor, indent: 56),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class StatsMonthlyTrendCard extends StatelessWidget {
  final int year;
  final List<int> thisYear;
  final List<int> lastYear;

  const StatsMonthlyTrendCard({
    super.key,
    required this.year,
    required this.thisYear,
    required this.lastYear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final maxY = <int>[...thisYear, ...lastYear]
        .fold<int>(1, (a, b) => max(a, b))
        .toDouble();
    final groups = <BarChartGroupData>[
      for (var i = 0; i < 12; i++)
        BarChartGroupData(
          x: i,
          barsSpace: 4,
          barRods: [
            BarChartRodData(
              toY: thisYear[i].toDouble(),
              width: 7,
              color: scheme.primary,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(6)),
            ),
            BarChartRodData(
              toY: lastYear[i].toDouble(),
              width: 7,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
        ),
    ];

    final now = DateTime.now().toLocal();
    final currentMonthIndex =
        year == now.year ? (now.month - 1).clamp(0, 11) : 11;
    final prev = currentMonthIndex == 0
        ? lastYear[11]
        : thisYear[currentMonthIndex - 1];
    final curr = thisYear[currentMonthIndex];
    final pct = prev == 0 ? null : ((curr - prev) / prev) * 100.0;
    final pctLabel = pct == null
        ? '—'
        : '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(0)}% vs last month';
    final pctColor = pct == null
        ? scheme.onSurfaceVariant
        : (pct >= 0 ? scheme.primary : scheme.error);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MONTHLY TREND',
          style: tt.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        AppTheme.h12,
        AppCard(
          padding: AppTheme.pAll16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    maxY: maxY <= 0 ? 1 : maxY,
                    minY: 0,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: groups,
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index > 11) {
                              return const SizedBox.shrink();
                            }
                            const labels = [
                              'J',
                              'F',
                              'M',
                              'A',
                              'M',
                              'J',
                              'J',
                              'A',
                              'S',
                              'O',
                              'N',
                              'D',
                            ];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                labels[index],
                                style: tt.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AppTheme.h12,
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing12,
                      vertical: AppTheme.spacing8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: pctColor.withValues(alpha: 0.14),
                      border:
                          Border.all(color: pctColor.withValues(alpha: 0.30)),
                    ),
                    child: Text(
                      pctLabel,
                      style: tt.bodySmall?.copyWith(
                        color: pctColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _LegendDot(color: scheme.primary, label: '$year'),
                      AppTheme.w12,
                      _LegendDot(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
                        label: '${year - 1}',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        AppTheme.w6,
        Text(
          label,
          style: tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}


