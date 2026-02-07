// ══════════════════════════════════════════════════════════════════════════
// 🎨 CUSTOMIZE PAGE - Wallpaper Customization
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:github_wallpaper/app_services.dart';
import 'package:github_wallpaper/ui_render.dart';
import 'package:github_wallpaper/app_models.dart';
import 'package:github_wallpaper/app_theme.dart';
import 'package:github_wallpaper/app_utils.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class CustomizePage extends StatefulWidget {
  final CachedContributionData? data;
  final Function(String) onSetWallpaper;
  final VoidCallback? onRequestSync;

  const CustomizePage({
    super.key,
    required this.data,
    required this.onSetWallpaper,
    this.onRequestSync,
  });

  @override
  State<CustomizePage> createState() => _CustomizePageState();
}

class _CustomizePageState extends State<CustomizePage> {
  late WallpaperConfig _config;
  late TextEditingController _quoteController;
  bool _isGenerating = false;
  String _deviceName = 'Loading...';
  // Fixed to lock screen layout; preview uses MonthHeatmapRenderer for all targets
  static const WallpaperTarget _previewTarget = WallpaperTarget.lock;

  @override
  void initState() {
    super.initState();
    _config = StorageService.getWallpaperConfig();
    _quoteController = TextEditingController(text: _config.customQuote);
    _loadDeviceInfo();
  }

  @override
  void dispose() {
    _quoteController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    String name = 'Unknown Device';
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        name = '${androidInfo.brand.toUpperCase()} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        name = iosInfo.utsname.machine;
      }
    } catch (e) {
      name = 'Mobile Device';
    }
    try {
      await StorageService.saveDeviceModel(name);
    } catch (_) {}
    if (mounted) {
      setState(() => _deviceName = name);
    }
  }

  void _fitToWidth() {
    final dims = StorageService.getDimensions();
    final wallpaperWidth = dims?['width'] ?? AppConstants.defaultWallpaperWidth;
    final effectiveConfig = DeviceCompatibilityChecker.applyPlacement(
      base: _config,
      target: _previewTarget,
    );
    final targetWidth = wallpaperWidth -
        effectiveConfig.paddingLeft -
        effectiveConfig.paddingRight;
    // Preview always uses month calendar (7 columns)
    const columns = AppConstants.monthGridColumns;
    final baseGraphWidth =
        (AppConstants.heatmapBoxSize + AppConstants.heatmapBoxSpacing) *
                columns -
            AppConstants.heatmapBoxSpacing;

    // Increased max scale from 3.0 to 8.0 to support Month view (Lock screen) correctly
    final newScale = (targetWidth / baseGraphWidth).clamp(0.5, 8.0);

    _updateConfig(_config.copyWith(
      scale: newScale,
      horizontalPosition: 0.5,
      verticalPosition: 0.5,
    ));
  }

  Future<void> _saveAndApply() async {
    final scheme = Theme.of(context).colorScheme;
    final target = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: scheme.surfaceContainerHighest,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Set Wallpaper',
                style: TextStyle(
                  fontSize: AppTheme.fontTitle,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Home Screen'),
                onTap: () => Navigator.pop(context, 'home'),
              ),
              ListTile(
                leading: const Icon(Icons.lock_outlined),
                title: const Text('Lock Screen'),
                onTap: () => Navigator.pop(context, 'lock'),
              ),
              ListTile(
                leading: const Icon(Icons.smartphone),
                title: const Text('Both Screens'),
                onTap: () => Navigator.pop(context, 'both'),
              ),
              const SizedBox(height: AppTheme.spacing8),
            ],
          ),
        ),
      ),
    );

    if (target == null || !mounted) return;

    // Validate quote
    final validationError = isValidQuoteFormat(_config.customQuote);
    if (validationError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationError),
            backgroundColor: AppTheme.warningOrange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isGenerating = true);

    try {
      await StorageService.saveWallpaperConfig(_config);
      await widget.onSetWallpaper(target);

      if (mounted) {
        ErrorHandler.showSuccess(context, 'Wallpaper updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.handle(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _updateConfig(WallpaperConfig newConfig) {
    setState(() => _config = newConfig);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data == null) {
      return _buildNoDataState();
    }

    final scheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;
    final textScale = media.textScaler.scale(1.0);
    final previewFlex = textScale > 1.2 ? 5 : 6;
    final controlsFlex = textScale > 1.2 ? 7 : 6;

    final previewPanel = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing20,
        vertical: AppTheme.spacing16,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outline.withValues(alpha: 0.55)),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(child: _buildPreviewSection()),
    );

    final controlsPanel = Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacing20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionHeader(
                title: 'Customize',
                subtitle: _deviceName,
                trailing: Icon(Icons.wallpaper_rounded, color: scheme.primary),
              ),
              const SizedBox(height: AppTheme.spacing16),
              // Theme toggle removed
              AppCard(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                child: _buildCustomizationSection(),
              ),
              const SizedBox(height: AppTheme.spacing32),
              _buildApplyButton(),
              const SizedBox(height: AppTheme.spacing32),
            ],
          ),
        ),
      ),
    );

    if (isLandscape) {
      return Row(
        children: [
          Expanded(child: previewPanel),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(child: controlsPanel),
        ],
      );
    }

    return Column(
      children: [
        Expanded(flex: previewFlex, child: previewPanel),
        Expanded(flex: controlsFlex, child: controlsPanel),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // NO DATA STATE
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildNoDataState() {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              ),
              child: Icon(
                Icons.palette_outlined,
                size: 40,
                color: scheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),
            Text(
              'No data available',
              style: TextStyle(
                fontSize: AppTheme.fontLarge,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Sync your GitHub data first',
              style: TextStyle(
                fontSize: AppTheme.fontBase,
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onRequestSync,
                icon: const Icon(Icons.sync),
                label: const Text(
                  'Sync Now',
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
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
    var wallpaperWidth = dims?['width'] ?? AppConstants.defaultWallpaperWidth;
    var wallpaperHeight =
        dims?['height'] ?? AppConstants.defaultWallpaperHeight;
    final wallpaperPixelRatio =
        dims?['pixelRatio'] ?? AppConstants.defaultPixelRatio;

    final physicalWidth = (wallpaperWidth * wallpaperPixelRatio).round();
    final physicalHeight = (wallpaperHeight * wallpaperPixelRatio).round();

    final wallpaperAspectRatio = wallpaperWidth / wallpaperHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate limits
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;

        // Reserve space for text info, but allow scrolling if needed
        // Increased infoHeight buffer from 60 to 120 to be safer
        final infoHeight = 120.0;
        final previewMaxHeight = (maxH - infoHeight).clamp(120.0, maxH);

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
              // 100% Unified: Removed target selector as requested ("ONE FIXED")
              // All targets (Home/Lock/Both) now share the exact same professional layout.
              const SizedBox(height: 10),
              Semantics(
                label:
                    'Wallpaper preview for $_deviceName. Resolution $physicalWidth by $physicalHeight pixels.',
                image: true,
                child: Container(
                  height: previewHeight,
                  width: previewWidth,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    boxShadow: AppTheme.shadow(scheme.shadow),
                    border: Border.all(color: scheme.outline, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    child: Stack(
                      children: [
                        RepaintBoundary(
                          child: CustomPaint(
                            key: ValueKey(
                                '${_config.hashCode}_${_previewTarget.name}'),
                            painter: _WallpaperPreviewPainter(
                              data: widget.data!,
                              wallpaperWidth: wallpaperWidth,
                              wallpaperHeight: wallpaperHeight,
                              target: _previewTarget,
                              config: DeviceCompatibilityChecker.applyPlacement(
                                base: _config,
                                target: _previewTarget,
                              ),
                            ),
                            child: Container(),
                          ),
                        ),
                        // Visual Guide for System UI
                        _buildSystemUiGuides(previewHeight / wallpaperHeight),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Preview for $_deviceName',
                style: TextStyle(
                  fontSize: AppTheme.fontBody,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Wallpaper: ${physicalWidth}x${physicalHeight}px',
                style: TextStyle(
                  fontSize: AppTheme.fontCaption,
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // THEME SECTION
  // ══════════════════════════════════════════════════════════════════════

// Theme section removed as per user request ("REMOVE DARK AND LIGHHT MODE WE KEEP SYSTEM DEFAULT")

  // ══════════════════════════════════════════════════════════════════════
  // CUSTOMIZATION SECTION
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildCustomizationSection() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: AppTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Text Overlay',
            style: TextStyle(
              fontSize: AppTheme.fontBase,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _quoteController,
            decoration: InputDecoration(
              labelText: 'Custom Quote',
              hintText: 'Enter your motivation...',
              filled: true,
              fillColor: scheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing12,
              ),
            ),
            onChanged: (value) {
              _updateConfig(_config.copyWith(customQuote: value));
            },
          ),
          const SizedBox(height: 12),
          if (_config.customQuote.isNotEmpty) ...[
            _buildSlider(
              label: 'Quote Size',
              value: _config.quoteFontSize,
              min: 10.0,
              max: 40.0,
              divisions: 15,
              onChanged: (value) {
                _updateConfig(_config.copyWith(quoteFontSize: value));
              },
            ),
            const SizedBox(height: 12),
            _buildSlider(
              label: 'Quote Opacity',
              value: _config.quoteOpacity,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              onChanged: (value) {
                _updateConfig(_config.copyWith(quoteOpacity: value));
              },
            ),
          ],
          const SizedBox(height: AppTheme.spacing24),
          const Divider(),
          const SizedBox(height: AppTheme.spacing24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Scale',
                  style: TextStyle(
                    fontSize: AppTheme.fontBase,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _fitToWidth,
                icon: const Icon(Icons.fit_screen, size: 16),
                label: const Text('Fit Width',
                    style: TextStyle(fontSize: AppTheme.fontBody)),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Auto Fit Width',
                  style: TextStyle(
                    fontSize: AppTheme.fontBase,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Switch(
                value: _config.autoFitWidth,
                activeThumbColor: scheme.primary,
                onChanged: (value) {
                  _updateConfig(_config.copyWith(autoFitWidth: value));
                },
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: scheme.primary,
              inactiveTrackColor: scheme.outline.withValues(alpha: 0.6),
              thumbColor: scheme.primary,
              overlayColor: scheme.primary.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: _config.scale,
              min: 0.5,
              max: 8.0,
              divisions: 75,
              onChanged: _config.autoFitWidth
                  ? null
                  : (value) {
                      _updateConfig(_config.copyWith(scale: value));
                    },
            ),
          ),
          const SizedBox(height: AppTheme.spacing20),
          _buildSlider(
            label: 'Opacity',
            value: _config.opacity,
            min: 0.3,
            max: 1.0,
            divisions: 7,
            onChanged: (value) {
              _updateConfig(_config.copyWith(opacity: value));
            },
          ),
          const SizedBox(height: AppTheme.spacing20),
          _buildSlider(
            label: 'Corner Radius',
            value: _config.cornerRadius,
            min: 0,
            max: 8,
            divisions: 8,
            onChanged: (value) {
              _updateConfig(_config.copyWith(cornerRadius: value));
            },
          ),
          const SizedBox(height: AppTheme.spacing20),
          Text(
            'Layout automatically reserves space for the status bar/notch and lock-screen clock. Position controls are applied after that.',
            style: TextStyle(
              fontSize: AppTheme.fontCaption,
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildSlider(
            label: 'Position (Vertical, within safe area)',
            value: _config.verticalPosition,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: (value) {
              _updateConfig(_config.copyWith(verticalPosition: value));
            },
          ),
          const SizedBox(height: AppTheme.spacing20),
          _buildSlider(
            label: 'Position (Horizontal, within safe area)',
            value: _config.horizontalPosition,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: (value) {
              _updateConfig(_config.copyWith(horizontalPosition: value));
            },
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // SLIDER WIDGET
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppTheme.fontBase,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                fontSize: AppTheme.fontSmall,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: scheme.primary,
            inactiveTrackColor: scheme.outline.withValues(alpha: 0.6),
            thumbColor: scheme.primary,
            overlayColor: scheme.primary.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // APPLY BUTTON
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildApplyButton() {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: Semantics(
        button: true,
        enabled: !_isGenerating,
        label: 'Apply wallpaper',
        child: ElevatedButton(
          onPressed: _isGenerating ? null : _saveAndApply,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing16,
              vertical: AppTheme.spacing12,
            ),
            backgroundColor: scheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
          child: _isGenerating
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.onPrimary,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 22),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Apply Wallpaper',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppTheme.fontLarge,
                          fontWeight: FontWeight.w600,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSystemUiGuides(double previewScale) {
    // Only show for Lock Screen mode to avoid clutter
    // 100% Unified: Guides now relevant for all targets since they share the same layout
    // if (_previewTarget != WallpaperTarget.lock) return const SizedBox.shrink();

    final safeInsets = StorageService.getSafeInsets();
    if (safeInsets == EdgeInsets.zero) return const SizedBox.shrink();

    return IgnorePointer(
      child: Stack(
        children: [
          // Clock Area Indicator (approximate)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height:
                safeInsets.top * previewScale + 60, // Padding + space for clock
            child: Container(
              color: AppTheme.errorRed.withValues(alpha: 0.1),
              child: const Center(
                child: Text(
                  'SYSTEM CLOCK AREA',
                  style: TextStyle(
                      color: AppTheme.errorRed,
                      fontSize: AppTheme.fontCaption,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          // Navigation / Gesture Indicator
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: safeInsets.bottom * previewScale + 20,
            child: Container(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              child: const Center(
                child: Text(
                  'GESTURE AREA',
                  style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: AppTheme.fontCaption,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// WALLPAPER PREVIEW PAINTER
// ══════════════════════════════════════════════════════════════════════════

class _WallpaperPreviewPainter extends CustomPainter {
  final CachedContributionData data;
  final WallpaperConfig config;
  final double wallpaperWidth;
  final double wallpaperHeight;
  final WallpaperTarget target;

  _WallpaperPreviewPainter({
    required this.data,
    required this.config,
    required this.wallpaperWidth,
    required this.wallpaperHeight,
    required this.target,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (wallpaperWidth <= 0 || wallpaperHeight <= 0) return;
    final scaleX = size.width / wallpaperWidth;
    final scaleY = size.height / wallpaperHeight;
    canvas.save();
    canvas.scale(scaleX, scaleY);
    final wallpaperSize = Size(wallpaperWidth, wallpaperHeight);
    // 100% Unified: Always use MonthHeatmapRenderer for preview consistency
    MonthHeatmapRenderer.render(
      canvas: canvas,
      size: wallpaperSize,
      data: data,
      config: config,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WallpaperPreviewPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.data != data ||
        oldDelegate.wallpaperWidth != wallpaperWidth ||
        oldDelegate.wallpaperHeight != wallpaperHeight ||
        oldDelegate.target != target;
  }
}
