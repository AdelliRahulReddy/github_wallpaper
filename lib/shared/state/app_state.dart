import 'package:flutter/material.dart';

import 'dart:async';

import 'package:github_wallpaper/shared/services/background_scheduler.dart';
import 'package:github_wallpaper/shared/services/notification_service.dart';
import 'package:github_wallpaper/data/datasources/local/storage_service.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';

class PresentationFormatter {
  static String getGreeting() {
    final h = DateTime.now().hour;
    return h < 12
        ? 'Good Morning'
        : h < 17
            ? 'Good Afternoon'
            : 'Good Evening';
  }

  static String formatCompactNumber(int n) => n >= 1000000
      ? '${(n / 1000000).toStringAsFixed(1)}m'
      : n >= 1000
          ? '${(n / 1000).toStringAsFixed(1)}k'
          : '$n';
  static String formatTimeSince(DateTime d) => timeAgo(d, long: true);
  static String formatTimeAgoCompact(DateTime d) => timeAgo(d, long: false);
  static String timeAgo(DateTime d, {bool long = false}) {
    final now = DateTime.now().toLocal();
    final target = d.toLocal();
    final diff = now.difference(target);

    if (diff.inSeconds.abs() > 300) {
      AppLog.info(
          'Clock drift detected: now=$now, target=$target, diff=${diff.inMinutes}m');
    }

    if (diff.inMinutes < 1) {
      return long ? 'Just now' : 'just now';
    }
    if (diff.inMinutes < 60) {
      return long ? '${diff.inMinutes} min ago' : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return long ? '${diff.inHours} hr ago' : '${diff.inHours}h ago';
    }
    return long ? '${diff.inDays} days ago' : '${diff.inDays}d ago';
  }
}

class TrendSummary {
  final int current, previous;
  const TrendSummary({required this.current, required this.previous});
  double get deltaRatio => previous <= 0
      ? (current <= 0 ? 0.0 : 1.0)
      : (current - previous) / previous;
  String get deltaLabel =>
      '${deltaRatio > 0 ? '+' : ''}${(deltaRatio * 100).toStringAsFixed(0)}% vs prev';
}

class ContributionAnalyzer {
  static Map<String, dynamic> analyzeContributions(List<dynamic> days,
      {required DateTime? nowUtc,
      required DateTime Function(dynamic) dateOf,
      required int Function(dynamic) countOf}) {
    final now = (nowUtc ?? DateTime.now()).toLocal();
    final sortedDays = List.from(days)
      ..sort((a, b) => dateOf(a).compareTo(dateOf(b)));

    // 1. Create a map for easy O(1) date lookup
    final dayMap = <String, int>{};
    for (var d in days) {
      final raw = dateOf(d).toLocal();
      dayMap[AppDateUtils.formatDate(DateTime(raw.year, raw.month, raw.day))] =
          countOf(d);
    }

    final todayUtc = DateTime(now.year, now.month, now.day);
    final todayStr = AppDateUtils.formatDate(todayUtc);

    // 2. Identify Current Streak
    int currentStreak = 0;
    DateTime checkDate = todayUtc;

    // If today is 0, we can still have a streak from yesterday (grace period)
    if ((dayMap[todayStr] ?? 0) <= 0) {
      checkDate = todayUtc.subtract(const Duration(days: 1));
    }

    while (true) {
      final dateStr = AppDateUtils.formatDate(checkDate);
      if ((dayMap[dateStr] ?? 0) > 0) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    // 3. Identify Longest Streak, Total, Peak, etc.
    int longestStreak = 0;
    int totalContributions = 0;
    int activeDaysCount = 0;
    int peakDayContributions = 0;
    int tempStreak = 0;
    DateTime? prevDate;

    for (var d in sortedDays) {
      final raw = dateOf(d).toLocal();
      final date = DateTime(raw.year, raw.month, raw.day);
      final count = countOf(d);

      if (count > 0) {
        totalContributions += count;
        activeDaysCount++;
        if (count > peakDayContributions) peakDayContributions = count;

        if (prevDate != null) {
          final diff = date.difference(prevDate).inDays;
          if (diff == 1) {
            tempStreak++;
          } else {
            if (tempStreak > longestStreak) longestStreak = tempStreak;
            tempStreak = 1;
          }
        } else {
          tempStreak = 1;
        }
        prevDate = date;
      } else {
        if (tempStreak > longestStreak) longestStreak = tempStreak;
        tempStreak = 0;
        prevDate = null;
      }
    }
    if (tempStreak > longestStreak) longestStreak = tempStreak;

    // 4. Weekday analysis
    final weekdayCounts = <int, int>{};
    for (var entry in dayMap.entries) {
      final date = AppDateUtils.parseDate(entry.key)!;
      weekdayCounts[date.weekday] =
          (weekdayCounts[date.weekday] ?? 0) + entry.value;
    }

    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    var mostActiveWeekday = AppConstants.fallbackWeekday;
    if (totalContributions > 0) {
      int maxWeekday = 1;
      int maxWCount = -1;
      for (int i = 1; i <= 7; i++) {
        final c = weekdayCounts[i] ?? 0;
        if (c > maxWCount) {
          maxWCount = c;
          maxWeekday = i;
        }
      }
      mostActiveWeekday = weekdays[maxWeekday - 1];
    }

    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalContributions': totalContributions,
      'activeDaysCount': activeDaysCount,
      'peakDayContributions': peakDayContributions,
      'todayContributions': dayMap[todayStr] ?? 0,
      'mostActiveWeekday': mostActiveWeekday,
    };
  }

  static ({DateTime date, int count})? findPeakDay<T>(
    List<T> days, {
    required DateTime Function(T) dateOf,
    required int Function(T) countOf,
  }) {
    DateTime? bestDate;
    var bestCount = 0;

    for (final day in days) {
      final count = countOf(day);
      if (count <= 0) continue;

      final rawDate = dateOf(day).toLocal();
      final normalizedDate = DateTime(rawDate.year, rawDate.month, rawDate.day);

      if (count > bestCount ||
          (count == bestCount &&
              bestDate != null &&
              normalizedDate.isAfter(bestDate))) {
        bestCount = count;
        bestDate = normalizedDate;
      }
    }

    if (bestDate == null || bestCount <= 0) return null;
    return (date: bestDate, count: bestCount);
  }

  static double averagePerActiveDay<T>(
    List<T> days, {
    required int Function(T) countOf,
  }) {
    var total = 0;
    var activeDays = 0;

    for (final day in days) {
      final count = countOf(day);
      if (count <= 0) continue;
      total += count;
      activeDays += 1;
    }

    if (activeDays == 0) return 0;
    return total / activeDays;
  }

  static TrendSummary computeTrend(List<dynamic> days,
      {required int window,
      required DateTime Function(dynamic) dateOf,
      required int Function(dynamic) countOf}) {
    final nowUtc = DateTime.now().toLocal();
    final today = DateTime(nowUtc.year, nowUtc.month, nowUtc.day);

    int current = 0;
    int previous = 0;

    final currentStart = today.subtract(Duration(days: window - 1));
    final previousStart = today.subtract(Duration(days: window * 2 - 1));

    for (var d in days) {
      final raw = dateOf(d).toLocal();
      final date = DateTime(raw.year, raw.month, raw.day);
      final count = countOf(d);

      if (!date.isBefore(currentStart) && !date.isAfter(today)) {
        current += count;
      } else if (!date.isBefore(previousStart) && date.isBefore(currentStart)) {
        previous += count;
      }
    }

    return TrendSummary(current: current, previous: previous);
  }
}

class CacheValidator {
  static bool isStale(DateTime lastUpdated,
      {Duration threshold = const Duration(hours: 6)}) {
    final now = DateTime.now().toLocal();
    return now.difference(lastUpdated.toLocal()).abs() > threshold;
  }
}

abstract class SafeChangeNotifier extends ChangeNotifier {
  bool _isDisposed = false;

  @protected
  bool get isDisposed => _isDisposed;

  @protected
  void notifySafely() {
    if (_isDisposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

class SettingsPreferencesState extends SafeChangeNotifier {
  bool streakRemindersEnabled = StorageService.getStreakReminderEnabled();
  bool streakSavedEnabled = StorageService.getStreakSavedEnabled();
  bool celebrationsEnabled = StorageService.getCelebrationsEnabled();
  bool weeklyDigestEnabled = StorageService.getWeeklyDigestEnabled();
  bool syncSuccessNotificationsEnabled =
      StorageService.getSyncSuccessNotificationsEnabled();
  bool dailySyncAlertEnabled = StorageService.getDailySyncAlertEnabled();
  bool adminBroadcastNotificationsEnabled =
      StorageService.getAdminBroadcastNotificationsEnabled();
  int weeklyCommitGoal = StorageService.getWeeklyCommitGoal();
  TimeOfDay weeklyDigestTime = StorageService.getWeeklyDigestTime();
  String? email = StorageService.getUserEmail();

  void refreshFromStorage() {
    streakRemindersEnabled = StorageService.getStreakReminderEnabled();
    streakSavedEnabled = StorageService.getStreakSavedEnabled();
    celebrationsEnabled = StorageService.getCelebrationsEnabled();
    weeklyDigestEnabled = StorageService.getWeeklyDigestEnabled();
    syncSuccessNotificationsEnabled =
        StorageService.getSyncSuccessNotificationsEnabled();
    dailySyncAlertEnabled = StorageService.getDailySyncAlertEnabled();
    adminBroadcastNotificationsEnabled =
        StorageService.getAdminBroadcastNotificationsEnabled();
    weeklyCommitGoal = StorageService.getWeeklyCommitGoal();
    weeklyDigestTime = StorageService.getWeeklyDigestTime();
    email = StorageService.getUserEmail();
    notifySafely();
  }

  void setStreakRemindersEnabled(bool value) {
    unawaited(_setStreakRemindersEnabled(value));
  }

  Future<void> _setStreakRemindersEnabled(bool value) async {
    streakRemindersEnabled = value;
    notifySafely();

    await StorageService.setStreakReminderEnabled(value);
    if (value) {
      await NotificationService.requestPermissions();
    }

    final shouldRun = StorageService.getStreakReminderEnabled() ||
        StorageService.getWeeklyDigestEnabled();
    if (shouldRun) {
      await BackgroundScheduler.scheduleStreakReminders();
    } else {
      await BackgroundScheduler.cancelStreakReminders();
    }
  }

  void setStreakSavedEnabled(bool value) {
    unawaited(_setStreakSavedEnabled(value));
  }

  Future<void> _setStreakSavedEnabled(bool value) async {
    streakSavedEnabled = value;
    notifySafely();

    await StorageService.setStreakSavedEnabled(value);
    if (value) {
      await NotificationService.requestPermissions();
    }
  }

  void setCelebrationsEnabled(bool value) {
    unawaited(_setCelebrationsEnabled(value));
  }

  Future<void> _setCelebrationsEnabled(bool value) async {
    celebrationsEnabled = value;
    notifySafely();

    await StorageService.setCelebrationsEnabled(value);
    if (value) {
      await NotificationService.requestPermissions();
    }
  }

  void setWeeklyDigestEnabled(bool value) {
    unawaited(_setWeeklyDigestEnabled(value));
  }

  Future<void> _setWeeklyDigestEnabled(bool value) async {
    weeklyDigestEnabled = value;
    notifySafely();

    await StorageService.setWeeklyDigestEnabled(value);
    if (value) {
      await NotificationService.requestPermissions();
    }

    final shouldRun = StorageService.getStreakReminderEnabled() ||
        StorageService.getWeeklyDigestEnabled();
    if (shouldRun) {
      await BackgroundScheduler.scheduleStreakReminders();
    } else {
      await BackgroundScheduler.cancelStreakReminders();
    }
  }

  Future<void> setWeeklyDigestTime(TimeOfDay value) async {
    weeklyDigestTime = value;
    notifySafely();
    await StorageService.setWeeklyDigestTime(
      hour: value.hour,
      minute: value.minute,
    );
    if (StorageService.getWeeklyDigestEnabled()) {
      await BackgroundScheduler.scheduleStreakReminders();
    }
  }

  void setDailySyncAlertEnabled(bool value) {
    unawaited(_setDailySyncAlertEnabled(value));
  }

  Future<void> _setDailySyncAlertEnabled(bool value) async {
    dailySyncAlertEnabled = value;
    notifySafely();

    await StorageService.setDailySyncAlertEnabled(value);
    if (value) {
      await NotificationService.requestPermissions();
    }
  }

  void setSyncSuccessNotificationsEnabled(bool value) {
    unawaited(_setSyncSuccessNotificationsEnabled(value));
  }

  Future<void> _setSyncSuccessNotificationsEnabled(bool value) async {
    syncSuccessNotificationsEnabled = value;
    notifySafely();

    await StorageService.setSyncSuccessNotificationsEnabled(value);
    if (value) {
      await NotificationService.requestPermissions();
    }
  }

  void setAdminBroadcastNotificationsEnabled(bool value) {
    unawaited(_setAdminBroadcastNotificationsEnabled(value));
  }

  Future<void> _setAdminBroadcastNotificationsEnabled(bool value) async {
    adminBroadcastNotificationsEnabled = value;
    notifySafely();

    await NotificationService.setAdminBroadcastNotificationsEnabled(value);
  }

  Future<void> setWeeklyCommitGoal(int value) async {
    weeklyCommitGoal = value;
    notifySafely();
    await StorageService.setWeeklyCommitGoal(value);
  }

  Future<void> refreshEmailFromGitHub() async {
    refreshFromStorage();
  }
}

class ThemeModeState extends SafeChangeNotifier {
  ThemeMode _mode = StorageService.getThemeMode();
  ThemeMode get mode => _mode;

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifySafely();
    await StorageService.setThemeMode(mode);
  }

  void refreshFromStorage() {
    _mode = StorageService.getThemeMode();
    notifySafely();
  }
}
