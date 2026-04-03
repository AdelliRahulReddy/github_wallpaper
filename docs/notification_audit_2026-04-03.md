# Notification Audit

Date: 2026-04-03

Status: current as of the 2026-04-03 notification refactor and admin-broadcast cleanup. Use `CODEBASE.md` for the broader repository index.

## Scope

Audited Flutter app notifications, background reminder scheduling, admin broadcast delivery, Firebase Functions broadcast sending, and the admin dashboard broadcast form.

## Inventory

| Type | Purpose | Trigger | Delivery | Recipient targeting | User control | Status |
| --- | --- | --- | --- | --- | --- | --- |
| Auth error | Warn when GitHub auth is expired or missing during background sync | `ContributionRepository.syncGitHubData()` returns auth error while running in background | Local notification via `flutter_local_notifications` | Users with background sync flow active, `dailySyncAlertEnabled == true`, and OS permission granted | Notifications > `Sync issues` | Healthy after refactor |
| Sync failure | Warn when background sync fails and cached data is used | Network/socket/unknown errors in background sync | Local notification | Same as auth error recipients | Notifications > `Sync issues` | Healthy after refactor |
| Sync success | Optional once-per-day confirmation after successful background refresh | Background sync success and no success notification sent today | Local notification | Users with `syncSuccessNotificationsEnabled == true` and OS permission granted | Notifications > `Sync completed` | Healthy after refactor |
| Streak reminder | Remind users before day end if they still have zero commits | WorkManager reminder window, fresh cache, zero commits today, not sent already | Local notification | Users with `streakReminderEnabled == true` and OS permission granted | Notifications > `Streak reminders` | Healthy after refactor |
| Streak saved | Confirm when the user commits after receiving a streak reminder | Post-sync path sees reminder sent today and `todayCommits > 0` | Local notification | Users with `streakSavedEnabled == true` | Notifications > `Streak saved` | Healthy after refactor |
| Celebration: streak milestone | Celebrate streak threshold crossings | Post-sync milestone detection for streak values `[7, 14, 30, 50, 100, 365]` | Local notification | Users with `celebrationsEnabled == true` | Notifications > `Milestone celebrations` | Healthy after refactor |
| Celebration: total contributions | Celebrate total contribution threshold crossings | Post-sync milestone detection for totals `[500, 1000, 2500, 5000, 10000]` | Local notification | Users with `celebrationsEnabled == true` | Notifications > `Milestone celebrations` | Healthy after refactor |
| Weekly digest | Summarize last 7 days of GitHub activity | Sunday reminder window with fresh cache and digest not already sent that week | Local notification | Users with `weeklyDigestEnabled == true` and OS permission granted | Notifications > `Weekly digest` | Healthy after refactor |
| Admin broadcast | Deliver urgent broadcast messages from admin dashboard | Firebase Function `sendAdminBroadcast` publishes to topic | FCM push with local surfacing in app when appropriate | Signed-in, non-anonymous users with valid app session, broadcast toggle on, and OS permission granted | Notifications > `Admin announcements` | Healthy after refactor |

## Issues Found

1. Notification copy and channel config were hardcoded in multiple places.
   Affected files: `notification_service.dart`, `background_scheduler.dart`, `contribution_repository.dart`, `functions/index.js`, `admin/index.html`, `admin/app.js`.
   Fix: centralized delivery copy, channel metadata, ids, topic rules, and broadcast limits into a notification catalog/config layer.

2. Non-admin local notifications had no iOS/macOS delivery details.
   Impact: several notification types were effectively Android-only even though permission prompts existed on Apple platforms.
   Fix: every notification spec now builds `NotificationDetails` with Android, iOS, and macOS payloads.

3. Admin broadcasts could duplicate on iOS/macOS foreground delivery.
   Root cause: FCM foreground presentation was enabled and the app also showed a local notification for the same incoming message.
   Fix: local admin broadcast display is now suppressed on Darwin when the remote payload already contains a system notification.

4. Admin broadcast notification ids were time-based and collision-prone.
   Impact: multiple broadcasts close together could overwrite each other in the tray.
   Fix: ids are now derived from `broadcast_id` or `messageId` when available.

5. Only the admin broadcast channel was pre-created.
   Impact: Android system settings would not expose the rest of the notification categories until first delivery.
   Fix: all channels are now created during notification service initialization.

## Remaining Risks

1. Admin broadcast `received`, `displayed`, and `opened` counts still depend on client acknowledgements. Metrics can undercount users who are offline, force-quit, or never return to the app after OS delivery.
2. There is still no shared cross-runtime source file for Dart and Node constants. The duplication is reduced and centralized per runtime, but not eliminated across languages.
3. The audit validated logic and syntax plus Flutter unit/widget tests, but not real-device OS delivery on Android/iOS notification trays.

## Accessibility Review

1. Channel names and descriptions are explicit and human-readable, which improves Android system settings discoverability.
2. Notification titles and bodies are now concise and avoid decorative-only emoji signaling.
3. Settings page controls use visible labels and native `Switch` controls, which is acceptable for screen readers and large text.
4. Recommendation: add action labels for future interactive notifications only if they are mirrored in visible UI and tested with TalkBack/VoiceOver.

## Automated Validation

- `dart analyze lib/app/services/notification_catalog.dart lib/app/services/notification_service.dart lib/app/services/background_scheduler.dart lib/features/contributions/repositories/contribution_repository.dart test/notification_service_test.dart test/background_scheduler_test.dart test/sync_logic_test.dart`
- `flutter test test/notification_service_test.dart test/background_scheduler_test.dart test/sync_logic_test.dart`
- `node --check functions/index.js`
- `node --check admin/app.js`

## Manual Test Matrix

1. Deny notification permission, enable `Admin announcements`, verify the user stays unsubscribed from the FCM topic and no local admin broadcast is shown.
2. Enable `Sync issues`, force an expired GitHub token, trigger background sync, verify the auth error notification title/body and single-channel delivery.
3. Enable `Sync completed`, run two successful background syncs on the same local day, verify only one success notification appears.
4. Enable `Streak reminders`, set reminder time near current local time, ensure zero commits today, verify one reminder appears and does not repeat after `streak_reminder_last_sent_day` is set.
5. After a reminder is sent, create a commit and sync, verify `Streak saved` appears once.
6. Enable `Milestone celebrations`, seed milestone-crossing data, sync, verify streak and total milestones send the correct copy.
7. Enable `Weekly digest`, move device time to Sunday inside the digest window, verify digest body with and without a top repo.
8. Send an admin broadcast from the web admin, verify broadcast acceptance in Firestore, device receipt, local display on Android foreground, no duplicate foreground alert on iOS/macOS, and ack counters increment in `admin_notifications/{id}`.
