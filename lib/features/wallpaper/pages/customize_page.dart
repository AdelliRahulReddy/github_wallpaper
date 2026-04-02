// ══════════════════════════════════════════════════════════════════════════
// 🎨 CUSTOMIZE PAGE - Wallpaper Customization
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/features/wallpaper/widgets/ui_render.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/core/ui/app_components.dart';
import 'package:github_wallpaper/features/wallpaper/models/theme_presets.dart';
import 'package:github_wallpaper/features/contributions/services/daily_quotes.dart';
import 'package:github_wallpaper/app/services/background_scheduler.dart';
import 'package:github_wallpaper/features/wallpaper/services/device_config_service.dart';
import 'package:github_wallpaper/features/wallpaper/services/wallpaper_service.dart';
import 'package:github_wallpaper/features/wallpaper/models/wallpaper_templates.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:async';

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
  bool _isGeneratingQuote = false;
  bool _isRefreshingDeviceProfile = false;
  bool _autoUpdateEnabled = false;
  bool _autoApplyAfterSyncEnabled = false;
  bool _safePreviewEnabled = true;
  late final PageController _themeController;

  @override
  void initState() {
    super.initState();
    _config = _normalizedConfig(StorageService.getWallpaperConfig());
    _quoteController = TextEditingController(text: _config.customQuote);
    _autoUpdateEnabled = StorageService.getAutoUpdate();
    _autoApplyAfterSyncEnabled = StorageService.getAutoApplyAfterSync();
    _safePreviewEnabled = false;
    _themeController = PageController(
      initialPage: _themeIndexFor(_config.themeId),
      viewportFraction: 0.86,
    );
    unawaited(_ensureDeviceMetrics());
  }

  @override
  void dispose() {
    _quoteController.dispose();
    _themeController.dispose();
    super.dispose();
  }

  int _themeIndexFor(String themeId) {
    final themes = ThemePresets.all;
    final index = themes.indexWhere((theme) => theme.id == themeId);
    return index < 0 ? 0 : index;
  }

  WallpaperConfig _normalizedConfig(WallpaperConfig config) {
    return config.copyWith(
      themeId: ThemePresets.fromId(config.themeId).id,
      templateId: WallpaperTemplates.fromId(config.templateId).id,
    );
  }

  void _syncThemeGalleryToCurrentSelection({bool animate = true}) {
    final pageIndex = _themeIndexFor(_config.themeId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_themeController.hasClients) return;
      final current =
          _themeController.page?.round() ?? _themeController.initialPage;
      if (current == pageIndex) return;
      if (animate) {
        _themeController.animateToPage(
          pageIndex,
          duration: AppTheme.durationFast,
          curve: Curves.easeOutCubic,
        );
      } else {
        _themeController.jumpToPage(pageIndex);
      }
    });
  }

  WallpaperConfig _configForTarget(WallpaperTarget target) =>
      DeviceCompatibilityChecker.applyPlacement(base: _config, target: target);

  String _sanitizeQuote(String value) {
    final sanitized = ValidationUtils.sanitizeQuote(value);
    if (sanitized.length <= AppConstants.quoteMaxLength) {
      return sanitized;
    }
    return sanitized.substring(0, AppConstants.quoteMaxLength);
  }

  void _setQuoteText(String value, {bool preserveTemplateSelection = false}) {
    final next = _sanitizeQuote(value);
    if (_quoteController.text != next) {
      _quoteController.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
    _updateConfig(
      _config.copyWith(customQuote: next),
      preserveTemplateSelection: preserveTemplateSelection,
    );
  }

  Future<void> _generateQuote() async {
    if (_isGeneratingQuote || widget.data == null) return;
    HapticFeedback.lightImpact();
    setState(() => _isGeneratingQuote = true);
    try {
      final result = await DailyQuoteService.ensureDailyQuoteResult(
        data: widget.data!,
        forceRegenerate: true,
      );
      if (!mounted) return;
      _setQuoteText(result.quote);
      if (result.usedFallback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Live quote unavailable. Used your daily fallback quote.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.handle(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingQuote = false);
      }
    }
  }

  Future<void> _applyTemplate(WallpaperTemplate template) async {
    HapticFeedback.selectionClick();
    var next = template.apply(_config).copyWith(templateId: template.id);
    if (template.seedQuoteIfEmpty && next.customQuote.isEmpty) {
      next = next.copyWith(customQuote: DailyQuoteService.today());
    }
    _updateConfig(
      next,
      preserveTemplateSelection: true,
      syncQuoteField: true,
    );
    if (next.autoFitWidth) {
      _fitToWidth(preserveTemplateSelection: true);
    }
  }

  void _fitToWidth({
    WallpaperTarget? target,
    bool preserveTemplateSelection = false,
  }) {
    final dims = StorageService.getDimensions();
    final wallpaperWidth = dims?['width'] ?? AppConstants.defaultWallpaperWidth;
    final effectiveTarget = target ?? WallpaperTarget.lock;
    final effectiveConfig = _configForTarget(effectiveTarget);
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

    _updateConfig(
        _config.copyWith(
          scale: newScale,
          horizontalPosition: 0.5,
          verticalPosition: 0.5,
        ),
        preserveTemplateSelection: preserveTemplateSelection);
  }

  Future<void> _saveAndApply() async {
    const target = 'lock';
    final resolvedConfig = _normalizedConfig(_config);

    // Validate quote
    final validationError = isValidQuoteFormat(resolvedConfig.customQuote);
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
      FocusScope.of(context).unfocus();
      if (resolvedConfig != _config && mounted) {
        setState(() => _config = resolvedConfig);
      }
      await StorageService.saveWallpaperConfig(resolvedConfig);
      await StorageService.setLastWallpaperTarget(WallpaperTarget.lock);
      final ok = await widget.onSetWallpaper(target);
      if (!mounted) return;
      if (ok) {
        _showWallpaperAppliedCelebration();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Wallpaper could not be applied. Try again on the lock screen.',
            ),
            backgroundColor: AppTheme.warningOrange,
            behavior: SnackBarBehavior.floating,
          ),
        );
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

  void _showWallpaperAppliedCelebration() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => const _WallpaperAppliedCelebration(),
    );
  }

  void _updateConfig(
    WallpaperConfig newConfig, {
    bool preserveTemplateSelection = false,
    bool syncQuoteField = false,
  }) {
    var resolved = newConfig;
    if (!preserveTemplateSelection &&
        newConfig != _config &&
        newConfig.templateId != 'custom') {
      resolved = newConfig.copyWith(templateId: 'custom');
    }

    final didThemeChange = resolved.themeId != _config.themeId;
    if (syncQuoteField && _quoteController.text != resolved.customQuote) {
      _quoteController.value = TextEditingValue(
        text: resolved.customQuote,
        selection: TextSelection.collapsed(offset: resolved.customQuote.length),
      );
    }

    setState(() => _config = resolved);
    if (didThemeChange) {
      _syncThemeGalleryToCurrentSelection();
    }
  }

  Future<void> _toggleSafePreview(bool value) async {
    HapticFeedback.selectionClick();
    await StorageService.setSafePreviewEnabled(value);
    if (mounted) {
      setState(() => _safePreviewEnabled = value);
    }
  }

  Future<void> _ensureDeviceMetrics({bool forceRefresh = false}) async {
    if (_isRefreshingDeviceProfile) return;
    if (!forceRefresh && StorageService.getDimensions() != null) return;

    if (mounted) {
      setState(() => _isRefreshingDeviceProfile = true);
    }
    try {
      await DeviceConfigService.initializeFromPlatformDispatcher();
      if (!mounted) return;
      if (_config.autoFitWidth) {
        _fitToWidth(preserveTemplateSelection: true);
      } else {
        setState(() {});
      }
    } catch (e, s) {
      AppLog.error(e, s);
    } finally {
      if (mounted) {
        setState(() => _isRefreshingDeviceProfile = false);
      }
    }
  }

  Future<void> _refreshDeviceProfile() async {
    HapticFeedback.lightImpact();
    await _ensureDeviceMetrics(forceRefresh: true);
  }

  bool get _autoWallpaperEnabled =>
      _autoUpdateEnabled && _autoApplyAfterSyncEnabled;

  Future<void> _setAutoWallpaperEnabled(bool value) async {
    HapticFeedback.selectionClick();
    if (mounted) {
      setState(() {
        _autoUpdateEnabled = value;
        _autoApplyAfterSyncEnabled = value;
      });
    }

    await StorageService.setAutoUpdate(value);
    await StorageService.setAutoApplyAfterSync(value);

    if (value) {
      await BackgroundScheduler.scheduleUpdates();
    } else {
      await BackgroundScheduler.cancelUpdates();
    }
  }

  String _applyButtonLabel() => 'Set Lock Screen';

  @override
  Widget build(BuildContext context) => _buildCustomizePage(context);
}

extension _CustomizePageStateView on _CustomizePageState {
  Widget _buildCustomizePage(BuildContext context) {
    if (widget.data == null) {
      return _buildNoDataState();
    }

    final scheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;
    final basePagePadding = AppTheme.pagePadding(context);

    final previewPanel = Container(
      key: const ValueKey('customize-preview-panel'),
      width: double.infinity,
      padding: basePagePadding.copyWith(top: 12, bottom: isLandscape ? 12 : 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surface,
            scheme.surfaceContainerHighest.withValues(alpha: 0.96),
            scheme.primary.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: _buildPreviewSection(),
    );

    final controlsPanel = Container(
      key: const ValueKey('customize-controls-panel'),
      clipBehavior: isLandscape ? Clip.none : Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: isLandscape
            ? null
            : const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: isLandscape
            ? null
            : [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, -10),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: basePagePadding.copyWith(
            top: 18,
            bottom: 24,
          ),
          child: _buildControlsSections(),
        ),
      ),
    );

    if (isLandscape) {
      return Row(
        children: [
          Expanded(child: previewPanel),
          const SizedBox(width: 16),
          Expanded(child: controlsPanel),
        ],
      );
    }

    return Column(
      children: [
        Expanded(child: previewPanel),
        Expanded(child: controlsPanel),
      ],
    );
  }

  Widget _buildControlsSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: AppStrings.customize,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.restore_rounded),
                tooltip: 'Reset to Defaults',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _updateConfig(
                    WallpaperConfig.defaults(),
                    preserveTemplateSelection: true,
                    syncQuoteField: true,
                  );
                  _fitToWidth(preserveTemplateSelection: true);
                  _syncThemeGalleryToCurrentSelection();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildTemplatePicker(),
        const SizedBox(height: 14),
        _buildThemePicker(),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: _buildCustomizationSection(),
        ),
        const SizedBox(height: 16),
        _buildActionGroup(),
        const SizedBox(height: 8),
      ],
    );
  }
}

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
    final wallpaperWidth = dims?['width'] ?? AppConstants.defaultWallpaperWidth;
    final wallpaperHeight =
        dims?['height'] ?? AppConstants.defaultWallpaperHeight;
    final wallpaperAspectRatio = wallpaperWidth / wallpaperHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stageWidth = constraints.maxWidth;
        final stageHeight = constraints.maxHeight;
        final stageShortSide =
            stageWidth < stageHeight ? stageWidth : stageHeight;

        double previewHeight = stageHeight - 12;
        double previewWidth = previewHeight * wallpaperAspectRatio;

        if (previewWidth > stageWidth - 16) {
          previewWidth = stageWidth - 16;
          previewHeight = previewWidth / wallpaperAspectRatio;
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.surface.withValues(alpha: 0.92),
                      scheme.surfaceContainerHighest.withValues(alpha: 0.92),
                      scheme.tertiary.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(
                    color: scheme.outline.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
            _buildPreviewAura(
              alignment: const Alignment(-0.88, -0.78),
              color: scheme.primary,
              size: stageShortSide * 0.34,
            ),
            _buildPreviewAura(
              alignment: const Alignment(0.96, 0.58),
              color: scheme.tertiary,
              size: stageShortSide * 0.42,
            ),
            _buildPreviewAura(
              alignment: const Alignment(0.06, -0.96),
              color: scheme.secondary,
              size: stageShortSide * 0.24,
            ),
            Center(
              child: Semantics(
                label: 'Wallpaper preview for lock screen.',
                image: true,
                child: Container(
                  height: previewHeight,
                  width: previewWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(34),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        scheme.surface.withValues(alpha: 0.98),
                        scheme.surfaceContainerHigh.withValues(alpha: 0.94),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.shadow.withValues(alpha: 0.08),
                        blurRadius: 36,
                        offset: const Offset(0, 18),
                      ),
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.82),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: scheme.outline.withValues(alpha: 0.10),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            RepaintBoundary(
                              child: CustomPaint(
                                key: const ValueKey('customize-preview-canvas'),
                                painter: WallpaperPreviewPainter(
                                  data: widget.data!,
                                  wallpaperWidth: wallpaperWidth,
                                  wallpaperHeight: wallpaperHeight,
                                  target: WallpaperTarget.lock,
                                  config:
                                      _configForTarget(WallpaperTarget.lock),
                                ),
                                child: const SizedBox.expand(),
                              ),
                            ),
                            if (_safePreviewEnabled)
                              _buildSystemUiGuides(
                                previewHeight / wallpaperHeight,
                                WallpaperTarget.lock,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreviewAura({
    required Alignment alignment,
    required Color color,
    required double size,
  }) {
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.22),
                color.withValues(alpha: 0.08),
                color.withValues(alpha: 0.0),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: size * 0.42,
                spreadRadius: size * 0.04,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _CustomizePageStateTemplates on _CustomizePageState {
  Widget _buildTemplatePicker() {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isAppDark = Theme.of(context).brightness == Brightness.dark;
    final templates = WallpaperTemplates.all;

    return Container(
      padding: AppTheme.pagePadding(context),
      decoration: AppTheme.glassCard(
        context,
        opacity: isAppDark ? 0.18 : 0.14,
        tint: scheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Templates',
                  style: tt.titleLarge?.copyWith(color: scheme.onSurface),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _updateConfig(
                    _config.copyWith(autoFitWidth: true),
                    preserveTemplateSelection: true,
                  );
                  _fitToWidth(preserveTemplateSelection: true);
                },
                icon: const Icon(Icons.fit_screen_rounded, size: 16),
                label: const Text('Auto-fit'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 112,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                final isSelected = _config.templateId == template.id;

                return Padding(
                  padding: EdgeInsets.only(
                      right: index == templates.length - 1 ? 0 : 12),
                  child: Semantics(
                    button: true,
                    selected: isSelected,
                    label:
                        'Template ${template.label}. ${template.description}',
                    hint: isSelected ? 'Currently selected.' : 'Tap to apply.',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: AppTheme.brLarge,
                        onTap: () => _applyTemplate(template),
                        child: AnimatedContainer(
                          duration: AppTheme.durationFast,
                          width: 200,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: AppTheme.brLarge,
                            border: Border.all(
                              color: isSelected
                                  ? scheme.primary
                                  : scheme.outlineVariant.withValues(
                                      alpha: isAppDark ? 0.65 : 0.45),
                              width: isSelected ? 2 : 1,
                            ),
                            color: isSelected
                                ? scheme.primary
                                    .withValues(alpha: isAppDark ? 0.18 : 0.08)
                                : (isAppDark
                                    ? scheme.surface.withValues(alpha: 0.85)
                                    : scheme.surfaceContainerHighest
                                        .withValues(alpha: 0.55)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                template.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tt.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: isSelected
                                      ? scheme.primary
                                      : scheme.onSurface,
                                ),
                              ),
                              Text(
                                template.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: tt.bodySmall?.copyWith(
                                  color:
                                      scheme.onSurface.withValues(alpha: 0.65),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
}

extension _CustomizePageStateThemes on _CustomizePageState {
  Widget _buildThemePicker() {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isAppDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: AppTheme.pagePadding(context),
      decoration: AppTheme.glassCard(
        context,
        opacity: isAppDark ? 0.18 : 0.14,
        tint: scheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Color Style',
                  style: textTheme.titleLarge?.copyWith(
                    color: scheme.onSurface,
                  ),
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
                        onSelectionChanged: (selection) {
                          HapticFeedback.selectionClick();
                          _updateConfig(
                            _config.copyWith(isDarkMode: selection.first),
                          );
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
          const SizedBox(height: 14),
          Text(
            'Swipe to explore • Tap to apply',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 14),
          _buildThemeGallery(
            scheme: scheme,
            textTheme: textTheme,
            isAppDark: isAppDark,
          ),
        ],
      ),
    );
  }
}

extension _CustomizePageStateThemeGallery on _CustomizePageState {
  Widget _buildThemeGallery({
    required ColorScheme scheme,
    required TextTheme textTheme,
    required bool isAppDark,
  }) {
    final themes = ThemePresets.all;

    return Column(
      children: [
        SizedBox(
          height: 104,
          child: Stack(
            children: [
              PageView.builder(
                controller: _themeController,
                itemCount: themes.length,
                itemBuilder: (context, index) {
                  final themePreset = themes[index];
                  final isSelected = _config.themeId == themePreset.id;
                  final levels = ThemePresets.levelsFor(
                    themePreset.id,
                    isDarkMode: _config.isDarkMode,
                  );

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Semantics(
                      button: true,
                      selected: isSelected,
                      label: 'Color style ${themePreset.label}',
                      hint: isSelected
                          ? 'Currently selected.'
                          : 'Tap to apply this palette.',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: AppTheme.brLarge,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _updateConfig(
                              _config.copyWith(themeId: themePreset.id),
                            );
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
                                    : scheme.outlineVariant.withValues(
                                        alpha: isAppDark ? 0.65 : 0.45,
                                      ),
                                width: isSelected ? 2 : 1,
                              ),
                              color: isSelected
                                  ? scheme.primary.withValues(
                                      alpha: isAppDark ? 0.18 : 0.08,
                                    )
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
                                        themePreset.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: isSelected
                                              ? scheme.primary
                                              : scheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    if (themePreset.id == 'github')
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
                                              style: textTheme.labelSmall
                                                  ?.copyWith(
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
                                          horizontal: 6,
                                        ),
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
                                                      3,
                                                    ),
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
                                          color:
                                              levels[4].withValues(alpha: 0.45),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Aa',
                                          style: textTheme.labelSmall?.copyWith(
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
            count: themes.length,
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
    );
  }
}

extension _CustomizePageStateControls on _CustomizePageState {
  Widget _buildActionGroup() {
    final scheme = Theme.of(context).colorScheme;
    final autoEnabled = _autoWallpaperEnabled;
    final compactDock = MediaQuery.sizeOf(context).height < 780;

    return AppCard(
      key: const ValueKey('customize-action-group'),
      padding: EdgeInsets.fromLTRB(
        compactDock ? 14 : 16,
        compactDock ? 14 : 16,
        compactDock ? 14 : 16,
        compactDock ? 16 : 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compactDock ? 12 : 14,
              vertical: compactDock ? 10 : 12,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: scheme.outline.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: compactDock ? 32 : 34,
                  height: compactDock ? 32 : 34,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.autorenew_rounded,
                    size: compactDock ? 17 : 18,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto wallpaper',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: AppTheme.fontBase,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        autoEnabled
                            ? 'Refreshes and sets your lock screen automatically.'
                            : 'Off for now. Turn on for hands-free lock updates.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.66),
                          fontSize: compactDock
                              ? AppTheme.fontCaption
                              : AppTheme.fontSmall,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: autoEnabled,
                  onChanged: _isGenerating
                      ? null
                      : (value) => _setAutoWallpaperEnabled(value),
                ),
              ],
            ),
          ),
          SizedBox(height: compactDock ? 10 : 12),
          _buildApplyButton(compact: true),
        ],
      ),
    );
  }

  Widget _buildCustomizationSection() {
    final scheme = Theme.of(context).colorScheme;
    final showAdvanced = !_config.autoFitWidth;

    return Column(
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
        const SizedBox(height: 14),
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
        const SizedBox(height: 14),
        const Divider(),
        const SizedBox(height: 10),
        _buildTextOverlaySection(scheme),
        const SizedBox(height: 10),
        _buildStatsBarControls(scheme),
        const SizedBox(height: 14),
        const Divider(),
        const SizedBox(height: 10),
        _buildAdvancedLayoutSection(scheme, showAdvanced),
      ],
    );
  }
}

extension _CustomizePageStateControlSections on _CustomizePageState {
  Widget _buildTextOverlaySection(ColorScheme scheme) {
    return ExpansionTile(
      key: ValueKey('text-overlay-${_config.customQuote.isNotEmpty}'),
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
        _config.customQuote.isEmpty ? 'Optional quote layer' : 'Quote enabled',
        style: TextStyle(
          fontSize: AppTheme.fontCaption,
          color: scheme.onSurface.withValues(alpha: 0.7),
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        AppTheme.h8,
        Text(
          'Text stays inside the safe area so it does not clash with the lockscreen clock or bottom gesture space.',
          style: TextStyle(
            fontSize: AppTheme.fontCaption,
            color: scheme.onSurface.withValues(alpha: 0.68),
            height: 1.35,
          ),
        ),
        AppTheme.h8,
        TextField(
          controller: _quoteController,
          maxLength: AppConstants.quoteMaxLength,
          decoration: const InputDecoration(
            labelText: AppStrings.customQuote,
            hintText: AppStrings.quoteHint,
          ),
          onChanged: _setQuoteText,
        ),
        AppTheme.h8,
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _isGeneratingQuote ? null : _generateQuote,
            icon: _isGeneratingQuote
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  )
                : const Icon(Icons.auto_awesome, size: 16),
            label: Text(
              _isGeneratingQuote
                  ? 'Generating Quote...'
                  : 'Generate Live Quote',
              style: const TextStyle(fontSize: AppTheme.fontBody),
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
    );
  }

  Widget _buildStatsBarControls(ColorScheme scheme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Show bottom info bar',
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
          onChanged: (value) =>
              _updateConfig(_config.copyWith(statCurrentStreak: value)),
        ),
        AppTheme.h8,
        _buildMetricToggle(
          label: 'Longest streak',
          value: _config.statLongestStreak,
          enabled: _config.showQuickStatsBar,
          onChanged: (value) =>
              _updateConfig(_config.copyWith(statLongestStreak: value)),
        ),
        AppTheme.h8,
        _buildMetricToggle(
          label: 'Total commits',
          value: _config.statTotalCommits,
          enabled: _config.showQuickStatsBar,
          onChanged: (value) =>
              _updateConfig(_config.copyWith(statTotalCommits: value)),
        ),
        AppTheme.h8,
        _buildMetricToggle(
          label: 'Top language',
          value: _config.statTopLanguage,
          enabled: _config.showQuickStatsBar,
          onChanged: (value) =>
              _updateConfig(_config.copyWith(statTopLanguage: value)),
        ),
      ],
    );
  }

  Widget _buildPreviewToolsSection(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: AppTheme.brLarge,
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview tools',
                      style: TextStyle(
                        fontSize: AppTheme.fontBase,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Guides show where Android system UI can cover the wallpaper.',
                      style: TextStyle(
                        fontSize: AppTheme.fontCaption,
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _safePreviewEnabled,
                activeThumbColor: scheme.primary,
                onChanged: _toggleSafePreview,
              ),
            ],
          ),
          AppTheme.h8,
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed:
                  _isRefreshingDeviceProfile ? null : _refreshDeviceProfile,
              icon: _isRefreshingDeviceProfile
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                _isRefreshingDeviceProfile
                    ? 'Refreshing fit...'
                    : 'Refresh device fit',
                style: const TextStyle(fontSize: AppTheme.fontBody),
              ),
              style: TextButton.styleFrom(
                padding: AppTheme.pZero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedLayoutSection(ColorScheme scheme, bool showAdvanced) {
    return ExpansionTile(
      key: ValueKey('advanced-layout-${_config.autoFitWidth}'),
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
            ? 'Auto-fit keeps the layout inside the safe area'
            : 'Manual scale and position controls',
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
                if (value) {
                  _fitToWidth();
                }
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
        _buildPreviewToolsSection(scheme),
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
            min: AppConstants.minWallpaperScale,
            max: AppConstants.maxWallpaperScale,
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
    );
  }
}

extension _CustomizePageStateControlHelpers on _CustomizePageState {
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

  Widget _buildApplyButton({bool compact = false}) {
    final scheme = Theme.of(context).colorScheme;
    final buttonLabel = _applyButtonLabel();
    final visibleLabel = _applyButtonLabel();
    return SizedBox(
      width: double.infinity,
      child: Semantics(
        button: true,
        enabled: !_isGenerating,
        label: buttonLabel,
        child: ElevatedButton(
          onPressed: _isGenerating
              ? null
              : () {
                  HapticFeedback.heavyImpact();
                  _saveAndApply();
                },
          style: ElevatedButton.styleFrom(
            minimumSize: Size.fromHeight(compact ? 50 : 54),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 18,
              vertical: compact ? 14 : 14,
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(compact ? 22 : 26),
            ),
          ),
          child: _isGenerating
              ? SizedBox(
                  width: compact ? 20 : 24,
                  height: compact ? 20 : 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.onPrimary,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: compact ? 18 : 22,
                    ),
                    SizedBox(width: compact ? 6 : 8),
                    Flexible(
                      child: Text(
                        visibleLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize:
                              compact ? AppTheme.fontBase : AppTheme.fontLarge,
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
}

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
