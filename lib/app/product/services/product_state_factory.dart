import 'package:github_wallpaper/app/product/models/product_models.dart';
import 'package:github_wallpaper/app/product/services/entitlement_engine.dart';
import 'package:github_wallpaper/app/product/services/insight_engine.dart';
import 'package:github_wallpaper/app/product/services/sync_engine.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';

class ProductStateFactory {
  static ProductSnapshot fromStorage({
    CachedContributionData? data,
    SyncState? syncState,
    DateTime? now,
  }) {
    final resolvedData = data ?? StorageService.getCachedData();
    final preferences = PreferenceState(
      wallpaperConfig: StorageService.getWallpaperConfig(),
      lastWallpaperTarget: StorageService.getLastWallpaperTarget(),
      autoUpdate: StorageService.getAutoUpdate(),
      autoApplyAfterSync: StorageService.getAutoApplyAfterSync(),
      updateScheduleMode: StorageService.getUpdateScheduleMode(),
      updateDailyTime: ClockTime(
        hour: StorageService.getUpdateDailyTime().hour,
        minute: StorageService.getUpdateDailyTime().minute,
      ),
      updateIntervalMinutes: StorageService.getUpdateIntervalMinutes(),
      safePreviewEnabled: StorageService.getSafePreviewEnabled(),
      weeklyCommitGoal: StorageService.getWeeklyCommitGoal(),
      streakReminderEnabled: StorageService.getStreakReminderEnabled(),
      weeklyDigestEnabled: StorageService.getWeeklyDigestEnabled(),
      codingLevel: StorageService.getCodingLevel(),
      quoteTone: StorageService.getQuoteTone(),
    );
    final entitlements = EntitlementEngine.resolve();
    final sync = syncState ??
        SyncEngine.fromStorage(
          data: resolvedData,
          lastSuccessfulSyncAt: StorageService.getEffectiveLastSync(),
          hasAuthError: StorageService.hasAuthError(),
          hasPendingRefresh: StorageService.hasPendingWallpaperRefresh(),
          now: now,
        );

    return ProductSnapshot(
      raw: resolvedData == null ? null : RawSnapshot.fromData(resolvedData),
      insights: resolvedData == null
          ? null
          : InsightEngine.build(
              RawSnapshot.fromData(resolvedData),
              now: now,
            ),
      preferences: preferences,
      entitlements: entitlements,
      sync: sync,
    );
  }
}
