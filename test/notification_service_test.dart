import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:github_wallpaper/app/services/notification_catalog.dart';
import 'package:github_wallpaper/app/services/notification_service.dart';

RemoteMessage _remoteMessage({
  Map<String, dynamic>? data,
  Map<String, dynamic>? notification,
  String? messageId,
}) {
  final map = <String, dynamic>{
    'data': data ?? <String, dynamic>{},
    'messageId': messageId ?? 'msg-1',
  };
  if (notification != null) {
    map['notification'] = notification;
  }
  return RemoteMessage.fromMap(map);
}

void main() {
  group('NotificationCatalog specs', () {
    test('defines all notification channels with unique ids', () {
      final channelIds =
          NotificationCatalog.allSpecs.map((spec) => spec.channelId).toSet();
      final notificationIds = NotificationCatalog.allSpecs
          .map((spec) => spec.notificationId)
          .toSet();

      expect(NotificationCatalog.allSpecs, hasLength(8));
      expect(channelIds, hasLength(NotificationCatalog.allSpecs.length));
      expect(notificationIds, hasLength(NotificationCatalog.allSpecs.length));
      for (final spec in NotificationCatalog.allSpecs) {
        expect(spec.channelName, isNotEmpty);
        expect(spec.channelDescription, isNotEmpty);
        expect(spec.platformDetails.android, isNotNull);
        expect(spec.platformDetails.iOS, isNotNull);
        expect(spec.platformDetails.macOS, isNotNull);
      }
    });
  });

  group('NotificationCatalog content', () {
    late String? previousLocale;

    setUp(() {
      previousLocale = Intl.defaultLocale;
      Intl.defaultLocale = 'en_US';
    });

    tearDown(() {
      Intl.defaultLocale = previousLocale;
    });

    test('builds sync success notification with localized time', () {
      final content = NotificationCatalog.syncSuccessCopy(
        DateTime(2026, 4, 3, 21, 5),
      );

      expect(content.title, 'GitWall synced successfully');
      expect(content.body, contains('9:05'));
      expect(content.body, contains('PM'));
    });

    test('builds streak reminder message for unmet goal', () {
      final content = NotificationCatalog.streakReminderCopy(
        goalDays: 30,
        currentStreak: 12,
      );

      expect(content.title, 'Save your streak');
      expect(content.body, contains('12-day streak'));
    });

    test('builds streak reminder message for goal reached', () {
      final content = NotificationCatalog.streakReminderCopy(
        goalDays: 7,
        currentStreak: 8,
      );

      expect(content.body,
          'You hit your goal streak. Keep it going with a commit today.');
    });

    test('builds scheduled streak reminder message', () {
      final content = NotificationCatalog.scheduledStreakReminderCopy(
        goalDays: 30,
      );

      expect(content.title, 'Save your streak');
      expect(content.body, contains('No commits yet today'));
    });

    test('builds weekly digest message with top repo', () {
      final content = NotificationCatalog.weeklyDigestCopy(
        currentCommits: 14,
        deltaLabel: '+75%',
        topRepoName: 'adell/sample',
      );

      expect(content.title, 'Weekly Digest');
      expect(content.body,
          'This week: 14 commits (+75%) | Top repo: adell/sample');
    });

    test('builds admin broadcast fallback copy', () {
      final content = NotificationCatalog.remoteAdminBroadcastCopy(
        _remoteMessage(
          data: {
            'type': NotificationCatalog.adminBroadcastType,
          },
        ),
      );

      expect(content.title, 'GitWall update');
      expect(content.body, 'A new message was sent from GitWall admin.');
    });
  });

  group('NotificationCatalog routing', () {
    test('allows admin topic subscription only for valid opted-in users', () {
      expect(
        NotificationCatalog.shouldSubscribeToAdminBroadcasts(
          hasSignedInUser: true,
          hasValidAppSession: true,
          isAnonymousUser: false,
          broadcastsEnabled: true,
          permissionStatus: AuthorizationStatus.authorized,
        ),
        isTrue,
      );

      expect(
        NotificationCatalog.shouldSubscribeToAdminBroadcasts(
          hasSignedInUser: true,
          hasValidAppSession: true,
          isAnonymousUser: false,
          broadcastsEnabled: false,
          permissionStatus: AuthorizationStatus.authorized,
        ),
        isFalse,
      );

      expect(
        NotificationCatalog.shouldSubscribeToAdminBroadcasts(
          hasSignedInUser: true,
          hasValidAppSession: false,
          isAnonymousUser: false,
          broadcastsEnabled: true,
          permissionStatus: AuthorizationStatus.authorized,
        ),
        isFalse,
      );

      expect(
        NotificationCatalog.shouldSubscribeToAdminBroadcasts(
          hasSignedInUser: false,
          hasValidAppSession: true,
          isAnonymousUser: false,
          broadcastsEnabled: true,
          permissionStatus: AuthorizationStatus.authorized,
        ),
        isFalse,
      );
    });

    test('suppresses duplicate local admin notifications on darwin', () {
      final messageWithNotification = _remoteMessage(
        data: {'type': NotificationCatalog.adminBroadcastType},
        notification: {
          'title': 'Broadcast',
          'body': 'Hello',
        },
      );

      expect(
        NotificationCatalog.shouldDisplayAdminBroadcastLocally(
          message: messageWithNotification,
          platform: TargetPlatform.iOS,
        ),
        isFalse,
      );
      expect(
        NotificationCatalog.shouldDisplayAdminBroadcastLocally(
          message: messageWithNotification,
          platform: TargetPlatform.android,
        ),
        isTrue,
      );
    });

    test('still allows local admin notification for data-only darwin messages',
        () {
      final dataOnlyMessage = _remoteMessage(
        data: {
          'type': NotificationCatalog.adminBroadcastType,
          'title': 'Broadcast',
          'body': 'Hello',
        },
      );

      expect(
        NotificationCatalog.shouldDisplayAdminBroadcastLocally(
          message: dataOnlyMessage,
          platform: TargetPlatform.macOS,
        ),
        isTrue,
      );
    });

    test('uses stable admin broadcast notification ids when possible', () {
      final idA = NotificationCatalog.resolveAdminBroadcastNotificationId(
        broadcastId: 'broadcast-123',
        messageId: 'message-1',
      );
      final idB = NotificationCatalog.resolveAdminBroadcastNotificationId(
        broadcastId: 'broadcast-123',
        messageId: 'message-2',
      );

      expect(idA, idB);
      expect(idA, greaterThanOrEqualTo(0));
    });
  });

  group('NotificationService streak scheduling', () {
    test('schedules today first when reminder time has not passed', () {
      final dates = NotificationService.computeScheduledStreakReminderDates(
        now: DateTime(2026, 4, 3, 10, 15),
        reminderTime: const TimeOfDay(hour: 11, minute: 0),
        hasCommittedToday: false,
      );

      expect(dates.first, DateTime(2026, 4, 3));
      expect(dates[1], DateTime(2026, 4, 4));
    });

    test('skips today when reminder time has passed', () {
      final dates = NotificationService.computeScheduledStreakReminderDates(
        now: DateTime(2026, 4, 3, 13, 0),
        reminderTime: const TimeOfDay(hour: 11, minute: 0),
        hasCommittedToday: false,
      );

      expect(dates.first, DateTime(2026, 4, 4));
    });

    test('skips today when commits are already present', () {
      final dates = NotificationService.computeScheduledStreakReminderDates(
        now: DateTime(2026, 4, 3, 9, 30),
        reminderTime: const TimeOfDay(hour: 11, minute: 0),
        hasCommittedToday: true,
      );

      expect(dates.first, DateTime(2026, 4, 4));
    });
  });
}
