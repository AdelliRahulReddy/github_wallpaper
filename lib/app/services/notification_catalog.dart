import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

import 'package:github_wallpaper/features/contributions/services/contribution_metrics.dart';

class NotificationCopy {
  final String title;
  final String body;

  const NotificationCopy({
    required this.title,
    required this.body,
  });
}

class NotificationSpec {
  final int notificationId;
  final String channelId;
  final String channelName;
  final String channelDescription;
  final Importance importance;
  final Priority priority;
  final Color? color;
  final String icon;

  const NotificationSpec({
    required this.notificationId,
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
    required this.importance,
    required this.priority,
    this.color,
    this.icon = 'ic_stat_gitwall',
  });

  AndroidNotificationChannel get androidChannel => AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: importance,
      );

  AndroidNotificationDetails get androidDetails => AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: importance,
        priority: priority,
        color: color,
        icon: icon,
      );

  NotificationDetails get platformDetails => NotificationDetails(
        android: androidDetails,
        iOS: NotificationCatalog.darwinDetails,
        macOS: NotificationCatalog.darwinDetails,
      );
}

class NotificationCatalog {
  static const String adminBroadcastTopic = 'all_users_broadcast';
  static const String adminBroadcastType = 'admin_broadcast';
  static const int adminBroadcastMaxTitleLength = 80;
  static const int adminBroadcastMaxBodyLength = 240;
  static const int scheduledStreakReminderBaseId = 2100;
  static const int scheduledStreakReminderHorizonDays = 7;

  static const DarwinNotificationDetails darwinDetails =
      DarwinNotificationDetails();

  static const NotificationSpec authError = NotificationSpec(
    notificationId: 1001,
    channelId: 'auth_error_channel',
    channelName: 'Authentication Errors',
    channelDescription: 'Notifications for expired GitHub tokens',
    importance: Importance.high,
    priority: Priority.high,
    color: Color(0xFF0D1117),
  );

  static const NotificationSpec syncFailure = NotificationSpec(
    notificationId: 1002,
    channelId: 'sync_failure_channel',
    channelName: 'Sync Failures',
    channelDescription: 'Notifications for failed background sync attempts',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const NotificationSpec syncSuccess = NotificationSpec(
    notificationId: 1003,
    channelId: 'sync_success_channel',
    channelName: 'Sync Completed',
    channelDescription:
        'Notifications when GitWall finishes a background refresh',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const NotificationSpec streakReminder = NotificationSpec(
    notificationId: 2001,
    channelId: 'streak_reminder_channel',
    channelName: 'Streak Reminders',
    channelDescription: 'Reminders to keep your GitHub streak alive',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const NotificationSpec streakSaved = NotificationSpec(
    notificationId: 2002,
    channelId: 'streak_saved_channel',
    channelName: 'Streak Saved',
    channelDescription:
        'Positive confirmations when you keep your streak alive',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const NotificationSpec celebrations = NotificationSpec(
    notificationId: 2003,
    channelId: 'celebrations_channel',
    channelName: 'Celebrations',
    channelDescription: 'Milestones for streaks and contributions',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const NotificationSpec weeklyDigest = NotificationSpec(
    notificationId: 2004,
    channelId: 'weekly_digest_channel',
    channelName: 'Weekly Digest',
    channelDescription: 'Weekly summary of your GitHub activity',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const NotificationSpec adminBroadcast = NotificationSpec(
    notificationId: 3001,
    channelId: 'admin_broadcast_channel',
    channelName: 'Admin Broadcasts',
    channelDescription:
        'Messages sent instantly from the GitWall admin dashboard',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const List<NotificationSpec> allSpecs = [
    authError,
    syncFailure,
    syncSuccess,
    streakReminder,
    streakSaved,
    celebrations,
    weeklyDigest,
    adminBroadcast,
  ];

  static NotificationCopy authErrorCopy() => const NotificationCopy(
        title: 'GitHub authentication required',
        body: 'Sync paused. Reconnect GitHub from settings.',
      );

  static NotificationCopy syncFailureCopy() => const NotificationCopy(
        title: 'GitWall sync failed',
        body: 'Using cached data. We will retry in the next cycle.',
      );

  static NotificationCopy syncSuccessCopy(DateTime syncedAt) {
    final formattedTime = DateFormat.jm().format(syncedAt.toLocal());
    return NotificationCopy(
      title: 'GitWall synced successfully',
      body: 'Your latest GitHub activity was refreshed at $formattedTime.',
    );
  }

  static NotificationCopy streakReminderCopy({
    required int goalDays,
    required int currentStreak,
  }) {
    final body = currentStreak >= goalDays
        ? 'You hit your goal streak. Keep it going with a commit today.'
        : 'No commits yet today. Commit now to keep your $currentStreak-day streak alive.';
    return NotificationCopy(
      title: 'Save your streak',
      body: body,
    );
  }

  static NotificationCopy scheduledStreakReminderCopy({
    required int goalDays,
  }) {
    return NotificationCopy(
      title: 'Save your streak',
      body: goalDays <= 0
          ? 'No commits yet today. Commit now to keep your streak moving.'
          : 'No commits yet today. Commit now to protect your streak goal.',
    );
  }

  static NotificationCopy streakSavedCopy(int currentStreak) =>
      NotificationCopy(
        title: 'Streak saved',
        body: 'Nice. Your $currentStreak-day streak stays alive.',
      );

  static NotificationCopy weeklyDigestCopy({
    required int currentCommits,
    required String deltaLabel,
    String? topRepoName,
  }) {
    final trimmedRepo = topRepoName?.trim();
    final body = (trimmedRepo == null || trimmedRepo.isEmpty)
        ? 'This week: $currentCommits commits ($deltaLabel)'
        : 'This week: $currentCommits commits ($deltaLabel) | Top repo: $trimmedRepo';
    return NotificationCopy(
      title: 'Weekly Digest',
      body: body,
    );
  }

  static NotificationCopy streakMilestoneCopy(int streakDays) =>
      NotificationCopy(
        title: '$streakDays-day streak',
        body: 'Consistency looks good on you.',
      );

  static NotificationCopy totalContributionMilestoneCopy(int total) =>
      NotificationCopy(
        title:
            '${PresentationFormatter.formatCompactNumber(total)} contributions',
        body: 'Big numbers. Bigger momentum.',
      );

  static NotificationCopy remoteAdminBroadcastCopy(RemoteMessage message) {
    final title =
        '${message.notification?.title ?? message.data['title'] ?? ''}'.trim();
    final body =
        '${message.notification?.body ?? message.data['body'] ?? ''}'.trim();
    return NotificationCopy(
      title: title.isNotEmpty ? title : 'GitWall update',
      body:
          body.isNotEmpty ? body : 'A new message was sent from GitWall admin.',
    );
  }

  static bool shouldSubscribeToAdminBroadcasts({
    required bool hasSignedInUser,
    required bool hasValidAppSession,
    required bool isAnonymousUser,
    required bool broadcastsEnabled,
    required AuthorizationStatus permissionStatus,
  }) {
    return hasSignedInUser &&
        hasValidAppSession &&
        !isAnonymousUser &&
        broadcastsEnabled &&
        isAuthorizationAllowed(permissionStatus);
  }

  static bool isAuthorizationAllowed(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  static bool shouldDisplayAdminBroadcastLocally({
    required RemoteMessage message,
    TargetPlatform? platform,
  }) {
    final resolvedPlatform = platform ?? defaultTargetPlatform;
    final isDarwin = resolvedPlatform == TargetPlatform.iOS ||
        resolvedPlatform == TargetPlatform.macOS;
    if (!isDarwin) {
      return true;
    }
    return message.notification == null;
  }

  static int resolveAdminBroadcastNotificationId({
    String? broadcastId,
    String? messageId,
    DateTime? now,
  }) {
    final normalizedBroadcastId = (broadcastId ?? '').trim();
    final normalizedMessageId = (messageId ?? '').trim();
    final stableKey = normalizedBroadcastId.isNotEmpty
        ? normalizedBroadcastId
        : normalizedMessageId;
    if (stableKey.isNotEmpty) {
      return stableKey.hashCode & 0x7fffffff;
    }
    return (now ?? DateTime.now()).millisecondsSinceEpoch.remainder(
          0x7fffffff,
        );
  }
}
