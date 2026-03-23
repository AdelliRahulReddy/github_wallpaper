part of 'home_page.dart';

class _HomeProductivityInsightsSection extends StatelessWidget {
  final CachedContributionData data;

  const _HomeProductivityInsightsSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final canUseAdvancedStats = MembershipEntitlements.canUseAdvancedStats;

    final bestDay = data.stats.mostActiveWeekday;
    final peakDay = ContributionAnalyzer.findPeakDay(
      data.days,
      dateOf: (day) => day.date,
      countOf: (day) => day.contributionCount,
    );
    final byKey = {for (final d in data.days) d.dateKey: d};
    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 29));
    var last30Total = 0;
    for (var i = 0; i < 30; i++) {
      final d = start.add(Duration(days: i));
      last30Total += byKey[AppDateUtils.formatDate(d)]?.contributionCount ?? 0;
    }
    final avg = (last30Total / 30.0);

    final weekStart = today.subtract(const Duration(days: 6));
    var weekActiveDays = 0;
    for (var i = 0; i < 7; i++) {
      final d = weekStart.add(Duration(days: i));
      final c = byKey[AppDateUtils.formatDate(d)]?.contributionCount ?? 0;
      if (c > 0) weekActiveDays += 1;
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRODUCTIVITY INSIGHTS',
          style: tt.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        AppTheme.h12,
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _InsightTile(
                    icon: Icons.schedule_outlined,
                    iconColor: scheme.primary,
                    label: 'Peak Day',
                    value: peakDay == null ? '—' : '${peakDay.count}',
                    subtitle: peakDay == null
                        ? 'No record yet'
                        : 'On ${DateFormat('d MMM').format(peakDay.date)}',
                  ),
                ),
                AppTheme.w12,
                Expanded(
                  child: _InsightTile(
                    icon: Icons.calendar_month_outlined,
                    iconColor: scheme.secondary,
                    label: 'Best Day',
                    value: bestDay == AppConstants.fallbackWeekday ? '—' : bestDay,
                    subtitle: bestDay == AppConstants.fallbackWeekday
                        ? 'No activity yet'
                        : 'Most productive weekday',
                  ),
                ),
              ],
            ),
            AppTheme.h12,
            Row(
              children: [
                Expanded(
                  child: _InsightTile(
                    icon: Icons.query_stats_outlined,
                    iconColor: scheme.primary,
                    label: 'Avg/Day',
                    value: avg.toStringAsFixed(1),
                    subtitle: 'Last 30 days',
                  ),
                ),
                AppTheme.w12,
                Expanded(
                  child: _InsightTile(
                    icon: Icons.emoji_events_outlined,
                    iconColor: scheme.tertiary,
                    label: 'Consistency',
                    value: '$weekActiveDays/7',
                    subtitle: 'Days active this week',
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    if (canUseAdvancedStats) {
      return content;
    }

    return _HomeLockedInsightsPreview(
      title: 'Productivity insights are Pro',
      body:
          'Peak day, best weekday, average activity, and consistency insights stay visible here as a locked preview.',
      child: content,
    );
  }
}

class _HomeLockedInsightsPreview extends StatelessWidget {
  final String title;
  final String body;
  final Widget child;

  const _HomeLockedInsightsPreview({
    required this.title,
    required this.body,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    void openPaywall() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const MembershipPaywallPage(
            featureName: 'Productivity Insights',
            featureDescription:
                'Peak day, best weekday, average activity, and consistency insights are part of Pro.',
          ),
        ),
      );
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
                child: child,
              ),
            ),
          ),
          Positioned.fill(
            child: Material(
              color: scheme.surface.withValues(alpha: 0.28),
              child: InkWell(
                onTap: openPaywall,
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    margin: AppTheme.pAll20,
                    padding: AppTheme.pAll20,
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
                          size: AppTheme.iconLG,
                          color: scheme.primary,
                        ),
                        AppTheme.h12,
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
                            height: 1.4,
                          ),
                        ),
                        AppTheme.h16,
                        FilledButton.tonal(
                          onPressed: openPaywall,
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

class _InsightTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;

  const _InsightTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AppCard(
      padding: AppTheme.pAll20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppTheme.spacing32,
            height: AppTheme.spacing32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(icon, size: AppTheme.iconSM, color: iconColor),
          ),
          AppTheme.h12,
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          AppTheme.h8,
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          AppTheme.h8,
          Text(subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _HomeQuickNumbersSection extends StatelessWidget {
  final CachedContributionData data;
  final TrendSummary trend7d;

  const _HomeQuickNumbersSection({required this.data, required this.trend7d});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK NUMBERS',
          style: tt.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        AppTheme.h12,
        LayoutBuilder(
          builder: (context, constraints) {
            final minTileWidth = AppTheme.spacing40 * 3;
            final idealTileWidth =
                (constraints.maxWidth - AppTheme.spacing12 * 2) / 3;
            final needsScroll = idealTileWidth < minTileWidth;

            final tiles = [
              _QuickNumberTile(
                icon: Icons.calendar_month_outlined,
                label: 'Recent Days',
                value: '${data.stats.activeDaysCount}',
              ),
              _QuickNumberTile(
                icon: Icons.insights_outlined,
                label: '7-Day',
                value: '${trend7d.current}',
              ),
              _QuickNumberTile(
                icon: Icons.emoji_events_outlined,
                label: 'Recent Commits',
                value: '${data.totalContributions}',
              ),
            ];

            if (needsScroll) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    for (var i = 0; i < tiles.length; i++) ...[
                      SizedBox(width: minTileWidth, child: tiles[i]),
                      if (i != tiles.length - 1) AppTheme.w12,
                    ],
                  ],
                ),
              );
            }

            return Row(
              children: [
                Expanded(child: tiles[0]),
                AppTheme.w12,
                Expanded(child: tiles[1]),
                AppTheme.w12,
                Expanded(child: tiles[2]),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuickNumberTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _QuickNumberTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SizedBox(
      height: 125,
      child: AppCard(
        padding: AppTheme.pAll20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: AppTheme.iconMD, color: scheme.onSurfaceVariant),
            const Spacer(),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            AppTheme.h8,
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
