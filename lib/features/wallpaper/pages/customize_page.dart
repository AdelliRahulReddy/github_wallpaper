// ══════════════════════════════════════════════════════════════════════════
// 🎨 CUSTOMIZE PAGE - Wallpaper Customization
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/features/wallpaper/widgets/ui_render.dart';
import 'package:github_wallpaper/features/membership/controllers/membership_controller.dart';
import 'package:github_wallpaper/features/membership/pages/membership_paywall_page.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/core/ui/app_components.dart';
import 'package:github_wallpaper/features/wallpaper/models/theme_presets.dart';
import 'package:github_wallpaper/features/contributions/services/daily_quotes.dart';
import 'package:github_wallpaper/features/membership/services/membership_entitlements.dart';
import 'package:github_wallpaper/app/services/background_scheduler.dart';
import 'package:github_wallpaper/features/wallpaper/services/device_config_service.dart';
import 'package:github_wallpaper/features/wallpaper/services/wallpaper_service.dart';
import 'package:github_wallpaper/features/wallpaper/models/wallpaper_templates.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:provider/provider.dart';
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
  late WallpaperTarget _previewTarget;
  bool _safePreviewEnabled = true;
  late final PageController _themeController;

  @override
  void initState() {
    super.initState();
    _config = StorageService.getWallpaperConfig();
    if (!MembershipEntitlements.isThemeUnlocked(_config.themeId)) {
      _config = _config.copyWith(
        themeId: MembershipEntitlements.normalizeThemeId(_config.themeId),
      );
    }
    if (!MembershipEntitlements.isTemplateUnlocked(_config.templateId)) {
      _config = _config.copyWith(
        templateId: MembershipEntitlements.normalizeTemplateId(
          _config.templateId,
        ),
      );
    }
    _quoteController = TextEditingController(text: _config.customQuote);
    _previewTarget = StorageService.getLastWallpaperTarget();
    _safePreviewEnabled = StorageService.getSafePreviewEnabled();
    _themeController = PageController(
      initialPage: _themeIndexFor(_config.themeId),
      viewportFraction: 0.86,
    );
    unawaited(_ensureDeviceMetrics());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _normalizeConfigForMembership();
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

  void _normalizeConfigForMembership() {
    var next = _config;
    if (!MembershipEntitlements.isThemeUnlocked(next.themeId)) {
      next = next.copyWith(
        themeId: MembershipEntitlements.normalizeThemeId(next.themeId),
      );
    }
    if (!MembershipEntitlements.isTemplateUnlocked(next.templateId)) {
      next = next.copyWith(
        templateId: MembershipEntitlements.normalizeTemplateId(next.templateId),
      );
    }
    if (next == _config) return;
    setState(() => _config = next);
    _syncThemeGalleryToCurrentSelection(animate: false);
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
    if (!context.read<MembershipController>().hasProAccess) return;
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

  Future<bool> _promptForLockedAccess({
    required String featureName,
    required String featureDescription,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MembershipPaywallPage(
          featureName: featureName,
          featureDescription: featureDescription,
        ),
      ),
    );
    if (!mounted) return false;
    final refreshed = context.read<MembershipController>().info ??
        StorageService.getCachedMembershipInfo();
    if (refreshed?.hasProAccess == true &&
        BackgroundScheduler.shouldScheduleReminderChecks()) {
      await BackgroundScheduler.scheduleStreakReminders();
    }
    if (mounted) {
      setState(() {});
    }
    return refreshed?.hasProAccess == true;
  }

  Future<void> _applyTemplate(WallpaperTemplate template) async {
    if (!MembershipEntitlements.isTemplateUnlocked(template.id)) {
      final unlocked = await _promptForLockedAccess(
        featureName: template.label,
        featureDescription:
            '${template.label} is a Pro template with a more styled layout and polish.',
      );
      if (!unlocked || !mounted) return;
    }

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
    final effectiveTarget = target ?? _previewTarget;
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

  void _setPreviewTarget(WallpaperTarget target) {
    if (_previewTarget == target) return;
    HapticFeedback.selectionClick();
    setState(() => _previewTarget = target);
    if (_config.autoFitWidth) {
      _fitToWidth(target: target, preserveTemplateSelection: true);
    }
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
                leading: const Icon(Icons.lock_outlined),
                title: const Text(AppStrings.lockScreen),
                subtitle: const Text('Recommended for the cleanest layout'),
                onTap: () => Navigator.pop(context, 'lock'),
              ),
              ListTile(
                leading: const Icon(Icons.smartphone),
                title: const Text('Both Screens (Advanced)'),
                subtitle: const Text(
                    'Also mirrors the wallpaper to your home screen'),
                onTap: () => Navigator.pop(context, 'both'),
              ),
              AppTheme.h8,
            ],
          ),
        ),
      ),
    );

    if (target == null || !mounted) return;

    final targetEnum = switch (target) {
      'home' => WallpaperTarget.home,
      'lock' => WallpaperTarget.lock,
      'both' => WallpaperTarget.both,
      _ => WallpaperTarget.lock,
    };
    _setPreviewTarget(targetEnum);

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
      final ok = await widget.onSetWallpaper(target);
      if (ok && mounted) {
        _showWallpaperAppliedCelebration();
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

  String _previewTargetLabel(WallpaperTarget target) {
    switch (target) {
      case WallpaperTarget.home:
        return AppStrings.homeScreen;
      case WallpaperTarget.lock:
        return AppStrings.lockScreen;
      case WallpaperTarget.both:
        return AppStrings.bothScreens;
    }
  }

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
                        _setPreviewTarget(WallpaperTarget.lock);
                        _fitToWidth(preserveTemplateSelection: true);
                        _syncThemeGalleryToCurrentSelection();
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
                  '🧩  Templates',
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
          AppTheme.h12,
          if (!MembershipEntitlements.hasProAccess)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Free includes the essentials. Locked templates stay visible so you can preview the Pro set.',
                style: tt.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ),
          SizedBox(
            height: 112,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                final isUnlocked =
                    MembershipEntitlements.isTemplateUnlocked(template.id);
                final isSelected = _config.templateId == template.id;

                return Padding(
                  padding: EdgeInsets.only(
                      right: index == templates.length - 1 ? 0 : 12),
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
                        ),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${template.emoji} ${template.label}',
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
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.65),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            if (!isUnlocked)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        scheme.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: scheme.primary
                                          .withValues(alpha: 0.18),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.lock_rounded,
                                        size: 12,
                                        color: scheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Pro',
                                        style: tt.labelSmall?.copyWith(
                                          color: scheme.primary,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
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
          AppTheme.h12,
          Text(
            MembershipEntitlements.hasProAccess
                ? 'Swipe to explore • Tap to apply'
                : 'Swipe to explore • Free palettes apply instantly, Pro palettes open access',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          AppTheme.h12,
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
                  final isUnlocked =
                      MembershipEntitlements.isThemeUnlocked(themePreset.id);
                  final isSelected = _config.themeId == themePreset.id;
                  final levels = ThemePresets.levelsFor(
                    themePreset.id,
                    isDarkMode: _config.isDarkMode,
                  );

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: AppTheme.brLarge,
                        onTap: () async {
                          if (!isUnlocked) {
                            final unlocked = await _promptForLockedAccess(
                              featureName: themePreset.label,
                              featureDescription:
                                  '${themePreset.label} is a Pro palette. Claim access to use the full color system.',
                            );
                            if (!unlocked || !mounted) return;
                          }
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
                                      '${themePreset.emoji} ${themePreset.label}',
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
                                  if (!isUnlocked)
                                    Container(
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
                                              .withValues(alpha: 0.18),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.lock_rounded,
                                            size: 12,
                                            color: scheme.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Pro',
                                            style:
                                                textTheme.labelSmall?.copyWith(
                                              color: scheme.primary,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else if (themePreset.id == 'github')
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
                                            style:
                                                textTheme.labelSmall?.copyWith(
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
                                        borderRadius: BorderRadius.circular(6),
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
                                                  right: i == levels.length - 1
                                                      ? 0
                                                      : 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: levels[i],
                                                  borderRadius:
                                                      BorderRadius.circular(3),
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
                                      color: levels[4].withValues(alpha: 0.18),
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
        if (!MembershipEntitlements.hasProAccess) ...[
          const SizedBox(height: 10),
          Text(
            'Free includes the essential palettes. Locked palettes stay visible so you can preview what Pro unlocks.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.60),
            ),
          ),
        ],
      ],
    );
  }
}

extension _CustomizePageStateControls on _CustomizePageState {
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
          _buildTextOverlaySection(scheme),
          AppTheme.h8,
          _buildStatsBarControls(scheme),
          AppTheme.h16,
          const Divider(),
          AppTheme.h12,
          _buildPreviewToolsSection(scheme),
          AppTheme.h16,
          _buildAdvancedLayoutSection(scheme, showAdvanced),
        ],
      ),
    );
  }
}

extension _CustomizePageStateControlSections on _CustomizePageState {
  Widget _buildTextOverlaySection(ColorScheme scheme) {
    final hasProAccess =
        context.watch<MembershipController?>()?.hasProAccess ?? false;

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
            onPressed: _isGeneratingQuote
                ? null
                : () async {
                    if (hasProAccess) {
                      await _generateQuote();
                      return;
                    }
                    await _promptForLockedAccess(
                      featureName: 'Live Quote Generation',
                      featureDescription:
                          'Generate fresh AI quotes from Customize instead of using only the daily fallback quote.',
                    );
                  },
            icon: _isGeneratingQuote
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  )
                : Icon(
                    hasProAccess ? Icons.auto_awesome : Icons.lock_rounded,
                    size: 16,
                  ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Safe preview guides',
                style: TextStyle(
                  fontSize: AppTheme.fontBase,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ),
            Switch(
              value: _safePreviewEnabled,
              activeThumbColor: scheme.primary,
              onChanged: _toggleSafePreview,
            ),
          ],
        ),
        Text(
          'Guides show where Android system UI can cover the wallpaper.',
          style: TextStyle(
            fontSize: AppTheme.fontCaption,
            color: scheme.onSurface.withValues(alpha: 0.65),
          ),
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
                  ? 'Refreshing Device Fit...'
                  : 'Refresh Device Fit',
              style: const TextStyle(fontSize: AppTheme.fontBody),
            ),
            style: TextButton.styleFrom(
              padding: AppTheme.pZero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ],
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
