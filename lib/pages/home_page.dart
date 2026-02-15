// ══════════════════════════════════════════════════════════════════════════
// 🏠 HOME PAGE - Production Dashboard
// ══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:github_wallpaper/app_services.dart';
import 'package:github_wallpaper/app_models.dart';
import 'package:github_wallpaper/app_theme.dart';
import 'package:github_wallpaper/app_utils.dart';
import 'package:github_wallpaper/app_state.dart';
import 'package:github_wallpaper/ui_render.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  final CachedContributionData? data;
  final bool isLoading;
  final String? loadError;
  final Future<void> Function() onRefresh;

  const HomePage({
    super.key,
    required this.data,
    required this.isLoading,
    required this.loadError,
    required this.onRefresh,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _daysInSixMonths = AppConstants.dashboardHeatmapDays;
  static const int _trendDays = 30;
  TrendSummary _trend7d = const TrendSummary(current: 0, previous: 0);
  TrendSummary _trend30d = const TrendSummary(current: 0, previous: 0);
  late final bool _showFirstLoginGreeting;

  @override
  void initState() {
    super.initState();
    _setTrends(widget.data);
    _showFirstLoginGreeting = StorageService.isFirstLoginGreetingPending();
    if (_showFirstLoginGreeting) {
      unawaited(() async {
        try {
          await StorageService.setFirstLoginGreetingPending(false);
        } catch (_) {}
      }());
    }
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _setTrends(widget.data);
    }
  }

  void _setTrends(CachedContributionData? data) {
    if (data == null) {
      _trend7d = const TrendSummary(current: 0, previous: 0);
      _trend30d = const TrendSummary(current: 0, previous: 0);
      return;
    }
    _trend7d = ContributionAnalyzer.computeTrend(
      data.days,
      window: 7,
      dateOf: (day) => day.date,
      countOf: (day) => day.contributionCount,
    );
    _trend30d = ContributionAnalyzer.computeTrend(
      data.days,
      window: 30,
      dateOf: (day) => day.date,
      countOf: (day) => day.contributionCount,
    );
  }

  Color _heatmapColor(int level) {
    final ext = Theme.of(context).extension<AppThemeExt>();
    if (ext != null && level >= 0 && level < ext.heatmapLevels.length) {
      return ext.heatmapLevels[level];
    }
    return AppThemeExt(isLight: true).heatmapLevels[level.clamp(0, 4)];
  }

  List<ContributionDay> _sortedDays(List<ContributionDay> days) {
    final sorted = List<ContributionDay>.from(days)
      ..sort((a, b) => a.date.compareTo(b.date));
    return sorted;
  }

  List<ContributionDay> _lastDays(List<ContributionDay> days, int count) {
    if (days.isEmpty) return const [];
    final sorted = _sortedDays(days);
    final start = (sorted.length - count).clamp(0, sorted.length);
    return sorted.sublist(start);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    var username = StorageService.getUsername() ?? 'Developer';
    if (username.isNotEmpty) {
      username = username[0].toUpperCase() + username.substring(1);
    }
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final toolbarHeight = textScale > 1.2 ? 180.0 : 160.0;

    if (widget.isLoading && widget.data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.loadError != null && widget.data == null) {
      return _buildErrorState();
    }

    final data = widget.data;
    final trend7d = _trend7d;
    final trend30d = _trend30d;

    final titleDate = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: scheme.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            centerTitle: false,
            automaticallyImplyLeading: false,
            backgroundColor: scheme.surface,
            surfaceTintColor: scheme.surface.withValues(alpha: 0),
            elevation: 0,
            toolbarHeight: toolbarHeight,
            titleSpacing: AppTheme.spacing20,
            title: Padding(
              padding: AppTheme.pSymV16,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _showFirstLoginGreeting ? AppStrings.welcome : AppStrings.welcomeBack,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.primary.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w800,
                            fontSize: AppTheme.fontBase,
                            height: 1.25,
                            letterSpacing: 1.5,
                          ),
                        ),
                        AppTheme.h8,
                        Text(
                          username,
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: AppTheme.fontDisplay,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            letterSpacing: -0.8,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        AppTheme.h12,
                        Text(
                          titleDate.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w700,
                            fontSize: AppTheme.fontBody,
                            height: 1.2,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppTheme.w16,
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.15),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: widget.data?.avatarUrl != null
                          ? Image.network(
                              widget.data!.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildAvatarFallback(username, scheme),
                            )
                          : _buildAvatarFallback(username, scheme),
                    ),
                  ),
                ],
              ),
            ),
            actions: const [],
            bottom: widget.isLoading
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(2),
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      backgroundColor: scheme.surfaceContainerHighest,
                      color: scheme.primary,
                    ),
                  )
                : null,
          ),
          SliverPadding(
            padding: AppTheme.pLTRB20_16_20_32,
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  if (widget.loadError != null && data != null) ...[
                    AppCard(
                      padding: AppTheme.pAll16,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: scheme.secondary,
                            size: 18,
                          ),
                          AppTheme.w12,
                          Expanded(
                            child: Text(
                              widget.loadError!,
                              style: TextStyle(
                                color: scheme.onSurface.withValues(alpha: 0.72),
                                fontSize: AppTheme.fontBody,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppTheme.h16,
                  ],
                  if (data == null) ...[
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppSectionHeader(
                            title: AppStrings.getStarted,
                            subtitle:
                                AppStrings.homeGetStartedSubtitle,
                          ),
                          AppTheme.h16,
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: widget.onRefresh,
                              child: const Text(AppStrings.syncNow),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    _buildOverview(
                      data,
                      trend7d: trend7d,
                      trend30d: trend30d,
                    ),
                    AppTheme.h20,
                    _buildTrendsSection(data),
                    AppTheme.h20,
                    _buildHeatmapSection(data),
                    AppTheme.h20,
                    _buildRepositoriesSection(data),
                    AppTheme.h20,
                    _buildLanguagesSection(data),
                    AppTheme.h20,
                    _buildActivityInsights(data),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(
    CachedContributionData data, {
    required TrendSummary trend7d,
    required TrendSummary trend30d,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final lastSync = StorageService.getEffectiveLastSync() ?? data.lastUpdated;
    final updated = 'Last Synced ${PresentationFormatter.formatTimeAgoCompact(lastSync)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppTheme.pOnlyT8B12,
          child: AppSectionHeader(
            title: AppStrings.overview,
            subtitle: updated,
            trailing: IconButton.filledTonal(
              onPressed: widget.isLoading ? null : widget.onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        AppTheme.h8,
        HeroMetricCard(
          title: AppStrings.totalContributions,
          value: PresentationFormatter.formatCompactNumber(
              data.totalContributions),
          subtitle: AppStrings.totalContributionsSubtitle,
          icon: Icons.auto_graph_rounded,
          color: scheme.primary,
        ),
        AppTheme.h16,
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final crossAxisCount = w >= 980
                ? 4
                : w >= 680
                    ? 3
                    : 2;
            final baseAspect = crossAxisCount >= 4
                ? 1.45
                : crossAxisCount == 3
                    ? 1.35
                    : 1.2;
            final aspect = baseAspect / textScale.clamp(1.0, 1.5);

            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: AppTheme.spacing12,
              mainAxisSpacing: AppTheme.spacing12,
              childAspectRatio: aspect,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                MetricTile(
                  label: AppStrings.currentStreak,
                  value: '${data.currentStreak}d',
                  icon: Icons.local_fire_department_rounded,
                  iconColor: AppTheme.warningOrange,
                ),
                MetricTile(
                  label: AppStrings.today,
                  value: '${data.todayCommits}',
                  icon: Icons.today_rounded,
                  iconColor: scheme.secondary,
                ),
                MetricTile(
                  label: AppStrings.longestStreak,
                  value: '${data.longestStreak}d',
                  icon: Icons.emoji_events_rounded,
                  iconColor: AppTheme.accentViolet,
                ),
                MetricTile(
                  label: AppStrings.activeRepos,
                  value: '${data.activeRepositoriesCount}',
                  icon: Icons.inventory_2_rounded,
                  iconColor: scheme.primary,
                ),
                MetricTile(
                  label: AppStrings.trend7d,
                  value: PresentationFormatter.formatCompactNumber(
                      trend7d.current),
                  helper: trend7d.deltaLabel,
                  icon: Icons.show_chart_rounded,
                  iconColor: scheme.primary,
                ),
                MetricTile(
                  label: AppStrings.trend30d,
                  value: PresentationFormatter.formatCompactNumber(
                      trend30d.current),
                  helper: trend30d.deltaLabel,
                  icon: Icons.timeline_rounded,
                  iconColor: scheme.primary,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeatmapSection(CachedContributionData data) {
    final scheme = Theme.of(context).colorScheme;
    final days = data.days.length > _daysInSixMonths
        ? data.days.sublist(data.days.length - _daysInSixMonths)
        : data.days;
    final total = days.fold<int>(0, (sum, d) => sum + d.contributionCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: AppStrings.activityGraph,
          subtitle:
              '${AppStrings.last6Months} • ${PresentationFormatter.formatCompactNumber(total)} ${AppStrings.commits}',
        ),
        AppTheme.h12,
        AppCard(
          padding: AppTheme.pAll16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppTheme.spacing12,
                runSpacing: AppTheme.spacing8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    AppStrings.less,
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.70),
                      fontSize: AppTheme.fontCaption,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      final countLabel = i == 0
                          ? '0'
                          : i == 1
                              ? '1-${data.quartiles.q1}'
                              : i == 2
                                  ? '${data.quartiles.q1 + 1}-${data.quartiles.q2}'
                                  : i == 3
                                      ? '${data.quartiles.q2 + 1}-${data.quartiles.q3}'
                                      : '${data.quartiles.q3 + 1}+';
                      
                      return Padding(
                        padding: AppTheme.pOnlyR12,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _heatmapColor(i),
                                borderRadius: AppTheme.brSmall,
                                border: Border.all(
                                  color: scheme.outline.withValues(alpha: 0.35),
                                ),
                              ),
                            ),
                            AppTheme.w4,
                            Text(
                              countLabel,
                              style: TextStyle(
                                color: scheme.onSurface.withValues(alpha: 0.55),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  Text(
                    AppStrings.more,
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.70),
                      fontSize: AppTheme.fontCaption,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              AppTheme.h12,
              SizedBox(
                height: AppTheme.heatmapHeight,
                child: days.isEmpty
                    ? Center(
                        child: Text(
                          AppStrings.noActivityData,
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.70),
                          ),
                        ),
                      )
                    : _ScrollableHeatmapGrid(
                        days: days,
                        quartiles: data.quartiles,
                        heatmapColor: _heatmapColor,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendsSection(CachedContributionData data) {
    final scheme = Theme.of(context).colorScheme;
    final days = _lastDays(data.days, _trendDays);
    final values = days.map((d) => d.contributionCount.toDouble()).toList();
    final total = days.fold<int>(0, (a, d) => a + d.contributionCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: AppStrings.commitFrequency,
          subtitle:
              'Last $_trendDays days • ${PresentationFormatter.formatCompactNumber(total)} ${AppStrings.commits}',
        ),
        AppTheme.h12,
        AppCard(
          padding: AppTheme.pAll16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 130,
                child: values.isEmpty
                    ? Center(
                        child: Text(
                          AppStrings.noRecentActivity,
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : _SparklineChart(
                        values: values,
                        lineColor: scheme.primary,
                        fillColor: scheme.primary,
                        onIndexSelected: (index) {
                          final day = days[index];
                          final label = DateFormat('EEE, d MMM')
                              .format(day.date.toLocal());
                          showModalBottomSheet<void>(
                            context: context,
                            backgroundColor: scheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppTheme.brVertLarge,
                            ),
                            builder: (context) => SafeArea(
                              child: Padding(
                                padding: AppTheme.pAll20,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      label,
                                      style: TextStyle(
                                        color: scheme.onSurface,
                                        fontSize: AppTheme.fontTitle,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    AppTheme.h12,
                                    Text(
                                      '${day.contributionCount} commits',
                                      style: TextStyle(
                                        color: scheme.onSurface
                                            .withValues(alpha: 0.72),
                                        fontSize: AppTheme.fontLarge,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    AppTheme.h20,
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Close'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              AppTheme.h12,
              Text(
                AppStrings.tapChartToInspect,
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.60),
                  fontSize: AppTheme.fontCaption,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRepositoriesSection(CachedContributionData data) {
    final scheme = Theme.of(context).colorScheme;
    final repos = data.repositories.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: AppStrings.activeRepositories,
          subtitle: '${data.activeRepositoriesCount} ${AppStrings.reposWithCommits}',
        ),
        AppTheme.h12,
        AppCard(
          padding: AppTheme.pZero,
          child: repos.isEmpty
              ? Padding(
                  padding: AppTheme.pAll20,
                  child: Text(
                    AppStrings.noRepoActivity,
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontSize: AppTheme.fontBody,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: repos.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: scheme.outline.withValues(alpha: 0.55),
                  ),
                  itemBuilder: (context, index) {
                    final r = repos[index];
                    final lang = r.primaryLanguageName;
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing16,
                        vertical: 6,
                      ),
                      title: Text(
                        r.nameWithOwner,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: lang == null || lang.isEmpty
                          ? null
                          : Text(
                              lang,
                              style: TextStyle(
                                color: scheme.onSurface.withValues(alpha: 0.70),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                      trailing: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 110),
                        child: Text(
                          '${PresentationFormatter.formatCompactNumber(r.commitCount)} ${AppStrings.commits}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.70),
                            fontWeight: FontWeight.w700,
                            fontSize: AppTheme.fontBody,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLanguagesSection(CachedContributionData data) {
    final scheme = Theme.of(context).colorScheme;
    final langs = data.topLanguages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: AppStrings.topLanguages,
          subtitle: AppStrings.languagesSubtitle,
        ),
        AppTheme.h12,
        AppCard(
          child: langs.isEmpty
              ? Text(
                  AppStrings.noLanguageData,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.72),
                    fontSize: AppTheme.fontBody,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : Column(
                  children: [
                    for (final l in langs) ...[
                      _LanguageRow(
                        name: l.name,
                        color: _parseHexColor(l.color) ?? scheme.primary,
                        percent: l.percent,
                      ),
                      if (l != langs.last)
                        AppTheme.h12,
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildActivityInsights(CachedContributionData data) {
    final scheme = Theme.of(context).colorScheme;
    int weekendTotal = 0;
    int weekdayTotal = 0;
    final levels = [0, 0, 0, 0, 0];

    for (final day in data.days) {
      if (day.date.weekday >= 6) {
        weekendTotal += day.contributionCount;
      } else {
        weekdayTotal += day.contributionCount;
      }

      if (day.contributionCount == 0) continue;
      final level = RenderUtils.getContributionLevel(
        day.contributionCount,
        quartiles: data.quartiles,
      );
      if (level >= 0 && level < levels.length) levels[level]++;
    }

    final total = weekendTotal + weekdayTotal;
    final weekendPct = total > 0 ? weekendTotal / total : 0.0;
    final weekdayPct = total > 0 ? weekdayTotal / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: AppStrings.activityInsights,
          subtitle: AppStrings.insightsSubtitle,
        ),
        AppTheme.h12,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.weekendVsWeekday,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: AppTheme.fontLarge,
                  fontWeight: FontWeight.w800,
                ),
              ),
              AppTheme.h12,
              ClipRRect(
                borderRadius: AppTheme.brMedium,
                child: SizedBox(
                  height: AppTheme.barHeight,
                  child: Row(
                    children: [
                      Expanded(
                        flex: total > 0
                            ? ((weekdayPct * 100).toInt()).clamp(1, 99)
                            : 1,
                        child: Container(color: scheme.primary),
                      ),
                      Expanded(
                        flex: total > 0
                            ? ((weekendPct * 100).toInt()).clamp(1, 99)
                            : 1,
                        child: Container(color: scheme.secondary),
                      ),
                    ],
                  ),
                ),
              ),
              AppTheme.h12,
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 420 ||
                      MediaQuery.of(context).textScaler.scale(1.0) > 1.15;

                  final weekdayStat = _MiniStat(
                    label: AppStrings.weekdays,
                    value: PresentationFormatter.formatCompactNumber(
                      weekdayTotal,
                    ),
                    pct: '${(weekdayPct * 100).toStringAsFixed(0)}%',
                    color: scheme.primary,
                  );
                  final weekendStat = _MiniStat(
                    label: AppStrings.weekends,
                    value: PresentationFormatter.formatCompactNumber(
                      weekendTotal,
                    ),
                    pct: '${(weekendPct * 100).toStringAsFixed(0)}%',
                    color: scheme.secondary,
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        weekdayStat,
                        AppTheme.h12,
                        weekendStat,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: weekdayStat),
                      AppTheme.w16,
                      Expanded(child: weekendStat),
                    ],
                  );
                },
              ),
              AppTheme.h20,
              Text(
                AppStrings.impactLevels,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: AppTheme.fontLarge,
                  fontWeight: FontWeight.w800,
                ),
              ),
              AppTheme.h12,
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 560 ||
                      MediaQuery.of(context).textScaler.scale(1.0) > 1.15;

                  if (isCompact) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _ImpactChip(
                                label: AppStrings.levelLow,
                                count: levels[1],
                                color: _heatmapColor(1),
                              ),
                            ),
                            AppTheme.w8,
                            Expanded(
                              child: _ImpactChip(
                                label: AppStrings.levelMed,
                                count: levels[2],
                                color: _heatmapColor(2),
                              ),
                            ),
                          ],
                        ),
                        AppTheme.h8,
                        Row(
                          children: [
                            Expanded(
                              child: _ImpactChip(
                                label: AppStrings.levelHigh,
                                count: levels[3],
                                color: _heatmapColor(3),
                              ),
                            ),
                            AppTheme.w8,
                            Expanded(
                              child: _ImpactChip(
                                label: AppStrings.levelMax,
                                count: levels[4],
                                color: _heatmapColor(4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _ImpactChip(
                          label: 'Low',
                          count: levels[1],
                          color: _heatmapColor(1),
                        ),
                      ),
                      AppTheme.w8,
                      Expanded(
                        child: _ImpactChip(
                          label: 'Med',
                          count: levels[2],
                          color: _heatmapColor(2),
                        ),
                      ),
                      AppTheme.w8,
                      Expanded(
                        child: _ImpactChip(
                          label: 'High',
                          count: levels[3],
                          color: _heatmapColor(3),
                        ),
                      ),
                      AppTheme.w8,
                      Expanded(
                        child: _ImpactChip(
                          label: 'Max',
                          count: levels[4],
                          color: _heatmapColor(4),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // LOADING & ERROR STATES
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildErrorState() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: scheme.error),
          AppTheme.h16,
          Text(widget.loadError ?? AppStrings.unknown,
              style:
                  TextStyle(color: scheme.onSurface.withValues(alpha: 0.72))),
          AppTheme.h16,
          FilledButton(onPressed: widget.onRefresh, child: Text(AppStrings.retry)),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String username, ColorScheme scheme) {
    return Container(
      color: scheme.primary.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : '?',
          style: TextStyle(
            color: scheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// SUB-WIDGETS
// ══════════════════════════════════════════════════════════════════════

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String pct;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.pct,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        AppTheme.w8,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppTheme.fontBody,
                  color: scheme.onSurface.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Wrap(
                spacing: 4,
                runSpacing: 2,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    '($pct)',
                    style: TextStyle(
                      fontSize: AppTheme.fontSmall,
                      color: scheme.onSurface.withValues(alpha: 0.60),
                      fontWeight: FontWeight.w700,
                    ),
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

class _ImpactChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _ImpactChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: AppTheme.pAll12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.65)),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppTheme.brSmall,
              border: Border.all(
                color: scheme.outline.withValues(alpha: 0.35),
              ),
            ),
          ),
          AppTheme.w8,
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
                fontSize: AppTheme.fontSmall,
              ),
            ),
          ),
          AppTheme.w4,
          Text(
            '$count',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final String name;
  final Color color;
  final double percent;

  const _LanguageRow({
    required this.name,
    required this.color,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pctLabel = '${(percent * 100).toStringAsFixed(0)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            AppTheme.w8,
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              pctLabel,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        AppTheme.h8,
        ClipRRect(
          borderRadius: AppTheme.brSmall,
          child: LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: scheme.surfaceContainerHighest,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SparklineChart extends StatelessWidget {
  final List<double> values;
  final Color lineColor;
  final Color fillColor;
  final ValueChanged<int> onIndexSelected;

  const _SparklineChart({
    required this.values,
    required this.lineColor,
    required this.fillColor,
    required this.onIndexSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final dx = details.localPosition.dx.clamp(0.0, width);
            final t = width <= 0 ? 0.0 : (dx / width);
            final raw = (t * (values.length - 1));
            onIndexSelected(raw.round().clamp(0, values.length - 1));
          },
          child: CustomPaint(
            size: Size(width, constraints.maxHeight),
            painter: _SparklinePainter(
              values: values,
              lineColor: lineColor,
              fillColor: fillColor,
            ),
          ),
        );
      },
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final Color fillColor;

  _SparklinePainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || values.length == 1) return;
    if (size.width <= 0 || size.height <= 0) return;

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs();

    Offset pointAt(int i) {
      final t = i / (values.length - 1);
      final x = t * size.width;
      final normalized = range <= 0 ? 0.0 : ((values[i] - minV) / range);
      final y = size.height - (normalized * size.height);
      return Offset(x, y);
    }

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < values.length; i++) {
      final p = pointAt(i);
      path.lineTo(p.dx, p.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          fillColor.withValues(alpha: 0.22),
          fillColor.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = lineColor;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor;
  }
}

Color? _parseHexColor(String? hex) {
  if (hex == null) return null;
  final cleaned = hex.trim();
  if (cleaned.isEmpty) return null;
  final normalized = cleaned.startsWith('#') ? cleaned.substring(1) : cleaned;
  final value = int.tryParse(normalized, radix: 16);
  if (value == null) return null;
  if (normalized.length == 6) {
    return Color(0xFF000000 | value);
  }
  if (normalized.length == 8) {
    return Color(value);
  }
  return null;
}

class _ScrollableHeatmapGrid extends StatelessWidget {
  final List<ContributionDay> days;
  final Quartiles quartiles;
  final Color Function(int level) heatmapColor;

  const _ScrollableHeatmapGrid({
    required this.days,
    required this.quartiles,
    required this.heatmapColor,
  });

  @override
  Widget build(BuildContext context) {
    final displayDays = days.length > AppConstants.dashboardHeatmapDays
        ? days.sublist(days.length - AppConstants.dashboardHeatmapDays)
        : days;
    if (displayDays.isEmpty) {
      return const Center(child: Text('No activity data'));
    }

    // Group by calendar week: week start = Sunday (row 0), then Mon..Sat (rows 1..6).
    // Dart: weekday 1=Mon, 7=Sun → index 0=Sun is weekday % 7 (7→0, 1→1, ..., 6→6).
    final Map<String, List<ContributionDay?>> weekKeyToSlots = {};
    for (var day in displayDays) {
      final d = day.date;
      final weekStart = DateTime(d.year, d.month, d.day)
          .subtract(Duration(days: d.weekday % 7));
      final key =
          '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
      weekKeyToSlots.putIfAbsent(key, () => List.filled(7, null));
      weekKeyToSlots[key]![d.weekday % 7] = day;
    }

    final sortedKeys = weekKeyToSlots.keys.toList()..sort();
    final List<List<ContributionDay?>> weeks = sortedKeys
        .map((k) => List<ContributionDay?>.from(weekKeyToSlots[k]!))
        .toList();

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      reverse: true, // Show newest on the right
      itemCount: weeks.length,
      separatorBuilder: (_, __) => AppTheme.w8,
      itemBuilder: (context, index) {
        // Reverse indexing logic for reverse list view
        // index 0 is the NEWEST week (last in our list)
        final weekData = weeks[weeks.length - 1 - index];

        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (dayIndex) {
            final day = weekData[dayIndex];
            return _HeatmapCell(
              day: day,
              quartiles: quartiles,
              heatmapColor: heatmapColor,
            );
          }),
        );
      },
      padding: AppTheme.pZero,
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  final ContributionDay? day;
  final Quartiles quartiles;
  final Color Function(int level) heatmapColor;

  const _HeatmapCell({
    required this.day,
    required this.quartiles,
    required this.heatmapColor,
  });

  @override
  Widget build(BuildContext context) {
    if (day == null) {
      return const SizedBox.square(dimension: 22);
    }

    final scheme = Theme.of(context).colorScheme;
    final color = _getColorForLevel(day!.contributionCount, quartiles);

    // Format date carefully
    final dateStr =
        "${day!.date.year}-${day!.date.month.toString().padLeft(2, '0')}-${day!.date.day.toString().padLeft(2, '0')}";

    return Semantics(
      button: true,
      label: '$dateStr. ${day!.contributionCount} ${AppStrings.commits}.',
      child: Material(
        color: scheme.surface.withValues(alpha: 0),
        child: InkWell(
          borderRadius: AppTheme.brSmall,
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              backgroundColor: scheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.brVertLarge,
              ),
              builder: (context) => SafeArea(
              child: Padding(
                padding: AppTheme.pAll20,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: AppTheme.fontTitle,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppTheme.h12,
                      Text(
                        '${day!.contributionCount} ${AppStrings.commits}',
                        style: TextStyle(
                          fontSize: AppTheme.fontLarge,
                          color: scheme.onSurface.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppTheme.h20,
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppTheme.brSmall,
                border:
                    Border.all(color: scheme.outline.withValues(alpha: 0.35)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorForLevel(int count, Quartiles quartiles) {
    final level = RenderUtils.getContributionLevel(count, quartiles: quartiles);
    return heatmapColor(level);
  }
}
