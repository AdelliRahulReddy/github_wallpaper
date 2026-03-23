part of 'share_card.dart';

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
