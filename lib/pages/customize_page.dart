// ══════════════════════════════════════════════════════════════════════════
// 🎨 CUSTOMIZE PAGE - Wallpaper Customization
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:github_wallpaper/app_services.dart';
import 'package:github_wallpaper/ui_render.dart';
import 'package:github_wallpaper/app_models.dart';
import 'package:github_wallpaper/app_theme.dart';
import 'package:github_wallpaper/app_utils.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:github_wallpaper/theme_presets.dart';
import 'package:github_wallpaper/daily_quotes.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

class CustomizePage extends StatefulWidget {
  final CachedContributionData? data;
  final Future<bool> Function(String) onSetWallpaper;
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
  String _deviceName = AppStrings.loading;
  static const WallpaperTarget _previewTarget = WallpaperTarget.lock;
  bool _safePreviewEnabled = true;
  late final PageController _themeController;

  // Parallax tilt
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  @override
  void initState() {
    super.initState();
    _config = StorageService.getWallpaperConfig();
    _quoteController = TextEditingController(text: _config.customQuote);
    _safePreviewEnabled = StorageService.getSafePreviewEnabled();
    _themeController = PageController(viewportFraction: 0.86);
    _loadDeviceInfo();
    _startParallax();
  }

  void _startParallax() {
    try {
      _accelSub = accelerometerEventStream().listen((e) {
        if (!mounted) return;
        setState(() {
          // Clamp to ±4° for subtlety
          _tiltX = (e.y / 9.8).clamp(-1.0, 1.0) * 4.0;
          _tiltY = (e.x / 9.8).clamp(-1.0, 1.0) * (-4.0);
        });
      });
    } catch (_) {
      // Sensor not available – fine, no parallax
    }
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _quoteController.dispose();
    _themeController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    String name = AppStrings.unknownDevice;
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        name = '${androidInfo.brand.toUpperCase()} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        name = iosInfo.utsname.machine;
      }
    } catch (e) {
      name = AppStrings.defaultDeviceName;
    }
    try {
      await StorageService.saveDeviceModel(name);
    } catch (e, s) {
      AppLog.error(e, s);
    }
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
    final newScale = (targetWidth / baseGraphWidth)
        .clamp(AppConstants.minWallpaperScale, AppConstants.maxWallpaperScale);

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
          padding: AppTheme.pSymV20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.setWallpaper,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: scheme.onSurface),
              ),
              AppTheme.h16,
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text(AppStrings.homeScreen),
                onTap: () => Navigator.pop(context, 'home'),
              ),
              ListTile(
                leading: const Icon(Icons.lock_outlined),
                title: const Text(AppStrings.lockScreen),
                onTap: () => Navigator.pop(context, 'lock'),
              ),
              ListTile(
                leading: const Icon(Icons.smartphone),
                title: const Text(AppStrings.bothScreens),
                onTap: () => Navigator.pop(context, 'both'),
              ),
              AppTheme.h8,
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
    final previewFlex = textScale > 1.2 ? 6 : 7;
    final controlsFlex = textScale > 1.2 ? 6 : 5;

    final previewPanel = Container(
      width: double.infinity,
      padding: AppTheme.pagePadding(context).copyWith(top: 12, bottom: 12),
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
          padding: AppTheme.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionHeader(
                title: AppStrings.customize,
                subtitle: _deviceName,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore_rounded),
                      tooltip: 'Reset to Defaults',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _updateConfig(WallpaperConfig.defaults());
                      },
                    ),
                    Icon(Icons.wallpaper_rounded, color: scheme.primary),
                  ],
                ),
              ),
              AppTheme.h16,
              _buildThemePicker(),
              AppTheme.h12,
              AppCard(
                padding: AppTheme.pAll16,
                child: _buildCustomizationSection(),
              ),
              AppTheme.h32,
              _buildApplyButton(),
              AppTheme.h32,
            ],
          ),
        ),
      ),
    );

    if (isLandscape) {
      return Row(
        children: [
          Expanded(child: previewPanel),
          AppTheme.w12,
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

        // Keep metadata compact so preview occupies more of the top panel.
        final infoHeight = 68.0;
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
              // 100% Unified: Removed target selector as requested ("ONE FIXED")
              // All targets (Home/Lock/Both) now share the exact same professional layout.
              AppTheme.h12, // Standardized spacing
              Semantics(
                label:
                    'Wallpaper preview for $_deviceName. Resolution $physicalWidth by $physicalHeight pixels.',
                image: true,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // perspective
                    ..rotateX(math.pi / 180 * _tiltX)
                    ..rotateY(math.pi / 180 * _tiltY),
                  transformAlignment: Alignment.center,
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
                                config:
                                    DeviceCompatibilityChecker.applyPlacement(
                                  base: _config,
                                  target: _previewTarget,
                                ),
                              ),
                              child: Container(),
                            ),
                          ),
                          // Visual Guide for System UI
                          if (_safePreviewEnabled)
                            _buildSystemUiGuides(
                                previewHeight / wallpaperHeight),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              AppTheme.h8,
              Text(
                '${AppStrings.previewFor} $_deviceName',
                style: TextStyle(
                  fontSize: AppTheme.fontBody,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              AppTheme.h4,
              Text(
                '${AppStrings.wallpaperResolution} ${physicalWidth}x${physicalHeight}px',
                style: TextStyle(
                  fontSize: AppTheme.fontCaption,
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
                textAlign: TextAlign.center,
              ),
              AppTheme.h8,
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 6,
                children: [
                  Text(
                    'Safe preview',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.78),
                        ),
                  ),
                  Switch(
                    value: _safePreviewEnabled,
                    activeThumbColor: scheme.primary,
                    onChanged: (v) async {
                      HapticFeedback.selectionClick();
                      await StorageService.setSafePreviewEnabled(v);
                      if (mounted) setState(() => _safePreviewEnabled = v);
                    },
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      await AppConfig.initializeFromPlatformDispatcher();
                      await _loadDeviceInfo();
                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Re-detect'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
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

  Widget _buildThemePicker() {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isAppDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: AppTheme.pagePadding(context),
      decoration: AppTheme.glassCard(
        context,
        opacity: isAppDark ? 0.18 : 0.12,
        tint: scheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '🎨  Color Style',
                  style: tt.titleLarge?.copyWith(color: scheme.onSurface),
                ),
              ),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Tooltip(
                      message: 'Preview mode',
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode_rounded, size: 16),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode_rounded, size: 16),
                          ),
                        ],
                        selected: {_config.isDarkMode},
                        onSelectionChanged: (s) {
                          HapticFeedback.selectionClick();
                          _updateConfig(_config.copyWith(isDarkMode: s.first));
                        },
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          AppTheme.h12,
          Text(
            'Swipe to explore • Tap to apply',
            style: tt.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          AppTheme.h12,
          SizedBox(
            height: 104,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _themeController,
                  itemCount: ThemePresets.all.length,
                  itemBuilder: (context, index) {
                    final t = ThemePresets.all[index];
                    final isSelected = _config.themeId == t.id;
                    final levels = ThemePresets.levelsFor(
                      t.id,
                      isDarkMode: _config.isDarkMode,
                    );

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: AppTheme.brLarge,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _updateConfig(_config.copyWith(themeId: t.id));
                          },
                          child: AnimatedContainer(
                            duration: AppTheme.durationFast,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: AppTheme.brLarge,
                              border: Border.all(
                                color: isSelected
                                    ? scheme.primary
                                    : scheme.outlineVariant
                                        .withValues(alpha: isAppDark ? 0.65 : 0.45),
                                width: isSelected ? 2 : 1,
                              ),
                              color: isSelected
                                  ? scheme.primary
                                      .withValues(alpha: isAppDark ? 0.18 : 0.08)
                                  : (isAppDark
                                      ? scheme.surface.withValues(alpha: 0.85)
                                      : scheme.surfaceContainerHighest
                                          .withValues(alpha: 0.55)),
                              boxShadow: isAppDark
                                  ? AppTheme.shadow(
                                      scheme.shadow,
                                      blur: 18,
                                      opacity: isSelected ? 0.18 : 0.12,
                                    )
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${t.emoji} ${t.label}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: tt.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: isSelected
                                              ? scheme.primary
                                              : scheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    if (t.id == 'github')
                                      ConstrainedBox(
                                        constraints:
                                            const BoxConstraints(maxWidth: 72),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: scheme.primary
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                color: scheme.primary
                                                    .withValues(alpha: 0.20),
                                              ),
                                            ),
                                            child: Text(
                                              'Default',
                                              style: tt.labelSmall?.copyWith(
                                                color: scheme.primary,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    else if (isSelected)
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 18,
                                        color: scheme.primary,
                                      )
                                    else
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 18,
                                        color: scheme.onSurface
                                            .withValues(alpha: 0.55),
                                      ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 12,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          color: scheme.surface
                                              .withValues(alpha: 0.35),
                                          border: Border.all(
                                            color: scheme.outline
                                                .withValues(alpha: 0.20),
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6),
                                        child: Row(
                                          children: [
                                            for (int i = 0;
                                                i < levels.length;
                                                i++)
                                              Expanded(
                                                child: Container(
                                                  margin: EdgeInsets.only(
                                                    right:
                                                        i == levels.length - 1
                                                            ? 0
                                                            : 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: levels[i],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            3),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color:
                                            levels[4].withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: levels[4]
                                              .withValues(alpha: 0.45),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Aa',
                                          style: tt.labelSmall?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: scheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IgnorePointer(
                    child: Container(
                      width: 22,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            scheme.surface.withValues(alpha: 0.92),
                            scheme.surface.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IgnorePointer(
                    child: Container(
                      width: 22,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            scheme.surface.withValues(alpha: 0.92),
                            scheme.surface.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: SmoothPageIndicator(
              controller: _themeController,
              count: ThemePresets.all.length,
              effect: ExpandingDotsEffect(
                activeDotColor: scheme.primary,
                dotColor: scheme.outline.withValues(alpha: 0.25),
                dotHeight: 7,
                dotWidth: 7,
                expansionFactor: 3.2,
                spacing: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // CUSTOMIZATION SECTION
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildCustomizationSection() {
    final scheme = Theme.of(context).colorScheme;
    final showAdvanced = !_config.autoFitWidth;
    return Container(
      padding: AppTheme.pagePadding(context),
      decoration: AppTheme.glassCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Quick Adjust',
                  style: TextStyle(
                    fontSize: AppTheme.fontBase,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: scheme.primary.withValues(alpha: 0.20)),
                ),
                child: Text(
                  _config.autoFitWidth ? 'Auto-fit' : 'Manual',
                  style: TextStyle(
                    fontSize: AppTheme.fontSmall,
                    fontWeight: FontWeight.w900,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          AppTheme.h12,
          _buildSlider(
            label: AppStrings.opacity,
            value: _config.opacity,
            min: 0.3,
            max: 1.0,
            divisions: 7,
            onChanged: (value) {
              _updateConfig(_config.copyWith(opacity: value));
            },
          ),
          AppTheme.h16,
          _buildSlider(
            label: AppStrings.cornerRadius,
            value: _config.cornerRadius,
            min: 0,
            max: 8,
            divisions: 8,
            onChanged: (value) {
              _updateConfig(_config.copyWith(cornerRadius: value));
            },
          ),
          AppTheme.h16,
          const Divider(),
          AppTheme.h12,
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            initiallyExpanded: _config.customQuote.isNotEmpty,
            title: Text(
              AppStrings.textOverlay,
              style: TextStyle(
                fontSize: AppTheme.fontBase,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            subtitle: Text(
              _config.customQuote.isEmpty ? 'Optional' : 'Enabled',
              style: TextStyle(
                fontSize: AppTheme.fontCaption,
                color: scheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            children: [
              AppTheme.h8,
              TextField(
                controller: _quoteController,
                decoration: const InputDecoration(
                  labelText: AppStrings.customQuote,
                  hintText: AppStrings.quoteHint,
                ),
                onChanged: (value) {
                  _updateConfig(_config.copyWith(customQuote: value));
                },
              ),
              AppTheme.h8,
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    final quote = DailyQuoteService.today();
                    _quoteController.text = quote;
                    _updateConfig(_config.copyWith(customQuote: quote));
                  },
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text(
                    "Use Today's Quote",
                    style: TextStyle(fontSize: AppTheme.fontBody),
                  ),
                  style: TextButton.styleFrom(
                    padding: AppTheme.pZero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              if (_config.customQuote.isNotEmpty) ...[
                AppTheme.h8,
                _buildSlider(
                  label: AppStrings.quoteSize,
                  value: _config.quoteFontSize,
                  min: 10.0,
                  max: 40.0,
                  divisions: 15,
                  onChanged: (value) {
                    _updateConfig(_config.copyWith(quoteFontSize: value));
                  },
                ),
                AppTheme.h12,
                _buildSlider(
                  label: AppStrings.quoteOpacity,
                  value: _config.quoteOpacity,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  onChanged: (value) {
                    _updateConfig(_config.copyWith(quoteOpacity: value));
                  },
                ),
              ],
              AppTheme.h8,
            ],
          ),
          AppTheme.h8,
          Row(
            children: [
              Expanded(
                child: Text(
                  'Show stats bar',
                  style: TextStyle(
                    fontSize: AppTheme.fontBase,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Switch(
                value: _config.showQuickStatsBar,
                activeThumbColor: scheme.primary,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  _updateConfig(_config.copyWith(showQuickStatsBar: value));
                },
              ),
            ],
          ),
          AppTheme.h8,
          _buildMetricToggle(
            label: 'Current streak',
            value: _config.statCurrentStreak,
            enabled: _config.showQuickStatsBar,
            onChanged: (v) =>
                _updateConfig(_config.copyWith(statCurrentStreak: v)),
          ),
          AppTheme.h8,
          _buildMetricToggle(
            label: 'Longest streak',
            value: _config.statLongestStreak,
            enabled: _config.showQuickStatsBar,
            onChanged: (v) =>
                _updateConfig(_config.copyWith(statLongestStreak: v)),
          ),
          AppTheme.h8,
          _buildMetricToggle(
            label: 'Total commits',
            value: _config.statTotalCommits,
            enabled: _config.showQuickStatsBar,
            onChanged: (v) =>
                _updateConfig(_config.copyWith(statTotalCommits: v)),
          ),
          AppTheme.h8,
          _buildMetricToggle(
            label: 'Top language',
            value: _config.statTopLanguage,
            enabled: _config.showQuickStatsBar,
            onChanged: (v) =>
                _updateConfig(_config.copyWith(statTopLanguage: v)),
          ),
          AppTheme.h8,
          AppTheme.h8,
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            initiallyExpanded: showAdvanced,
            title: Text(
              'Advanced Layout',
              style: TextStyle(
                fontSize: AppTheme.fontBase,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            subtitle: Text(
              _config.autoFitWidth
                  ? 'Turn off auto-fit to unlock scale'
                  : 'Scale and position controls',
              style: TextStyle(
                fontSize: AppTheme.fontCaption,
                color: scheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.autoFitWidth,
                      style: TextStyle(
                        fontSize: AppTheme.fontBase,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  Switch(
                    value: _config.autoFitWidth,
                    activeThumbColor: scheme.primary,
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      _updateConfig(_config.copyWith(autoFitWidth: value));
                    },
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _fitToWidth();
                  },
                  icon: const Icon(Icons.fit_screen, size: 16),
                  label: const Text(
                    AppStrings.autoFixDevice,
                    style: TextStyle(fontSize: AppTheme.fontBody),
                  ),
                  style: TextButton.styleFrom(
                    padding: AppTheme.pZero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              AppTheme.h12,
              Text(
                AppStrings.scale,
                style: TextStyle(
                  fontSize: AppTheme.fontBase,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              AppTheme.h8,
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
              AppTheme.h12,
              Text(
                AppStrings.layoutNote,
                style: TextStyle(
                  fontSize: AppTheme.fontCaption,
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              AppTheme.h12,
              _buildSlider(
                label: AppStrings.positionVertical,
                value: _config.verticalPosition,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                onChanged: (value) {
                  _updateConfig(_config.copyWith(verticalPosition: value));
                },
              ),
              AppTheme.h20,
              _buildSlider(
                label: AppStrings.positionHorizontal,
                value: _config.horizontalPosition,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                onChanged: (value) {
                  _updateConfig(_config.copyWith(horizontalPosition: value));
                },
              ),
              AppTheme.h8,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricToggle({
    required String label,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppTheme.fontBody,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: scheme.primary,
            onChanged: !enabled
                ? null
                : (v) {
                    HapticFeedback.selectionClick();
                    onChanged(v);
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
            AppTheme.w12,
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
        AppTheme.h8,
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
            onChanged: (double val) {
              HapticFeedback.selectionClick();
              onChanged(val);
            },
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
        label: AppStrings.applyWallpaper,
        child: ElevatedButton(
          onPressed: _isGenerating
              ? null
              : () {
                  HapticFeedback.heavyImpact();
                  _saveAndApply();
                },
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
                    AppTheme.w8,
                    Flexible(
                      child: Text(
                        AppStrings.applyWallpaper,
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
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final safeInsets = StorageService.getSafeInsets();
    if (safeInsets == EdgeInsets.zero) return const SizedBox.shrink();

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: safeInsets.top * previewScale +
                (76 * previewScale).clamp(36, 90),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.errorRed.withValues(alpha: 0.16),
                    AppTheme.errorRed.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: LayoutBuilder(
                  builder: (context, c) {
                    final maxWidth =
                        (c.maxWidth - 24).clamp(0.0, c.maxWidth);
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Container(
                        margin: EdgeInsets.only(bottom: 8 * previewScale),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppTheme.errorRed.withValues(alpha: 0.25),
                          ),
                          boxShadow: AppTheme.shadow(scheme.shadow,
                              opacity: 0.08, blur: 18),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_clock_rounded,
                                size: 14, color: AppTheme.errorRed),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                AppStrings.systemClockArea,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: tt.labelSmall?.copyWith(
                                  color: AppTheme.errorRed,
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
            height: safeInsets.bottom * previewScale +
                (34 * previewScale).clamp(18, 44),
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
                child: LayoutBuilder(
                  builder: (context, c) {
                    final maxWidth =
                        (c.maxWidth - 24).clamp(0.0, c.maxWidth);
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Container(
                        margin: EdgeInsets.only(top: 8 * previewScale),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color:
                                AppTheme.primaryBlue.withValues(alpha: 0.25),
                          ),
                          boxShadow: AppTheme.shadow(scheme.shadow,
                              opacity: 0.08, blur: 18),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.swipe_up_rounded,
                                size: 14, color: AppTheme.primaryBlue),
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

// ══════════════════════════════════════════════════════════════════════════
// WALLPAPER PREVIEW PAINTER
// ══════════════════════════════════════════════════════════════════════════
