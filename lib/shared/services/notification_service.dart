import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:github_wallpaper/core/constants/environment_config.dart';
import 'package:github_wallpaper/core/constants/firebase_options.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/data/datasources/local/storage_service.dart';

const String adminBroadcastTopic = 'all_users_broadcast';
const AndroidNotificationChannel _adminBroadcastChannel =
    AndroidNotificationChannel(
  'admin_broadcast_channel',
  'Admin Broadcasts',
  description: 'Messages sent instantly from the GitWall admin dashboard',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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

  static Future<void> init() async {
    if (_initialized) return;
    const AndroidInitializationSettings initAndroid =
        AndroidInitializationSettings('ic_stat_gitwall');

    final DarwinInitializationSettings initDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final InitializationSettings initSettings = InitializationSettings(
        android: initAndroid, iOS: initDarwin, macOS: initDarwin);

    await _plugin.initialize(initSettings);
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_adminBroadcastChannel);
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
    await showAdminBroadcastNotification(
      title: _remoteMessageTitle(message),
      body: _remoteMessageBody(message),
    );
    await acknowledgeBroadcastEvent(message, 'displayed');
  }

  static bool _isAdminBroadcast(RemoteMessage message) {
    return message.data['type'] == 'admin_broadcast';
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
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
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
      final canSubscribe = user != null &&
          !user.isAnonymous &&
          StorageService.getAdminBroadcastNotificationsEnabled() &&
          isAuthorizationAllowed(permissionStatus);

      if (canSubscribe) {
        await FirebaseMessaging.instance.subscribeToTopic(adminBroadcastTopic);
        AppLog.info('Subscribed to topic: $adminBroadcastTopic');
      } else {
        await FirebaseMessaging.instance
            .unsubscribeFromTopic(adminBroadcastTopic);
        AppLog.info(
            'Admin broadcasts unavailable. Unsubscribed from $adminBroadcastTopic');
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

  static String _remoteMessageTitle(RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'];
    return '$title'.trim().isNotEmpty ? '$title'.trim() : 'GitWall update';
  }

  static String _remoteMessageBody(RemoteMessage message) {
    final body = message.notification?.body ?? message.data['body'];
    return '$body'.trim().isNotEmpty
        ? '$body'.trim()
        : 'A new message was sent from GitWall admin.';
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
      color: Color(0xFF0D1117),
      icon: 'ic_stat_gitwall',
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _plugin.show(
      1001,
      'GitHub authentication required',
      'Sync paused. Reconnect GitHub from settings.',
      platformDetails,
    );
  }

  static Future<void> showSyncFailureNotification() async {
    if (!_initialized) await init();
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'sync_failure_channel',
      'Sync Failures',
      channelDescription: 'Notifications for failed background sync attempts',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_gitwall',
    );
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);
    await _plugin.show(
      1002,
      'GitWall sync failed',
      'Using cached data. We will retry in the next cycle.',
      platformDetails,
    );
  }

  static Future<void> showSyncSuccessNotification({
    required DateTime syncedAt,
  }) async {
    if (!_initialized) await init();
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'sync_success_channel',
      'Sync Completed',
      channelDescription:
          'Notifications when GitWall finishes a background refresh',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: 'ic_stat_gitwall',
    );
    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails();
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final localTime = syncedAt.toLocal();
    final hour = localTime.hour % 12 == 0 ? 12 : localTime.hour % 12;
    final minute = localTime.minute.toString().padLeft(2, '0');
    final suffix = localTime.hour >= 12 ? 'PM' : 'AM';
    final formattedTime = '$hour:$minute $suffix';

    await _plugin.show(
      1003,
      'GitWall synced successfully',
      'Your latest GitHub activity was refreshed at $formattedTime.',
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

  static Future<void> showStreakSavedNotification(
      {required int currentStreak}) async {
    if (!_initialized) await init();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'streak_saved_channel',
      'Streak Saved',
      channelDescription:
          'Positive confirmations when you keep your streak alive',
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

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
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

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
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

  static Future<void> showAdminBroadcastNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) await init();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'admin_broadcast_channel',
      'Admin Broadcasts',
      channelDescription:
          'Messages sent instantly from the GitWall admin dashboard',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_gitwall',
    );
    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails();
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
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
      if (user == null) {
        AppLog.info(
            'Skipping admin broadcast ack for $broadcastId because no Firebase user exists yet.');
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
