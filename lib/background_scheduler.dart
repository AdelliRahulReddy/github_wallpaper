// ══════════════════════════════════════════════════════════════════════════
// 🔔 BACKGROUND UPDATE SCHEDULER
// ══════════════════════════════════════════════════════════════════════════
//
// This service manages WorkManager scheduling for guaranteed background updates.
// Works even when app is closed, battery restricted, or after device reboot.

import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import 'app_services.dart';
import 'app_utils.dart';

/// Unique task identifier for WorkManager
const String _taskName = "wallpaper-auto-update";
const String _streakReminderTaskName = "streak-reminder-check";

/// Background callback dispatcher
/// This runs in a separate isolate when WorkManager triggers the task
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // CRITICAL: Initialize Flutter binding and StorageService for background isolate
      // Background tasks run in separate isolate without main app context
      WidgetsFlutterBinding.ensureInitialized();
      await StorageService.init();

      if (task == _streakReminderTaskName) {
        final enabled = StorageService.getStreakReminderEnabled();
        if (!enabled) return true;

        final t = StorageService.getStreakReminderTime();
        final now = DateTime.now();
        final windowStart =
            DateTime(now.year, now.month, now.day, t.hour, t.minute);
        final windowEnd = windowStart.add(const Duration(minutes: 70));
        if (now.isBefore(windowStart) || now.isAfter(windowEnd)) return true;

        final dayKey = AppDateUtils.formatDate(now.toUtc());
        if (StorageService.getStreakReminderLastSentDay() == dayKey) return true;

        final cached = StorageService.getCachedData();
        if (cached == null) return true;

        final todayCommits = cached.getContributionsForDate(DateTime.now().toUtc());
        if (todayCommits > 0) return true;

        await NotificationService.showStreakReminderNotification(
          goalDays: StorageService.getStreakGoalDays(),
          currentStreak: cached.currentStreak,
        );
        await StorageService.setStreakReminderLastSentDay(dayKey);
        AppLog.info('Streak reminder sent');
        return true;
      }

      AppLog.info('Background update triggered by WorkManager');

      // DEDUPLICATION: Check if update was recently completed by FCM or manual refresh
      final lastUpdate = StorageService.getEffectiveLastSync();
      if (lastUpdate != null) {
        final timeSinceUpdate = DateTime.now().toUtc().difference(lastUpdate.toUtc());
        final cooldownMinutes =
            AppConstants.autoUpdateIntervalMinutes - 5; // 5 min buffer

        if (timeSinceUpdate.inMinutes < cooldownMinutes) {
          AppLog.info(
              'Skipping WorkManager update - recently updated ${timeSinceUpdate.inMinutes} min ago (cooldown: $cooldownMinutes min)');
          return true; // Not an error, just skipping
        }
      }

      // Perform wallpaper refresh in background
      final result =
          await WallpaperService.refreshWallpaper(isBackground: true);
      final isSuccess = BackgroundScheduler.shouldMarkTaskSuccessful(result);
      AppLog.info(
        '${isSuccess ? 'Background update completed' : 'Background update retryable failure'}: ${result.name}',
      );
      return isSuccess;
    } catch (e, s) {
      AppLog.error('Background update failed: $e', s);
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
  /// Runs every 1-2 hours (Android decides exact interval based on battery/Doze)
  /// - Survives app closure
  /// - Survives device reboot
  /// - Survives battery optimization
  /// - Respects network constraints
  static Future<void> scheduleUpdates() async {
    if (!_initialized) {
      await initialize();
    }

    try {
      await Workmanager().registerPeriodicTask(
        _taskName,
        _taskName,
        frequency: Duration(minutes: AppConstants.autoUpdateIntervalMinutes),
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

      AppLog.info(
          'Background updates scheduled (every ${AppConstants.autoUpdateIntervalMinutes} minutes)');
    } catch (e, s) {
      AppLog.error('Failed to schedule background updates: $e', s);
    }
  }

  static Future<void> scheduleStreakReminders() async {
    if (!_initialized) {
      await initialize();
    }
    try {
      await Workmanager().registerPeriodicTask(
        _streakReminderTaskName,
        _streakReminderTaskName,
        frequency: Duration(minutes: AppConstants.autoUpdateIntervalMinutes),
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
        ),
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
}
