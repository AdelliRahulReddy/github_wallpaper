import 'package:github_wallpaper/app/product/models/product_models.dart';
import 'package:github_wallpaper/app/services/refresh_result.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';

class SyncEngine {
  static SyncMode resolveMode({
    bool isBackground = false,
    bool isRecovery = false,
    bool isRenderOnly = false,
  }) {
    if (isRenderOnly) return SyncMode.renderOnlyRefresh;
    if (isRecovery) return SyncMode.recoverySync;
    if (isBackground) return SyncMode.scheduledSync;
    return SyncMode.fullSync;
  }

  static SyncState fromStorage({
    required CachedContributionData? data,
    required DateTime? lastSuccessfulSyncAt,
    required bool hasAuthError,
    required bool hasPendingRefresh,
    SyncMode mode = SyncMode.freshnessCheck,
    DateTime? now,
  }) {
    final stale = data == null || data.isStale(null, now);
    if (hasAuthError) {
      return SyncState(
        status: SyncStatus.authRequired,
        mode: mode,
        failureType: SyncFailureType.auth,
        lastAttemptAt: null,
        lastSuccessfulSyncAt: lastSuccessfulSyncAt,
        hasCachedData: data != null,
        hasPendingRefresh: hasPendingRefresh,
        hasAuthError: true,
        isStale: stale,
        message: 'GitHub authentication required',
      );
    }

    return SyncState(
      status: data == null
          ? SyncStatus.idle
          : (stale ? SyncStatus.stale : SyncStatus.fresh),
      mode: mode,
      failureType: SyncFailureType.none,
      lastAttemptAt: null,
      lastSuccessfulSyncAt: lastSuccessfulSyncAt,
      hasCachedData: data != null,
      hasPendingRefresh: hasPendingRefresh,
      hasAuthError: false,
      isStale: stale,
    );
  }

  static SyncState begin(
    SyncState current, {
    required SyncMode mode,
    DateTime? at,
  }) {
    return current.copyWith(
      status: SyncStatus.syncing,
      mode: mode,
      failureType: SyncFailureType.none,
      lastAttemptAt: (at ?? DateTime.now()).toUtc(),
      hasAuthError: false,
      clearMessage: true,
    );
  }

  static SyncState complete(
    SyncState current, {
    required RefreshResult result,
    CachedContributionData? data,
    DateTime? at,
  }) {
    final timestamp = (at ?? DateTime.now()).toUtc();
    switch (result) {
      case RefreshResult.success:
      case RefreshResult.noChanges:
        final stale =
            data == null ? current.isStale : data.isStale(null, timestamp);
        return current.copyWith(
          status: stale ? SyncStatus.stale : SyncStatus.synced,
          failureType: SyncFailureType.none,
          lastSuccessfulSyncAt: timestamp,
          hasCachedData: data != null || current.hasCachedData,
          hasAuthError: false,
          hasPendingRefresh: false,
          isStale: stale,
          clearMessage: true,
        );
      case RefreshResult.authError:
        return current.copyWith(
          status: SyncStatus.authRequired,
          failureType: SyncFailureType.auth,
          hasAuthError: true,
          isStale: true,
          message: 'GitHub authentication required',
        );
      case RefreshResult.networkError:
        return current.copyWith(
          status: SyncStatus.failed,
          failureType: SyncFailureType.network,
          message: 'Network unavailable during sync',
        );
      case RefreshResult.throttled:
        return current.copyWith(
          status: current.hasCachedData && !current.isStale
              ? SyncStatus.fresh
              : SyncStatus.failed,
          failureType: SyncFailureType.throttled,
          message: 'Sync skipped because data was refreshed recently',
        );
      case RefreshResult.unknownError:
        return current.copyWith(
          status: SyncStatus.failed,
          failureType: SyncFailureType.unknown,
          message: 'Unexpected sync failure',
        );
    }
  }

  static SyncState fromRefreshDecision(
    RefreshDecision decision, {
    required CachedContributionData? data,
    required DateTime? lastSuccessfulSyncAt,
    required bool hasPendingRefresh,
    required SyncMode mode,
    required DateTime now,
  }) {
    final base = fromStorage(
      data: data,
      lastSuccessfulSyncAt: lastSuccessfulSyncAt,
      hasAuthError: decision.skipReason == RefreshSkipReason.authError,
      hasPendingRefresh: hasPendingRefresh,
      mode: mode,
      now: now,
    );
    switch (decision.skipReason) {
      case null:
        return base;
      case RefreshSkipReason.authError:
        return base.copyWith(
          status: SyncStatus.authRequired,
          failureType: SyncFailureType.auth,
          message: 'GitHub authentication required',
        );
      case RefreshSkipReason.networkError:
        return base.copyWith(
          status: SyncStatus.failed,
          failureType: SyncFailureType.network,
          message: 'Network unavailable during sync',
        );
      case RefreshSkipReason.throttled:
        return base.copyWith(
          status: base.hasCachedData && !base.isStale
              ? SyncStatus.fresh
              : SyncStatus.failed,
          failureType: SyncFailureType.throttled,
          message: 'Sync skipped because data was refreshed recently',
        );
      case RefreshSkipReason.noChanges:
        return base.copyWith(
          status: base.hasCachedData && !base.isStale
              ? SyncStatus.fresh
              : SyncStatus.idle,
          failureType: SyncFailureType.none,
          clearMessage: true,
        );
    }
  }
}
