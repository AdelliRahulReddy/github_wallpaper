import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

import 'package:github_wallpaper/data/models/app_models.dart';
import 'package:github_wallpaper/data/models/membership_models.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/features/wallpaper/widgets/ui_render.dart';

class StorageService {
  static final _initLock = Lock();
  static SharedPreferences? _p;
  static const _kRef = 'pending_wp_refresh';
  static const _ss = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true));
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
    } catch (_) {}
  }

  static SharedPreferences? get _s => _p;

  static Future<void> setToken(String t) async {
    if (t.trim().isEmpty) throw ArgumentError('Empty token');
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

  static Future<void> setUsername(String u) async {
    final nextUsername = u.trim();
    if (nextUsername.isEmpty) throw ArgumentError();

    final prefs = await init();
    final previousUsername = prefs.getString(AppConstants.keyUsername)?.trim();
    if (previousUsername != null &&
        previousUsername.isNotEmpty &&
        previousUsername.toLowerCase() != nextUsername.toLowerCase()) {
      await prefs.remove(AppConstants.keyDisplayName);
    }

    await prefs.setString(AppConstants.keyUsername, nextUsername);
  }

  static String? getUsername() => _s?.getString(AppConstants.keyUsername);

  static Future<void> setDisplayName(String? name) async {
    final sanitized = name?.replaceAll(RegExp(r'\s+'), ' ').trim();
    final prefs = await init();
    if (sanitized == null || sanitized.isEmpty) {
      await prefs.remove(AppConstants.keyDisplayName);
      return;
    }
    await prefs.setString(AppConstants.keyDisplayName, sanitized);
  }

  static String? getDisplayName() {
    final value = _s?.getString(AppConstants.keyDisplayName)?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static Future<void> setUserEmail(String? email) async {
    final v = email?.trim();
    final prefs = await init();
    if (v == null || v.isEmpty) {
      await prefs.remove(AppConstants.keyUserEmail);
      return;
    }
    await prefs.setString(AppConstants.keyUserEmail, v);
  }

  static String? getUserEmail() => _s?.getString(AppConstants.keyUserEmail);

  static Future<void> setCachedData(CachedContributionData d) async {
    _memCache = d;
    final json = d.toJson();
    final includePrivate = getIncludePrivateRepos();
    if (!includePrivate && json.containsKey('topLanguages')) {
      final publicRepos = d.repositories.where((r) => !r.isPrivate).toList();
      final publicLangs =
          CachedContributionData.calculateTopLanguages(publicRepos);
      json['topLanguages'] = publicLangs.map((l) => l.toJson()).toList();
    }

    final sensitiveFields = <String, dynamic>{};
    if (json.containsKey('repositories')) {
      final repos = json['repositories'] as List?;
      if (includePrivate && repos != null) {
        sensitiveFields['repositories'] = repos;
      } else if (repos != null) {
        sensitiveFields['repositories'] =
            repos.where((r) => r is Map && r['isPrivate'] != true).toList();
      }
      json.remove('repositories');
    }

    final prefs = await init();
    await prefs.setString(AppConstants.keyCachedData, jsonEncode(json));
    if (sensitiveFields.isNotEmpty) {
      await _ss.write(
        key: AppConstants.keyCachedDataSensitive,
        value: jsonEncode(sensitiveFields),
      );
      _sensitiveCache = sensitiveFields;
    } else {
      await _ss.delete(key: AppConstants.keyCachedDataSensitive);
      _sensitiveCache = null;
    }
  }

  static CachedContributionData? getCachedData() {
    if (_memCache != null) return _memCache!;
    try {
      final basicJson = _s?.getString(AppConstants.keyCachedData);
      if (basicJson == null) return null;
      final json = jsonDecode(basicJson) as Map<String, dynamic>;
      if (_sensitiveCache != null) {
        json.addAll(_sensitiveCache!);
      }
      _memCache = CachedContributionData.fromJson(json);
      return _memCache;
    } catch (e, s) {
      AppLog.error(e, s);
      _memCache = null;
      _sensitiveCache = null;
      unawaited(_clearCorruptedCachedData());
      return null;
    }
  }

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
    MonthHeatmapRenderer.clearCaches();
    final prefs = await init();
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
      prefs.remove(AppConstants.keyLastWallpaperUpdate),
      prefs.remove(_kRef),
      _safeSecureDelete(AppConstants.keyCachedDataSensitive),
    ]);
  }

  static Future<void> _clearCorruptedCachedData() async {
    final prefs = await init();
    await Future.wait([
      prefs.remove(AppConstants.keyCachedData),
      _safeSecureDelete(AppConstants.keyCachedDataSensitive),
    ]);
  }

  static Future<void> setIncludePrivateRepos(bool include) async =>
      (await init()).setBool(AppConstants.keyIncludePrivateRepos, include);

  static bool getIncludePrivateRepos() =>
      _s?.getBool(AppConstants.keyIncludePrivateRepos) ?? true;

  static Future<void> setCrashlyticsConsent(bool consent) async =>
      (await init()).setBool(AppConstants.keyCrashlyticsConsent, consent);

  static bool getCrashlyticsConsent() =>
      _s?.getBool(AppConstants.keyCrashlyticsConsent) ?? false;

  static bool hasCrashlyticsConsentBeenSet() =>
      _s?.containsKey(AppConstants.keyCrashlyticsConsent) ?? false;

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

  static Future<void> setAutoUpdate(bool e) async =>
      (await init()).setBool(AppConstants.keyAutoUpdate, e);
  static bool getAutoUpdate() =>
      _s?.getBool(AppConstants.keyAutoUpdate) ?? true;

  static Future<void> setAutoApplyAfterSync(bool e) async =>
      (await init()).setBool(AppConstants.keyAutoApplyAfterSync, e);

  static bool getAutoApplyAfterSync() =>
      _s?.getBool(AppConstants.keyAutoApplyAfterSync) ?? true;

  static Future<void> setUpdateScheduleMode(UpdateScheduleMode m) async =>
      (await init()).setString(AppConstants.keyUpdateScheduleMode, m.name);

  static UpdateScheduleMode getUpdateScheduleMode() {
    final raw = _s?.getString(AppConstants.keyUpdateScheduleMode);
    return UpdateScheduleMode.values.firstWhere((e) => e.name == raw,
        orElse: () => UpdateScheduleMode.autoDaily);
  }

  static Future<void> setUpdateDailyTime(
      {required int hour, required int minute}) async {
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
      (await init())
          .setString(AppConstants.keyUpdateScheduleLastDailyKey, dayKey);

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

  static Future<void> setWeeklyCommitGoal(int commits) async {
    final value = commits.clamp(5, 100);
    await (await init()).setInt(AppConstants.keyWeeklyCommitGoal, value);
  }

  static int getWeeklyCommitGoal() =>
      (_s?.getInt(AppConstants.keyWeeklyCommitGoal) ?? 20).clamp(5, 100);

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
      (await init())
          .setString(AppConstants.keyStreakReminderLastSentDay, dayKey);

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
      (await init())
          .setString(AppConstants.keyWeeklyDigestLastSentWeek, weekKey);

  static String? getWeeklyDigestLastSentWeek() =>
      _s?.getString(AppConstants.keyWeeklyDigestLastSentWeek);

  static Future<void> setDailySyncAlertEnabled(bool enabled) async =>
      (await init()).setBool(AppConstants.keyDailySyncAlertEnabled, enabled);

  static bool getDailySyncAlertEnabled() =>
      _s?.getBool(AppConstants.keyDailySyncAlertEnabled) ?? true;

  static Future<void> setSyncSuccessNotificationsEnabled(bool enabled) async =>
      (await init())
          .setBool(AppConstants.keySyncSuccessNotificationsEnabled, enabled);

  static bool getSyncSuccessNotificationsEnabled() =>
      _s?.getBool(AppConstants.keySyncSuccessNotificationsEnabled) ?? false;

  static Future<void> setSyncSuccessLastSentDay(String dayKey) async =>
      (await init()).setString(AppConstants.keySyncSuccessLastSentDay, dayKey);

  static String? getSyncSuccessLastSentDay() =>
      _s?.getString(AppConstants.keySyncSuccessLastSentDay);

  static Future<void> setAdminBroadcastNotificationsEnabled(
          bool enabled) async =>
      (await init())
          .setBool(AppConstants.keyAdminBroadcastNotificationsEnabled, enabled);

  static bool getAdminBroadcastNotificationsEnabled() =>
      _s?.getBool(AppConstants.keyAdminBroadcastNotificationsEnabled) ?? true;

  static Future<void> setThemeMode(ThemeMode mode) async =>
      (await init()).setString(AppConstants.keyThemeMode, mode.name);

  static ThemeMode getThemeMode() {
    final raw = _s?.getString(AppConstants.keyThemeMode);
    return ThemeMode.values
        .firstWhere((e) => e.name == raw, orElse: () => ThemeMode.system);
  }

  static Future<void> setSeenLongestStreak(int v) async =>
      (await init()).setInt(AppConstants.keySeenLongestStreak, v);

  static int getSeenLongestStreak() =>
      _s?.getInt(AppConstants.keySeenLongestStreak) ?? 0;

  static Future<void> setSeenStreakMilestone(int v) async =>
      (await init()).setInt(AppConstants.keySeenStreakMilestone, v);

  static int getSeenStreakMilestone() =>
      _s?.getInt(AppConstants.keySeenStreakMilestone) ?? 0;

  static Future<void> setCodingLevel(String value) async =>
      (await init()).setString(AppConstants.keyCodingLevel, value);

  static String getCodingLevel() =>
      _s?.getString(AppConstants.keyCodingLevel) ?? 'Regular coder';

  static Future<void> setQuoteTone(String value) async =>
      (await init()).setString(AppConstants.keyQuoteTone, value);

  static String getQuoteTone() =>
      _s?.getString(AppConstants.keyQuoteTone) ?? 'Motivational';

  static Future<void> setCachedAiQuote(
      {required String quote, required String dayKey}) async {
    final p = await init();
    await p.setString(AppConstants.keyCachedAiQuote, quote);
    await p.setString(AppConstants.keyCachedAiQuoteDay, dayKey);
  }

  static String? getCachedAiQuote() =>
      _s?.getString(AppConstants.keyCachedAiQuote);

  static String? getCachedAiQuoteDay() =>
      _s?.getString(AppConstants.keyCachedAiQuoteDay);

  static Future<void> setCachedMembershipInfo(MembershipInfo info) async {
    final prefs = await init();
    await prefs.setString(
      AppConstants.keyMembershipInfo,
      jsonEncode(info.toCacheJson()),
    );
    final lastValidatedAt = info.lastValidatedAt;
    if (lastValidatedAt != null) {
      await prefs.setString(
        AppConstants.keyMembershipLastValidatedAt,
        lastValidatedAt.toIso8601String(),
      );
    } else {
      await prefs.remove(AppConstants.keyMembershipLastValidatedAt);
    }
  }

  static MembershipInfo? getCachedMembershipInfo() {
    try {
      final raw = _s?.getString(AppConstants.keyMembershipInfo);
      if (raw == null || raw.trim().isEmpty) return null;
      return MembershipInfo.fromCacheJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (e, s) {
      AppLog.error(e, s);
      unawaited(clearCachedMembershipInfo());
      return null;
    }
  }

  static DateTime? getMembershipLastValidatedAt() {
    final raw = _s?.getString(AppConstants.keyMembershipLastValidatedAt);
    return raw == null ? null : DateTime.tryParse(raw)?.toLocal();
  }

  static Future<void> clearCachedMembershipInfo() async {
    final prefs = await init();
    await Future.wait([
      prefs.remove(AppConstants.keyMembershipInfo),
      prefs.remove(AppConstants.keyMembershipLastValidatedAt),
    ]);
  }

  static Future<void> setOnboardingComplete(bool v) async =>
      (await init()).setBool(AppConstants.keyOnboarding, v);
  static bool isOnboardingComplete() =>
      _s?.getBool(AppConstants.keyOnboarding) ?? false;
  static Future<bool> hasAuthenticatedSession() async {
    if (!isOnboardingComplete()) return false;
    final token = await getToken();
    final username = getUsername();
    return token?.trim().isNotEmpty == true &&
        username?.trim().isNotEmpty == true;
  }

  static Future<void> setFirstLoginGreetingPending(bool v) async =>
      (await init()).setBool(AppConstants.keyFirstLoginGreetingPending, v);
  static bool isFirstLoginGreetingPending() =>
      _s?.getBool(AppConstants.keyFirstLoginGreetingPending) ?? false;

  static Future<void> setHasAuthError(bool v) async =>
      (await init()).setBool('has_auth_error', v);
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

  static Map<String, double>? getDimensions() {
    final p = _s;
    final w = p?.getDouble(AppConstants.keyDimensionWidth);
    final h = p?.getDouble(AppConstants.keyDimensionHeight);
    final pr = p?.getDouble(AppConstants.keyDimensionPixelRatio);
    if (w == null || h == null || pr == null) return null;
    return {'width': w, 'height': h, 'pixelRatio': pr};
  }

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
    final normalized =
        t == WallpaperTarget.both ? WallpaperTarget.both : WallpaperTarget.lock;
    (await init()).setString(
      AppConstants.keyLastWallpaperTarget,
      normalized.name,
    );
  }

  static WallpaperTarget getLastWallpaperTarget() {
    final name = _s?.getString(AppConstants.keyLastWallpaperTarget);
    if (name == WallpaperTarget.both.name) {
      return WallpaperTarget.both;
    }
    return WallpaperTarget.lock;
  }

  static Future<void> recordWallpaperUpdate([DateTime? dt]) async {
    final now = (dt ?? DateTime.now()).toUtc();
    await (await init()).setString(
      AppConstants.keyLastWallpaperUpdate,
      now.toIso8601String(),
    );
  }

  static DateTime? getLastWallpaperUpdate() {
    final raw = _p?.getString(AppConstants.keyLastWallpaperUpdate);
    return raw == null ? null : DateTime.tryParse(raw)?.toUtc();
  }

  static Future<void> recordSyncSuccess([DateTime? dt]) async {
    final now = dt ?? DateTime.now().toUtc();
    final p = await init();
    final s = now.toIso8601String();
    await p.setString(AppConstants.keyLastSuccessfulUpdate, s);
  }

  static DateTime? getEffectiveLastSync() {
    final p = _p;
    if (p == null) return null;

    final sStr = p.getString(AppConstants.keyLastSuccessfulUpdate);
    final s = sStr != null ? DateTime.tryParse(sStr)?.toUtc() : null;
    if (s != null) return s;

    // Legacy fallback for installs that only persisted the older sync key.
    final legacy = p.getString(AppConstants.keyLastUpdate);
    return legacy == null ? null : DateTime.tryParse(legacy)?.toUtc();
  }

  static Future<void> logout() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (e, s) {
      AppLog.error(e, s);
    }
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
      prefs.remove(AppConstants.keyDisplayName),
      prefs.remove(AppConstants.keyUserEmail),
      prefs.remove(AppConstants.keyWallpaperConfig),
      prefs.remove(AppConstants.keyWallpaperHash),
      prefs.remove(AppConstants.keyWallpaperPath),
      prefs.remove(AppConstants.keyLastWallpaperTarget),
      prefs.remove(AppConstants.keyLastWallpaperUpdate),
      prefs.remove(AppConstants.keyHasSeenDashboard),
      prefs.remove(AppConstants.keyFirstLoginGreetingPending),
      prefs.remove(AppConstants.keyAutoUpdate),
      prefs.remove(AppConstants.keyAutoApplyAfterSync),
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
      prefs.remove(AppConstants.keyWeeklyCommitGoal),
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
      prefs.remove(AppConstants.keyDailySyncAlertEnabled),
      prefs.remove(AppConstants.keySyncSuccessNotificationsEnabled),
      prefs.remove(AppConstants.keySyncSuccessLastSentDay),
      prefs.remove(AppConstants.keyAdminBroadcastNotificationsEnabled),
      prefs.remove(AppConstants.keyThemeMode),
      prefs.remove(AppConstants.keySeenLongestStreak),
      prefs.remove(AppConstants.keySeenStreakMilestone),
      prefs.remove(AppConstants.keyCodingLevel),
      prefs.remove(AppConstants.keyQuoteTone),
      prefs.remove(AppConstants.keyCachedAiQuote),
      prefs.remove(AppConstants.keyCachedAiQuoteDay),
      prefs.remove(AppConstants.keyMembershipInfo),
      prefs.remove(AppConstants.keyMembershipLastValidatedAt),
    ]);
    await _safeSecureDelete(AppConstants.keyToken);
  }
}
