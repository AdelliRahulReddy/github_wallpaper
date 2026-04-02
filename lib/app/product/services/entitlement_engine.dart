import 'package:github_wallpaper/app/product/models/product_models.dart';
import 'package:github_wallpaper/features/wallpaper/models/theme_presets.dart';
import 'package:github_wallpaper/features/wallpaper/models/wallpaper_templates.dart';

class EntitlementEngine {
  static final List<String> themeIds = _allThemeIds();
  static final List<String> templateIds = _allTemplateIds();

  static EntitlementState resolve() {
    return EntitlementState(
      enabledFeatures: Set<EntitledFeature>.of(EntitledFeature.values),
      availableThemeIds: List<String>.of(themeIds),
      availableTemplateIds: List<String>.of(templateIds),
    );
  }

  static bool isThemeUnlocked(EntitlementState state, String themeId) =>
      state.availableThemeIds.contains(themeId);

  static String normalizeThemeId(EntitlementState state, String themeId) =>
      isThemeUnlocked(state, themeId) ? themeId : ThemePresets.defaultId;

  static bool isTemplateUnlocked(EntitlementState state, String templateId) =>
      state.availableTemplateIds.contains(templateId);

  static String normalizeTemplateId(
    EntitlementState state,
    String templateId,
  ) =>
      isTemplateUnlocked(state, WallpaperTemplates.canonicalId(templateId))
          ? WallpaperTemplates.canonicalId(templateId)
          : WallpaperTemplates.all.first.id;

  static List<HeatmapTheme> availableThemes(EntitlementState state) =>
      ThemePresets.all
          .where((theme) => state.availableThemeIds.contains(theme.id))
          .toList(growable: false);

  static List<WallpaperTemplate> availableTemplates(EntitlementState state) =>
      WallpaperTemplates.all
          .where((template) => state.availableTemplateIds.contains(template.id))
          .toList(growable: false);

  static List<String> _allThemeIds() =>
      ThemePresets.all.map((theme) => theme.id).toList(growable: false);

  static List<String> _allTemplateIds() => WallpaperTemplates.all
      .map((template) => template.id)
      .toList(growable: false);
}
