// ══════════════════════════════════════════════════════════════════════════
// 🔔 BACKGROUND UPDATE SCHEDULER
// ══════════════════════════════════════════════════════════════════════════
// 
// This service manages WorkManager scheduling for guaranteed background updates.
// Works even when app is closed, battery restricted, or after device reboot.

import 'package:workmanager/workmanager.dart';
import 'app_services.dart';
import 'app_utils.dart';

/// Unique task identifier for WorkManager
const String _taskName = "wallpaper-auto-update";

/// Background callback dispatcher
/// This runs in a separate isolate when WorkManager triggers the task
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // CRITICAL: Initialize StorageService for background isolate
      // Background tasks run in separate isolate without main app context
      await StorageService.init();
      
      AppLog.info('Background update triggered by WorkManager');
      
      // DEDUPLICATION: Check if update was recently completed by FCM
      final lastUpdate = StorageService.getLastSuccessfulUpdate();
      if (lastUpdate != null) {
        final timeSinceUpdate = DateTime.now().difference(lastUpdate);
        final cooldownMinutes = AppConstants.autoUpdateIntervalMinutes - 5; // 5 min buffer
        
        if (timeSinceUpdate.inMinutes < cooldownMinutes) {
          AppLog.info('Skipping WorkManager update - FCM already updated ${timeSinceUpdate.inMinutes} min ago (cooldown: $cooldownMinutes min)');
          return true; // Not an error, just skipping
        }
      }
      
      // Perform wallpaper refresh in background
      final result = await WallpaperService.refreshWallpaper(isBackground: true);
      
      if (result.isSuccess) {
        AppLog.info('Background update completed successfully');
        return true;
      } else {
        AppLog.info('Background update skipped: ${result.name}');
        return false;
      }
    } catch (e, s) {
      AppLog.error('Background update failed: $e', s);
      return false;
    }
  });
}

/// Background Update Scheduler Service
class BackgroundScheduler {
  static bool _initialized = false;

  /// Initialize WorkManager (call once on app start)
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false, // Set to true only for WorkManager debugging
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
          requiresCharging: false,       // Allow on battery
          requiresDeviceIdle: false,     // Allow when device is active
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace, // Changed for workmanager 0.9.0
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 15),
      );
      
      AppLog.info('Background updates scheduled (every ${AppConstants.autoUpdateIntervalMinutes} minutes)');
    } catch (e, s) {
      AppLog.error('Failed to schedule background updates: $e', s);
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
