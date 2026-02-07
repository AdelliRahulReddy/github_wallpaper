import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:github_wallpaper/app_theme.dart';
import 'package:github_wallpaper/pages/setup_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pc = PageController();
  int _page = 0;
  bool _isNavigatingToSetup = false;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _pc.nextPage(duration: 500.ms, curve: Curves.easeOutCubic);
    } else {
      _navigateToSetup();
    }
  }

  void _navigateToSetup() {
    if (!mounted || _isNavigatingToSetup) return;
    _isNavigatingToSetup = true;

    Navigator.of(context)
        .pushReplacement(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SetupPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
      transitionDuration: 800.ms,
    ))
        .whenComplete(() {
      if (mounted) {
        _isNavigatingToSetup = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accents = [
      scheme.primary,
      AppTheme.accentViolet,
      scheme.secondary,
    ];
    final accent = accents[_page];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Sky elements (Adapted)
            ..._buildSky(context, _page, accent, isDark),

            // Pages
            PageView(
              controller: _pc,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                _Slide(
                  title: 'Your Code,\nVisualized',
                  subtitle:
                      'Transform your GitHub contributions into beautiful, minimal wallpapers',
                  isDark: isDark,
                  accent: accent,
                  content: _ContributionDemo(accent: accent, isDark: isDark),
                ),
                _Slide(
                  title: 'Always\nUpdated',
                  subtitle:
                      'Your wallpaper syncs automatically as you commit code throughout the day',
                  isDark: isDark,
                  accent: accent,
                  content: _SyncDemo(accent: accent),
                ),
                _Slide(
                  title: 'Make It\nYours',
                  subtitle:
                      'Customize colors, layout, and style to match your aesthetic',
                  isDark: isDark,
                  accent: accent,
                  content: const _CustomizeDemo(),
                ),
              ],
            ),

            // Skip
            Positioned(
              top: AppTheme.spacing16,
              right: AppTheme.spacing20,
              child: TextButton(
                onPressed: _navigateToSetup,
                child: Text('Skip',
                    style: TextStyle(
                        color: (isDark ? AppTheme.darkText : AppTheme.lightText)
                            .withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                        fontSize: AppTheme.fontMedium)),
              ),
            ),

            // Bottom controls
            Positioned(
              bottom: AppTheme.spacing40,
              left: AppTheme.spacing24,
              right: AppTheme.spacing24,
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pc,
                    count: 3,
                    effect: ExpandingDotsEffect(
                      activeDotColor: accent,
                      dotColor: accent.withValues(alpha: 0.15),
                      dotHeight: AppTheme.spacing8,
                      dotWidth: AppTheme.spacing8,
                      expansionFactor: 3,
                      spacing: AppTheme.spacing8 / 1.33,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing24),
                  SizedBox(
                    width: double.infinity,
                    height: AppTheme.spacing32 + AppTheme.spacing24,
                    child: FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: scheme.onPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusLarge)),
                        elevation: 2,
                        shadowColor: accent.withValues(alpha: 0.2),
                      ),
                      child: Text(_page < 2 ? 'Continue' : 'Get Started',
                          style: const TextStyle(
                              fontSize: AppTheme.fontLarge,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3)),
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

  List<Widget> _buildSky(
      BuildContext context, int page, Color accent, bool isDark) {
    final scheme = Theme.of(context).colorScheme;
    return [
      // Sun/Moon based on page
      if (page == 0) ...[
        Positioned(
          top: 60,
          right: 40,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? scheme.surface.withValues(alpha: 0.35)
                  : scheme.secondary.withValues(alpha: 0.5),
              boxShadow: [
                BoxShadow(
                    color: isDark
                        ? scheme.surface.withValues(alpha: 0.2)
                        : scheme.secondary.withValues(alpha: 0.35),
                    blurRadius: 40,
                    spreadRadius: 10)
              ],
            ),
          ),
        ),
        if (!isDark) ...[
          _cloud(80, null, 120, null, 0),
          _cloud(null, 200, 60, null, 800),
        ] else ...[
          _star(100, 80, null, null, 3, 0),
          _star(200, null, 60, null, 2, 800),
        ]
      ] else if (page == 1) ...[
        Positioned(
          top: 50,
          right: 50,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accent,
                  AppTheme.accentViolet.withValues(alpha: 0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                    color: accent.withValues(alpha: 0.45),
                    blurRadius: 50,
                    spreadRadius: 15)
              ],
            ),
          ),
        ),
      ] else ...[
        Positioned(
          top: 60,
          right: 40,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.surface.withValues(alpha: isDark ? 0.3 : 0.9),
              boxShadow: [
                BoxShadow(
                    color: (isDark ? scheme.surface : scheme.primary)
                        .withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 8)
              ],
            ),
          ),
        ),
        _star(100, 80, null, null, 3, 0),
        _star(150, null, 120, null, 2, 400),
        _star(80, null, null, 180, 2.5, 800),
        _star(null, 90, 140, null, 2, 1200),
      ],
    ];
  }

  // ... (keep _star and _cloud helpers if needed, or remove if unused in modified logic)
  Widget _star(double? top, double? right, double? left, double? bottom,
      double size, int delay) {
    return Positioned(
      top: top,
      right: right,
      left: left,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.5),
                blurRadius: AppTheme.spacing8 / 2,
              )
            ]),
      ),
    );
  }

  Widget _cloud(
      double? top, double? bottom, double? left, double? right, int delay) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 80,
        height: 30,
        decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final String title, subtitle;
  final bool isDark;
  final Color accent;
  final Widget content;

  const _Slide(
      {required this.title,
      required this.subtitle,
      required this.isDark,
      required this.accent,
      required this.content});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppTheme.spacing60 + AppTheme.spacing20),
                Text(title,
                    style: TextStyle(
                        fontSize: AppTheme.fontDisplay + AppTheme.spacing8,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppTheme.darkText : AppTheme.lightText,
                        height: 1.1,
                        letterSpacing: -1.5)),
                const SizedBox(height: AppTheme.spacing20),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: AppTheme.fontLarge,
                        color: (isDark ? AppTheme.darkText : AppTheme.lightText)
                            .withValues(alpha: 0.7),
                        height: 1.5,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: AppTheme.spacing40),
                Expanded(
                  child: Center(child: content),
                ),
                const SizedBox(
                    height: AppTheme.spacing32 +
                        AppTheme.spacing32 +
                        AppTheme.spacing32 +
                        AppTheme.spacing32 +
                        AppTheme.spacing12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Slide 1: Contribution Demo
class _ContributionDemo extends StatelessWidget {
  final Color accent;
  final bool isDark;
  const _ContributionDemo({required this.accent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest.withValues(
      alpha: isDark ? 0.9 : 1,
    );
    final colors = [
      base,
      accent.withValues(alpha: 0.3),
      accent.withValues(alpha: 0.5),
      accent.withValues(alpha: 0.7),
      accent
    ];

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing32),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: isDark ? 0.45 : 0.95),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
        boxShadow: AppTheme.shadow(accent, opacity: 0.15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          7,
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing8 / 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(12, (c) {
                final level = (r + c) % 5;
                return Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacing8 / 2),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                        color: colors[level],
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall / 2)),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// Slide 2: Sync Demo
class _SyncDemo extends StatelessWidget {
  final Color accent;
  const _SyncDemo({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing rings
        ...List.generate(
          3,
          (i) => Container(
            width: 180.0 + (i * 40),
            height: 180.0 + (i * 40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: accent.withValues(alpha: 0.2 - (i * 0.04)),
                  width: 1.5),
            ),
          ),
        ),

        // Center icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: Icon(Icons.sync_rounded, size: 48, color: accent),
        ),
      ],
    );
  }
}

// Slide 3: Customize Demo
class _CustomizeDemo extends StatelessWidget {
  const _CustomizeDemo();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _card(
            LinearGradient(
                colors: [scheme.primary, AppTheme.primaryBrandAccent]),
            'Ocean Blue',
            0,
            context),
        const SizedBox(height: AppTheme.spacing16),
        _card(
            LinearGradient(
                colors: [AppTheme.primaryBrandAccent, AppTheme.accentViolet]),
            'Purple Dream',
            200,
            context),
        const SizedBox(height: AppTheme.spacing16),
        _card(LinearGradient(colors: [scheme.secondary, scheme.primary]),
            'Green Energy', 400, context),
      ],
    );
  }

  Widget _card(
      LinearGradient gradient, String name, int delay, BuildContext context) {
    final onGradient =
        ThemeData.estimateBrightnessForColor(gradient.colors[0]) ==
                Brightness.dark
            ? AppTheme.lightSurface
            : AppTheme.darkBg;
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing24,
        vertical: AppTheme.spacing16,
      ),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
              color:
                  Theme.of(context).colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: onGradient.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium - 2)),
            child: Icon(Icons.palette_rounded, color: onGradient, size: 22),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Text(name,
              style: TextStyle(
                  color: onGradient,
                  fontSize: AppTheme.fontLarge,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2)),
          const Spacer(),
          Icon(Icons.arrow_forward_ios_rounded,
              color: onGradient.withValues(alpha: 0.8), size: 18),
        ],
      ),
    );
  }
}
