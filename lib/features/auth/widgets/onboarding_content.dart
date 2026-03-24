import 'package:flutter/material.dart';

import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';

class OnboardingSlideOne extends StatelessWidget {
  final Color accent;
  final bool isDark;

  const OnboardingSlideOne({
    super.key,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return _OnboardingSlideShell(
      accent: accent,
      isDark: isDark,
      tagline: AppStrings.onboardingTagline,
      title: AppStrings.onboardingTitle1,
      subtitle: AppStrings.onboardingDesc1,
      content: _AnimatedHeatmap(accent: accent, isDark: isDark),
    );
  }
}

class OnboardingSlideTwo extends StatelessWidget {
  final Color accent;
  final bool isDark;

  const OnboardingSlideTwo({
    super.key,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return _OnboardingSlideShell(
      accent: accent,
      isDark: isDark,
      tagline: AppStrings.onboardingTagline,
      title: AppStrings.onboardingTitle2,
      subtitle: AppStrings.onboardingDesc2,
      content: _FeaturesGrid(accent: accent, isDark: isDark),
    );
  }
}

class _OnboardingSlideShell extends StatelessWidget {
  final Color accent;
  final bool isDark;
  final String tagline;
  final String title;
  final String subtitle;
  final Widget content;

  const _OnboardingSlideShell({
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
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < 380 ? 18.0 : 24.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final topGap = (height * 0.05).clamp(16.0, 28.0);
        final betweenGap = (height * 0.04).clamp(14.0, 24.0);
        final contentGap = (height * 0.05).clamp(18.0, 28.0);
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: topGap),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: scheme.surface.withValues(alpha: 0.85),
                          border: Border.all(
                            color: scheme.outline.withValues(alpha: 0.35),
                          ),
                          boxShadow:
                              AppTheme.shadow(scheme.shadow, opacity: 0.10),
                        ),
                        child: Icon(
                          Icons.wallpaper_rounded,
                          color: accent,
                          size: 20,
                        ),
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
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.25),
                                  ),
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
                  Text(
                    title,
                    style: (textTheme.displaySmall ??
                            const TextStyle(fontSize: 26))
                        .copyWith(
                      color: scheme.onSurface,
                      height: 1.08,
                      letterSpacing: -1.2,
                    ),
                  ),
                  AppTheme.h16,
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
                  SizedBox(height: (height * 0.08).clamp(18.0, 42.0)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedHeatmap extends StatelessWidget {
  final Color accent;
  final bool isDark;

  const _AnimatedHeatmap({
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final levels = AppThemeExt.of(context).heatmapLevels;
    const rows = 7;
    const cols = 14;
    const total = rows * cols;
    final levelsStory = List.generate(total, (index) {
      final col = index % cols;
      final row = index ~/ cols;
      if (col <= 3) return (row % 3 == 0) ? 1 : 0;
      if (col <= 9) {
        final intensity = ((col - 4) / 5 * 3).floor() + 1;
        return intensity.clamp(1, 4);
      }
      if (col == 10) return 0;
      return (row % 2 == 0) ? 4 : 3;
    });

    const gap = 4.0;
    const cell = 16.0;

    return Container(
      padding: AppTheme.pAll24,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppTheme.brXL,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: scheme.tertiary,
                size: 14,
              ),
              AppTheme.w4,
              Flexible(
                child: Text(
                  AppStrings.onboardingHeatmapLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          AppTheme.h12,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(rows, (row) {
                return Padding(
                  padding: AppTheme.pOnlyB4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(cols, (col) {
                      final index = row * cols + col;
                      final level = levelsStory[index];
                      final color = levels[level.clamp(0, 4)];
                      return Padding(
                        padding: col == cols - 1
                            ? EdgeInsets.zero
                            : const EdgeInsets.only(right: gap),
                        child: Container(
                          width: cell,
                          height: cell,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: AppTheme.brXS,
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
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppStrings.onboardingStreakBadge,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturesGrid extends StatelessWidget {
  final Color accent;
  final bool isDark;

  const _FeaturesGrid({
    required this.accent,
    required this.isDark,
  });

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
      children: List.generate(features.length, (index) {
        final feature = features[index];
        return Padding(
          padding:
              index < features.length - 1 ? AppTheme.pOnlyB12 : EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: isDark ? 0.45 : 0.95),
              borderRadius: AppTheme.brLarge,
              border: Border.all(color: feature.color.withValues(alpha: 0.18)),
              boxShadow: AppTheme.shadow(feature.color, opacity: 0.08),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: feature.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: feature.color.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Icon(feature.icon, size: 18, color: feature.color),
                ),
                AppTheme.w12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.title,
                        style: TextStyle(
                          fontSize: AppTheme.fontBase,
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurface,
                          height: 1.2,
                        ),
                      ),
                      AppTheme.h2,
                      Text(
                        feature.desc,
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
          ),
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
