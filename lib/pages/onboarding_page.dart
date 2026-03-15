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
      AppTheme.successGreen, // Slide 1: Contributions (Green)
      AppTheme.accentViolet, // Slide 2: Sync
      scheme.primary,        // Slide 3: Support
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
              onPageChanged: (i) {
                if (mounted) setState(() => _page = i);
              },
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
                  title: '100% Private,\n100% Yours',
                  subtitle:
                      'Your data never leaves your device. Secure, local, and built for privacy.',
                  isDark: isDark,
                  accent: accent,
                  content: const _PrivacyDemo(),
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
                        color: scheme.onSurface.withValues(alpha: 0.6),
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
                  AppTheme.h24,
                    SizedBox(
                      width: double.infinity,
                      height: AppTheme.spacing48 + AppTheme.spacing8, // 56
                      child: FilledButton(
                        onPressed: _next,
                        child: Text(_page < 2 ? 'Continue' : 'Get Started'),
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
          _cloud(80, null, 120, null),
          _cloud(null, 200, 60, null),
        ] else ...[
          _star(100, 80, null, null, 3),
          _star(200, null, 60, null, 2),
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
        _star(100, 80, null, null, 3),
        _star(150, null, 120, null, 2),
        _star(80, null, null, 180, 2.5),
        _star(null, 90, 140, null, 2),
      ],
    ];
  }

  Widget _star(double? top, double? right, double? left, double? bottom,
      double size) {
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
                blurRadius: 4.0,
              )
            ]),
      ),
    );
  }

  Widget _cloud(double? top, double? bottom, double? left, double? right) {
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
            borderRadius: AppTheme.brMedium),
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
    final scheme = Theme.of(context).colorScheme;
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: AppTheme.pSymH32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTheme.h80, // spacing60 + spacing20
                Text(title,
                    style: TextStyle(
                        fontSize: AppTheme.fontDisplay + AppTheme.spacing8,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                        height: 1.1,
                        letterSpacing: -1.5)),
                AppTheme.h20,
                Text(subtitle,
                    style: TextStyle(
                        fontSize: AppTheme.fontLarge,
                        color: scheme.onSurface.withValues(alpha: 0.7),
                        height: 1.5,
                        fontWeight: FontWeight.w500)),
                AppTheme.h40,
                Expanded(
                  child: Center(child: content),
                ),
                AppTheme.h140, // spacer for bottom controls
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
    final levels = AppThemeExt.of(context).heatmapLevels;

    return Container(
      padding: AppTheme.pAll32,
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: isDark ? 0.45 : 0.95),
        borderRadius: AppTheme.brXL,
        border: Border.all(color: accent.withValues(alpha: 0.2)),
        boxShadow: AppTheme.shadow(accent, opacity: 0.15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          7,
          (r) => Padding(
            padding: AppTheme.pOnlyB4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(12, (c) {
                final level = (r + c) % 5;
                return Padding(
                  padding: AppTheme.pOnlyR4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                        color: levels[level],
                        borderRadius: AppTheme.brXS),
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

// Slide 3: Privacy Demo
class _PrivacyDemo extends StatelessWidget {
  const _PrivacyDemo();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: AppTheme.pAll32,
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: isDark ? 0.45 : 0.95),
        borderRadius: AppTheme.brXL,
        border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
        boxShadow: AppTheme.shadow(scheme.primary, opacity: 0.1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: AppTheme.pAll24,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_outlined,
              size: 64,
              color: scheme.primary,
            ),
          ),
          AppTheme.h24,
          Text(
            'Secure & Local',
            style: TextStyle(
              fontSize: AppTheme.fontLarge,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          AppTheme.h8,
          Text(
            'Direct GitHub API connection.\nEverything stays on your device.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTheme.fontBase,
              color: scheme.onSurface.withValues(alpha: 0.6),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
