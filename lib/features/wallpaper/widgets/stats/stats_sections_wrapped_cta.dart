part of 'stats_sections.dart';

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
                              : WrappedScreen(
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
