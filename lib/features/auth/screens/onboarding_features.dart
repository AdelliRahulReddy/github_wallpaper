part of 'onboarding_screen.dart';

class _AnimatedHeatmap extends StatelessWidget {
  final Color accent;
  final bool isDark;
  const _AnimatedHeatmap({required this.accent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final levels = AppThemeExt.of(context).heatmapLevels;
    const rows = 7;
    const cols = 14;
    const total = rows * cols;
    final levelsStory = List.generate(total, (i) {
      final col = i % cols;
      final row = i ~/ cols;
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
              Icon(Icons.local_fire_department_rounded,
                  color: scheme.tertiary, size: 14),
              AppTheme.w4,
              Flexible(
                child: Text(
                  AppStrings.onboardingHeatmapLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
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
                      final idx = row * cols + col;
                      final level = levelsStory[idx];
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
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
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
              ,
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
