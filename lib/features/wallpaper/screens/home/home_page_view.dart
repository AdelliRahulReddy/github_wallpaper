part of 'home_page.dart';

extension _HomePageStateView on _HomePageState {
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
    final preSnapshotGap = (viewportHeight * 0.03).clamp(14.0, 28.0);
    final preStreakGap = (viewportHeight * 0.035).clamp(16.0, 30.0);
    final afterStreakGap = (viewportHeight * 0.06).clamp(24.0, 64.0);

    if (widget.isLoading && widget.data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.loadError != null && widget.data == null) {
      return _buildErrorState();
    }

    final data = widget.data;
    final trend7d = _trend7d;
    final trend30d = _trend30d;
    final weeklyCommitGoal = StorageService.getWeeklyCommitGoal();
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
            () => _HomeRecentActivityFeedCard(data: data, limit: 5),
            () => const _HomeQuoteCard(),
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
                    child: GestureDetector(
                      onTap: () async {
                        final updated =
                            await SettingsPage.showUpdateTokenDialog(context);
                        if (updated) widget.onRefresh();
                      },
                      child: Container(
                        padding: AppTheme.pAll16,
                        margin: AppTheme.pOnlyB16,
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: AppTheme.brMedium,
                          border: Border.all(
                              color: scheme.error.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: scheme.onErrorContainer),
                            AppTheme.w12,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
              if (data == null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: AppTheme.pagePadding(context),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        'No data yet.',
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.70),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: topSectionPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HomeTodayHeroCard(
                          data: data,
                          isLoading: widget.isLoading,
                          isSharing: _isSharing,
                          onRefresh: widget.onRefresh,
                          onShare: () =>
                              _openShareSheet(data, trend7d, trend30d),
                        ),
                        AppTheme.h16,
                        _HomeWeeklyGoalCard(
                          data: data,
                          weeklyGoal: weeklyCommitGoal,
                        ),
                        SizedBox(height: preSnapshotGap),
                        _HomeJourneySnapshotCard(data: data),
                        SizedBox(height: preStreakGap),
                        _HomeCurrentStreakCard(data: data),
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
                      addAutomaticKeepAlives: false,
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
