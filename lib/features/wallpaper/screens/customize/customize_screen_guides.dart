part of 'customize_screen.dart';

extension _CustomizePageStateGuides on _CustomizePageState {
  Widget _buildSystemUiGuides(
    double previewScale,
    WallpaperTarget target,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final safeInsets = StorageService.getSafeInsets();
    if (safeInsets == EdgeInsets.zero) return const SizedBox.shrink();
    final dims = StorageService.getDimensions();
    final screenHeight = dims?['height'] ?? AppConstants.defaultWallpaperHeight;
    final isLockStyle = target != WallpaperTarget.home;
    final topGuideColor =
        isLockStyle ? AppTheme.errorRed : AppTheme.primaryBlue;
    final topGuideLabel =
        isLockStyle ? AppStrings.systemClockArea : AppStrings.statusBarArea;
    final topGuideIcon =
        isLockStyle ? Icons.lock_clock_rounded : Icons.phone_android_rounded;
    final topGuideHeight = DeviceCompatibilityChecker.reservedTopPx(
          screenHeight: screenHeight,
          safeInsets: safeInsets,
          target: target,
        ) *
        previewScale;
    final bottomGuideHeight = DeviceCompatibilityChecker.reservedBottomPx(
          screenHeight: screenHeight,
          safeInsets: safeInsets,
          target: target,
        ) *
        previewScale;
    final showTopLabel = topGuideHeight >= 28;
    final showBottomLabel = bottomGuideHeight >= 28;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topGuideHeight,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    topGuideColor.withValues(alpha: 0.16),
                    topGuideColor.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: !showTopLabel
                    ? const SizedBox.shrink()
                    : LayoutBuilder(
                        builder: (context, c) {
                          final maxWidth =
                              (c.maxWidth - 24).clamp(0.0, c.maxWidth);
                          return ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxWidth),
                            child: Container(
                              margin: EdgeInsets.only(
                                bottom: (8 * previewScale).clamp(6, 12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surface.withValues(alpha: 0.88),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: topGuideColor.withValues(alpha: 0.25),
                                ),
                                boxShadow: AppTheme.shadow(scheme.shadow,
                                    opacity: 0.08, blur: 18),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    topGuideIcon,
                                    size: 14,
                                    color: topGuideColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      topGuideLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: tt.labelSmall?.copyWith(
                                        color: topGuideColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: bottomGuideHeight,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.16),
                    AppTheme.primaryBlue.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: !showBottomLabel
                    ? const SizedBox.shrink()
                    : LayoutBuilder(
                        builder: (context, c) {
                          final maxWidth =
                              (c.maxWidth - 24).clamp(0.0, c.maxWidth);
                          return ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxWidth),
                            child: Container(
                              margin: EdgeInsets.only(
                                top: (8 * previewScale).clamp(6, 12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surface.withValues(alpha: 0.88),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppTheme.primaryBlue
                                      .withValues(alpha: 0.25),
                                ),
                                boxShadow: AppTheme.shadow(scheme.shadow,
                                    opacity: 0.08, blur: 18),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.swipe_up_rounded,
                                    size: 14,
                                    color: AppTheme.primaryBlue,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      AppStrings.gestureArea,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: tt.labelSmall?.copyWith(
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
