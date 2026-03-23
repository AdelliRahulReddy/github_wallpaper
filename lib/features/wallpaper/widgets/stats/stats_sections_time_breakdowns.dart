part of 'stats_sections.dart';

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
