import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/features/contributions/services/contribution_metrics.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/features/contributions/services/share_service.dart';
import 'package:github_wallpaper/features/contributions/widgets/share_card.dart';

// ─────────────────────────────────────────────────────────────
// WRAPPED PAGE
// ─────────────────────────────────────────────────────────────

class WrappedPage extends StatefulWidget {
  final CachedContributionData data;
  final String username;
  const WrappedPage({super.key, required this.data, required this.username});

  @override
  State<WrappedPage> createState() => _WrappedPageState();
}

class _WrappedPageState extends State<WrappedPage> {
  final _pc = PageController();
  int _currentPage = 0;

  // ── Derived stats ──────────────────────────────────────────
  late final List<ContributionDay> _yearDays;
  late final int _yearTotal;
  late final int _activeDays;
  late final ContributionDay? _bestDay;
  late final RepoContribution? _topRepo;
  late final LanguageUsage? _topLang;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc();
    final from = now.subtract(const Duration(days: 365));
    _yearDays = widget.data.days
        .where((d) => !d.date.isBefore(from) && !d.date.isAfter(now))
        .toList();
    _yearTotal = _yearDays.fold(0, (sum, d) => sum + d.contributionCount);
    _activeDays =
        _yearDays.fold(0, (sum, d) => sum + (d.contributionCount > 0 ? 1 : 0));
    _bestDay = _yearDays.isEmpty
        ? null
        : (List<ContributionDay>.from(_yearDays)
              ..sort(
                  (a, b) => b.contributionCount.compareTo(a.contributionCount)))
            .first;
    _topRepo = widget.data.repositories.isEmpty
        ? null
        : widget.data.repositories.first;
    _topLang = widget.data.topLanguages.isEmpty
        ? null
        : widget.data.topLanguages.first;
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _setCurrentPage(int page) {
    HapticFeedback.selectionClick();
    if (mounted) setState(() => _currentPage = page);
  }

  @override
  Widget build(BuildContext context) => _buildWrappedPage(context);
}

extension _WrappedPageStateView on _WrappedPageState {
  Widget _buildWrappedPage(BuildContext context) {
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

class _WrappedSlide extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final bool isDark;
  final Widget child;

  const _WrappedSlide({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTheme.h8,
        Text(
          title,
          style: (textTheme.displaySmall ?? const TextStyle(fontSize: 26))
              .copyWith(
            color: scheme.onSurface,
            height: 1.08,
            letterSpacing: -1.2,
          ),
        ),
        AppTheme.h6,
        Text(
          subtitle,
          style: TextStyle(
            fontSize: AppTheme.fontBase,
            color: scheme.onSurface.withValues(alpha: 0.60),
            fontWeight: FontWeight.w600,
          ),
        ),
        AppTheme.h24,
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: AppTheme.pAll24,
            child: child,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// RECAP SLIDE  (slide 7 — final screen with share)
// ─────────────────────────────────────────────────────────────

class _RecapSlide extends StatelessWidget {
  final CachedContributionData data;
  final int yearTotal;
  final int activeDays;
  final String topRepoName;
  final String topLanguageName;
  final Color accent;
  final bool isDark;

  const _RecapSlide({
    required this.data,
    required this.yearTotal,
    required this.activeDays,
    required this.topRepoName,
    required this.topLanguageName,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final stats = [
      _RecapStat(
        icon: Icons.commit_rounded,
        color: scheme.primary,
        label: 'Contributions',
        value: PresentationFormatter.formatCompactNumber(yearTotal),
      ),
      _RecapStat(
        icon: Icons.calendar_today_rounded,
        color: AppTheme.successGreen,
        label: 'Active days',
        value: '$activeDays',
      ),
      _RecapStat(
        icon: Icons.local_fire_department_rounded,
        color: AppTheme.warningOrange,
        label: 'Best streak',
        value: '${data.longestStreak}d',
      ),
      _RecapStat(
        icon: Icons.inventory_2_rounded,
        color: AppTheme.accentViolet,
        label: 'Active repos',
        value: '${data.activeRepositoriesCount}',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTheme.h8,
        Text(
          'That\'s a\nWrap 🎉',
          style: (textTheme.displaySmall ?? const TextStyle(fontSize: 26))
              .copyWith(
            color: scheme.onSurface,
            height: 1.08,
            letterSpacing: -1.2,
          ),
        ),
        AppTheme.h6,
        Text(
          'Your ${DateTime.now().year} on GitHub',
          style: TextStyle(
            fontSize: AppTheme.fontBase,
            color: scheme.onSurface.withValues(alpha: 0.60),
            fontWeight: FontWeight.w600,
          ),
        ),
        AppTheme.h24,

        // Recap grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppTheme.spacing12,
          mainAxisSpacing: AppTheme.spacing12,
          childAspectRatio: 1.6,
          children: stats.asMap().entries.map((e) {
            final s = e.value;
            return Container(
              padding: AppTheme.pAll16,
              decoration: BoxDecoration(
                color: s.color.withValues(alpha: isDark ? 0.10 : 0.07),
                borderRadius: AppTheme.brLarge,
                border: Border.all(color: s.color.withValues(alpha: 0.20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(s.icon, size: 16, color: s.color),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.value,
                        style: TextStyle(
                          fontSize: AppTheme.fontTitle,
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurface,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        s.label,
                        style: TextStyle(
                          fontSize: AppTheme.fontCaption,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface.withValues(alpha: 0.60),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),

        const Spacer(),

        // Share CTA
        SizedBox(
          width: double.infinity,
          height: AppTheme.spacing48 + AppTheme.spacing8,
          child: FilledButton.icon(
            onPressed: () => _share(context),
            icon: const Icon(Icons.ios_share_rounded, size: 18),
            label: const Text('Share my Wrapped'),
          ),
        ),

        AppTheme.h12,

        SizedBox(
          width: double.infinity,
          height: AppTheme.spacing48,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Back to dashboard',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface.withValues(alpha: 0.80),
              ),
            ),
          ),
        ),

        AppTheme.h20,
      ],
    );
  }

  void _share(BuildContext context) {
    final boundaryKey = GlobalKey();
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.brVertLarge),
      isScrollControlled: true,
      builder: (ctx) {
        var started = false;
        final cs = Theme.of(ctx).colorScheme;

        return StatefulBuilder(
          builder: (ctx, setState) {
            if (!started) {
              started = true;
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                try {
                  final box = ctx.findRenderObject() as RenderBox?;
                  final origin = box == null
                      ? null
                      : box.localToGlobal(Offset.zero) & box.size;
                  final bytes = await ShareService.capturePng(boundaryKey);
                  final path = await ShareService.savePngBytes(bytes,
                      prefix: 'gitwall_wrapped');
                  await ShareService.sharePngFile(
                    path,
                    text: 'My GitWall Wrapped',
                    sharePositionOrigin: origin,
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  final messenger = messengerKey.currentState;
                  if (messenger != null && messenger.mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Shared successfully!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e, s) {
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    ErrorHandler.handle(ctx, e);
                    return;
                  }
                  if (context.mounted) {
                    ErrorHandler.handle(context, e);
                    return;
                  }
                  AppLog.error(e, s);
                }
              });
            }

            return SafeArea(
              child: Padding(
                padding: AppTheme.pAll20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.outline.withValues(alpha: 0.4),
                        borderRadius: AppTheme.brXXL,
                      ),
                    ),
                    AppTheme.h16,
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Share',
                            style: TextStyle(
                              fontSize: AppTheme.fontTitle,
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                    AppTheme.h12,
                    RepaintBoundary(
                      key: boundaryKey,
                      child: WrappedShareCard(
                        username: data.username,
                        yearTotalContributions: yearTotal,
                        activeDays: activeDays,
                        bestStreakDays: data.longestStreak,
                        topRepoName: topRepoName,
                        topLanguageName: topLanguageName,
                        showBranding: false,
                      ),
                    ),
                    AppTheme.h16,
                    const LinearProgressIndicator(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RecapStat {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _RecapStat(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value});
}

class _BigNumber extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _BigNumber(
      {required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
        AppTheme.h12,
        Text(
          value,
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w900,
            height: 1.0,
            letterSpacing: -1.5,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MINI STAT CARD
// ─────────────────────────────────────────────────────────────
class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  const _MiniStatCard(
      {required this.label,
      required this.value,
      required this.accent,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: AppTheme.brLarge,
        color: scheme.surface.withValues(alpha: 0.60),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          AppTheme.h12,
          Text(
            label,
            style: TextStyle(
              fontSize: AppTheme.fontCaption,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
          AppTheme.h4,
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// REPO CARD
// ─────────────────────────────────────────────────────────────
class _RepoCard extends StatelessWidget {
  final RepoContribution repo;
  const _RepoCard({required this.repo});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          repo.nameWithOwner,
          style: TextStyle(
            fontSize: AppTheme.fontLarge,
            fontWeight: FontWeight.w900,
            color: scheme.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        AppTheme.h12,
        Text(
          '${PresentationFormatter.formatCompactNumber(repo.commitCount)} commits',
          style: TextStyle(
            fontSize: AppTheme.fontTitle,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface.withValues(alpha: 0.80),
          ),
        ),
        if (repo.primaryLanguageName != null) ...[
          AppTheme.h8,
          Text(
            repo.primaryLanguageName!,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LANGUAGE CARD  (uses real language color)
// ─────────────────────────────────────────────────────────────
class _LanguageCard extends StatelessWidget {
  final LanguageUsage lang;
  const _LanguageCard({required this.lang});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = '${(lang.percent * 100).toStringAsFixed(0)}%';

    final langColor = AppColorUtils.parseHexColor(lang.color) ?? scheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Language color dot
        Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: langColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: langColor.withValues(alpha: 0.45),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ],
              ),
            ),
            AppTheme.w8,
            Text(
              lang.name,
              style: TextStyle(
                fontSize: AppTheme.fontBase,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface.withValues(alpha: 0.70),
              ),
            ),
          ],
        ),
        AppTheme.h16,
        // Large name in language color
        Text(
          lang.name,
          style: TextStyle(
            fontSize: AppTheme.fontDisplay + AppTheme.spacing8,
            fontWeight: FontWeight.w900,
            color: langColor,
            height: 1.0,
            letterSpacing: -1.5,
          ),
        ),
        AppTheme.h8,
        Text(
          '$pct of your codebase',
          style: TextStyle(
            fontSize: AppTheme.fontTitle,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.info_outline_rounded,
            color: scheme.onSurface.withValues(alpha: 0.55)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
