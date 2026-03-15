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
import 'package:github_wallpaper/wallpaper_templates.dart';
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

  // Parallax tilt
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  @override
  void initState() {
    super.initState();
    _config = StorageService.getWallpaperConfig();
    _quoteController = TextEditingController(text: _config.customQuote);
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
                style: TextStyle(
                  fontSize: AppTheme.fontTitle,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
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
              _buildTemplatePicker(),
              AppTheme.h12,
              _buildThemePicker(),
              AppTheme.h12,
              // Theme toggle removed
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
    return Container(
      padding: AppTheme.pagePadding(context),
      decoration: AppTheme.glassCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎨  Heatmap Theme',
            style: TextStyle(
              fontSize: AppTheme.fontBase,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          AppTheme.h4,
          Text(
            'Choose a colour palette for your wallpaper heatmap',
            style: TextStyle(
              fontSize: AppTheme.fontCaption,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          AppTheme.h12,
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ThemePresets.all.length,
              separatorBuilder: (_, __) => AppTheme.w8,
              itemBuilder: (context, index) {
                final t = ThemePresets.all[index];
                final isSelected = _config.themeId == t.id;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _updateConfig(_config.copyWith(themeId: t.id));
                  },
                  child: AnimatedContainer(
                    duration: AppTheme.durationFast,
                    width: 72,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: AppTheme.brMedium,
                      border: Border.all(
                        color: isSelected ? scheme.primary : scheme.outline.withValues(alpha: 0.4),
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? scheme.primary.withValues(alpha: 0.08)
                          : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 5-cell colour swatch preview
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int lvl = 0; lvl < t.levels.length; lvl++)
                              Container(
                                width: 9, height: 9,
                                margin: const EdgeInsets.only(right: 2),
                                decoration: BoxDecoration(
                                  color: t.levels[lvl],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                          ],
                        ),
                        AppTheme.h6,
                        Text(
                          '${t.emoji} ${t.label}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? scheme.primary : scheme.onSurface.withValues(alpha: 0.75),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatePicker() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: AppTheme.pagePadding(context),
      decoration: AppTheme.glassCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✨  Templates',
            style: TextStyle(
              fontSize: AppTheme.fontBase,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          AppTheme.h4,
          Text(
            'Apply a 1-tap layout preset',
            style: TextStyle(
              fontSize: AppTheme.fontCaption,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          AppTheme.h12,
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: WallpaperTemplates.all.length,
              separatorBuilder: (_, __) => AppTheme.w8,
              itemBuilder: (context, index) {
                final t = WallpaperTemplates.all[index];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final next = t.apply(_config);
                    _updateConfig(next);
                    _quoteController.text = next.customQuote;
                    if (next.autoFitWidth) _fitToWidth();
                  },
                  child: Container(
                    width: 170,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: AppTheme.brMedium,
                      border: Border.all(
                        color: scheme.outline.withValues(alpha: 0.4),
                        width: 1,
                      ),
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${t.emoji} ${t.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                        ),
                        AppTheme.h6,
                        Text(
                          t.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppTheme.fontCaption,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface.withValues(alpha: 0.7),
                            height: 1.25,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: ThemePresets.fromId(t.apply(_config).themeId).levels[4],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            AppTheme.w6,
                            Text(
                              'Tap to apply',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
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
    return Container(
      padding: AppTheme.pagePadding(context),
      decoration: AppTheme.glassCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  AppStrings.autoFitWidth,
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
          AppTheme.h16,
          const Divider(),
          AppTheme.h16,
          Text(
            AppStrings.textOverlay,
            style: TextStyle(
              fontSize: AppTheme.fontBase,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          AppTheme.h12,
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
          AppTheme.h4,
          if (_config.customQuote.isNotEmpty) ...[
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  AppStrings.scale,
                  style: TextStyle(
                    fontSize: AppTheme.fontBase,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
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
          AppTheme.h20,
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
          AppTheme.h20,
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
          AppTheme.h20,
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
        label: 'Apply wallpaper',
        child: ElevatedButton(
          onPressed: _isGenerating ? null : () {
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
                  AppStrings.systemClockArea,
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
                  AppStrings.gestureArea,
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
