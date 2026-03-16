import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app_exceptions.dart';
import 'app_models.dart';
import 'app_state.dart';
import 'app_utils.dart';
import 'firebase_options.dart';
import 'ui_render.dart';
import 'widget_service.dart';

export 'app_exceptions.dart';



// STORAGE
class StorageService {
  static final _initLock = Lock();
  static SharedPreferences? _p;
  static const _kRef = 'pending_wp_refresh';
  static const _ss = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true));

  // MEMORY CACHE
  static CachedContributionData? _memCache;
  static Map<String, dynamic>? _sensitiveCache;

  static Future<SharedPreferences> init() async {
    if (_p != null) return _p!;
    return await _initLock.synchronized(() async {
      if (_p != null) return _p!;
      _p = await SharedPreferences.getInstance();
      await _loadSensitiveCache();
      return _p!;
    });
  }

  static Future<void> _loadSensitiveCache() async {
    try {
      final sensitiveStr =
          await _ss.read(key: AppConstants.keyCachedDataSensitive);
      if (sensitiveStr != null && sensitiveStr.isNotEmpty) {
        _sensitiveCache = jsonDecode(sensitiveStr) as Map<String, dynamic>;
      }
    } catch (_) {
      // Ignore load errors - cache will work without sensitive data
    }
  }



  static SharedPreferences? get _s => _p;

  // Token
  static Future<void> setToken(String t) async {
    if (t.trim().isEmpty) throw ArgumentError('Empty token');
    if (isValidTokenFormat(t) != null) throw ArgumentError('Invalid token');
    await _ss.write(key: AppConstants.keyToken, value: t.trim());
  }

  static Future<String?> getToken() async {
    try {
      return await _ss.read(key: AppConstants.keyToken);
    } catch (e) {
      if (e.toString().contains('CORRUPTED')) {
        AppLog.error('Token storage corrupted, clearing token.', null);
        await _ss.delete(key: AppConstants.keyToken);
      }
      return null;
    }
  }

  static Future<void> deleteToken() => _ss.delete(key: AppConstants.keyToken);
  static Future<bool> hasToken() async =>
      (await getToken())?.isNotEmpty ?? false;

  // User
  static Future<void> setUsername(String u) async {
    if (u.trim().isEmpty) throw ArgumentError();
    await (await init()).setString(AppConstants.keyUsername, u.trim());
  }

  static String? getUsername() => _s?.getString(AppConstants.keyUsername);

  // Cache with encrypted sensitive data
  static Future<void> setCachedData(CachedContributionData d) async {
    _memCache = d;

    // Separate sensitive from non-sensitive data
    final json = d.toJson();
    final includePrivate = getIncludePrivateRepos();
    
    // Privacy Fix: If private repos are excluded, we must recompute topLanguages
    // for the unencrypted public cache to ensure private activity doesn't leak into analytics.
    if (!includePrivate && json.containsKey('topLanguages')) {
      final publicRepos = d.repositories.where((r) => !r.isPrivate).toList();
      final publicLangs = CachedContributionData.calculateTopLanguages(publicRepos);
      json['topLanguages'] = publicLangs.map((l) => l.toJson()).toList();
    }

    final sensitiveFields = <String, dynamic>{};

    // Extract sensitive fields to encrypt
    if (json.containsKey('repositories')) {
      final repos = json['repositories'] as List?;

      if (includePrivate && repos != null) {
        sensitiveFields['repositories'] = repos;
      } else if (repos != null) {
        // Only include public repos
        sensitiveFields['repositories'] =
            repos.where((r) => r is Map && r['isPrivate'] != true).toList();
      }
      json.remove('repositories');
    }

    // Store non-sensitive data in SharedPreferences
    final prefs = await init();
    await prefs.setString(AppConstants.keyCachedData, jsonEncode(json));

    // Store sensitive data in FlutterSecureStorage
    if (sensitiveFields.isNotEmpty) {
      await _ss.write(
        key: AppConstants.keyCachedDataSensitive,
        value: jsonEncode(sensitiveFields),
      );
      // Update in-memory cache for fast synchronous access
      _sensitiveCache = sensitiveFields;
    } else {
      await _ss.delete(key: AppConstants.keyCachedDataSensitive);
      _sensitiveCache = null;
    }
  }

  static CachedContributionData? getCachedData() {
    if (_memCache != null) return _memCache!;
    try {
      // Get non-sensitive data from SharedPreferences
      final basicJson = _s?.getString(AppConstants.keyCachedData);
      if (basicJson == null) return null;

      final json = jsonDecode(basicJson) as Map<String, dynamic>;

      // Merge preloaded sensitive data from memory
      if (_sensitiveCache != null) {
        json.addAll(_sensitiveCache!);
      }

      _memCache = CachedContributionData.fromJson(json);
      return _memCache;
    } catch (e, s) {
      AppLog.error(e, s);
      return null;
    }
  }

  /// Clear in-memory cache to force reload from storage
  static void clearMemoryCache() {
    _memCache = null;
  }

  static Future<void> _safeSecureDelete(String key) async {
    try {
      await _ss.delete(key: key);
    } catch (e, s) {
      AppLog.error(e, s);
    }
  }

  static Future<void> clearCache() async {
    _memCache = null;
    _sensitiveCache = null;
    MonthHeatmapRenderer.clearCaches(); // Clear rendering cache
    final prefs = await init();
    
    // Delete wallpaper file if it exists
    final path = prefs.getString(AppConstants.keyWallpaperPath);
    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (e, s) {
        AppLog.error(e, s);
      }
    }

    await Future.wait([
      prefs.remove(AppConstants.keyCachedData),
      prefs.remove(AppConstants.keyLastUpdate),
      prefs.remove(AppConstants.keyLastSuccessfulUpdate),
      prefs.remove(AppConstants.keyLastBackgroundSync),
      prefs.remove(AppConstants.keyWallpaperHash),
      prefs.remove(AppConstants.keyWallpaperPath),
      prefs.remove(AppConstants.keyLastWallpaperTarget),
      prefs.remove(_kRef),
      _safeSecureDelete(AppConstants.keyCachedDataSensitive),
    ]);
  }


  // Private repo preference
  static Future<void> setIncludePrivateRepos(bool include) async =>
      (await init()).setBool(AppConstants.keyIncludePrivateRepos, include);

  static bool getIncludePrivateRepos() =>
      _s?.getBool(AppConstants.keyIncludePrivateRepos) ??
      true; // Default: true for backward compat

  // Crashlytics consent (GDPR compliance)
  static Future<void> setCrashlyticsConsent(bool consent) async =>
      (await init()).setBool(AppConstants.keyCrashlyticsConsent, consent);

  static bool getCrashlyticsConsent() =>
      _s?.getBool(AppConstants.keyCrashlyticsConsent) ??
      false; // Default: false (GDPR)

  static bool hasCrashlyticsConsentBeenSet() =>
      _s?.containsKey(AppConstants.keyCrashlyticsConsent) ?? false;

  // Config
  static Future<void> saveWallpaperConfig(WallpaperConfig c) async =>
      (await init())
          .setString(AppConstants.keyWallpaperConfig, jsonEncode(c.toJson()));
  static WallpaperConfig getWallpaperConfig() {
    try {
      final j = _s?.getString(AppConstants.keyWallpaperConfig);
      return j == null
          ? WallpaperConfig.defaults()
          : WallpaperConfig.fromJson(jsonDecode(j));
    } catch (_) {
      return WallpaperConfig.defaults();
    }
  }

  // Settings
  static Future<void> setAutoUpdate(bool e) async =>
      (await init()).setBool(AppConstants.keyAutoUpdate, e);
  static bool getAutoUpdate() =>
      _s?.getBool(AppConstants.keyAutoUpdate) ??
      true; // Default enabled for first-run consistency with product behavior.

  static Future<void> setUpdateScheduleMode(UpdateScheduleMode m) async =>
      (await init()).setString(AppConstants.keyUpdateScheduleMode, m.name);

  static UpdateScheduleMode getUpdateScheduleMode() {
    final raw = _s?.getString(AppConstants.keyUpdateScheduleMode);
    return UpdateScheduleMode.values
        .firstWhere((e) => e.name == raw, orElse: () => UpdateScheduleMode.autoDaily);
  }

  static Future<void> setUpdateDailyTime({required int hour, required int minute}) async {
    final h = hour.clamp(0, 23);
    final m = minute.clamp(0, 59);
    final p = await init();
    await p.setInt(AppConstants.keyUpdateScheduleHour, h);
    await p.setInt(AppConstants.keyUpdateScheduleMinute, m);
  }

  static TimeOfDay getUpdateDailyTime() {
    final h = _s?.getInt(AppConstants.keyUpdateScheduleHour) ?? 9;
    final m = _s?.getInt(AppConstants.keyUpdateScheduleMinute) ?? 0;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  static Future<void> setUpdateIntervalMinutes(int minutes) async {
    final v = minutes.clamp(15, 24 * 60);
    (await init()).setInt(AppConstants.keyUpdateScheduleIntervalMinutes, v);
  }

  static int getUpdateIntervalMinutes() =>
      _s?.getInt(AppConstants.keyUpdateScheduleIntervalMinutes) ??
      AppConstants.autoUpdateIntervalMinutes;

  static Future<void> setUpdateScheduleLastDailyKey(String dayKey) async =>
      (await init()).setString(AppConstants.keyUpdateScheduleLastDailyKey, dayKey);

  static String? getUpdateScheduleLastDailyKey() =>
      _s?.getString(AppConstants.keyUpdateScheduleLastDailyKey);

  static Future<void> setSafePreviewEnabled(bool v) async =>
      (await init()).setBool(AppConstants.keySafePreviewEnabled, v);

  static bool getSafePreviewEnabled() =>
      _s?.getBool(AppConstants.keySafePreviewEnabled) ?? true;

  static Future<void> setStreakGoalDays(int days) async {
    final v = days.clamp(1, 365);
    (await init()).setInt(AppConstants.keyStreakGoalDays, v);
  }

  static int getStreakGoalDays() =>
      _s?.getInt(AppConstants.keyStreakGoalDays) ?? 30;

  static Future<void> setStreakReminderEnabled(bool enabled) async =>
      (await init()).setBool(AppConstants.keyStreakReminderEnabled, enabled);

  static bool getStreakReminderEnabled() =>
      _s?.getBool(AppConstants.keyStreakReminderEnabled) ?? false;

  static Future<void> setStreakReminderTime(
      {required int hour, required int minute}) async {
    final h = hour.clamp(0, 23);
    final m = minute.clamp(0, 59);
    final p = await init();
    await p.setInt(AppConstants.keyStreakReminderHour, h);
    await p.setInt(AppConstants.keyStreakReminderMinute, m);
  }

  static TimeOfDay getStreakReminderTime() {
    final h = _s?.getInt(AppConstants.keyStreakReminderHour) ?? 20;
    final m = _s?.getInt(AppConstants.keyStreakReminderMinute) ?? 0;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  static Future<void> setStreakReminderLastSentDay(String dayKey) async =>
      (await init()).setString(AppConstants.keyStreakReminderLastSentDay, dayKey);

  static String? getStreakReminderLastSentDay() =>
      _s?.getString(AppConstants.keyStreakReminderLastSentDay);

  static Future<void> setStreakSavedEnabled(bool enabled) async =>
      (await init()).setBool(AppConstants.keyStreakSavedEnabled, enabled);

  static bool getStreakSavedEnabled() =>
      _s?.getBool(AppConstants.keyStreakSavedEnabled) ?? false;

  static Future<void> setStreakSavedLastSentDay(String dayKey) async =>
      (await init()).setString(AppConstants.keyStreakSavedLastSentDay, dayKey);

  static String? getStreakSavedLastSentDay() =>
      _s?.getString(AppConstants.keyStreakSavedLastSentDay);

  static Future<void> setCelebrationsEnabled(bool enabled) async =>
      (await init()).setBool(AppConstants.keyCelebrationsEnabled, enabled);

  static bool getCelebrationsEnabled() =>
      _s?.getBool(AppConstants.keyCelebrationsEnabled) ?? false;

  static Future<void> setLastCelebratedStreakMilestone(int v) async =>
      (await init()).setInt(AppConstants.keyCelebrationsLastStreakMilestone, v);

  static int getLastCelebratedStreakMilestone() =>
      _s?.getInt(AppConstants.keyCelebrationsLastStreakMilestone) ?? 0;

  static Future<void> setLastCelebratedTotalMilestone(int v) async =>
      (await init()).setInt(AppConstants.keyCelebrationsLastTotalMilestone, v);

  static int getLastCelebratedTotalMilestone() =>
      _s?.getInt(AppConstants.keyCelebrationsLastTotalMilestone) ?? 0;

  static Future<void> setWeeklyDigestEnabled(bool enabled) async =>
      (await init()).setBool(AppConstants.keyWeeklyDigestEnabled, enabled);

  static bool getWeeklyDigestEnabled() =>
      _s?.getBool(AppConstants.keyWeeklyDigestEnabled) ?? false;

  static Future<void> setWeeklyDigestTime(
      {required int hour, required int minute}) async {
    final h = hour.clamp(0, 23);
    final m = minute.clamp(0, 59);
    final p = await init();
    await p.setInt(AppConstants.keyWeeklyDigestHour, h);
    await p.setInt(AppConstants.keyWeeklyDigestMinute, m);
  }

  static TimeOfDay getWeeklyDigestTime() {
    final h = _s?.getInt(AppConstants.keyWeeklyDigestHour) ?? 20;
    final m = _s?.getInt(AppConstants.keyWeeklyDigestMinute) ?? 30;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  static Future<void> setWeeklyDigestLastSentWeek(String weekKey) async =>
      (await init()).setString(AppConstants.keyWeeklyDigestLastSentWeek, weekKey);

  static String? getWeeklyDigestLastSentWeek() =>
      _s?.getString(AppConstants.keyWeeklyDigestLastSentWeek);

  static Future<void> setEarlyAccessShown(bool v) async =>
      (await init()).setBool(AppConstants.keyEarlyAccessShown, v);

  static bool getEarlyAccessShown() =>
      _s?.getBool(AppConstants.keyEarlyAccessShown) ?? false;

  static Future<void> setEarlyAccessCelebratePending(bool v) async {
    final p = await init();
    v ? p.setBool(AppConstants.keyEarlyAccessCelebratePending, true) : p.remove(AppConstants.keyEarlyAccessCelebratePending);
  }

  static bool consumeEarlyAccessCelebratePending() {
    final p = _s;
    if (p == null) return false;
    final v = p.getBool(AppConstants.keyEarlyAccessCelebratePending) ?? false;
    if (v) {
      p.remove(AppConstants.keyEarlyAccessCelebratePending);
    }
    return v;
  }

  static Future<void> setEarlyAccessCelebrationShown(bool v) async =>
      (await init()).setBool(AppConstants.keyEarlyAccessCelebrationShown, v);

  static bool getEarlyAccessCelebrationShown() =>
      _s?.getBool(AppConstants.keyEarlyAccessCelebrationShown) ?? false;

  static Future<void> setProEnabled(bool enabled) async =>
      (await init()).setBool(AppConstants.keyProEnabled, enabled);

  static bool getProEnabled() => _s?.getBool(AppConstants.keyProEnabled) ?? false;


  static Future<void> setOnboardingComplete(bool v) async =>
      (await init()).setBool(AppConstants.keyOnboarding, v);
  static bool isOnboardingComplete() =>
      _s?.getBool(AppConstants.keyOnboarding) ?? false;
  static Future<void> setFirstLoginGreetingPending(bool v) async =>
      (await init()).setBool(AppConstants.keyFirstLoginGreetingPending, v);
  static bool isFirstLoginGreetingPending() =>
      _s?.getBool(AppConstants.keyFirstLoginGreetingPending) ?? false;

  // ✨ NEW - Auth Error State for Token Expiration
  static Future<void> setHasAuthError(bool v) async => (await init()).setBool('has_auth_error', v);
  static bool hasAuthError() => _s?.getBool('has_auth_error') ?? false;

  static Future<void> setPendingWallpaperRefresh(bool v) async {
    final p = await init();
    v ? p.setBool(_kRef, true) : p.remove(_kRef);
  }

  static bool hasPendingWallpaperRefresh() => _s?.getBool(_kRef) ?? false;
  static Future<void> consumePendingWallpaperRefresh() async =>
      (await init()).remove(_kRef);

  static Future<void> setHasSeenDashboard(bool v) async =>
      (await init()).setBool(AppConstants.keyHasSeenDashboard, v);
  static bool hasSeenDashboard() =>
      _s?.getBool(AppConstants.keyHasSeenDashboard) ?? false;

  // Dimensions
  static Future<void> saveDeviceModel(String m) async =>
      (await init()).setString(AppConstants.keyDeviceModel, m.trim());
  static String? getDeviceModel() =>
      _s?.getString(AppConstants.keyDeviceModel)?.trim();
  static Future<void> saveDeviceMetrics(
      {required double width,
      required double height,
      required double pixelRatio,
      required EdgeInsets safeInsets}) async {
    (await init())
      ..setDouble(AppConstants.keyDimensionWidth, width)
      ..setDouble(AppConstants.keyDimensionHeight, height)
      ..setDouble(AppConstants.keyDimensionPixelRatio, pixelRatio)
      ..setDouble(AppConstants.keySafeInsetTop, safeInsets.top)
      ..setDouble(AppConstants.keySafeInsetBottom, safeInsets.bottom)
      ..setDouble(AppConstants.keySafeInsetLeft, safeInsets.left)
      ..setDouble(AppConstants.keySafeInsetRight, safeInsets.right);
  }

  static EdgeInsets getSafeInsets() {
    final p = _s;
    return EdgeInsets.fromLTRB(
        p?.getDouble(AppConstants.keySafeInsetLeft) ?? 0,
        p?.getDouble(AppConstants.keySafeInsetTop) ?? 0,
        p?.getDouble(AppConstants.keySafeInsetRight) ?? 0,
        p?.getDouble(AppConstants.keySafeInsetBottom) ?? 0);
  }

  /// Returns a map with 'width', 'height', and 'pixelRatio'.
  /// Returns null if storage is not initialized or metrics are not saved.
  static Map<String, double>? getDimensions() {
    final p = _s;
    final w = p?.getDouble(AppConstants.keyDimensionWidth);
    final h = p?.getDouble(AppConstants.keyDimensionHeight);
    final pr = p?.getDouble(AppConstants.keyDimensionPixelRatio);
    if (w == null || h == null || pr == null) return null;
    return {'width': w, 'height': h, 'pixelRatio': pr};
  }

  // Wallpaper
  static Future<void> saveWallpaperResult(String h, String p) async {
    (await init())
      ..setString(AppConstants.keyWallpaperHash, h)
      ..setString(AppConstants.keyWallpaperPath, p);
  }

  static String? getLastWallpaperHash() =>
      _s?.getString(AppConstants.keyWallpaperHash);
  static String? getLastWallpaperPath() =>
      _s?.getString(AppConstants.keyWallpaperPath);
  static Future<void> setHasAppliedWallpaper(bool v) async =>
      (await init()).setBool(AppConstants.keyHasAppliedWallpaper, v);
  static bool hasAppliedWallpaper() =>
      _s?.getBool(AppConstants.keyHasAppliedWallpaper) ?? false;

  static Future<void> setLastWallpaperTarget(WallpaperTarget t) async {
    (await init()).setString(AppConstants.keyLastWallpaperTarget, t.name);
  }

  static WallpaperTarget getLastWallpaperTarget() {
    final name = _s?.getString(AppConstants.keyLastWallpaperTarget);
    return WallpaperTarget.values
        .firstWhere((e) => e.name == name, orElse: () => WallpaperTarget.both);
  }

  /// Records a successful sync by updating both the generic and success timestamps.
  static Future<void> recordSyncSuccess([DateTime? dt]) async {
    final now = dt ?? DateTime.now().toUtc();
    final p = await init();
    final s = now.toIso8601String();
    await p.setString(AppConstants.keyLastUpdate, s);
    await p.setString(AppConstants.keyLastSuccessfulUpdate, s);
  }

  /// Returns the single most recent sync timestamp from any source.
  static DateTime? getEffectiveLastSync() {
    final p = _p;
    if (p == null) return null;

    final uStr = p.getString(AppConstants.keyLastUpdate);
    final bStr = p.getString(AppConstants.keyLastBackgroundSync);
    final sStr = p.getString(AppConstants.keyLastSuccessfulUpdate);
    
    final u = uStr != null ? DateTime.tryParse(uStr)?.toUtc() : null;
    final b = bStr != null ? DateTime.tryParse(bStr)?.toUtc() : null;
    final s = sStr != null ? DateTime.tryParse(sStr)?.toUtc() : null;
    
    DateTime? latest = u;
    if (b != null && (latest == null || b.isAfter(latest))) latest = b;
    if (s != null && (latest == null || s.isAfter(latest))) latest = s;
    return latest;
  }

  static Future<void> logout() async {
    try {
      await clearCache();
    } catch (e, s) {
      AppLog.error(e, s);
    }
    try {
      await deleteToken();
    } catch (e, s) {
      AppLog.error(e, s);
    }
    final prefs = await init();
    await Future.wait([
      prefs.remove(AppConstants.keyUsername),
      prefs.remove(AppConstants.keyWallpaperConfig),
      prefs.remove(AppConstants.keyOnboarding),
      prefs.remove(AppConstants.keyWallpaperHash),
      prefs.remove(AppConstants.keyWallpaperPath),
      prefs.remove(AppConstants.keyLastWallpaperTarget),
      prefs.remove(AppConstants.keyHasSeenDashboard),
      prefs.remove(AppConstants.keyFirstLoginGreetingPending),
      prefs.remove(AppConstants.keyAutoUpdate),
      prefs.remove(AppConstants.keyUpdateScheduleMode),
      prefs.remove(AppConstants.keyUpdateScheduleHour),
      prefs.remove(AppConstants.keyUpdateScheduleMinute),
      prefs.remove(AppConstants.keyUpdateScheduleIntervalMinutes),
      prefs.remove(AppConstants.keyUpdateScheduleLastDailyKey),
      prefs.remove(AppConstants.keySafePreviewEnabled),
      prefs.remove(AppConstants.keyHasAppliedWallpaper),
      prefs.remove(AppConstants.keyLastBackgroundSync),
      prefs.remove(_kRef),
      prefs.remove(AppConstants.keyStreakGoalDays),
      prefs.remove(AppConstants.keyStreakReminderEnabled),
      prefs.remove(AppConstants.keyStreakReminderHour),
      prefs.remove(AppConstants.keyStreakReminderMinute),
      prefs.remove(AppConstants.keyStreakReminderLastSentDay),
      prefs.remove(AppConstants.keyStreakSavedEnabled),
      prefs.remove(AppConstants.keyStreakSavedLastSentDay),
      prefs.remove(AppConstants.keyCelebrationsEnabled),
      prefs.remove(AppConstants.keyCelebrationsLastStreakMilestone),
      prefs.remove(AppConstants.keyCelebrationsLastTotalMilestone),
      prefs.remove(AppConstants.keyWeeklyDigestEnabled),
      prefs.remove(AppConstants.keyWeeklyDigestHour),
      prefs.remove(AppConstants.keyWeeklyDigestMinute),
      prefs.remove(AppConstants.keyWeeklyDigestLastSentWeek),
      prefs.remove(AppConstants.keyEarlyAccessShown),
      prefs.remove(AppConstants.keyEarlyAccessCelebratePending),
      prefs.remove(AppConstants.keyEarlyAccessCelebrationShown),
      prefs.remove(AppConstants.keyProEnabled),
    ]);
    await _safeSecureDelete(AppConstants.keyToken);
  }
}

// ══════════════════════════════════════════════════════════════════════════
// NOTIFICATION SERVICE
// ══════════════════════════════════════════════════════════════════════════
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    const AndroidInitializationSettings initAndroid =
        AndroidInitializationSettings('ic_stat_gitwall');
        
    // Darwin initialization settings are required for iOS/macOS, even though target is Android
    final DarwinInitializationSettings initDarwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
        
    final InitializationSettings initSettings =
        InitializationSettings(android: initAndroid, iOS: initDarwin, macOS: initDarwin);
        
    await _plugin.initialize(initSettings);
    _initialized = true;
    AppLog.info('NotificationService initialized');
  }

  static Future<void> requestPermissions() async {
    if (!_initialized) await init();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    } catch (e, s) {
      AppLog.error(e, s);
    }
    try {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e, s) {
      AppLog.error(e, s);
    }
  }

  static Future<void> showAuthErrorNotification() async {
    if (!_initialized) await init();
    
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'auth_error_channel',
      'Authentication Errors',
      channelDescription: 'Notifications for expired GitHub tokens',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF0D1117), // GitHub Dark BG
      icon: 'ic_stat_gitwall',
    );
    
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);
        
    await _plugin.show(
      1001,
      'GitHub Token Expired',
      'Wallpaper updates paused. Tap settings to update your token.',
      platformDetails,
    );
  }

  static Future<void> showStreakReminderNotification({
    required int goalDays,
    required int currentStreak,
  }) async {
    if (!_initialized) await init();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'streak_reminder_channel',
      'Streak Reminders',
      channelDescription: 'Reminders to keep your GitHub streak alive',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_gitwall',
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    final title = 'Save your streak';
    final body = currentStreak >= goalDays
        ? 'You hit your goal streak. Keep it going with a commit today.'
        : 'No commits yet today. Commit now to keep your $currentStreak‑day streak alive.';

    await _plugin.show(
      2001,
      title,
      body,
      platformDetails,
    );
  }

  static Future<void> showStreakSavedNotification({required int currentStreak}) async {
    if (!_initialized) await init();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'streak_saved_channel',
      'Streak Saved',
      channelDescription: 'Positive confirmations when you keep your streak alive',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: 'ic_stat_gitwall',
    );
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _plugin.show(
      2002,
      'Streak saved',
      'Nice. Your $currentStreak‑day streak stays alive.',
      platformDetails,
    );
  }

  static Future<void> showCelebrationNotification(
      {required String title, required String body}) async {
    if (!_initialized) await init();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'celebrations_channel',
      'Celebrations',
      channelDescription: 'Milestones for streaks and contributions',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: 'ic_stat_gitwall',
    );
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _plugin.show(
      2003,
      title,
      body,
      platformDetails,
    );
  }

  static Future<void> showWeeklyDigestNotification(
      {required String title, required String body}) async {
    if (!_initialized) await init();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'weekly_digest_channel',
      'Weekly Digest',
      channelDescription: 'Weekly summary of your GitHub activity',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: 'ic_stat_gitwall',
    );
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _plugin.show(
      2004,
      title,
      body,
      platformDetails,
    );
  }
}

// GITHUB
class GitHubService {
  static final http.Client _c = http.Client();

  static Future<http.Response> _viewerReq(String token, Duration timeout) {
    return _c
        .post(
          Uri.parse(AppConstants.apiUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'query': 'query{viewer{login}}'}),
        )
        .timeout(timeout);
  }
  static Future<CachedContributionData> getContributions(
      {required String username,
      required String token,
      bool forceRefresh = false}) async {
    // 1. Return cache if valid and not forced
    if (!forceRefresh) {
      final cached = StorageService.getCachedData();
      if (cached != null &&
          !cached.isStale() &&
          cached.username.toLowerCase() == username.toLowerCase()) {
        return cached;
      }
    } else {
      // CRITICAL: Clear in-memory cache to force fresh data load
      StorageService.clearMemoryCache();
    }

    // 2. Fetch from API
    try {
      final res = await _req(username, token);
      final data = jsonDecode(res.body);
      if (res.statusCode != 200 || data['errors'] != null) {
        if (res.statusCode == 401) throw TokenExpiredException();
        if (res.statusCode == 403) throw AccessDeniedException();
        if (res.statusCode == 429) throw RateLimitException();
        final errors = data['errors'];
        if (errors is List && errors.isNotEmpty) {
          final msg = errors.first['message']?.toString().toLowerCase() ?? '';
          if (msg.contains('rate limit')) throw RateLimitException();
          if (msg.contains('bad credentials') || msg.contains('unauthorized')) {
            throw TokenExpiredException();
          }
        }
        throw GitHubException('API Error: ${res.statusCode}',
            statusCode: res.statusCode, details: res.body);
      }
      if (data['data']?['user'] == null) throw UserNotFoundException();

      final parsed = _parse(data, username);

      // 3. Save to cache
      await StorageService.setCachedData(parsed);
      await StorageService.recordSyncSuccess();
      unawaited(WidgetService.updateFromData(parsed));
      unawaited(_postSyncNotifications(parsed));

      return parsed;
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      rethrow;
    }
  }

  static Future<http.Response> _req(String u, String t) async {
    const q =
        r'''query($login:String!,$from:DateTime!,$to:DateTime!){user(login:$login){avatarUrl contributionsCollection(from:$from,to:$to){contributionCalendar{totalContributions weeks{contributionDays{date contributionCount contributionLevel}}} commitContributionsByRepository(maxRepositories:100){repository{nameWithOwner url isPrivate primaryLanguage{name color} languages(first:20,orderBy:{field:SIZE,direction:DESC}){edges{size node{name color}}}} contributions{totalCount}}}}}''';
    final now = DateTime.now().toUtc();
    var a = 0;
    while (true) {
      try {
        final r = await _c
            .post(Uri.parse(AppConstants.apiUrl),
                headers: {
                  'Authorization': 'Bearer $t',
                  'Content-Type': 'application/json'
                },
                body: jsonEncode({
                  'query': q,
                  'variables': {
                    'login': u,
                    'from': now
                        .subtract(
                            Duration(days: AppConstants.githubDataFetchDays))
                        .toIso8601String(),
                    'to': now.toIso8601String()
                  }
                }))
            .timeout(AppConstants.apiTimeout);
        if (r.statusCode >= 500 && ++a < 3) {
          await Future.delayed(Duration(seconds: 1 << a));
          continue;
        }
        return r;
      } catch (e) {
        if (++a < 3) {
          await Future.delayed(Duration(seconds: 1 << a));
          continue;
        }
        rethrow;
      }
    }
  }

  static CachedContributionData _parse(Map<String, dynamic> j, String u) {
    try {
      final user = j['data']?['user'];
      if (user == null) throw UserNotFoundException();

      final avatarUrl = user['avatarUrl'] as String?;
      final coll = user['contributionsCollection'];
      if (coll == null) {
        throw GitHubException(
            'Incomplete data: contributionsCollection missing');
      }

      final cal = coll['contributionCalendar'];
      if (cal == null) {
        throw GitHubException('Incomplete data: contributionCalendar missing');
      }

      final days = <ContributionDay>[];
      final weeks = cal['weeks'] as List?;
      if (weeks != null) {
        for (var w in weeks) {
          final cDays = w['contributionDays'] as List?;
          if (cDays == null) continue;
          for (var d in cDays) {
            days.add(ContributionDay.fromJson(d));
          }
        }
      }

      final repos = <RepoContribution>[];
      final repoContribs = coll['commitContributionsByRepository'] as List?;
      if (repoContribs != null) {
        for (var r in repoContribs) {
          if (r['contributions']?['totalCount'] != null &&
              r['contributions']['totalCount'] > 0 &&
              r['repository'] != null) {
            final repo = r['repository'];
            final langs = <RepoLanguageSlice>[];
            final edges = repo['languages']?['edges'] as List?;
            if (edges != null) {
              for (var l in edges) {
                if (l['node'] != null) {
                  langs.add(RepoLanguageSlice(
                      name: l['node']['name'] ?? 'Unknown',
                      color: l['node']['color'],
                      size: l['size'] ?? 0));
                }
              }
            }
            repos.add(RepoContribution(
                nameWithOwner: repo['nameWithOwner'] ?? 'Unknown',
                url: repo['url'] ?? '',
                isPrivate: repo['isPrivate'] ?? false,
                commitCount: r['contributions']['totalCount'],
                primaryLanguageName: repo['primaryLanguage']?['name'],
                primaryLanguageColor: repo['primaryLanguage']?['color'],
                languages: langs));
          }
        }
      }
      repos.sort((a, b) => b.commitCount.compareTo(a.commitCount));
      return CachedContributionData(
          username: u,
          avatarUrl: avatarUrl,
          totalContributions: cal['totalContributions'] ?? 0,
          days: days,
          lastUpdated: DateTime.now().toUtc(),
          repositories: repos);
    } catch (e) {
      throw GitHubException('Parse Error: $e');
    }
  }


  static Future<bool> validateToken(String t) async {
    if (isValidTokenFormat(t) != null) return false;
    try {
      final r = await _viewerReq(t, const Duration(seconds: 8));
      return r.statusCode == 200 &&
          jsonDecode(r.body)['data']?['viewer']?['login'] != null;
    } catch (e, s) {
      AppLog.error(e, s);
      return false;
    }
  }

  static Future<void> _postSyncNotifications(CachedContributionData data) async {
    try {
      final nowUtc = DateTime.now().toUtc();
      final dayKey = AppDateUtils.formatDate(nowUtc);

      if (StorageService.getStreakSavedEnabled() &&
          StorageService.getStreakReminderLastSentDay() == dayKey &&
          data.todayCommits > 0 &&
          StorageService.getStreakSavedLastSentDay() != dayKey) {
        await NotificationService.showStreakSavedNotification(
          currentStreak: data.currentStreak,
        );
        await StorageService.setStreakSavedLastSentDay(dayKey);
      }

      if (StorageService.getCelebrationsEnabled()) {
        final streakMilestones = [7, 14, 30, 50, 100, 365];
        final totalMilestones = [500, 1000, 2500, 5000, 10000];

        final lastStreak = StorageService.getLastCelebratedStreakMilestone();
        final hitStreak =
            _greatestMilestoneAtOrBelow(data.currentStreak, streakMilestones);
        if (hitStreak > lastStreak) {
          await NotificationService.showCelebrationNotification(
            title: '🔥 $hitStreak‑day streak',
            body: 'Consistency looks good on you.',
          );
          await StorageService.setLastCelebratedStreakMilestone(hitStreak);
        }

        final lastTotal = StorageService.getLastCelebratedTotalMilestone();
        final hitTotal =
            _greatestMilestoneAtOrBelow(data.totalContributions, totalMilestones);
        if (hitTotal > lastTotal) {
          await NotificationService.showCelebrationNotification(
            title: '🚀 ${PresentationFormatter.formatCompactNumber(hitTotal)} contributions',
            body: 'Big numbers. Bigger momentum.',
          );
          await StorageService.setLastCelebratedTotalMilestone(hitTotal);
        }
      }
    } catch (e, s) {
      AppLog.error(e, s);
    }
  }

  static int _greatestMilestoneAtOrBelow(int value, List<int> milestones) {
    var best = 0;
    for (final m in milestones) {
      if (m <= value && m > best) best = m;
    }
    return best;
  }

  /// Lightweight background check specifically for token expiration detection.
  /// Throws TokenExpiredException if the token is affirmatively rejected.
  static Future<void> checkAuthStatus() async {
    final t = await StorageService.getToken();
    if (t == null) return;
    try {
      final r = await _viewerReq(t, const Duration(seconds: 5));
          
      if (r.statusCode == 401 || r.statusCode == 403) {
        throw TokenExpiredException();
      } else if (r.statusCode == 200) {
        if (StorageService.hasAuthError()) {
          await StorageService.setHasAuthError(false);
        }
      }
    } catch (e) {
      if (e is TokenExpiredException) rethrow; // Pass it up
      // Ignore network errors or timeouts during silent check
      AppLog.error(e);
    }
  }

  static void dispose() => _c.close();
}


String computeStableSignatureHash(String signature) {
  return sha256.convert(utf8.encode(signature)).toString();
}

// WALLPAPER

enum RefreshResult {
  success,
  noChanges,
  networkError,
  authError,
  unknownError,
  throttled;

  bool get isSuccess => index <= 1;
}

class WallpaperService {
  static final _l = Lock(), _ul = Lock();
  static const _wallpaperChannel = MethodChannel('github_wallpaper/wallpaper');

  static RefreshResult _resultForSkipReason(RefreshSkipReason? reason) {
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

  static Future<bool> generateAndSetWallpaper({
    required CachedContributionData data,
    required WallpaperConfig config,
    WallpaperTarget target = WallpaperTarget.both,
    bool forceApply = false,
    ValueChanged<double>? onProgress,
  }) async {
    return await _l.synchronized(() async {
      final hash = _hash(data, config, target);
      final previousHash = StorageService.getLastWallpaperHash();
      final previousPath = StorageService.getLastWallpaperPath();
      final hasPreviousFile =
          previousPath != null && await File(previousPath).exists();
      final isUnchanged = hash == previousHash && hasPreviousFile;

      if (!forceApply && isUnchanged) {
        AppLog.info('Wallpaper unchanged, skipping update (hash: $hash)');
        return false;
      }

      AppLog.info('Applying wallpaper (force: $forceApply, hash: $hash)');
      onProgress?.call(0.35);
      String wallpaperPath;
      if (isUnchanged) {
        wallpaperPath = previousPath;
      } else {
        final img = await _gen(data, config, target);
        wallpaperPath = await _save(img);
      }

      onProgress?.call(0.8);
      if (Platform.isAndroid) {
        await _setAndroidWallpaper(File(wallpaperPath), target);
        await StorageService.setHasAppliedWallpaper(true); // Ensure tracked
      }
      await StorageService.setLastWallpaperTarget(target);
      await StorageService.saveWallpaperResult(hash, wallpaperPath);
      AppLog.info('Wallpaper applied successfully (hash: $hash)');
      onProgress?.call(1.0);
      return true;
    });
  }

  static Future<String> generateWallpaperImage({
    required CachedContributionData data,
    required WallpaperConfig config,
    WallpaperTarget target = WallpaperTarget.both,
    bool forceGenerate = false,
    ValueChanged<double>? onProgress,
  }) async {
    return await _l.synchronized(() async {
      final hash = _hash(data, config, target);
      final previousHash = StorageService.getLastWallpaperHash();
      final previousPath = StorageService.getLastWallpaperPath();
      final hasPreviousFile =
          previousPath != null && await File(previousPath).exists();
      final isUnchanged = hash == previousHash && hasPreviousFile;

      onProgress?.call(0.35);
      final wallpaperPath = (!forceGenerate && isUnchanged)
          ? previousPath
          : await _save(await _gen(data, config, target));

      await StorageService.setLastWallpaperTarget(target);
      await StorageService.saveWallpaperResult(hash, wallpaperPath);
      onProgress?.call(1.0);
      return wallpaperPath;
    });
  }

  static Future<void> _setAndroidWallpaper(
      File wallpaperFile, WallpaperTarget target) async {
    bool nativeSuccess = false;
    try {
      final result = await _wallpaperChannel.invokeMethod<bool>(
        'setWallpaperFromPath',
        {'path': wallpaperFile.path, 'target': target.name},
      );
      nativeSuccess = result == true;
    } on MissingPluginException {
      // Fallback to plugin
    } on PlatformException catch (e) {
      AppLog.error('Native wallpaper method failed: ${e.code}', null);
    }

    if (nativeSuccess) return;

    // Fallback to plugin
    try {
      if (target == WallpaperTarget.both) {
        await WallpaperManagerPlus()
            .setWallpaper(wallpaperFile, WallpaperManagerPlus.homeScreen);
        await WallpaperManagerPlus()
            .setWallpaper(wallpaperFile, WallpaperManagerPlus.lockScreen);
        return;
      }

      await WallpaperManagerPlus()
          .setWallpaper(wallpaperFile, target.toManagerConstant());
    } catch (e) {
      throw WallpaperException(
          'Failed to set wallpaper directly and via fallback: $e');
    }
  }

  static Future<bool> openLiveWallpaperPicker() async {
    if (!Platform.isAndroid) return false;
    try {
      final ok = await _wallpaperChannel.invokeMethod<bool>(
        'openLiveWallpaperPicker',
      );
      return ok == true;
    } catch (e, s) {
      AppLog.error(e, s);
      return false;
    }
  }

  static Future<Uint8List> _gen(
      CachedContributionData d, WallpaperConfig c, WallpaperTarget t) async {
    final dm = StorageService.getDimensions();
    final w = dm?['width'] ?? AppConstants.defaultWallpaperWidth,
        h = dm?['height'] ?? AppConstants.defaultWallpaperHeight,
        pr = dm?['pixelRatio'] ?? AppConstants.defaultPixelRatio;

    final ec = DeviceCompatibilityChecker.applyPlacement(base: c, target: t);

    await Future<void>.delayed(Duration.zero);
    return await generateWallpaperTask({
      'data': jsonEncode(d.toJson()),
      'config': jsonEncode(ec.toJson()),
      'width': w,
      'height': h,
      'pixelRatio': pr,
    });
  }

  static Future<String> _save(Uint8List b) async {
    try {
      final d = await getTemporaryDirectory();

      // Cleanup: Delete all old wallpaper files to prevent storage accumulation
      try {
        final dir = Directory(d.path);
        if (await dir.exists()) {
          final files = dir.listSync();
          for (final f in files) {
            if (f is File &&
                f.path.contains('wp_') &&
                f.path.endsWith('.png')) {
              await f.delete();
            }
          }
        }
      } catch (e) {
        AppLog.error('Failed to cleanup old wallpapers: $e');
      }

      return (await File(
                  '${d.path}/wp_${DateTime.now().millisecondsSinceEpoch}.png')
              .writeAsBytes(b))
          .path;
    } catch (e) {
      throw WallpaperException('Failed to save wallpaper file: $e');
    }
  }

  static Future<RefreshResult> refreshWallpaper(
      {bool isBackground = false}) async {
    return await _ul.synchronized(() async {
      if (isBackground) {
        WidgetsFlutterBinding.ensureInitialized();
        await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform);
        await StorageService.init();
      }
      final username = StorageService.getUsername();
      final token = await StorageService.getToken();
      final scheduleMode = StorageService.getUpdateScheduleMode();
      final dailyTime = StorageService.getUpdateDailyTime();
      final intervalMinutes = StorageService.getUpdateIntervalMinutes();
      final dec = RefreshPolicy.shouldRefresh(
          isBackground: isBackground,
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
          lastDailyKey: StorageService.getUpdateScheduleLastDailyKey());
      if (!dec.shouldProceed) {
        final result = _resultForSkipReason(dec.skipReason);
        if (result == RefreshResult.noChanges) {
          await StorageService.consumePendingWallpaperRefresh();
        }
        return result;
      }
      try {
        if (username == null || token == null) {
          return RefreshResult.authError;
        }
        final d = await GitHubService.getContributions(
            username: username, token: token, forceRefresh: true);
        final target = StorageService.getLastWallpaperTarget();
        final result = await generateAndSetWallpaper(
                data: d,
                config: StorageService.getWallpaperConfig(),
                target: target)
            ? RefreshResult.success
            : RefreshResult.noChanges;
      if (isBackground &&
          scheduleMode == UpdateScheduleMode.autoDaily &&
          (result == RefreshResult.success || result == RefreshResult.noChanges)) {
        final localNow = DateTime.now();
        await StorageService.setUpdateScheduleLastDailyKey(
            AppDateUtils.formatDate(localNow));
      }
      if (result.isSuccess) {
        // Clear auth error if there was one
        if (StorageService.hasAuthError()) {
          await StorageService.setHasAuthError(false);
        }
        await StorageService.consumePendingWallpaperRefresh();
        await StorageService.recordSyncSuccess();
      }
      return result;
    } on NetworkException {
      return RefreshResult.networkError;
    } on SocketException {
      return RefreshResult.networkError;
    } on TokenExpiredException {
      await StorageService.setHasAuthError(true);
      if (isBackground) await NotificationService.showAuthErrorNotification();
      return RefreshResult.authError;
    } on AccessDeniedException {
      await StorageService.setHasAuthError(true);
      if (isBackground) await NotificationService.showAuthErrorNotification();
      return RefreshResult.authError;
    } on RateLimitException {
      return RefreshResult.throttled;
    } catch (e, s) {
      AppLog.error('Wallpaper refresh failed: $e', s);
      return RefreshResult.unknownError;
    }
  });
}

  // Connectivity check removed in favor of standard http error handling

  static String _hash(
      CachedContributionData d, WallpaperConfig c, WallpaperTarget t) {
    final todayKey = AppDateUtils.formatDate(DateTime.now().toUtc());
    final daySignature = d.days
        .map((day) => '${day.dateKey}:${day.contributionCount}')
        .join(',');
    final configSignature = jsonEncode(c.toJson());
    final signature =
        '${d.username.toLowerCase()}|${t.name}|$todayKey|$configSignature|$daySignature';
    return computeStableSignatureHash(signature);
  }
}


// SETUP & FCM
class DeviceCompatibilityChecker {
  static WallpaperConfig applyPlacement(
      {required WallpaperConfig base, required WallpaperTarget target}) {
    final m = StorageService.getDimensions(),
        i = StorageService.getSafeInsets();
    if (m == null) return base;
    final h = m['height']!;
    final lockClockBuffer = (h * AppConstants.deviceClockBufferHeightFraction)
        .clamp(AppConstants.deviceClockBufferMinPx,
            AppConstants.deviceClockBufferMaxPx)
        .toDouble();

    final double extraTop;
    final double extraBottom;
    switch (target) {
      case WallpaperTarget.lock:
      case WallpaperTarget.both:
        extraTop = i.top + lockClockBuffer;
        extraBottom = i.bottom + lockClockBuffer;
        break;
      case WallpaperTarget.home:
        // Home screen has fewer overlays than lock screen; keep placement tighter.
        extraTop = i.top + (lockClockBuffer * 0.35);
        extraBottom = i.bottom + (lockClockBuffer * 0.2);
        break;
    }

    return base.copyWith(
        paddingTop: base.paddingTop + extraTop,
        paddingBottom: base.paddingBottom + extraBottom,
        paddingLeft: base.paddingLeft + i.left + AppConstants.horizontalBuffer,
        paddingRight:
            base.paddingRight + i.right + AppConstants.horizontalBuffer);
  }
}

@pragma('vm:entry-point')
Future<void> _bgH(RemoteMessage m) async {
  try {
    if (m.data['type'] == 'refresh') {
      WidgetsFlutterBinding.ensureInitialized();
      try {
        final msg = RootIsolateToken.instance;
        if (msg != null) {
          BackgroundIsolateBinaryMessenger.ensureInitialized(msg);
        }
      } catch (e, s) {
        AppLog.error(e, s);
      }

      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);

      try {
        if (FirebaseCrashlytics.instance.isCrashlyticsCollectionEnabled) {
          // Crashlytics might be ready
        }
      } catch (e, s) {
        AppLog.error(e, s);
      }

      await StorageService.init();
      if (StorageService.getAutoUpdate() &&
          StorageService.hasAppliedWallpaper()) {
        final result = await WallpaperService.refreshWallpaper(isBackground: true);
        if (result == RefreshResult.networkError ||
            result == RefreshResult.unknownError ||
            result == RefreshResult.throttled) {
          await StorageService.setPendingWallpaperRefresh(true);
        }
      }
    }
  } catch (e, s) {
    // Error reporting handled in main.dart error handlers
    AppLog.error(e, s);
  }
}

class FcmService {
  static bool _initialized = false;
  static StreamSubscription<RemoteMessage>? _onMessageSub;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    FirebaseMessaging.onBackgroundMessage(_bgH);
    await syncTopicSubscription();
    _onMessageSub?.cancel();
    _onMessageSub = FirebaseMessaging.onMessage.listen((m) {
      if (m.data['type'] == 'refresh' &&
          StorageService.getAutoUpdate() &&
          StorageService.hasAppliedWallpaper()) {
        WallpaperService.refreshWallpaper();
      }
    });
  }

  static Future<void> dispose() async {
    try {
      await _onMessageSub?.cancel();
    } catch (e, s) {
      AppLog.error(e, s);
    }
    _onMessageSub = null;
    _initialized = false;
  }

  static Future<void> syncTopicSubscription() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    try {
      if (StorageService.getAutoUpdate()) {
        await FirebaseMessaging.instance
            .subscribeToTopic(AppConstants.fcmTopicDailyUpdates);
      } else {
        await FirebaseMessaging.instance
            .unsubscribeFromTopic(AppConstants.fcmTopicDailyUpdates);
      }
    } catch (e) {
      AppLog.error('FCM topic sync failed: $e');
    }
  }
}


class AppConfig {
  static final _l = Lock();
  static String? _sig;
  static Future<void> initializeFromPlatformDispatcher() async {
    try {
      final v = WidgetsBinding.instance.platformDispatcher.views.first;
      await _l.synchronized(() async {
        final mq = MediaQueryData.fromView(v);
        final sig = '${mq.size}|${mq.devicePixelRatio}';
        if (sig != _sig) {
          await StorageService.saveDeviceMetrics(
              width: mq.size.width,
              height: mq.size.height,
              pixelRatio: mq.devicePixelRatio,
              safeInsets: mq.viewPadding);
          _sig = sig;
        }
      });
    } catch (e, s) {
      AppLog.error(e, s);
    }
  }
}

// BOOTSTRAP
class BootstrapService {
  static Future<bool> boot({
    required Function(double) onProgress,
    required Function(String) onError,
  }) async {
    try {
      // 1. Storage
      await StorageService.init().timeout(const Duration(seconds: 10));
      onProgress(0.3);

      // 2. Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 15));

      final crashlyticsConsent = StorageService.getCrashlyticsConsent();
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode && crashlyticsConsent,
      );
      onProgress(0.6);

      // 3. Firebase Services (App Check, FCM)
      await _initFirebaseServices();
      onProgress(0.8);

      // 4. App Config
      await AppConfig.initializeFromPlatformDispatcher()
          .timeout(const Duration(seconds: 2), onTimeout: () {});

      // 5. Minimum Splash Duration
      onProgress(1.0);
      return true;
    } catch (e, stack) {
      // Error reporting handled in main.dart error handlers
      AppLog.error(e, stack);
      onError(ErrorHandler.getUserFriendlyMessage(e));
      return false;
    }
  }

  static Future<void> _initFirebaseServices() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    try {
      await FirebaseAppCheck.instance
          .activate(
            providerAndroid: kDebugMode
                ? AndroidDebugProvider()
                : AndroidPlayIntegrityProvider(),
            providerApple:
                kDebugMode ? AppleDebugProvider() : AppleAppAttestProvider(),
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      AppLog.error('AppCheck Activation Failed: $e');
    }

    try {
      await FcmService.init().timeout(const Duration(seconds: 5));
    } catch (e) {
      AppLog.error('FCM Init Failed: $e');
    }
  }
}
