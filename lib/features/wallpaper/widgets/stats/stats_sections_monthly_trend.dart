part of 'stats_sections.dart';

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
