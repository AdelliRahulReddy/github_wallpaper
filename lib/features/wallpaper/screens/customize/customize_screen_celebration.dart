part of 'customize_screen.dart';

class _WallpaperAppliedCelebration extends StatefulWidget {
  const _WallpaperAppliedCelebration();

  @override
  State<_WallpaperAppliedCelebration> createState() =>
      _WallpaperAppliedCelebrationState();
}

class _WallpaperAppliedCelebrationState
    extends State<_WallpaperAppliedCelebration> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      behavior: HitTestBehavior.opaque,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Center(
              child: Container(
                margin: AppTheme.pagePadding(context),
                padding: AppTheme.pAll24,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: AppTheme.brXXL,
                  border:
                      Border.all(color: scheme.outline.withValues(alpha: 0.35)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 54,
                      color: scheme.secondary,
                    ),
                    AppTheme.h16,
                    Text(
                      'Your streak is now your wallpaper 🎉',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppTheme.fontTitle,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                        height: 1.15,
                      ),
                    ),
                    AppTheme.h8,
                    Text(
                      'It will auto-update with every sync',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppTheme.fontBase,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withValues(alpha: 0.65),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
