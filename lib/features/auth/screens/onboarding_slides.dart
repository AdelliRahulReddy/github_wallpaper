part of 'onboarding_screen.dart';

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
                ),

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
                ),
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
