import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

import 'package:github_wallpaper/app/services/notification_catalog.dart';
import 'package:github_wallpaper/core/constants/environment_config.dart';
import 'package:github_wallpaper/core/constants/firebase_options.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/features/auth/services/identity_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await NotificationService.init();
  await NotificationService.handleIncomingRemoteMessage(message);
}

class NotificationService {
  static const MethodChannel _systemChannel =
      MethodChannel('github_wallpaper/system');
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _pushInitialized = false;
  static bool _timeZoneInitialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    await _ensureTimeZoneConfigured();

    const initAndroid = AndroidInitializationSettings('ic_stat_gitwall');
    const initDarwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: initAndroid,
      iOS: initDarwin,
      macOS: initDarwin,
    );

    await _plugin.initialize(initSettings);
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    for (final spec in NotificationCatalog.allSpecs) {
      await android?.createNotificationChannel(spec.androidChannel);
    }

    _initialized = true;
    AppLog.info('NotificationService initialized');
  }

  static Future<void> _ensureTimeZoneConfigured() async {
    if (_timeZoneInitialized) return;

    try {
      tz_data.initializeTimeZones();
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      _timeZoneInitialized = true;
      AppLog.info('Notification timezone configured: $timeZoneName');
    } catch (e, s) {
      AppLog.error('Failed to configure notification timezone: $e', s);
      _timeZoneInitialized = true;
    }
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

    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e, s) {
      AppLog.error(e, s);
    }

    await _syncAdminBroadcastTopicSubscription();
  }

  static Future<bool> ensureExactAlarmPermission(
      {bool interactive = false}) async {
    if (!_initialized) await init();

    if (!Platform.isAndroid) {
      return true;
    }

    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final canSchedule = await android?.canScheduleExactNotifications();
      if (canSchedule != false) {
        return true;
      }
      if (!interactive) {
        return false;
      }
      final requested = await android?.requestExactAlarmsPermission();
      return requested ?? false;
    } catch (e, s) {
      AppLog.error(e, s);
      return false;
    }
  }

  static Future<void> initPushMessaging() async {
    if (_pushInitialized) return;
    if (!_initialized) await init();

    try {
      final token = await FirebaseMessaging.instance.getToken();
      AppLog.info('FCM token ready: ${token ?? 'unavailable'}');
    } catch (e, s) {
      AppLog.error(e, s);
    }

    await _syncAdminBroadcastTopicSubscription();

    try {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e, s) {
      AppLog.error(e, s);
    }

    FirebaseMessaging.onMessage.listen((message) async {
      await handleIncomingRemoteMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      AppLog.info(
        'Admin broadcast opened from notification: ${message.messageId ?? 'unknown'}',
      );
      await acknowledgeBroadcastEvent(message, 'opened');
    });

    try {
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        AppLog.info(
          'Admin broadcast opened from terminated state: ${initialMessage.messageId ?? 'unknown'}',
        );
        await acknowledgeBroadcastEvent(initialMessage, 'opened');
      }
    } catch (e, s) {
      AppLog.error(e, s);
    }

    FirebaseAuth.instance.authStateChanges().listen((_) async {
      await _syncAdminBroadcastTopicSubscription();
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      AppLog.info('FCM token refreshed: $token');
      try {
        await _syncAdminBroadcastTopicSubscription();
      } catch (e, s) {
        AppLog.error(e, s);
      }
    });

    _pushInitialized = true;
    AppLog.info('Push messaging initialized');
  }

  static Future<void> handleIncomingRemoteMessage(RemoteMessage message) async {
    if (!_isAdminBroadcast(message)) return;
    if (!StorageService.getAdminBroadcastNotificationsEnabled()) return;
    if (!isAuthorizationAllowed(await getNotificationAuthorizationStatus())) {
      return;
    }

    await acknowledgeBroadcastEvent(message, 'received');

    final content = NotificationCatalog.remoteAdminBroadcastCopy(message);
    final shouldDisplayLocally =
        NotificationCatalog.shouldDisplayAdminBroadcastLocally(
      message: message,
    );

    if (shouldDisplayLocally) {
      await showAdminBroadcastNotification(
        title: content.title,
        body: content.body,
        notificationId: NotificationCatalog.resolveAdminBroadcastNotificationId(
          broadcastId: '${message.data['broadcast_id'] ?? ''}'.trim(),
          messageId: message.messageId,
        ),
      );
    }

    await acknowledgeBroadcastEvent(message, 'displayed');
  }

  static bool _isAdminBroadcast(RemoteMessage message) {
    return message.data['type'] == NotificationCatalog.adminBroadcastType;
  }

  static Future<AuthorizationStatus>
      getNotificationAuthorizationStatus() async {
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus;
    } catch (e, s) {
      AppLog.error(e, s);
      return AuthorizationStatus.notDetermined;
    }
  }

  static bool isAuthorizationAllowed(AuthorizationStatus status) {
    return NotificationCatalog.isAuthorizationAllowed(status);
  }

  static Future<void> setAdminBroadcastNotificationsEnabled(
      bool enabled) async {
    await StorageService.setAdminBroadcastNotificationsEnabled(enabled);
    if (enabled) {
      await requestPermissions();
    }
    await _syncAdminBroadcastTopicSubscription();
  }

  static Future<void> refreshAdminBroadcastSubscription() async {
    await _syncAdminBroadcastTopicSubscription();
  }

  static Future<void> _syncAdminBroadcastTopicSubscription() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final permissionStatus = await getNotificationAuthorizationStatus();
      final hasValidAppSession =
          await IdentityService.canUseAuthenticatedAppSession(
        user: user,
      );
      final canSubscribe = NotificationCatalog.shouldSubscribeToAdminBroadcasts(
        hasSignedInUser: user != null,
        hasValidAppSession: hasValidAppSession,
        isAnonymousUser: user?.isAnonymous ?? true,
        broadcastsEnabled:
            StorageService.getAdminBroadcastNotificationsEnabled(),
        permissionStatus: permissionStatus,
      );

      if (canSubscribe) {
        await FirebaseMessaging.instance
            .subscribeToTopic(NotificationCatalog.adminBroadcastTopic);
        AppLog.info(
          'Subscribed to topic: ${NotificationCatalog.adminBroadcastTopic}',
        );
      } else {
        await FirebaseMessaging.instance
            .unsubscribeFromTopic(NotificationCatalog.adminBroadcastTopic);
        AppLog.info(
          'Admin broadcasts unavailable. Unsubscribed from ${NotificationCatalog.adminBroadcastTopic}',
        );
      }
    } catch (e, s) {
      AppLog.error(e, s);
    }
  }

  static Future<bool> openSystemNotificationSettings() async {
    try {
      if (Platform.isAndroid) {
        final opened = await _systemChannel.invokeMethod<bool>(
          'openNotificationSettings',
        );
        return opened ?? false;
      }

      if (Platform.isIOS || Platform.isMacOS) {
        return launchUrl(
          Uri.parse('app-settings:'),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e, s) {
      AppLog.error(e, s);
    }

    return false;
  }

  static Future<void> showAuthErrorNotification() async {
    if (!_initialized) await init();
    final content = NotificationCatalog.authErrorCopy();
    await _plugin.show(
      NotificationCatalog.authError.notificationId,
      content.title,
      content.body,
      NotificationCatalog.authError.platformDetails,
    );
  }

  static Future<void> showSyncFailureNotification() async {
    if (!_initialized) await init();
    final content = NotificationCatalog.syncFailureCopy();
    await _plugin.show(
      NotificationCatalog.syncFailure.notificationId,
      content.title,
      content.body,
      NotificationCatalog.syncFailure.platformDetails,
    );
  }

  static Future<void> showSyncSuccessNotification({
    required DateTime syncedAt,
  }) async {
    if (!_initialized) await init();
    final content = NotificationCatalog.syncSuccessCopy(syncedAt);
    await _plugin.show(
      NotificationCatalog.syncSuccess.notificationId,
      content.title,
      content.body,
      NotificationCatalog.syncSuccess.platformDetails,
    );
  }

  static Future<void> showStreakReminderNotification({
    required int goalDays,
    required int currentStreak,
  }) async {
    if (!_initialized) await init();
    final content = NotificationCatalog.streakReminderCopy(
      goalDays: goalDays,
      currentStreak: currentStreak,
    );
    await _plugin.show(
      NotificationCatalog.streakReminder.notificationId,
      content.title,
      content.body,
      NotificationCatalog.streakReminder.platformDetails,
    );
    await StorageService.setStreakReminderLastSentDay(
      AppDateUtils.formatDate(DateTime.now().toLocal()),
    );
  }

  @visibleForTesting
  static List<DateTime> computeScheduledStreakReminderDates({
    required DateTime now,
    required TimeOfDay reminderTime,
    required bool hasCommittedToday,
    int horizonDays = NotificationCatalog.scheduledStreakReminderHorizonDays,
  }) {
    final localNow = now.toLocal();
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final todayReminder = DateTime(
      localNow.year,
      localNow.month,
      localNow.day,
      reminderTime.hour,
      reminderTime.minute,
    );

    var startOffset = 0;
    if (hasCommittedToday || !localNow.isBefore(todayReminder)) {
      startOffset = 1;
    }

    return List<DateTime>.generate(
      horizonDays,
      (index) => today.add(Duration(days: startOffset + index)),
      growable: false,
    );
  }

  static Future<void> syncScheduledStreakReminders({
    required bool enabled,
    required TimeOfDay reminderTime,
    required int goalDays,
    required int currentStreak,
    required bool hasCommittedToday,
    DateTime? now,
  }) async {
    if (!_initialized) await init();
    await cancelScheduledStreakReminders();

    if (!enabled) return;

    final canUseExact = await ensureExactAlarmPermission();
    final content = NotificationCatalog.scheduledStreakReminderCopy(
      goalDays: goalDays,
    );
    final scheduleMode = canUseExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final reminderDates = computeScheduledStreakReminderDates(
      now: now ?? DateTime.now(),
      reminderTime: reminderTime,
      hasCommittedToday: hasCommittedToday,
    );

    for (var index = 0; index < reminderDates.length; index++) {
      final day = reminderDates[index];
      final scheduledAt = tz.TZDateTime(
        tz.local,
        day.year,
        day.month,
        day.day,
        reminderTime.hour,
        reminderTime.minute,
      );
      final id = NotificationCatalog.scheduledStreakReminderBaseId + index;
      final payload = jsonEncode({
        'type': 'streak_reminder',
        'goalDays': goalDays,
        'currentStreak': currentStreak,
        'scheduledFor': scheduledAt.toIso8601String(),
      });

      await _plugin.zonedSchedule(
        id,
        content.title,
        content.body,
        scheduledAt,
        NotificationCatalog.streakReminder.platformDetails,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        payload: payload,
      );
    }
  }

  static Future<void> cancelScheduledStreakReminders() async {
    if (!_initialized) await init();

    for (var index = 0;
        index < NotificationCatalog.scheduledStreakReminderHorizonDays;
        index++) {
      await _plugin.cancel(
        NotificationCatalog.scheduledStreakReminderBaseId + index,
      );
    }
  }

  static Future<void> showStreakSavedNotification({
    required int currentStreak,
  }) async {
    if (!_initialized) await init();
    final content = NotificationCatalog.streakSavedCopy(currentStreak);
    await _plugin.show(
      NotificationCatalog.streakSaved.notificationId,
      content.title,
      content.body,
      NotificationCatalog.streakSaved.platformDetails,
    );
  }

  static Future<void> showCelebrationNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) await init();
    await _plugin.show(
      NotificationCatalog.celebrations.notificationId,
      title,
      body,
      NotificationCatalog.celebrations.platformDetails,
    );
  }

  static Future<void> showWeeklyDigestNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) await init();
    await _plugin.show(
      NotificationCatalog.weeklyDigest.notificationId,
      title,
      body,
      NotificationCatalog.weeklyDigest.platformDetails,
    );
  }

  static Future<void> showAdminBroadcastNotification({
    required String title,
    required String body,
    int? notificationId,
  }) async {
    if (!_initialized) await init();
    await _plugin.show(
      notificationId ?? NotificationCatalog.adminBroadcast.notificationId,
      title,
      body,
      NotificationCatalog.adminBroadcast.platformDetails,
    );
  }

  static Future<void> acknowledgeBroadcastEvent(
    RemoteMessage message,
    String event,
  ) async {
    final broadcastId = '${message.data['broadcast_id'] ?? ''}'.trim();
    if (broadcastId.isEmpty) {
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null ||
          !await IdentityService.canUseAuthenticatedAppSession(user: user)) {
        AppLog.info(
          'Skipping admin broadcast ack for $broadcastId because no valid GitWall app session exists yet.',
        );
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final idToken = await user.getIdToken();
      final response = await http.post(
        Uri.parse(AppConfig.adminBroadcastAckUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'broadcastId': broadcastId,
          'event': event,
          'messageId': message.messageId,
          'platform': defaultTargetPlatform.name,
          'appVersion': packageInfo.version,
          'buildNumber': packageInfo.buildNumber,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        AppLog.info('Admin broadcast acked: $event for $broadcastId');
        return;
      }

      AppLog.error(
        'Admin broadcast ack failed (${response.statusCode}): ${response.body}',
      );
    } catch (e, s) {
      AppLog.error(e, s);
    }
  }
}
