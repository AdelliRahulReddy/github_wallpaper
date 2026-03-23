part of 'stats_page.dart';

class _StatsHeaderSummary extends StatelessWidget {
  final String subtitle;
  final bool isCurrentYear;

  const _StatsHeaderSummary({
    required this.subtitle,
    required this.isCurrentYear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
          child: Text(
            subtitle,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: AppTheme.fontBody,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: AppTheme.pAll12,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: AppTheme.brMedium,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Text(
            isCurrentYear
                ? 'Based on the last 12 months of GitHub activity.'
                : 'Based on the last 12 months of GitHub activity. Some insights are current-year only.',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: AppTheme.fontCaption,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsCurrentYearOnlyNoticeCard extends StatelessWidget {
  const _StatsCurrentYearOnlyNoticeCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return AppCard(
      padding: AppTheme.pAll16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: scheme.onSurfaceVariant,
            size: AppTheme.iconMD,
          ),
          AppTheme.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current-year only insights',
                  style: tt.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                AppTheme.h4,
                Text(
                  'Top Languages, Top Repos, and Wrapped are available on the current-year view only.',
                  style: tt.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
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
