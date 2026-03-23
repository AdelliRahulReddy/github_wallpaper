part of 'app_utils.dart';

enum RefreshSkipReason { noChanges, throttled, networkError, authError }

class RefreshDecision {
  final bool shouldProceed;
  final RefreshSkipReason? skipReason;
  const RefreshDecision.proceed()
      : shouldProceed = true,
        skipReason = null;
  const RefreshDecision.skip(this.skipReason) : shouldProceed = false;
}

class RefreshPolicy {
  static RefreshDecision shouldRefresh(
      {required bool isBackground,
      bool isAutomatic = false,
      required bool isAndroid,
      required bool autoUpdateEnabled,
      required bool hasPendingRefresh,
      DateTime? lastUpdate,
      String? username,
      String? token,
      bool hasAuthError = false,
      bool hasConnectivity = true,
      DateTime? now,
      required UpdateScheduleMode scheduleMode,
      required int scheduleHour,
      required int scheduleMinute,
      required int scheduleIntervalMinutes,
      required String? lastDailyKey}) {
    if (!isAndroid && isBackground) {
      return const RefreshDecision.skip(RefreshSkipReason.noChanges);
    }
    final nowUtc = (now ?? DateTime.now()).toUtc();
    if (hasPendingRefresh &&
        lastUpdate != null &&
        nowUtc.difference(lastUpdate.toUtc()).inMinutes <
            AppConstants.pendingRefreshDebounceMinutes) {
      return const RefreshDecision.skip(RefreshSkipReason.noChanges);
    }
    if (!autoUpdateEnabled && (isBackground || isAutomatic)) {
      return const RefreshDecision.skip(RefreshSkipReason.noChanges);
    }
    if (hasAuthError) {
      return const RefreshDecision.skip(RefreshSkipReason.authError);
    }

    if ((isBackground || isAutomatic) && !hasPendingRefresh) {
      final localNow = (now ?? DateTime.now());
      final localKey = AppDateUtils.formatDate(localNow);
      if (scheduleMode == UpdateScheduleMode.autoDaily) {
        if (lastDailyKey == localKey) {
          return const RefreshDecision.skip(RefreshSkipReason.noChanges);
        }
        final start = DateTime(localNow.year, localNow.month, localNow.day,
            scheduleHour, scheduleMinute);
        final end = start.add(const Duration(minutes: 110));
        if (localNow.isBefore(start) || localNow.isAfter(end)) {
          return const RefreshDecision.skip(RefreshSkipReason.noChanges);
        }
      } else {
        if (lastUpdate != null &&
            nowUtc.difference(lastUpdate.toUtc()).inMinutes <
                scheduleIntervalMinutes) {
          return const RefreshDecision.skip(RefreshSkipReason.noChanges);
        }
      }
    }

    if ((isBackground || isAutomatic) &&
        lastUpdate != null &&
        nowUtc.difference(lastUpdate.toUtc()).inMinutes <
            AppConstants.refreshCooldownMinutes) {
      return const RefreshDecision.skip(RefreshSkipReason.throttled);
    }
    if (!hasConnectivity) {
      return const RefreshDecision.skip(RefreshSkipReason.networkError);
    }
    if (username == null ||
        token == null ||
        username.trim().isEmpty ||
        token.trim().isEmpty) {
      return const RefreshDecision.skip(RefreshSkipReason.authError);
    }
    return const RefreshDecision.proceed();
  }
}
