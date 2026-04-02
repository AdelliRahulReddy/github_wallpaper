import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/app/product/models/product_models.dart';
import 'package:github_wallpaper/app/product/services/entitlement_engine.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/features/wallpaper/models/theme_presets.dart';
import 'package:github_wallpaper/features/wallpaper/models/wallpaper_config.dart';
import 'package:github_wallpaper/features/wallpaper/models/wallpaper_templates.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    await StorageService.clearInternalUserId();
    await StorageService.setLastWallpaperTarget(WallpaperTarget.lock);
  });

  test('entitlements include every feature and every design preset', () {
    final entitlements = EntitlementEngine.resolve();

    expect(entitlements.enabledFeatures, containsAll(EntitledFeature.values));
    expect(
      EntitlementEngine.availableThemes(entitlements).length,
      ThemePresets.all.length,
    );
    expect(
      EntitlementEngine.availableTemplates(entitlements).length,
      WallpaperTemplates.all.length,
    );
    expect(
      EntitlementEngine.normalizeThemeId(entitlements, 'dracula'),
      'dracula',
    );
    expect(
      EntitlementEngine.normalizeTemplateId(entitlements, 'code_centric'),
      'code_centric',
    );
  });

  test('persists the app-owned user id', () async {
    const internalUserId = 'gw_usr_abcdefghijklmnopqrstuvwx';
    await StorageService.setInternalUserId(internalUserId);

    expect(StorageService.getInternalUserId(), internalUserId);
  });

  test('coerces stored wallpaper target to lock', () async {
    await StorageService.setLastWallpaperTarget(WallpaperTarget.home);

    expect(StorageService.getLastWallpaperTarget(), WallpaperTarget.lock);
  });
}
