// ══════════════════════════════════════════════════════════════════════════
// 🔔 BACKGROUND UPDATE SCHEDULER
// ══════════════════════════════════════════════════════════════════════════
//
// This service manages WorkManager scheduling for guaranteed background updates.
// Works even when app is closed, battery restricted, or after device reboot.

import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'package:github_wallpaper/core/constants/firebase_options.dart';
import 'package:github_wallpaper/app/services/notification_service.dart';
import 'package:github_wallpaper/app/services/refresh_result.dart';
import 'package:github_wallpaper/app/services/telemetry_service.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/features/contributions/repositories/contribution_repository.dart';

/// Unique task identifier for WorkManager
const String _taskName = "wallpaper-auto-update";
const String _streakReminderTaskName = "streak-reminder-check";

RefreshResult _resultForSkipReason(RefreshSkipReason? reason) {
  switch (reason) {
    case RefreshSkipReason.noChanges:
      return RefreshResult.noChanges;
    case RefreshSkipReason.throttled:
      return RefreshResult.throttled;
    case RefreshSkipReason.networkError:
      return RefreshResult.networkError;
    case RefreshSkipReason.authError:
      return RefreshResult.authError;
    case null:
      return RefreshResult.noChanges;
  }
}

bool _shouldPersistDailyKey(RefreshResult result) {
  switch (result) {
    case RefreshResult.success:
    case RefreshResult.noChanges:
    case RefreshResult.authError:
    case RefreshResult.throttled:
      return true;
    case RefreshResult.networkError:
    case RefreshResult.unknownError:
      return false;
  }
}

bool _hasFreshReminderData(CachedContributionData data, DateTime now) {
  final localLastUpdated = data.lastUpdated.toLocal();
  final sameDay = localLastUpdated.year == now.year &&
      localLastUpdated.month == now.month &&
      localLastUpdated.day == now.day;
  return sameDay || !data.isStale(const Duration(hours: 6), now.toLocal());
}

Future<void> _runReminderChecks() async {
  final now = DateTime.now();
  final cached = StorageService.getCachedData();

  if (cached == null) {
    AppLog.info('Skipping reminder checks - no cached data');
    return;
  }

  if (!_hasFreshReminderData(cached, now)) {
    AppLog.info('Skipping reminder checks - cached activity is stale');
    return;
  }

  if (StorageService.getStreakReminderEnabled()) {
    final t = StorageService.getStreakReminderTime();
    final windowStart =
        DateTime(now.year, now.month, now.day, t.hour, t.minute);
    final windowEnd = windowStart.add(const Duration(minutes: 70));

    final dayKey = AppDateUtils.formatDate(now);
    final alreadySent = StorageService.getStreakReminderLastSentDay() == dayKey;
    final todayCommits = cached.days
        .where((d) => AppDateUtils.formatDate(d.date.toLocal()) == dayKey)
        .fold<int>(0, (sum, d) => sum + d.contributionCount);

    if (!alreadySent &&
        todayCommits == 0 &&
        !now.isBefore(windowStart) &&
        !now.isAfter(windowEnd)) {
      await NotificationService.showStreakReminderNotification(
        goalDays: StorageService.getStreakGoalDays(),
        currentStreak: cached.currentStreak,
      );
      await StorageService.setStreakReminderLastSentDay(dayKey);
      AppLog.info('Streak reminder sent');
    }
  }

  if (StorageService.getWeeklyDigestEnabled()) {
    final t = StorageService.getWeeklyDigestTime();
    final windowStart =
        DateTime(now.year, now.month, now.day, t.hour, t.minute);
    final windowEnd = windowStart.add(const Duration(minutes: 110));

    if (now.weekday == DateTime.sunday &&
        !now.isBefore(windowStart) &&
        !now.isAfter(windowEnd)) {
      final weekKey = AppDateUtils.formatDate(now);
      if (StorageService.getWeeklyDigestLastSentWeek() != weekKey) {
        final today = DateTime(now.year, now.month, now.day);
        final currentStart = today.subtract(const Duration(days: 6));
        final prevStart = today.subtract(const Duration(days: 13));
        final prevEnd = currentStart.subtract(const Duration(days: 1));

        var current = 0;
        var previous = 0;
        for (final d in cached.days) {
          final local = d.date.toLocal();
          final dateOnly = DateTime(local.year, local.month, local.day);
          if (!dateOnly.isBefore(currentStart) && !dateOnly.isAfter(today)) {
            current += d.contributionCount;
          } else if (!dateOnly.isBefore(prevStart) &&
              !dateOnly.isAfter(prevEnd)) {
            previous += d.contributionCount;
          }
        }

        final deltaPct = previous <= 0
            ? (current > 0 ? 100 : 0)
            : (((current - previous) * 100) / previous).round();
        final sign = deltaPct >= 0 ? '+' : '';
        final deltaLabel = '$sign$deltaPct%';
        final topRepo =
            cached.repositories.isEmpty ? null : cached.repositories.first;

        final title = 'Weekly Digest';
        final body = topRepo == null
            ? 'This week: $current commits ($deltaLabel)'
            : 'This week: $current commits ($deltaLabel) • Top repo: ${topRepo.nameWithOwner}';

        await NotificationService.showWeeklyDigestNotification(
          title: title,
          body: body,
        );
        await StorageService.setWeeklyDigestLastSentWeek(weekKey);
        AppLog.info('Weekly digest sent');
      }
    }
  }
}

Future<RefreshResult> _runBackgroundWallpaperUpdate() async {
  AppLog.info('Background update triggered by WorkManager');

  if (!StorageService.hasAppliedWallpaper()) {
    AppLog.info(
        'Skipping background update - wallpaper has not been applied yet');
    return RefreshResult.noChanges;
  }

  final username = StorageService.getUsername();
  final token = await StorageService.getToken();
  final scheduleMode = StorageService.getUpdateScheduleMode();
  final dailyTime = StorageService.getUpdateDailyTime();
  final intervalMinutes = StorageService.getUpdateIntervalMinutes();

  final decision = RefreshPolicy.shouldRefresh(
    isBackground: true,
    isAndroid: Platform.isAndroid,
    autoUpdateEnabled: StorageService.getAutoUpdate(),
    hasPendingRefresh: StorageService.hasPendingWallpaperRefresh(),
    lastUpdate: StorageService.getEffectiveLastSync(),
    username: username,
    token: token,
    scheduleMode: scheduleMode,
    scheduleHour: dailyTime.hour,
    scheduleMinute: dailyTime.minute,
    scheduleIntervalMinutes: intervalMinutes,
    lastDailyKey: StorageService.getUpdateScheduleLastDailyKey(),
  );

  if (!decision.shouldProceed) {
    final result = _resultForSkipReason(decision.skipReason);
    if (result == RefreshResult.noChanges) {
      await StorageService.consumePendingWallpaperRefresh();
    }
    AppLog.info('Background update skipped: ${result.name}');
    return result;
  }

  final result =
      await ContributionRepository.syncGitHubData(isBackground: true);
  if (scheduleMode == UpdateScheduleMode.autoDaily &&
      _shouldPersistDailyKey(result)) {
    await StorageService.setUpdateScheduleLastDailyKey(
      AppDateUtils.formatDate(DateTime.now()),
    );
  }
  return result;
}

/// Background callback dispatcher
/// This runs in a separate isolate when WorkManager triggers the task
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    try {
      // CRITICAL: Initialize Flutter binding and StorageService for background isolate
      // Background tasks run in separate isolate without main app context
      WidgetsFlutterBinding.ensureInitialized();
      await StorageService.init();
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      if (task == _streakReminderTaskName) {
        await _runReminderChecks();
        return true;
      }

      final result = await _runBackgroundWallpaperUpdate();
      final isSuccess = BackgroundScheduler.shouldMarkTaskSuccessful(result);
      AppLog.info(
        '${isSuccess ? 'Background update completed' : 'Background update retryable failure'}: ${result.name}',
      );
      return isSuccess;
    } catch (e, s) {
      AppLog.error('Background update failed: $e', s);
      await TelemetryService.logBackgroundJobFailure(e, s);
      return false;
    }
  });
}

/// Background Update Scheduler Service
class BackgroundScheduler {
  static bool _initialized = false;

  @visibleForTesting
  static bool shouldMarkTaskSuccessful(RefreshResult result) {
    switch (result) {
      case RefreshResult.success:
      case RefreshResult.noChanges:
      case RefreshResult.authError:
      case RefreshResult.throttled:
        return true;
      case RefreshResult.networkError:
      case RefreshResult.unknownError:
        return false;
    }
  }

  /// Initialize WorkManager (call once on app start)
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Workmanager().initialize(
        callbackDispatcher,
      );
      _initialized = true;
      AppLog.info('WorkManager initialized successfully');
    } catch (e, s) {
      AppLog.error('WorkManager initialization failed: $e', s);
    }
  }

  /// Schedule periodic wallpaper updates
  ///
  /// Uses the user's stored schedule settings and WorkManager timing constraints.
  /// - Survives app closure
  /// - Survives device reboot
  /// - Survives battery optimization
  /// - Respects network constraints
  static Future<void> scheduleUpdates() async {
    if (!_initialized) {
      await initialize();
    }

    try {
      final mode = StorageService.getUpdateScheduleMode();
      final intervalMinutes = StorageService.getUpdateIntervalMinutes();
      final minutes = mode == UpdateScheduleMode.interval
          ? intervalMinutes
          : AppConstants.dailyScheduleCheckIntervalMinutes;
      await Workmanager().registerPeriodicTask(
        _taskName,
        _taskName,
        frequency: Duration(minutes: minutes),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false, // Allow even on low battery
          requiresCharging: false, // Allow on battery
          requiresDeviceIdle: false, // Allow when device is active
        ),
        existingWorkPolicy:
            ExistingPeriodicWorkPolicy.replace, // Changed for workmanager 0.9.0
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 15),
      );

      AppLog.info('Background updates scheduled (every $minutes minutes)');
    } catch (e, s) {
      AppLog.error('Failed to schedule background updates: $e', s);
    }
  }

  static Future<void> scheduleStreakReminders() async {
    if (!_initialized) {
      await initialize();
    }
    if (!shouldScheduleReminderChecks()) {
      await cancelStreakReminders();
      return;
    }
    try {
      await Workmanager().registerPeriodicTask(
        _streakReminderTaskName,
        _streakReminderTaskName,
        frequency:
            const Duration(minutes: AppConstants.reminderCheckIntervalMinutes),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 15),
      );
      AppLog.info('Streak reminders scheduled');
    } catch (e, s) {
      AppLog.error('Failed to schedule streak reminders: $e', s);
    }
  }

  static Future<void> cancelStreakReminders() async {
    if (!_initialized) {
      await initialize();
    }
    try {
      await Workmanager().cancelByUniqueName(_streakReminderTaskName);
      AppLog.info('Streak reminders cancelled');
    } catch (e, s) {
      AppLog.error('Failed to cancel streak reminders: $e', s);
    }
  }

  /// Cancel all scheduled updates
  static Future<void> cancelUpdates() async {
    if (!_initialized) {
      await initialize();
    }

    try {
      await Workmanager().cancelByUniqueName(_taskName);
      AppLog.info('Background updates cancelled');
    } catch (e, s) {
      AppLog.error('Failed to cancel background updates: $e', s);
    }
  }

  /// Check if updates are currently scheduled
  static Future<bool> isScheduled() async {
    // WorkManager doesn't provide a direct way to check this
    // We rely on SharedPreferences auto-update flag
    return StorageService.getAutoUpdate();
  }

  static bool shouldScheduleReminderChecks() {
    return StorageService.getStreakReminderEnabled() ||
        StorageService.getWeeklyDigestEnabled();
  }
}
