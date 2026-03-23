// ══════════════════════════════════════════════════════════════════════════
// 🎨 CUSTOMIZE PAGE - Wallpaper Customization
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:github_wallpaper/data/datasources/local/storage_service.dart';
import 'package:github_wallpaper/features/wallpaper/widgets/ui_render.dart';
import 'package:github_wallpaper/features/settings/screens/membership_paywall_page.dart';
import 'package:github_wallpaper/data/models/app_models.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/shared/widgets/app_components.dart';
import 'package:github_wallpaper/data/models/theme_presets.dart';
import 'package:github_wallpaper/shared/services/daily_quotes.dart';
import 'package:github_wallpaper/shared/services/membership_entitlements.dart';
import 'package:github_wallpaper/shared/services/background_scheduler.dart';
import 'package:github_wallpaper/shared/state/membership_state.dart';
import 'package:github_wallpaper/data/datasources/local/device_config_service.dart';
import 'package:github_wallpaper/shared/services/wallpaper_service.dart';
import 'package:github_wallpaper/data/models/wallpaper_templates.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:provider/provider.dart';
import 'dart:async';

part 'customize_screen_view.dart';
part 'customize_screen_preview.dart';
part 'customize_screen_templates.dart';
part 'customize_screen_themes.dart';
part 'customize_screen_theme_gallery.dart';
part 'customize_screen_controls.dart';
part 'customize_screen_control_sections.dart';
part 'customize_screen_control_helpers.dart';
part 'customize_screen_guides.dart';
part 'customize_screen_celebration.dart';

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
    if (!context.read<MembershipState>().hasProAccess) return;
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
    final refreshed = context.read<MembershipState>().info ??
        StorageService.getCachedMembershipInfo();
    if (refreshed?.hasProAccess == true &&
        BackgroundScheduler.shouldScheduleReminderChecks()) {
      await BackgroundScheduler.scheduleStreakReminders();
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
      'home' => WallpaperTarget.lock,
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
