part of 'stats_page.dart';

extension _StatsPageStateView on _StatsPageState {
  Future<void> _openStatsPaywall({
    required String featureName,
    required String featureDescription,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MembershipPaywallPage(
          featureName: featureName,
          featureDescription: featureDescription,
        ),
      ),
    );
  }

  List<int> _availableYears(CachedContributionData data) {
    final years = <int>{};
    for (final day in data.days) {
      years.add(day.date.toLocal().year);
    }
    final ordered = years.toList()..sort();
    return ordered.reversed.toList();
  }

  List<ContributionDay> _daysForYear(CachedContributionData data, int year) {
    return [
      for (final day in data.days)
        if (day.date.toLocal().year == year) day,
    ];
  }

  List<int> _monthlyTotalsForYear(CachedContributionData data, int year) {
    final totals = List<int>.filled(12, 0);
    for (final day in data.days) {
      final date = day.date.toLocal();
      if (date.year == year) {
        totals[date.month - 1] += day.contributionCount;
      }
    }
    return totals;
  }

  int _yearTotal(CachedContributionData data, int year) {
    var total = 0;
    for (final day in data.days) {
      if (day.date.toLocal().year == year) {
        total += day.contributionCount;
      }
    }
    return total;
  }

  ContributionStats _statsForYear(List<ContributionDay> yearDays, int year) {
    final now = DateTime.now().toLocal();
    final cutoff = year == now.year
        ? DateTime(now.year, now.month, now.day)
        : DateTime(year, 12, 31);
    return ContributionStats.fromDays(
      yearDays,
      nowUtc: cutoff.toUtc(),
    );
  }

  Widget _lockableStatsSection({
    required bool locked,
    required Widget child,
    required String featureName,
    required String featureDescription,
  }) {
    if (!locked) {
      return child;
    }
    return StatsLockedPreview(
      title: '$featureName is Pro',
      body: featureDescription,
      onTap: () => _openStatsPaywall(
        featureName: featureName,
        featureDescription: featureDescription,
      ),
      child: child,
    );
  }

  void _showDayDetail(
    ContributionDay day,
    ColorScheme scheme,
    Color backgroundColor,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.brVertLarge),
      builder: (ctx) {
        final label = MaterialLocalizations.of(ctx).formatFullDate(day.date);
        return SafeArea(
          child: Padding(
            padding: AppTheme.pAll24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                    fontSize: AppTheme.fontBody,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                AppTheme.h8,
                Text(
                  '${day.contributionCount} contribution${day.contributionCount == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: AppTheme.fontHeadline,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsPage(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final canUseAdvancedStats = MembershipEntitlements.canUseAdvancedStats;
    final canViewWrapped = MembershipEntitlements.canViewWrapped;

    if (widget.isLoading && widget.data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.loadError != null && widget.data == null) {
      return Center(
        child: Padding(
          padding: AppTheme.pAll24,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: scheme.onSurface.withValues(alpha: 0.35),
              ),
              AppTheme.h16,
              Text(
                AppStrings.loadError,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: AppTheme.fontTitle,
                  fontWeight: FontWeight.w900,
                ),
              ),
              AppTheme.h8,
              Text(
                widget.loadError ?? AppStrings.unknownError,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                  fontSize: AppTheme.fontBody,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              AppTheme.h24,
              FilledButton.icon(
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(AppStrings.tryAgain),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.data == null) {
      return Center(
        child: Padding(
          padding: AppTheme.pAll24,
          child: Text(
            'No data yet.',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.70),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final data = widget.data!;
    final years = _availableYears(data);
    if (years.isEmpty) {
      return Center(
        child: Padding(
          padding: AppTheme.pAll24,
          child: Text(
            'No stats yet.',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.70),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
    final nowYear = DateTime.now().toLocal().year;
    final selectedYear = canUseAdvancedStats
        ? (years.contains(_selectedYear)
            ? _selectedYear!
            : (years.contains(nowYear) ? nowYear : years.first))
        : (years.contains(nowYear) ? nowYear : years.first);
    final yearTotal = _yearTotal(data, selectedYear);
    final yearDays = _daysForYear(data, selectedYear);
    final yearStats = _statsForYear(yearDays, selectedYear);
    final isCurrentYear = selectedYear == nowYear;
    final thisYearMonthly = _monthlyTotalsForYear(data, selectedYear);
    final lastYearMonthly = _monthlyTotalsForYear(data, selectedYear - 1);
    final subtitle = isCurrentYear
        ? '${NumberFormat.decimalPattern().format(yearTotal)} contributions this year'
        : '${NumberFormat.decimalPattern().format(yearTotal)} contributions in $selectedYear';

    final sections = <Widget>[
      _StatsHeaderSummary(
        subtitle: subtitle,
        isCurrentYear: isCurrentYear,
      ),
      StatsYearHeatmapCard(
        data: data,
        year: selectedYear,
        onDayTap: (day) => _showDayDetail(day, scheme, backgroundColor),
      ),
      StatsAtAGlanceGrid(
        year: selectedYear,
        yearTotal: yearTotal,
        yearDays: yearDays,
        yearStats: yearStats,
        overallStats: data.stats,
        isCurrentYear: isCurrentYear,
        canUseAdvancedStats: canUseAdvancedStats,
        onUnlockPro: () => _openStatsPaywall(
          featureName: 'Advanced Stats',
          featureDescription:
              'Best-day insights, averages, and the deeper stats tiles are part of Pro.',
        ),
      ),
      _lockableStatsSection(
        locked: !canUseAdvancedStats,
        featureName: 'Weekly Breakdown',
        featureDescription:
            'Weekly contribution breakdowns are part of Pro.',
        child: StatsWeeklyBreakdownCard(data: data, year: selectedYear),
      ),
      _lockableStatsSection(
        locked: !canUseAdvancedStats,
        featureName: 'Monthly Trend',
        featureDescription:
            'Monthly comparisons and trend analysis are part of Pro.',
        child: StatsMonthlyTrendCard(
          year: selectedYear,
          thisYear: thisYearMonthly,
          lastYear: lastYearMonthly,
        ),
      ),
      _lockableStatsSection(
        locked: !canUseAdvancedStats,
        featureName: 'Streak History',
        featureDescription:
            'Historical streak analysis and milestone breakdowns are part of Pro.',
        child: StatsStreakHistoryCard(
          year: selectedYear,
          allDays: data.days,
          yearDays: yearDays,
          yearStats: yearStats,
          overallStats: data.stats,
          isCurrentYear: isCurrentYear,
        ),
      ),
      _lockableStatsSection(
        locked: !canUseAdvancedStats,
        featureName: 'Most Active Days',
        featureDescription:
            'Weekday performance patterns are part of Pro.',
        child: StatsMostActiveDaysCard(yearDays: yearDays, year: selectedYear),
      ),
      if (isCurrentYear) ...[
        _lockableStatsSection(
          locked: !canUseAdvancedStats,
          featureName: 'Top Languages',
          featureDescription:
              'Language rankings and code mix insights are part of Pro.',
          child: StatsTopLanguagesCard(langs: data.topLanguages),
        ),
        _lockableStatsSection(
          locked: !canUseAdvancedStats,
          featureName: 'Top Repositories',
          featureDescription:
              'Repository rankings and contribution leaders are part of Pro.',
          child: StatsTopReposCard(repos: data.repositories),
        ),
        StatsYearWrappedCtaCard(
          data: data,
          locked: !canViewWrapped,
        ),
      ] else if (canUseAdvancedStats) ...[
        const _StatsCurrentYearOnlyNoticeCard(),
      ],
      AppTheme.h32,
    ];

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: scheme.primary,
      child: ColoredBox(
        color: backgroundColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: backgroundColor,
              surfaceTintColor: backgroundColor.withValues(alpha: 0),
              elevation: 0,
              titleSpacing: AppTheme.spacing20,
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Stats',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: AppTheme.fontLarge,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (canUseAdvancedStats)
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => _pickYear(years, selectedYear),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing12,
                          vertical: AppTheme.spacing8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: scheme.outlineVariant),
                          color: scheme.surfaceContainerHighest,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$selectedYear',
                              style: TextStyle(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.expand_more_rounded,
                              size: AppTheme.iconSM,
                              color: scheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SliverPadding(
              padding: AppTheme.pagePaddingTop(context),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == sections.length - 1
                            ? 0
                            : AppTheme.spacing16,
                      ),
                      child: sections[index],
                    );
                  },
                  childCount: sections.length,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
