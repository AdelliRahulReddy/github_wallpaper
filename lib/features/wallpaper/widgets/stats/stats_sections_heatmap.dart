part of 'stats_sections.dart';

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
