import 'dart:async';

import 'package:flutter/material.dart';

import 'package:github_wallpaper/core/state/safe_change_notifier.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/app/services/background_scheduler.dart';
import 'package:github_wallpaper/app/services/notification_service.dart';

class SettingsController extends SafeChangeNotifier {
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

