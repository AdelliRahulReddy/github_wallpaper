part of 'customize_screen.dart';

extension _CustomizePageStatePreview on _CustomizePageState {
  Widget _buildNoDataState() {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: AppTheme.pAll32,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                borderRadius: AppTheme.brMedium,
              ),
              child: Icon(
                Icons.auto_awesome_outlined,
                color: scheme.primary,
              ),
            ),
            AppTheme.h24,
            Text(
              AppStrings.noDataAvailable,
              style: TextStyle(
                fontSize: AppTheme.fontLarge,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
            AppTheme.h8,
            Text(
              AppStrings.syncFirst,
              style: TextStyle(
                fontSize: AppTheme.fontBase,
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            AppTheme.h24,
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onRequestSync,
                icon: const Icon(Icons.sync),
                label: const Text(
                  AppStrings.syncNow,
                  style: TextStyle(
                    fontSize: AppTheme.fontLarge,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.brMedium,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // PREVIEW SECTION
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildPreviewSection() {
    final scheme = Theme.of(context).colorScheme;
    final dims = StorageService.getDimensions();
    final usingFallbackMetrics = dims == null;
    var wallpaperWidth = dims?['width'] ?? AppConstants.defaultWallpaperWidth;
    var wallpaperHeight =
        dims?['height'] ?? AppConstants.defaultWallpaperHeight;

    final wallpaperAspectRatio = wallpaperWidth / wallpaperHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate limits
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;

        // Keep metadata compact so preview occupies more of the top panel.
        final infoHeight = usingFallbackMetrics ? 72.0 : 48.0;
        final previewMaxHeight = (maxH - infoHeight).clamp(160.0, maxH);

        double previewHeight = previewMaxHeight;
        double previewWidth = previewHeight * wallpaperAspectRatio;

        if (previewWidth > maxW) {
          previewWidth = maxW;
          previewHeight = previewWidth / wallpaperAspectRatio;
        }

        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTheme.h12, // Standardized spacing
              Semantics(
                label:
                    'Wallpaper preview for ${_previewTargetLabel(_previewTarget)}.',
                image: true,
                child: Container(
                  height: previewHeight,
                  width: previewWidth,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: AppTheme.brLarge,
                    boxShadow: AppTheme.shadow(scheme.shadow),
                    border: Border.all(color: scheme.outline, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: AppTheme.brLarge,
                    child: Stack(
                      children: [
                        RepaintBoundary(
                          child: CustomPaint(
                            painter: WallpaperPreviewPainter(
                              data: widget.data!,
                              wallpaperWidth: wallpaperWidth,
                              wallpaperHeight: wallpaperHeight,
                              target: _previewTarget,
                              config: _configForTarget(_previewTarget),
                            ),
                            child: Container(),
                          ),
                        ),
                        // Visual Guide for System UI
                        if (_safePreviewEnabled)
                          _buildSystemUiGuides(
                            previewHeight / wallpaperHeight,
                            _previewTarget,
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              AppTheme.h8,
              Text(
                'Wallpaper Preview',
                style: TextStyle(
                  fontSize: AppTheme.fontBody,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              if (usingFallbackMetrics) ...[
                AppTheme.h8,
                Text(
                  'Refresh device fit below for the most accurate preview.',
                  style: TextStyle(
                    fontSize: AppTheme.fontCaption,
                    color: AppTheme.warningOrange,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
