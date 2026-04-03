import 'package:flutter/material.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/ui/empty_state.dart';
import 'package:github_wallpaper/core/ui/press_scale.dart';
import 'package:github_wallpaper/core/ui/skeleton_loader.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/features/contributions/widgets/stats_sections.dart';
import 'package:github_wallpaper/core/ui/app_components.dart';
import 'package:intl/intl.dart';

class StatsPage extends StatefulWidget {
  final CachedContributionData? data;
  final bool isLoading;
  final String? loadError;
  final Future<void> Function() onRefresh;

  const StatsPage({
    super.key,
    required this.data,
    required this.isLoading,
    required this.loadError,
    required this.onRefresh,
  });

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  int? _selectedYear;

  Future<void> _pickYear(List<int> years, int activeYear) async {
    final scheme = Theme.of(context).colorScheme;
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.brVertLarge),
      builder: (ctx) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: years.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Theme.of(ctx).dividerColor),
            itemBuilder: (ctx, index) {
              final year = years[index];
              final selected = year == activeYear;
              return ListTile(
                title: Text(
                  '$year',
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                trailing: selected
                    ? Icon(Icons.check_rounded, color: scheme.primary)
                    : null,
                onTap: () => Navigator.of(ctx).pop(year),
              );
            },
          ),
        );
      },
    );

    if (!mounted || picked == null) return;
    setState(() => _selectedYear = picked);
  }

  @override
  Widget build(BuildContext context) => _buildStatsPage(context);
}

extension _StatsPageStateView on _StatsPageState {
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

    if (widget.isLoading && widget.data == null) {
      return const StatsPageSkeleton();
    }

    if (widget.loadError != null && widget.data == null) {
      return AppEmptyState(
        icon: Icons.cloud_off_rounded,
        title: AppStrings.loadError,
        message: widget.loadError ?? AppStrings.unknownError,
        ctaLabel: AppStrings.tryAgain,
        onCta: () => widget.onRefresh(),
      );
    }

    if (widget.data == null) {
      return AppEmptyState(
        icon: Icons.query_stats_outlined,
        title: 'No stats yet',
        message:
            'Sync GitHub once to unlock contribution trends, streak history, and yearly breakdowns.',
        ctaLabel: 'Refresh',
        onCta: () => widget.onRefresh(),
      );
    }

    final data = widget.data!;
    final years = _availableYears(data);
    if (years.isEmpty) {
      return AppEmptyState(
        icon: Icons.query_stats_outlined,
        title: 'No stats yet',
        message:
            'Your synced contribution history does not include any chartable days yet.',
        ctaLabel: 'Refresh',
        onCta: () => widget.onRefresh(),
      );
    }
    final nowYear = DateTime.now().toLocal().year;
    final selectedYear = years.contains(_selectedYear)
        ? _selectedYear!
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
      ),
      StatsWeeklyBreakdownCard(data: data, year: selectedYear),
      StatsMonthlyTrendCard(
        year: selectedYear,
        thisYear: thisYearMonthly,
        lastYear: lastYearMonthly,
      ),
      StatsStreakHistoryCard(
        year: selectedYear,
        allDays: data.days,
        yearDays: yearDays,
        yearStats: yearStats,
        overallStats: data.stats,
        isCurrentYear: isCurrentYear,
      ),
      StatsMostActiveDaysCard(yearDays: yearDays, year: selectedYear),
      if (isCurrentYear) ...[
        StatsTopLanguagesCard(langs: data.topLanguages),
        StatsTopReposCard(repos: data.repositories),
        StatsYearWrappedCtaCard(data: data),
      ] else ...[
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
                  Semantics(
                    container: true,
                    button: true,
                    label: 'Select stats year',
                    value: '$selectedYear',
                    hint: 'Open year picker',
                    child: ExcludeSemantics(
                      child: PressScale(
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () => _pickYear(years, selectedYear),
                            child: Container(
                              constraints: const BoxConstraints(
                                minHeight: AppTheme.spacing48,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacing12,
                                vertical: AppTheme.spacing8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                border:
                                    Border.all(color: scheme.outlineVariant),
                                color: scheme.surfaceContainerHighest,
                              ),
                              alignment: Alignment.center,
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
                        ),
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
