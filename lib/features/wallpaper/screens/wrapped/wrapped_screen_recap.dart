part of 'wrapped_screen.dart';

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
                  final bytes = await ShareUtils.capturePng(boundaryKey);
                  final path = await ShareUtils.savePngBytes(bytes,
                      prefix: 'gitwall_wrapped');
                  await ShareUtils.sharePngFile(
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
                        showBranding:
                            MembershipEntitlements.shouldWatermarkShares,
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
