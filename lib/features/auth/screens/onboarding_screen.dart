import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/features/auth/screens/setup_screen.dart';

// ─────────────────────────────────────────────────────────────
// ONBOARDING PAGE  (2 slides)
// ─────────────────────────────────────────────────────────────

part 'onboarding_slides.dart';


part 'onboarding_features.dart';
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pc = PageController();
  int _page = 0;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == 0) {
      _pc.nextPage(duration: AppTheme.durationNormal, curve: Curves.easeOut);
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
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
      transitionDuration: AppTheme.durationFast,
    ))
        .whenComplete(() {
      if (mounted) _isNavigating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accents = [AppTheme.successGreen, AppTheme.accentViolet];
    final accent = accents[_page];

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: AppTheme.pagePadding(context).copyWith(top: 0, bottom: 0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _goToSetup,
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
