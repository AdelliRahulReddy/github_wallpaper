part of 'wrapped_screen.dart';

extension _WrappedScreenStateView on _WrappedScreenState {
  Widget _buildWrappedScreen(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accents = [
      scheme.primary,
      AppTheme.successGreen,
      AppTheme.accentViolet,
      scheme.secondary,
      scheme.primary,
      AppTheme.primaryBlue,
      AppTheme.successGreen, // recap slide
    ];

    final currentAccent = accents[_currentPage.clamp(0, accents.length - 1)];
    final isLastSlide = _currentPage == 6;

    final slides = [
      // Slide 1 — Hero number
      _WrappedSlide(
        title: 'Your Year\nin Code',
        subtitle: '${widget.data.username} • Last 365 days',
        accent: accents[0],
        isDark: isDark,
        child: _BigNumber(
          label: 'Total contributions',
          value: PresentationFormatter.formatCompactNumber(_yearTotal),
          accent: accents[0],
        ),
      ),

      // Slide 2 — Consistency
      _WrappedSlide(
        title: 'Consistency',
        subtitle: 'How often you showed up',
        accent: accents[1],
        isDark: isDark,
        child: Row(
          children: [
            Expanded(
              child: _MiniStatCard(
                label: 'Active days',
                value: '$_activeDays',
                accent: AppTheme.successGreen,
                icon: Icons.check_circle_rounded,
              ),
            ),
            AppTheme.w12,
            Expanded(
              child: _MiniStatCard(
                label: 'Best streak',
                value: '${widget.data.longestStreak}d',
                accent: AppTheme.warningOrange,
                icon: Icons.local_fire_department_rounded,
              ),
            ),
          ],
        ),
      ),

      // Slide 3 — Momentum
      _WrappedSlide(
        title: 'Momentum',
        subtitle: 'Right now',
        accent: accents[2],
        isDark: isDark,
        child: Row(
          children: [
            Expanded(
              child: _MiniStatCard(
                label: 'Current streak',
                value: '${widget.data.currentStreak}d',
                accent: AppTheme.warningOrange,
                icon: Icons.local_fire_department_rounded,
              ),
            ),
            AppTheme.w12,
            Expanded(
              child: _MiniStatCard(
                label: 'Today',
                value: '${widget.data.todayCommits}',
                accent: scheme.secondary,
                icon: Icons.today_rounded,
              ),
            ),
          ],
        ),
      ),

      // Slide 4 — Peak day
      _WrappedSlide(
        title: 'Peak Day',
        subtitle: 'Your biggest day',
        accent: accents[3],
        isDark: isDark,
        child: _bestDay == null
            ? const _EmptyState(text: 'No activity recorded yet.')
            : _BigNumber(
                label: _bestDay.dateKey,
                value: '${_bestDay.contributionCount}',
                accent: accents[3],
              ),
      ),

      // Slide 5 — Top repo
      _WrappedSlide(
        title: 'Top Repo',
        subtitle: 'Where you shipped the most',
        accent: accents[4],
        isDark: isDark,
        child: _topRepo == null
            ? const _EmptyState(text: 'No repository activity found.')
            : _RepoCard(repo: _topRepo),
      ),

      // Slide 6 — Top language (with real language color)
      _WrappedSlide(
        title: 'Top Language',
        subtitle: 'Your strongest signal',
        accent: accents[5],
        isDark: isDark,
        child: _topLang == null
            ? const _EmptyState(text: 'No language data found.')
            : _LanguageCard(lang: _topLang),
      ),

      // Slide 7 — Recap + Share
      _RecapSlide(
        data: widget.data,
        yearTotal: _yearTotal,
        activeDays: _activeDays,
        topRepoName: _topRepo?.nameWithOwner ?? '',
        topLanguageName: _topLang?.name ?? '',
        accent: accents[6],
        isDark: isDark,
      ),
    ];

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // ── Header ──────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: scheme.surface.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: scheme.outline.withValues(alpha: 0.35)),
                          ),
                          child: Icon(Icons.arrow_back_rounded,
                              size: 18, color: scheme.onSurface),
                        ),
                      ),
                      AppTheme.w12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GitWall Wrapped',
                              style: TextStyle(
                                fontSize: AppTheme.fontBase,
                                fontWeight: FontWeight.w900,
                                color: scheme.onSurface,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              widget.data.username,
                              style: TextStyle(
                                fontSize: AppTheme.fontCaption,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Page counter
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: currentAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: currentAccent.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          '${_currentPage + 1} / ${slides.length}',
                          style: TextStyle(
                            fontSize: AppTheme.fontCaption,
                            fontWeight: FontWeight.w900,
                            color: currentAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Page indicator ───────────────────────────
                SmoothPageIndicator(
                  controller: _pc,
                  count: slides.length,
                  effect: ExpandingDotsEffect(
                    activeDotColor: currentAccent,
                    dotColor: scheme.outline.withValues(alpha: 0.25),
                    dotHeight: 6,
                    dotWidth: 6,
                    expansionFactor: 3,
                    spacing: 5,
                  ),
                ),

                AppTheme.h8,

                // ── Slides ───────────────────────────────────
                Expanded(
                  child: PageView.builder(
                    controller: _pc,
                    itemCount: slides.length,
                    onPageChanged: (i) {
                      _setCurrentPage(i);
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: AppTheme.pagePadding(context),
                        child: slides[index],
                      );
                    },
                  ),
                ),

                // ── Bottom hint ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: AnimatedSwitcher(
                    duration: AppTheme.durationFast,
                    child: isLastSlide
                        ? const SizedBox.shrink()
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            key: const ValueKey('swipe_hint'),
                            children: [
                              Icon(Icons.swipe_rounded,
                                  size: 16,
                                  color: currentAccent.withValues(alpha: 0.65)),
                              AppTheme.w6,
                              Text(
                                'Swipe to continue',
                                style: TextStyle(
                                  fontSize: AppTheme.fontCaption,
                                  fontWeight: FontWeight.w700,
                                  color: currentAccent.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
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
