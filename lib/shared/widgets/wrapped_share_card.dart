part of 'share_card.dart';

class WrappedShareCard extends StatelessWidget {
  final String username;
  final int yearTotalContributions;
  final int activeDays;
  final int bestStreakDays;
  final String topRepoName;
  final String topLanguageName;
  final bool showBranding;

  const WrappedShareCard({
    super.key,
    required this.username,
    required this.yearTotalContributions,
    required this.activeDays,
    required this.bestStreakDays,
    required this.topRepoName,
    required this.topLanguageName,
    this.showBranding = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final displayName = username.trim().isEmpty
        ? 'GitWall'
        : username.trim()[0].toUpperCase() + username.trim().substring(1);
    final year = DateTime.now().year;

    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: AppTheme.pAll20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.25)),
                    ),
                    child:
                        Icon(Icons.auto_awesome_rounded, color: scheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppTheme.fontTitle,
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'GitWall Wrapped • $year',
                          style: TextStyle(
                            fontSize: AppTheme.fontCaption,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showBranding)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        'GitWall',
                        style: TextStyle(
                          fontSize: AppTheme.fontSmall,
                          fontWeight: FontWeight.w900,
                          color: scheme.primary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _HeroRow(
                label: 'Year contributions',
                value: PresentationFormatter.formatCompactNumber(
                    yearTotalContributions),
                color: scheme.primary,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MiniMetric(
                      label: 'Active days',
                      value: '$activeDays',
                      color: AppTheme.successGreen,
                      icon: Icons.calendar_today_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetric(
                      label: 'Best streak',
                      value: '${bestStreakDays}d',
                      color: AppTheme.warningOrange,
                      icon: Icons.local_fire_department_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetric(
                      label: 'Top language',
                      value:
                          topLanguageName.trim().isEmpty ? '—' : topLanguageName,
                      color: AppTheme.accentViolet,
                      icon: Icons.code_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: scheme.outline.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top repo',
                      style: TextStyle(
                        fontSize: AppTheme.fontCaption,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      topRepoName.trim().isEmpty ? '—' : topRepoName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppTheme.fontBase,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
