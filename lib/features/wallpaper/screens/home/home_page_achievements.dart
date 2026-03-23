part of 'home_page.dart';

class _HomeAchievementsSection extends StatelessWidget {
  final CachedContributionData data;
  final int weeklyGoal;

  const _HomeAchievementsSection(
      {required this.data, required this.weeklyGoal});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final achievements = AchievementService.buildHomeAchievements(
      data: data,
      weeklyGoal: weeklyGoal,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACHIEVEMENTS',
          style: tt.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        AppTheme.h12,
        AppCard(
          padding: AppTheme.pAll20,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const cols = 4;
              const gap = 12.0;
              final itemW = ((constraints.maxWidth - (cols - 1) * gap) / cols)
                  .clamp(56.0, 84.0);
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final a in achievements)
                    SizedBox(width: itemW, child: _AchievementBadge(a: a)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final HomeAchievement a;

  const _AchievementBadge({required this.a});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bg = a.isUnlocked
        ? scheme.primary.withValues(alpha: 0.12)
        : scheme.surfaceContainerHighest;
    final fg = a.isUnlocked ? scheme.primary : scheme.onSurfaceVariant;
    final opacity = a.isUnlocked ? 1.0 : 0.38;

    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: AppTheme.spacing48,
            height: AppTheme.spacing48,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Icon(a.icon, size: AppTheme.iconMD, color: fg),
          ),
          AppTheme.h8,
          Text(
            a.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: tt.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant, fontSize: AppTheme.fontCaption),
          ),
          AppTheme.h2,
          Text(
            a.requirementLabel,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: tt.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
