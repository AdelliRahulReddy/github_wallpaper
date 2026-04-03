import 'dart:async';

import 'package:flutter/material.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/features/settings/pages/settings_page.dart';
import 'package:github_wallpaper/features/contributions/services/daily_quotes.dart';
import 'package:github_wallpaper/features/contributions/services/achievement_service.dart';
import 'package:github_wallpaper/features/contributions/services/share_service.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/features/contributions/services/contribution_metrics.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/ui/animated_counter.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/core/ui/app_components.dart';
import 'package:github_wallpaper/core/ui/empty_state.dart';
import 'package:github_wallpaper/core/ui/press_scale.dart';
import 'package:github_wallpaper/core/ui/skeleton_loader.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  final CachedContributionData? data;
  final bool isLoading;
  final String? loadError;
  final Future<void> Function() onRefresh;
  final VoidCallback? onOpenStats;
  final VoidCallback? onOpenInsights;
  final VoidCallback? onOpenStudio;

  const HomePage({
    super.key,
    required this.data,
    required this.isLoading,
    required this.loadError,
    required this.onRefresh,
    this.onOpenStats,
    this.onOpenInsights,
    this.onOpenStudio,
  }) : assert(onOpenStats != null || onOpenInsights != null);

  @override
  State<HomePage> createState() => _HomePageState();

  VoidCallback get openStats => onOpenStats ?? onOpenInsights ?? () {};
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  TrendSummary _trend7d = const TrendSummary(current: 0, previous: 0);
  TrendSummary _trend30d = const TrendSummary(current: 0, previous: 0);
  bool _isSharing = false;
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _topCardsController;
  bool _isHeaderCompact = false;
  bool _prefersReducedMotion = false;
  bool _hasPlayedTopCardEntrance = false;

  @override
  void initState() {
    super.initState();
    _topCardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    _setTrends(widget.data);
    _scrollController.addListener(_handleScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTopCardMotionPreference();
  }

  @override
  void dispose() {
    _topCardsController.dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _setTrends(widget.data);
    }
    if (oldWidget.data == null && widget.data != null) {
      if (_prefersReducedMotion) {
        _topCardsController.value = 1;
        _hasPlayedTopCardEntrance = true;
      } else {
        _hasPlayedTopCardEntrance = false;
        _maybePlayTopCardEntrance();
      }
    } else if (oldWidget.data != null && widget.data == null) {
      _topCardsController.value = 0;
      _hasPlayedTopCardEntrance = false;
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

  void _handleScroll() {
    final shouldCompact = _scrollController.hasClients &&
        _scrollController.offset > AppTheme.spacing12;
    if (shouldCompact == _isHeaderCompact || !mounted) return;
    setState(() => _isHeaderCompact = shouldCompact);
  }

  void _syncTopCardMotionPreference() {
    final prefersReducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_prefersReducedMotion == prefersReducedMotion) {
      if (!_prefersReducedMotion) {
        _maybePlayTopCardEntrance();
      }
      return;
    }

    _prefersReducedMotion = prefersReducedMotion;
    if (_prefersReducedMotion) {
      _topCardsController.value = 1;
      _hasPlayedTopCardEntrance = true;
      return;
    }

    if (widget.data != null && !_hasPlayedTopCardEntrance) {
      _topCardsController.value = 0;
      _maybePlayTopCardEntrance();
    }
  }

  void _maybePlayTopCardEntrance() {
    if (_prefersReducedMotion ||
        widget.data == null ||
        _hasPlayedTopCardEntrance) {
      if (_prefersReducedMotion) {
        _topCardsController.value = 1;
      }
      return;
    }

    _hasPlayedTopCardEntrance = true;
    _topCardsController
      ..value = 0
      ..forward();
  }

  void _showDayDetail(ContributionDay day) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.brVertLarge),
      builder: (ctx) {
        final label = DateFormat('EEEE, d MMMM yyyy').format(day.date);
        return Padding(
          padding: AppTheme.pAll24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: scheme.outline.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
              ),
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
              AppTheme.h20,
            ],
          ),
        );
      },
    );
  }

  String _headerDisplayName() {
    final preferredName = StorageService.getDisplayName()?.trim();
    if (preferredName != null && preferredName.isNotEmpty) {
      return preferredName;
    }

    var username = StorageService.getUsername()?.trim() ?? '';
    if (username.isEmpty) return 'there';
    username = username[0].toUpperCase() + username.substring(1);
    return username;
  }

  String _compactHeaderName() {
    final fullName = _headerDisplayName().trim();
    if (fullName.isEmpty) return 'there';

    final segments = fullName
        .split(RegExp(r'(?<=[a-z])(?=[A-Z])|[\s_.-]+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (segments.isNotEmpty) {
      final first = segments.first.trim();
      if (first.length <= 12) return first;
    }

    if (fullName.length <= 14) return fullName;
    return fullName.substring(0, 14).trim();
  }

  String _headerAvatarSeed() {
    final preferredName = StorageService.getDisplayName()?.trim();
    if (preferredName != null && preferredName.isNotEmpty) {
      return preferredName;
    }
    return StorageService.getUsername()?.trim() ?? '';
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openShareSheet(
    CachedContributionData data,
    TrendSummary trend7d,
    TrendSummary trend30d,
  ) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      await ShareService.shareCard(
        context: context,
        data: data,
        trend7d: trend7d,
        trend30d: trend30d,
      );
    } catch (e, s) {
      AppLog.error(e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.shareError,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Widget _buildErrorState() {
    return AppEmptyState(
      icon: Icons.cloud_off_rounded,
      title: AppStrings.loadError,
      message: widget.loadError ?? AppStrings.unknownError,
      ctaLabel: AppStrings.tryAgain,
      onCta: () => widget.onRefresh(),
    );
  }

  Widget _buildAvatarFallback(String username, ColorScheme scheme) {
    return Container(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : '?',
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: AppTheme.fontTitle,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _buildHomePage(context);
}

extension _HomePageStateView on _HomePageState {
  Widget _buildTopCardReveal({
    required int order,
    required Widget child,
  }) {
    if (_prefersReducedMotion) return child;

    final start = order * 0.12;
    final end = (start + 0.44).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: _topCardsController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 0.04 + (order * 0.01)),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  Widget _buildHomePage(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final homeHeaderBaseHeight = AppTheme.homeAppBarBaseHeight * 0.86;
    final isHeaderCompact = _isHeaderCompact;
    final headerAvatarSize = isHeaderCompact
        ? AppTheme.homeAvatarSize + 2
        : AppTheme.homeAvatarSize + AppTheme.spacing12;
    final toolbarHeight = (homeHeaderBaseHeight +
            (isHeaderCompact ? AppTheme.spacing10 : AppTheme.spacing16) +
            (textScale - 1.0) * AppTheme.spacing8)
        .clamp(
      homeHeaderBaseHeight + AppTheme.spacing10,
      homeHeaderBaseHeight + AppTheme.spacing32,
    );
    final topSectionPadding = AppTheme.pagePadding(context).copyWith(
      top: AppTheme.spacing12,
      bottom: 0,
    );
    final adaptiveRecentActivityLimit = viewportHeight >= 880
        ? 7
        : viewportHeight >= 740
            ? 6
            : 5;
    final preSnapshotGap = (viewportHeight * 0.03).clamp(14.0, 28.0);
    final preStreakGap = (viewportHeight * 0.035).clamp(16.0, 30.0);
    final afterStreakGap = (viewportHeight * 0.06).clamp(24.0, 64.0);

    if (widget.isLoading && widget.data == null) {
      return const HomePageSkeleton();
    }

    if (widget.loadError != null && widget.data == null) {
      return _buildErrorState();
    }

    final data = widget.data;
    final trend7d = _trend7d;
    final trend30d = _trend30d;
    final weeklyCommitGoal = StorageService.getWeeklyCommitGoal();
    final recentActivityLimit = StorageService.getRecentActivityLimit(
      fallback: adaptiveRecentActivityLimit,
    );
    final lastSync = data != null
        ? (StorageService.getEffectiveLastSync() ?? data.lastUpdated)
        : null;
    final headerName =
        isHeaderCompact ? _compactHeaderName() : _headerDisplayName().trim();
    final avatarSeed = _headerAvatarSeed();
    final sectionBuilders = data == null
        ? const <Widget Function()>[]
        : <Widget Function()>[
            () => _HomeWeekStripSection(
                  data: data,
                  onDayTap: _showDayDetail,
                ),
            () => _HomeLast30DaysGridSection(data: data),
            () => _HomeProductivityInsightsSection(data: data),
            () => _HomeQuickNumbersSection(data: data, trend7d: trend7d),
            () => _HomeAchievementsSection(
                  data: data,
                  weeklyGoal: weeklyCommitGoal,
                ),
            () => _HomeRecentActivityFeedCard(
                  data: data,
                  limit: recentActivityLimit,
                ),
            () => _HomeQuoteCard(data: data),
            () => AppTheme.h32,
          ];

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: widget.onRefresh,
          color: scheme.primary,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                centerTitle: false,
                automaticallyImplyLeading: false,
                backgroundColor: scheme.surface,
                surfaceTintColor: scheme.surface.withValues(alpha: 0),
                scrolledUnderElevation: isHeaderCompact ? 8 : 0,
                shadowColor: scheme.shadow.withValues(alpha: 0.08),
                elevation: 0,
                toolbarHeight: toolbarHeight,
                titleSpacing:
                    isHeaderCompact ? AppTheme.spacing16 : AppTheme.spacing20,
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _openSettings,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        width: headerAvatarSize,
                        height: headerAvatarSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: scheme.outline.withValues(
                              alpha: isHeaderCompact ? 0.18 : 0.22,
                            ),
                            width: AppTheme.borderWidthHairline,
                          ),
                        ),
                        child: ClipOval(
                          child: widget.data?.avatarUrl != null
                              ? Image.network(
                                  widget.data!.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildAvatarFallback(avatarSeed, scheme),
                                )
                              : _buildAvatarFallback(avatarSeed, scheme),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isHeaderCompact
                          ? AppTheme.spacing12
                          : AppTheme.spacing14,
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi $headerName',
                            maxLines: isHeaderCompact ? 1 : 2,
                            overflow: TextOverflow.fade,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                  height: isHeaderCompact ? 1.0 : 1.08,
                                ),
                          ),
                          if (data != null && lastSync != null) ...[
                            AppTheme.h4,
                            Text(
                              'Last synced ${PresentationFormatter.formatTimeAgoCompact(lastSync)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    height: 1.05,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _openSettings,
                      visualDensity: isHeaderCompact
                          ? VisualDensity.compact
                          : VisualDensity.standard,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints.tightFor(
                        width: isHeaderCompact ? 34 : 36,
                        height: isHeaderCompact ? 34 : 36,
                      ),
                      icon: Icon(
                        Icons.settings_outlined,
                        size: isHeaderCompact ? 18 : 20,
                      ),
                    ),
                  ],
                ),
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
              if (StorageService.hasAuthError())
                SliverPadding(
                  padding: topSectionPadding,
                  sliver: SliverToBoxAdapter(
                    child: PressScale(
                      child: Semantics(
                        container: true,
                        button: true,
                        label: 'Reconnect GitHub',
                        value: 'Wallpaper updates are paused.',
                        hint: 'Open the reconnect flow.',
                        child: ExcludeSemantics(
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: AppTheme.brMedium,
                            child: InkWell(
                              borderRadius: AppTheme.brMedium,
                              onTap: () async {
                                final updated =
                                    await SettingsPage.showUpdateTokenDialog(
                                        context);
                                if (updated) widget.onRefresh();
                              },
                              child: Container(
                                padding: AppTheme.pAll16,
                                margin: AppTheme.pOnlyB16,
                                decoration: BoxDecoration(
                                  color: scheme.errorContainer,
                                  borderRadius: AppTheme.brMedium,
                                  border: Border.all(
                                    color: scheme.error.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: scheme.onErrorContainer,
                                    ),
                                    AppTheme.w12,
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Action Required: Reconnect GitHub',
                                            style: TextStyle(
                                              color: scheme.onErrorContainer,
                                              fontWeight: FontWeight.bold,
                                              fontSize: AppTheme.fontBody,
                                            ),
                                          ),
                                          AppTheme.h2,
                                          Text(
                                            'Wallpaper updates are paused. Tap to reconnect.',
                                            style: TextStyle(
                                              color: scheme.onErrorContainer
                                                  .withValues(alpha: 0.8),
                                              fontSize: AppTheme.fontCaption,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (data == null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: Icons.insights_outlined,
                    title: 'No activity yet',
                    message:
                        'Sync GitHub once to populate your Home dashboard and daily progress cards.',
                    ctaLabel: 'Refresh',
                    onCta: () => widget.onRefresh(),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: topSectionPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTopCardReveal(
                          order: 0,
                          child: _HomeTodayHeroCard(
                            data: data,
                            isLoading: widget.isLoading,
                            isSharing: _isSharing,
                            onRefresh: widget.onRefresh,
                            onOpenStats: widget.openStats,
                            onShare: () =>
                                _openShareSheet(data, trend7d, trend30d),
                          ),
                        ),
                        AppTheme.h16,
                        _buildTopCardReveal(
                          order: 1,
                          child: _HomeWeeklyGoalCard(
                            data: data,
                            weeklyGoal: weeklyCommitGoal,
                          ),
                        ),
                        SizedBox(height: preSnapshotGap),
                        _buildTopCardReveal(
                          order: 2,
                          child: _HomeJourneySnapshotCard(data: data),
                        ),
                        SizedBox(height: preStreakGap),
                        _buildTopCardReveal(
                          order: 3,
                          child: _HomeCurrentStreakCard(data: data),
                        ),
                        SizedBox(height: afterStreakGap),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: AppTheme.pagePadding(context).copyWith(top: 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Column(
                          children: [
                            if (index == 0) AppTheme.h16,
                            sectionBuilders[index](),
                            if (index != sectionBuilders.length - 1)
                              AppTheme.h16,
                          ],
                        );
                      },
                      childCount: sectionBuilders.length,
                      addRepaintBoundaries: true,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

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
  final VoidCallback onOpenStats;
  final VoidCallback onShare;

  const _HomeTodayHeroCard({
    required this.data,
    required this.isLoading,
    required this.isSharing,
    required this.onRefresh,
    required this.onOpenStats,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final today = data.stats.todayContributions;
    final streak = data.stats.currentStreak;
    final bestStreak = data.stats.longestStreak;
    final streakLabel =
        streak > 0 ? 'Streak alive - $streak days' : 'Start your streak today';

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
          Semantics(
            label: "Today's contribution count",
            value: '$today commit${today == 1 ? '' : 's'} today',
            child: ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomLeft,
                      child: AnimatedCounter(
                        value: today,
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
            ),
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
          AppTheme.h12,
          Wrap(
            spacing: AppTheme.spacing8,
            runSpacing: AppTheme.spacing8,
            children: [
              _HeroAssistChip(
                icon: Icons.emoji_events_outlined,
                label: bestStreak > 0
                    ? 'Best streak $bestStreak ${bestStreak == 1 ? 'day' : 'days'}'
                    : 'Best streak starts today',
                accentColor: scheme.tertiary,
              ),
              Semantics(
                button: true,
                label: 'View more stats',
                hint: 'Open the Stats tab',
                child: ExcludeSemantics(
                  child: _HeroAssistChip(
                    icon: Icons.query_stats_rounded,
                    label: 'View more stats',
                    accentColor: scheme.primary,
                    onTap: onOpenStats,
                  ),
                ),
              ),
            ],
          ),
          AppTheme.h16,
          Row(
            children: [
              Expanded(
                child: PressScale(
                  enabled: !isLoading,
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
              ),
              AppTheme.w12,
              Expanded(
                child: PressScale(
                  enabled: !isSharing,
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeWeeklyGoalCard extends StatelessWidget {
  final CachedContributionData data;
  final int weeklyGoal;

  const _HomeWeeklyGoalCard({required this.data, required this.weeklyGoal});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: today.weekday - 1));
    final weeklyTotal = data.days.where((d) {
      final dt = d.date.toLocal();
      final day = DateTime(dt.year, dt.month, dt.day);
      return !day.isBefore(start) && !day.isAfter(today);
    }).fold<int>(0, (s, d) => s + d.contributionCount);

    final safeWeeklyGoal = weeklyGoal > 0 ? weeklyGoal : 1;
    final progress = (weeklyTotal / safeWeeklyGoal).clamp(0.0, 1.0);
    final remaining = (safeWeeklyGoal - weeklyTotal).clamp(0, safeWeeklyGoal);

    return Semantics(
      label: 'Weekly goal',
      value: remaining == 0
          ? '$weeklyTotal of $safeWeeklyGoal commits. Goal hit this week.'
          : '$weeklyTotal of $safeWeeklyGoal commits. $remaining more commits to hit your goal.',
      child: ExcludeSemantics(
        child: AppCard(
          padding: EdgeInsets.zero,
          child: Container(
            padding: AppTheme.pAll20,
            decoration: BoxDecoration(
              borderRadius: AppTheme.brLarge,
              border: Border.all(color: scheme.outlineVariant),
              color: scheme.primary.withValues(alpha: 0.10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events_outlined,
                        size: 18, color: scheme.primary),
                    AppTheme.w12,
                    Expanded(
                      child: Text('WEEKLY GOAL',
                          style: tt.labelSmall?.copyWith(
                            color: scheme.primary,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w800,
                          )),
                    ),
                    Flexible(
                      child: Text(
                        '$weeklyTotal/$safeWeeklyGoal commits',
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                AppTheme.h12,
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
                AppTheme.h12,
                Text(
                  remaining == 0
                      ? 'Goal hit this week! 💪'
                      : '$remaining more commits to hit your goal! 💪',
                  style: tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeCurrentStreakCard extends StatelessWidget {
  final CachedContributionData data;

  const _HomeCurrentStreakCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final current = data.stats.currentStreak;
    final best = data.stats.longestStreak;
    final progress = best <= 0 ? 0.0 : (current / best).clamp(0.0, 1.0);
    final remaining = (best - current).clamp(0, best);
    final helperText = best <= 0
        ? 'Start your first streak today.'
        : remaining == 0
            ? 'You matched your best!'
            : '$remaining days away from your best!';

    return Semantics(
      label: 'Current streak',
      value: best <= 0
          ? '$current days. $helperText'
          : '$current days. Best $best days. $helperText',
      child: ExcludeSemantics(
        child: AppCard(
          padding: AppTheme.pAll20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Current Streak 🔥',
                      style: tt.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  Text('Best',
                      style: tt.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                  AppTheme.w8,
                  Text('${best}d',
                      style: tt.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              AppTheme.h12,
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedCounter(
                    value: current,
                    style:
                        tt.displaySmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  AppTheme.w8,
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('days',
                        style: tt.titleMedium
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ),
                ],
              ),
              AppTheme.h12,
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: scheme.primary,
                ),
              ),
              AppTheme.h12,
              Text(
                helperText,
                style: tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeJourneySnapshotCard extends StatelessWidget {
  final CachedContributionData data;

  const _HomeJourneySnapshotCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final currentYear = DateTime.now().toLocal().year;
    final thisYearTotal = data.days
        .where((day) => day.date.toLocal().year == currentYear)
        .fold<int>(0, (sum, day) => sum + day.contributionCount);
    final mostActiveWeekday =
        data.stats.mostActiveWeekday == AppConstants.fallbackWeekday
            ? '—'
            : data.stats.mostActiveWeekday;

    final metrics = [
      (
        label: 'All-time',
        value: null,
        animatedValue: data.totalContributions,
        formatter: PresentationFormatter.formatCompactNumber,
        subtitle: 'Total commits',
      ),
      (
        label: 'This year',
        value: null,
        animatedValue: thisYearTotal,
        formatter: PresentationFormatter.formatCompactNumber,
        subtitle: '$currentYear total',
      ),
      (
        label: 'Active days',
        value: null,
        animatedValue: data.stats.activeDaysCount,
        formatter: (value) => '$value',
        subtitle: 'Days with commits',
      ),
      (
        label: 'Best weekday',
        value: mostActiveWeekday,
        animatedValue: null,
        formatter: null,
        subtitle: 'Most productive day',
      ),
    ];

    return AppCard(
      padding: AppTheme.pAll20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'JOURNEY SNAPSHOT',
            style: tt.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          AppTheme.h12,
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 520 ? 4 : 2;
              final itemWidth =
                  (constraints.maxWidth - AppTheme.spacing12 * (columns - 1)) /
                      columns;

              return Wrap(
                spacing: AppTheme.spacing12,
                runSpacing: AppTheme.spacing12,
                children: [
                  for (final metric in metrics)
                    SizedBox(
                      width: itemWidth,
                      child: _SnapshotMetric(
                        label: metric.label,
                        value: metric.value,
                        animatedValue: metric.animatedValue,
                        formatter: metric.formatter,
                        subtitle: metric.subtitle,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SnapshotMetric extends StatelessWidget {
  final String label;
  final String? value;
  final int? animatedValue;
  final String Function(int value)? formatter;
  final String subtitle;

  const _SnapshotMetric({
    required this.label,
    required this.value,
    required this.animatedValue,
    required this.formatter,
    required this.subtitle,
  }) : assert(value != null || animatedValue != null);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final resolvedValue = animatedValue != null
        ? (formatter?.call(animatedValue!) ?? '$animatedValue')
        : value!;

    return Semantics(
      label: label,
      value: '$resolvedValue. $subtitle',
      child: ExcludeSemantics(
        child: Container(
          padding: AppTheme.pAll16,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: AppTheme.brMedium,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              AppTheme.h8,
              if (animatedValue != null)
                AnimatedCounter(
                  value: animatedValue!,
                  formatter: formatter,
                  style: tt.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                )
              else
                Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              AppTheme.h6,
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroAssistChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback? onTap;

  const _HeroAssistChip({
    required this.icon,
    required this.label,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: accentColor.withValues(alpha: onTap == null ? 0.12 : 0.10),
        border: Border.all(
          color: onTap == null
              ? accentColor.withValues(alpha: 0.20)
              : accentColor.withValues(alpha: 0.26),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppTheme.iconSM, color: accentColor),
          AppTheme.w8,
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.bodySmall?.copyWith(
                color: onTap == null ? scheme.onSurface : accentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: content,
      ),
    );
  }
}

class _HomeWeekStripSection extends StatelessWidget {
  final CachedContributionData data;
  final void Function(ContributionDay day) onDayTap;

  const _HomeWeekStripSection({required this.data, required this.onDayTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final levels = AppThemeExt.of(context).heatmapLevels;

    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final byKey = {for (final d in data.days) d.dateKey: d};
    final weekDates = List.generate(
      7,
      (i) => today.subtract(Duration(days: 6 - i)),
    );
    final activeDays = weekDates.where((d) {
      final key = AppDateUtils.formatDate(d);
      return (byKey[key]?.contributionCount ?? 0) > 0;
    }).length;

    final labels = weekDates.map((d) => DateFormat('EEE').format(d)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THIS WEEK',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
        ),
        AppTheme.h12,
        AppCard(
          padding: AppTheme.pAll20,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < weekDates.length; i++)
                    _WeekDayCell(
                      date: weekDates[i],
                      label: labels[i],
                      day: byKey[AppDateUtils.formatDate(weekDates[i])],
                      levels: levels,
                      quartiles: data.quartiles,
                      onTap: onDayTap,
                    ),
                ],
              ),
              AppTheme.h12,
              Text(
                '$activeDays of 7 days active',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeQuoteCard extends StatelessWidget {
  final CachedContributionData data;

  const _HomeQuoteCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final quote = DailyQuoteService.today(data: data);

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

class _HomeProductivityInsightsSection extends StatelessWidget {
  final CachedContributionData data;

  const _HomeProductivityInsightsSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
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
                    value:
                        bestDay == AppConstants.fallbackWeekday ? '—' : bestDay,
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

    return content;
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

    return AppCard(
      padding: AppTheme.pAll20,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppConstants.quickNumberTileMinHeight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: AppTheme.iconMD, color: scheme.onSurfaceVariant),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                AppTheme.h8,
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeAchievementsSection extends StatelessWidget {
  final CachedContributionData data;
  final int weeklyGoal;

  const _HomeAchievementsSection(
      {required this.data, required this.weeklyGoal});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final achievements = AchievementService.buildHomeAchievements(
      data: data,
      weeklyGoal: weeklyGoal,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACHIEVEMENTS',
          style: tt.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        AppTheme.h12,
        AppCard(
          padding: AppTheme.pAll20,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const cols = 4;
              const gap = 12.0;
              final itemW = ((constraints.maxWidth - (cols - 1) * gap) / cols)
                  .clamp(56.0, 84.0);
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final a in achievements)
                    SizedBox(width: itemW, child: _AchievementBadge(a: a)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final HomeAchievement a;

  const _AchievementBadge({required this.a});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bg = a.isUnlocked
        ? scheme.primary.withValues(alpha: 0.12)
        : scheme.surfaceContainerHighest;
    final fg = a.isUnlocked ? scheme.primary : scheme.onSurfaceVariant;
    final opacity = a.isUnlocked ? 1.0 : 0.38;

    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: AppTheme.spacing48,
            height: AppTheme.spacing48,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Icon(a.icon, size: AppTheme.iconMD, color: fg),
          ),
          AppTheme.h8,
          Text(
            a.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: tt.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant, fontSize: AppTheme.fontCaption),
          ),
          AppTheme.h2,
          Text(
            a.requirementLabel,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: tt.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
