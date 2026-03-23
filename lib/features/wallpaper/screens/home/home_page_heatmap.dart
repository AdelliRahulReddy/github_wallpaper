part of 'home_page.dart';

class _HomeQuoteCard extends StatelessWidget {
  const _HomeQuoteCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final quote = DailyQuoteService.today();

    return AppCard(
      padding: EdgeInsets.zero,
      child: Container(
        padding: AppTheme.pAll20,
        decoration: BoxDecoration(
          borderRadius: AppTheme.brLarge,
          border: Border.all(color: scheme.outlineVariant),
          color: scheme.surfaceContainerHighest,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: AppTheme.spacing48,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            AppTheme.w16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.format_quote_rounded,
                      size: AppTheme.iconSM, color: scheme.primary),
                  AppTheme.h10,
                  Text(
                    quote,
                    style: tt.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: scheme.onSurface.withValues(alpha: 0.88),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekDayCell extends StatelessWidget {
  final DateTime date;
  final String label;
  final ContributionDay? day;
  final List<Color> levels;
  final Quartiles quartiles;
  final void Function(ContributionDay day) onTap;

  const _WeekDayCell({
    required this.date,
    required this.label,
    required this.day,
    required this.levels,
    required this.quartiles,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final count = day?.contributionCount ?? 0;
    final lvl = count <= 0
        ? 0
        : RenderUtils.getContributionLevel(count, quartiles: quartiles)
            .clamp(0, 4);
    final bg = levels[lvl];

    final box = Container(
      width: AppTheme.spacing40,
      padding: EdgeInsets.symmetric(vertical: AppTheme.spacing12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Center(
        child: Text(
          count == 0 ? '' : '$count',
          style: tt.bodySmall?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        day == null
            ? box
            : InkWell(
                onTap: () => onTap(day!),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: box,
              ),
        AppTheme.h6,
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontSize: AppTheme.fontCaption,
          ),
        ),
      ],
    );
  }
}

class _HomeLast30DaysGridSection extends StatelessWidget {
  final CachedContributionData data;

  const _HomeLast30DaysGridSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final levels = AppThemeExt.of(context).heatmapLevels;

    final byKey = {for (final d in data.days) d.dateKey: d};
    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final dates =
        List.generate(30, (i) => today.subtract(Duration(days: 29 - i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LAST 30 DAYS',
          style: tt.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        AppTheme.h12,
        AppCard(
          padding: AppTheme.pAll20,
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  const cols = 6;
                  const gap = 6.0;
                  final cell =
                      ((constraints.maxWidth - (cols - 1) * gap) / cols)
                          .clamp(12.0, 18.0);
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final d in dates)
                        _HeatCell(
                          size: cell,
                          day: byKey[AppDateUtils.formatDate(d)],
                          levels: levels,
                          quartiles: data.quartiles,
                        ),
                    ],
                  );
                },
              ),
              AppTheme.h16,
              Row(
                children: [
                  Text('Less',
                      style: tt.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                  const Spacer(),
                  for (var i = 0; i < 4; i++) ...[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: levels[i + 1],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    if (i != 3) AppTheme.w6,
                  ],
                  const Spacer(),
                  Text('More',
                      style: tt.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeatCell extends StatelessWidget {
  final double size;
  final ContributionDay? day;
  final List<Color> levels;
  final Quartiles quartiles;

  const _HeatCell({
    required this.size,
    required this.day,
    required this.levels,
    required this.quartiles,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = day?.contributionCount ?? 0;
    final lvl = count <= 0
        ? 0
        : RenderUtils.getContributionLevel(count, quartiles: quartiles)
            .clamp(0, 4);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: levels[lvl],
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: scheme.outlineVariant),
      ),
    );
  }
}
