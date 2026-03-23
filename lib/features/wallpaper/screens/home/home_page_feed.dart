part of 'home_page.dart';

class _HomeRecentActivityFeedCard extends StatelessWidget {
  final CachedContributionData data;
  final int limit;

  const _HomeRecentActivityFeedCard({required this.data, required this.limit});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = MaterialLocalizations.of(context);

    final byKey = {for (final d in data.days) d.dateKey: d};
    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final recent = <ContributionDay>[];
    for (var i = 0;
        i < AppConstants.githubDataFetchDays && recent.length < limit;
        i++) {
      final date = today.subtract(Duration(days: i));
      final day = byKey[AppDateUtils.formatDate(date)];
      if (day != null && day.contributionCount > 0) recent.add(day);
    }

    if (recent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT ACTIVITY',
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
              for (var i = 0; i < recent.length; i++) ...[
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: Icon(Icons.bolt_outlined,
                      size: AppTheme.iconMD, color: scheme.tertiary),
                  title: Text(loc.formatShortMonthDay(recent[i].date),
                      style: tt.bodyMedium),
                  trailing: Text(
                    recent[i].contributionCount == 1
                        ? '1 commit'
                        : '${recent[i].contributionCount} commits',
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (i != recent.length - 1)
                  Divider(color: Theme.of(context).dividerColor, indent: 56),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeTodayHeroCard extends StatelessWidget {
  final CachedContributionData data;
  final bool isLoading;
  final bool isSharing;
  final Future<void> Function() onRefresh;
  final VoidCallback onShare;

  const _HomeTodayHeroCard({
    required this.data,
    required this.isLoading,
    required this.isSharing,
    required this.onRefresh,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final today = data.stats.todayContributions;
    final streak = data.stats.currentStreak;
    final streakLabel = streak > 0
        ? 'Streak alive - $streak days'
        : 'Start your streak today';

    return AppCard(
      padding: AppTheme.pAll20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TODAY',
            style: tt.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          AppTheme.h12,
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    '$today',
                    style: tt.displayLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              AppTheme.w12,
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'commits',
                  style: tt.titleMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          AppTheme.h16,
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing12,
              vertical: AppTheme.spacing8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: scheme.primary.withValues(alpha: 0.16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department_outlined,
                    size: AppTheme.iconSM, color: scheme.primary),
                AppTheme.w8,
                Flexible(
                  child: Text(
                    streakLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodyMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppTheme.h16,
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : onRefresh,
                  icon: isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onSurfaceVariant,
                          ),
                        )
                      : Icon(Icons.refresh_rounded,
                          size: AppTheme.iconSM, color: scheme.onSurface),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    padding: AppTheme.pSymV16,
                    side: BorderSide(color: scheme.outlineVariant),
                    foregroundColor: scheme.onSurface,
                  ),
                ),
              ),
              AppTheme.w12,
              Expanded(
                child: FilledButton.icon(
                  onPressed: isSharing ? null : onShare,
                  icon: const Icon(Icons.ios_share_rounded,
                      size: AppTheme.iconSM),
                  label: const Text('Share'),
                  style: FilledButton.styleFrom(
                    padding: AppTheme.pSymV16,
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
