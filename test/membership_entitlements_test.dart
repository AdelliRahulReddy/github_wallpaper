import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/features/membership/models/membership_models.dart';
import 'package:github_wallpaper/features/membership/services/membership_entitlements.dart';
import 'package:github_wallpaper/features/wallpaper/models/wallpaper_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    await StorageService.clearCachedMembershipInfo();
    await StorageService.setAppUserId(null);
    await StorageService.setLastWallpaperTarget(WallpaperTarget.lock);
  });

  test('free users only get basic themes and branded shares', () async {
    await StorageService.setCachedMembershipInfo(
      MembershipInfo.free(),
    );

    expect(MembershipEntitlements.canUseAdvancedStats, isFalse);
    expect(MembershipEntitlements.canViewWrapped, isFalse);
    expect(MembershipEntitlements.shouldWatermarkShares, isTrue);
    expect(MembershipEntitlements.availableThemes().length, 3);
    expect(MembershipEntitlements.isThemeUnlocked('dracula'), isFalse);
    expect(MembershipEntitlements.normalizeThemeId('dracula'), 'github');
  });

  test('pro users get advanced stats, wrapped, and all themes', () async {
    await StorageService.setCachedMembershipInfo(
      MembershipInfo(
        plan: MembershipPlan.pro,
      ),
    );

    expect(MembershipEntitlements.canUseAdvancedStats, isTrue);
    expect(MembershipEntitlements.canViewWrapped, isTrue);
    expect(MembershipEntitlements.shouldWatermarkShares, isFalse);
    expect(MembershipEntitlements.availableThemes().length, greaterThan(3));
    expect(MembershipEntitlements.isThemeUnlocked('dracula'), isTrue);
  });

  test('persists the app-owned user id', () async {
    await StorageService.setAppUserId('github:123456');

    expect(StorageService.getAppUserId(), 'github:123456');
  });

  test('preserves home wallpaper target in storage', () async {
    await StorageService.setLastWallpaperTarget(WallpaperTarget.home);

    expect(StorageService.getLastWallpaperTarget(), WallpaperTarget.home);
  });
}

