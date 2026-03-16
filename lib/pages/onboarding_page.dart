import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:confetti/confetti.dart';
import 'package:github_wallpaper/app_theme.dart';
import 'package:github_wallpaper/app_utils.dart';
import 'package:github_wallpaper/pages/setup_page.dart';

// ─────────────────────────────────────────────────────────────
// ONBOARDING PAGE  (2 slides + Early Access CTA screen)
// ─────────────────────────────────────────────────────────────
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pc = PageController();
  int _page = 0; // 0,1 = slides  |  2 = Early Access screen
  bool _isNavigating = false;

  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _pc.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == 0) {
      _pc.nextPage(duration: 500.ms, curve: Curves.easeOutCubic);
    } else if (_page == 1) {
      // Transition to Early Access screen (page index 2 — not a PageView slide)
      setState(() => _page = 2);
      Future.delayed(200.ms, () {
        if (mounted) _confetti.play();
      });
    } else {
      _goToSetup();
    }
  }

  void _goToSetup() {
    if (!mounted || _isNavigating) return;
    _isNavigating = true;
    Navigator.of(context)
        .pushReplacement(PageRouteBuilder(
      pageBuilder: (_, a, __) => const SetupPage(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(
        opacity: a,
        child: ScaleTransition(
          scale: Tween(begin: 0.95, end: 1.0)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      transitionDuration: 700.ms,
    ))
        .whenComplete(() {
      if (mounted) _isNavigating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show Early Access screen when _page == 2
    if (_page == 2) {
      return _EarlyAccessScreen(
        confetti: _confetti,
        onContinue: _goToSetup,
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accents = [AppTheme.successGreen, AppTheme.accentViolet];
    final accent = accents[_page];

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.surface,
                    accent.withValues(alpha: isDark ? 0.10 : 0.07),
                    scheme.surface,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          _GlowBlob(
            color: accent.withValues(alpha: isDark ? 0.13 : 0.09),
            top: -160,
            right: -140,
            size: 420,
          ),
          _GlowBlob(
            color: AppTheme.successGreen.withValues(alpha: isDark ? 0.06 : 0.04),
            bottom: -120,
            left: -150,
            size: 380,
          ),
          SafeArea(
            child: Padding(
              padding: AppTheme.pagePadding(context).copyWith(top: 0, bottom: 0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        setState(() => _page = 2);
                        Future.delayed(200.ms, () {
                          if (mounted) _confetti.play();
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        backgroundColor: scheme.surface.withValues(alpha: 0.70),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                          side: BorderSide(
                              color: scheme.outline.withValues(alpha: 0.35)),
                        ),
                      ),
                      child: Text(
                        AppStrings.skip,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.72),
                            ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pc,
                      onPageChanged: (i) {
                        if (mounted) setState(() => _page = i);
                      },
                      children: [
                        _SlideOne(accent: accent, isDark: isDark),
                        _SlideTwo(accent: AppTheme.accentViolet, isDark: isDark),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.78),
                      borderRadius: AppTheme.brXL,
                      border: Border.all(
                          color: scheme.outline.withValues(alpha: 0.30)),
                      boxShadow: AppTheme.shadow(scheme.shadow, opacity: 0.10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SmoothPageIndicator(
                          controller: _pc,
                          count: 2,
                          effect: ExpandingDotsEffect(
                            activeDotColor: accent,
                            dotColor: scheme.outline.withValues(alpha: 0.25),
                            dotHeight: AppTheme.spacing8,
                            dotWidth: AppTheme.spacing8,
                            expansionFactor: 3,
                            spacing: AppTheme.spacing8 / 1.33,
                          ),
                        ),
                        AppTheme.h12,
                        SizedBox(
                          width: double.infinity,
                          height: AppTheme.spacing48 + AppTheme.spacing8,
                          child: FilledButton.icon(
                            onPressed: _next,
                            icon: Icon(
                              _page == 0
                                  ? Icons.arrow_forward_rounded
                                  : Icons.auto_awesome_rounded,
                              size: 18,
                            ),
                            label: Text(_page == 0
                                ? AppStrings.continue_
                                : AppStrings.onboardingCtaSlide2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SLIDE 1 — The Hook  (animated streak heatmap)
// ─────────────────────────────────────────────────────────────
class _SlideOne extends StatelessWidget {
  final Color accent;
  final bool isDark;
  const _SlideOne({required this.accent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _SlideShell(
      accent: accent,
      isDark: isDark,
      tagline: AppStrings.onboardingTagline,
      title: AppStrings.onboardingTitle1,
      subtitle: AppStrings.onboardingDesc1,
      content: _AnimatedHeatmap(accent: accent, isDark: isDark),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SLIDE 2 — The Features
// ─────────────────────────────────────────────────────────────
class _SlideTwo extends StatelessWidget {
  final Color accent;
  final bool isDark;
  const _SlideTwo({required this.accent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _SlideShell(
      accent: accent,
      isDark: isDark,
      tagline: AppStrings.onboardingTagline,
      title: AppStrings.onboardingTitle2,
      subtitle: AppStrings.onboardingDesc2,
      content: _FeaturesGrid(accent: accent, isDark: isDark),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHARED SLIDE SHELL
// ─────────────────────────────────────────────────────────────
class _SlideShell extends StatelessWidget {
  final Color accent;
  final bool isDark;
  final String tagline;
  final String title;
  final String subtitle;
  final Widget content;

  const _SlideShell({
    required this.accent,
    required this.isDark,
    required this.tagline,
    required this.title,
    required this.subtitle,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final w = MediaQuery.sizeOf(context).width;
    final horizontal = w < 380 ? 18.0 : 24.0;

    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxHeight;
        final topGap = (h * 0.05).clamp(16.0, 28.0);
        final betweenGap = (h * 0.04).clamp(14.0, 24.0);
        final contentGap = (h * 0.05).clamp(18.0, 28.0);
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: topGap),

                // App wordmark row
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: scheme.surface.withValues(alpha: 0.85),
                        border: Border.all(
                            color: scheme.outline.withValues(alpha: 0.35)),
                        boxShadow:
                            AppTheme.shadow(scheme.shadow, opacity: 0.10),
                      ),
                      child: Icon(Icons.wallpaper_rounded,
                          color: accent, size: 20),
                    ),
                    AppTheme.w12,
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              AppStrings.appName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: AppTheme.fontLarge,
                                fontWeight: FontWeight.w900,
                                color: scheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          AppTheme.w8,
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                    color: accent.withValues(alpha: 0.25)),
                              ),
                              child: Text(
                                tagline,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: AppTheme.fontCaption,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: betweenGap),

                // Title
                Text(
                  title,
                  style:
                      (textTheme.displaySmall ?? const TextStyle(fontSize: 26))
                          .copyWith(
                    color: scheme.onSurface,
                    height: 1.08,
                    letterSpacing: -1.2,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.12),

                AppTheme.h16,

                // Subtitle
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: AppTheme.fontLarge,
                    color: scheme.onSurface.withValues(alpha: 0.68),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                SizedBox(height: contentGap),
                Center(child: content),
                SizedBox(height: (h * 0.08).clamp(18.0, 42.0)),
              ],
            ),
          ),
        ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ANIMATED HEATMAP  (streak story)
// ─────────────────────────────────────────────────────────────
class _AnimatedHeatmap extends StatefulWidget {
  final Color accent;
  final bool isDark;
  const _AnimatedHeatmap({required this.accent, required this.isDark});

  @override
  State<_AnimatedHeatmap> createState() => _AnimatedHeatmapState();
}

class _AnimatedHeatmapState extends State<_AnimatedHeatmap>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;

  // 7 rows × 14 cols grid
  static const int _rows = 7;
  static const int _cols = 14;
  static const int _total = _rows * _cols;

  // Build a streak story:
  // cols 0-3:  sparse (level 0-1)
  // cols 4-9:  growing streak (level 2-4)
  // col  10:   missed day (special highlight)
  // cols 11-13: recovery (level 3-4)
  static final List<int> _levels = List.generate(_total, (i) {
    final col = i % _cols;
    final row = i ~/ _cols;
    if (col <= 3) return (row % 3 == 0) ? 1 : 0;
    if (col <= 9) {
      final intensity = ((col - 4) / 5 * 3).floor() + 1;
      return intensity.clamp(1, 4);
    }
    if (col == 10) return -1; // missed — special orange
    return (row % 2 == 0) ? 4 : 3;
  });

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(400.ms, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final levels = AppThemeExt.of(context).heatmapLevels;
    final highlight = AppThemeExt.of(context).heatmapHighlight;

    return AnimatedBuilder(
      animation: _progress,
      builder: (context, _) {
        final revealed = (_progress.value * _total).floor();
        const gap = 4.0;
        const cell = 16.0;
        return Container(
          padding: AppTheme.pAll24,
          decoration: BoxDecoration(
            color:
                scheme.surface.withValues(alpha: widget.isDark ? 0.45 : 0.95),
            borderRadius: AppTheme.brXL,
            border: Border.all(color: widget.accent.withValues(alpha: 0.18)),
            boxShadow: AppTheme.shadow(widget.accent, opacity: 0.14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mini legend
              Row(
                children: [
                  Icon(Icons.local_fire_department_rounded,
                      color: AppTheme.warningOrange, size: 14),
                  AppTheme.w4,
                  Flexible(
                    child: Text(
                      AppStrings.onboardingHeatmapLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppTheme.fontCaption,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ],
              ),
              AppTheme.h12,
              // Grid
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_rows, (row) {
                    return Padding(
                      padding: AppTheme.pOnlyB4,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_cols, (col) {
                          final idx = row * _cols + col;
                          final isVisible = idx < revealed;
                          final level = _levels[idx];
                          final isMissed = level == -1;
                          final color =
                              isMissed ? highlight : levels[level.clamp(0, 4)];

                          return Padding(
                            padding: col == _cols - 1
                                ? EdgeInsets.zero
                                : const EdgeInsets.only(right: gap),
                            child: AnimatedContainer(
                              duration: 120.ms,
                              width: cell,
                              height: cell,
                              decoration: BoxDecoration(
                                color: isVisible ? color : levels[0],
                                borderRadius: AppTheme.brXS,
                                boxShadow: (isVisible && level >= 3)
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.45),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    : null,
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ),
              AppTheme.h12,
              // Streak badge
              AnimatedOpacity(
                opacity: _progress.value > 0.85 ? 1.0 : 0.0,
                duration: 400.ms,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.warningOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color:
                                AppTheme.warningOrange.withValues(alpha: 0.30)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department_rounded,
                              size: 13, color: AppTheme.warningOrange),
                          AppTheme.w4,
                          Text(
                            AppStrings.onboardingStreakBadge,
                            style: TextStyle(
                              fontSize: AppTheme.fontCaption,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.warningOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FEATURES GRID  (slide 2)
// ─────────────────────────────────────────────────────────────
class _FeaturesGrid extends StatelessWidget {
  final Color accent;
  final bool isDark;
  const _FeaturesGrid({required this.accent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final features = [
      _FeatureItem(
        icon: Icons.sync_rounded,
        color: AppTheme.successGreen,
        title: AppStrings.onboardingFeature1Title,
        desc: AppStrings.onboardingFeature1Desc,
      ),
      _FeatureItem(
        icon: Icons.local_fire_department_rounded,
        color: AppTheme.warningOrange,
        title: AppStrings.onboardingFeature2Title,
        desc: AppStrings.onboardingFeature2Desc,
      ),
      _FeatureItem(
        icon: Icons.palette_rounded,
        color: AppTheme.accentViolet,
        title: AppStrings.onboardingFeature3Title,
        desc: AppStrings.onboardingFeature3Desc,
      ),
      _FeatureItem(
        icon: Icons.bar_chart_rounded,
        color: AppTheme.primaryBlue,
        title: AppStrings.onboardingFeature4Title,
        desc: AppStrings.onboardingFeature4Desc,
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(features.length, (i) {
        final f = features[i];
        return Padding(
          padding:
              i < features.length - 1 ? AppTheme.pOnlyB12 : EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: isDark ? 0.45 : 0.95),
              borderRadius: AppTheme.brLarge,
              border: Border.all(color: f.color.withValues(alpha: 0.18)),
              boxShadow: AppTheme.shadow(f.color, opacity: 0.08),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: f.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: f.color.withValues(alpha: 0.22)),
                  ),
                  child: Icon(f.icon, size: 18, color: f.color),
                ),
                AppTheme.w12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.title,
                        style: TextStyle(
                          fontSize: AppTheme.fontBase,
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurface,
                          height: 1.2,
                        ),
                      ),
                      AppTheme.h2,
                      Text(
                        f.desc,
                        style: TextStyle(
                          fontSize: AppTheme.fontCaption,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface.withValues(alpha: 0.65),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
              .animate(delay: (i * 80).ms)
              .fadeIn(duration: 350.ms)
              .slideX(begin: 0.06, curve: Curves.easeOutCubic),
        );
      }),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  const _FeatureItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });
}

// ─────────────────────────────────────────────────────────────
// EARLY ACCESS SCREEN  (replaces slide 3)
// ─────────────────────────────────────────────────────────────
class _EarlyAccessScreen extends StatelessWidget {
  final ConfettiController confetti;
  final VoidCallback onContinue;

  const _EarlyAccessScreen({
    required this.confetti,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    final unlocks = [
      _UnlockItem(
          icon: Icons.palette_rounded,
          label: AppStrings.onboardingUnlock1,
          color: AppTheme.accentViolet),
      _UnlockItem(
          icon: Icons.auto_awesome_rounded,
          label: AppStrings.onboardingUnlock2,
          color: AppTheme.successGreen),
      _UnlockItem(
          icon: Icons.tune_rounded,
          label: AppStrings.onboardingUnlock3,
          color: AppTheme.primaryBlue),
      _UnlockItem(
          icon: Icons.local_fire_department_rounded,
          label: AppStrings.onboardingUnlock4,
          color: AppTheme.warningOrange),
    ];

    return Scaffold(
      backgroundColor: scheme.surface,
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.2,
                      colors: [
                        AppTheme.successGreen
                            .withValues(alpha: isDark ? 0.12 : 0.08),
                        scheme.surface,
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: AnimatedBuilder(
                  animation: confetti,
                  builder: (context, _) {
                    if (confetti.state != ConfettiControllerState.playing) {
                      return const SizedBox.shrink();
                    }
                    return ConfettiWidget(
                      confettiController: confetti,
                      blastDirectionality: BlastDirectionality.explosive,
                      numberOfParticles: 28,
                      maxBlastForce: 18,
                      minBlastForce: 6,
                      emissionFrequency: 0.04,
                      gravity: 0.25,
                      colors: const [
                        AppTheme.successGreen,
                        AppTheme.accentViolet,
                        AppTheme.primaryBlue,
                        AppTheme.warningOrange,
                        Color(0xFFFF79C6),
                      ],
                    );
                  },
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.sizeOf(context).width < 380 ? 18 : 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AppTheme.h48,

                  // Icon badge
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: scheme.surface,
                      border: Border.all(
                          color: AppTheme.successGreen.withValues(alpha: 0.35),
                          width: 1.5),
                      boxShadow:
                          AppTheme.shadow(AppTheme.successGreen, opacity: 0.18),
                    ),
                    child: Icon(Icons.auto_awesome_rounded,
                        color: AppTheme.successGreen, size: 32),
                  )
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.easeOutBack),

                  AppTheme.h24,

                  Text(
                    AppStrings.earlyAccessTitle,
                    textAlign: TextAlign.center,
                    style: (textTheme.displaySmall ??
                            const TextStyle(fontSize: 26))
                        .copyWith(
                      color: scheme.onSurface,
                      letterSpacing: -1.0,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                  AppTheme.h12,

                  Text(
                    AppStrings.onboardingEarlyAccessSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTheme.fontLarge,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface.withValues(alpha: 0.65),
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 300.ms),

                  AppTheme.h40,

                  // Unlock pills grid
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: unlocks.asMap().entries.map((e) {
                      final i = e.key;
                      final u = e.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: u.color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: u.color.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(u.icon, size: 15, color: u.color),
                            AppTheme.w6,
                            Flexible(
                              child: Text(
                                u.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: AppTheme.fontSmall,
                                  fontWeight: FontWeight.w900,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                            AppTheme.w6,
                            Icon(Icons.check_circle_rounded,
                                size: 13,
                                color: u.color.withValues(alpha: 0.85)),
                          ],
                        ),
                      )
                          .animate(delay: (300 + i * 80).ms)
                          .fadeIn(duration: 350.ms)
                          .scale(
                              begin: const Offset(0.88, 0.88),
                              curve: Curves.easeOutBack);
                    }).toList(),
                  ),

                  AppTheme.h48,

                  // Free forever callout
                  Container(
                    width: double.infinity,
                    padding: AppTheme.pAll16,
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withValues(alpha: 0.07),
                      borderRadius: AppTheme.brLarge,
                      border: Border.all(
                          color: AppTheme.successGreen.withValues(alpha: 0.20)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.volunteer_activism_rounded,
                            color: AppTheme.successGreen, size: 20),
                        AppTheme.w12,
                        Expanded(
                          child: Text(
                            AppStrings.onboardingFreeForever,
                            style: TextStyle(
                              fontSize: AppTheme.fontBase,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface.withValues(alpha: 0.85),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.08),

                  AppTheme.h32,

                  // CTA
                  SizedBox(
                    width: double.infinity,
                    height: AppTheme.spacing48 + AppTheme.spacing8,
                    child: FilledButton.icon(
                      onPressed: onContinue,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text(AppStrings.earlyAccessCta),
                    ),
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.08),

                  AppTheme.h40,
                    ],
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

class _UnlockItem {
  final IconData icon;
  final String label;
  final Color color;
  const _UnlockItem(
      {required this.icon, required this.label, required this.color});
}

// ─────────────────────────────────────────────────────────────
// GLOW BLOB  (ambient background decoration)
// ─────────────────────────────────────────────────────────────
class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double? top, bottom, left, right;

  const _GlowBlob({
    required this.color,
    required this.size,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0.0)],
            ),
          ),
        ),
      ),
    );
  }
}
