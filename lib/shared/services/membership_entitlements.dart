import 'package:github_wallpaper/data/datasources/local/storage_service.dart';
import 'package:github_wallpaper/data/models/membership_models.dart';
import 'package:github_wallpaper/data/models/theme_presets.dart';
import 'package:github_wallpaper/data/models/wallpaper_templates.dart';

class MembershipEntitlements {
  static const List<String> freeThemeIds = ['github', 'github_soft', 'mono'];
  static const List<String> freeTemplateIds = ['minimal_dark', 'monochrome'];

  static MembershipInfo? get _membership =>
      StorageService.getCachedMembershipInfo();

  static bool get hasProAccess => _membership?.hasProAccess ?? false;
  static bool get canUseAiQuotes => hasProAccess;
  static bool get canUseAdvancedStats => hasProAccess;
  static bool get canViewWrapped => hasProAccess;
  static bool get canUseReminders => hasProAccess;
  static bool get shouldWatermarkShares => !hasProAccess;

  static List<HeatmapTheme> availableThemes() {
    if (hasProAccess) return ThemePresets.all;
    return ThemePresets.all
        .where((theme) => freeThemeIds.contains(theme.id))
        .toList();
  }

  static bool isThemeUnlocked(String themeId) {
    if (hasProAccess) return true;
    return freeThemeIds.contains(themeId);
  }

  static String normalizeThemeId(String themeId) {
    return isThemeUnlocked(themeId) ? themeId : freeThemeIds.first;
  }

  static List<WallpaperTemplate> availableTemplates() {
    if (hasProAccess) return WallpaperTemplates.all;
    return WallpaperTemplates.all
        .where((template) => freeTemplateIds.contains(template.id))
        .toList();
  }

  static bool isTemplateUnlocked(String templateId) {
    if (hasProAccess) return true;
    return freeTemplateIds.contains(templateId);
  }

  static String normalizeTemplateId(String templateId) {
    return isTemplateUnlocked(templateId) ? templateId : freeTemplateIds.first;
  }
}
