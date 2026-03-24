import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/features/membership/pages/membership_paywall_page.dart';
import 'package:github_wallpaper/features/settings/controllers/settings_controller.dart';
import 'package:github_wallpaper/features/settings/widgets/settings_widgets.dart';
import 'package:github_wallpaper/app/services/background_scheduler.dart';
import 'package:github_wallpaper/features/membership/services/membership_entitlements.dart';
import 'package:github_wallpaper/app/services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  TimeOfDay _streakTime = StorageService.getStreakReminderTime();
  TimeOfDay _weeklyDigestTime = StorageService.getWeeklyDigestTime();
  AuthorizationStatus _permissionStatus = AuthorizationStatus.notDetermined;

  @override
  void initState() {
    super.initState();
    _refreshPermissionStatus();
  }

  Future<void> _refreshPermissionStatus() async {
    final status =
        await NotificationService.getNotificationAuthorizationStatus();
    await NotificationService.refreshAdminBroadcastSubscription();
    if (!mounted) return;
    setState(() => _permissionStatus = status);
  }

  Future<void> _pickStreakTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _streakTime);
    if (!mounted || picked == null) return;
    setState(() => _streakTime = picked);
    await StorageService.setStreakReminderTime(
      hour: picked.hour,
      minute: picked.minute,
    );
    if (StorageService.getStreakReminderEnabled()) {
      await BackgroundScheduler.scheduleStreakReminders();
    }
  }

  Future<void> _pickWeeklyDigestTime(SettingsController prefs) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _weeklyDigestTime,
    );
    if (!mounted || picked == null) return;
    setState(() => _weeklyDigestTime = picked);
    await prefs.setWeeklyDigestTime(picked);
  }

  Future<void> _requestPermissionAgain() async {
    await NotificationService.requestPermissions();
    await _refreshPermissionStatus();
  }

  Future<void> _toggleStreakReminders(
    SettingsController prefs,
    bool value,
  ) async {
    prefs.setStreakRemindersEnabled(value);
    await _refreshPermissionStatus();
  }

  Future<void> _toggleAdminAnnouncements(
    SettingsController prefs,
    bool value,
  ) async {
    prefs.setAdminBroadcastNotificationsEnabled(value);
    await _refreshPermissionStatus();
  }

  Future<void> _toggleSyncIssues(
    SettingsController prefs,
    bool value,
  ) async {
    prefs.setDailySyncAlertEnabled(value);
    await _refreshPermissionStatus();
  }

  Future<void> _toggleSyncCompleted(
    SettingsController prefs,
    bool value,
  ) async {
    prefs.setSyncSuccessNotificationsEnabled(value);
    await _refreshPermissionStatus();
  }

  Future<void> _toggleWeeklyDigest(
    SettingsController prefs,
    bool value,
  ) async {
    prefs.setWeeklyDigestEnabled(value);
    await _refreshPermissionStatus();
  }

  Future<void> _toggleStreakSaved(
    SettingsController prefs,
    bool value,
  ) async {
    prefs.setStreakSavedEnabled(value);
    await _refreshPermissionStatus();
  }

  Future<void> _toggleCelebrations(
    SettingsController prefs,
    bool value,
  ) async {
    prefs.setCelebrationsEnabled(value);
    await _refreshPermissionStatus();
  }

  Future<void> _openSystemSettings() async {
    await NotificationService.openSystemNotificationSettings();
  }

  String _permissionLabel() {
    return switch (_permissionStatus) {
      AuthorizationStatus.authorized => 'Allowed',
      AuthorizationStatus.provisional => 'Allowed',
      AuthorizationStatus.denied => 'Blocked',
      AuthorizationStatus.notDetermined => 'Not asked',
    };
  }

  Color _permissionColor(ColorScheme scheme) {
    return NotificationService.isAuthorizationAllowed(_permissionStatus)
        ? scheme.secondary
        : scheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.settingsTokens;
    final prefs = context.watch<SettingsController>();
    final canUseReminders = MembershipEntitlements.canUseReminders;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: theme.scaffoldBackgroundColor,
        title: const Text('Notifications'),
      ),
      body: SingleChildScrollView(
        padding: tokens.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsCard(
              children: [
                SettingsTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'System notification access',
                  subtitle:
                      NotificationService.isAuthorizationAllowed(_permissionStatus)
                          ? 'Notifications can appear on this device.'
                          : 'Notifications are blocked or not granted yet.',
                  trailing: StatusChip(
                    label: _permissionLabel(),
                    color: _permissionColor(scheme),
                  ),
                  onTap: _refreshPermissionStatus,
                ),
                if (!NotificationService.isAuthorizationAllowed(
                  _permissionStatus,
                ))
                  SettingsTile(
                    icon: Icons.settings_outlined,
                    title: 'Enable in system settings',
                    subtitle:
                        'Open the device settings page for GitWall notifications.',
                    onTap: _openSystemSettings,
                  ),
                if (_permissionStatus == AuthorizationStatus.notDetermined)
                  SettingsTile(
                    icon: Icons.add_alert_outlined,
                    title: 'Request notification permission',
                    onTap: _requestPermissionAgain,
                  ),
                if (!canUseReminders)
                  SettingsTile(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Pro reminders',
                    subtitle:
                        'Streak reminders, milestone celebrations, and weekly digest are available on Pro plans only.',
                    trailing: const StatusChip(
                      label: 'Locked',
                      color: AppTheme.warningOrange,
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MembershipPaywallPage(
                          featureName: 'Pro reminders',
                          featureDescription:
                              'Reminder controls, weekly digest, and celebration notifications are part of Pro.',
                        ),
                      ),
                    ),
                  ),
                if (canUseReminders) ...[
                  SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: AppStrings.streakReminders,
                    subtitle: 'Prompt you before the day ends with no commits.',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: prefs.streakRemindersEnabled,
                          onChanged: (value) =>
                              _toggleStreakReminders(prefs, value),
                        ),
                      ],
                    ),
                    onTap: null,
                  ),
                  if (prefs.streakRemindersEnabled)
                    SettingsTile(
                      icon: Icons.schedule,
                      title: AppStrings.reminderTime,
                      trailing: Text(
                        _streakTime.format(context),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      onTap: _pickStreakTime,
                    ),
                  SettingsTile(
                    icon: Icons.done_all_outlined,
                    title: 'Streak saved',
                    subtitle: 'Confirm when you commit after a streak reminder.',
                    trailing: Switch(
                      value: prefs.streakSavedEnabled,
                      onChanged: (value) => _toggleStreakSaved(prefs, value),
                    ),
                    onTap: null,
                  ),
                  SettingsTile(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Milestone celebrations',
                    subtitle: 'Celebrate streak and contribution milestones.',
                    trailing: Switch(
                      value: prefs.celebrationsEnabled,
                      onChanged: (value) => _toggleCelebrations(prefs, value),
                    ),
                    onTap: null,
                  ),
                  SettingsTile(
                    icon: Icons.view_week_outlined,
                    title: 'Weekly digest',
                    subtitle: 'Get a Sunday summary of your GitHub week.',
                    trailing: Switch(
                      value: prefs.weeklyDigestEnabled,
                      onChanged: (value) => _toggleWeeklyDigest(prefs, value),
                    ),
                    onTap: null,
                  ),
                  if (prefs.weeklyDigestEnabled)
                    SettingsTile(
                      icon: Icons.schedule_send_outlined,
                      title: 'Weekly digest time',
                      trailing: Text(
                        _weeklyDigestTime.format(context),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      onTap: () => _pickWeeklyDigestTime(prefs),
                    ),
                ],
                SettingsTile(
                  icon: Icons.campaign_outlined,
                  title: 'Admin announcements',
                  subtitle: 'Instant alerts sent from the GitWall admin panel.',
                  trailing: Switch(
                    value: prefs.adminBroadcastNotificationsEnabled,
                    onChanged: (value) =>
                        _toggleAdminAnnouncements(prefs, value),
                  ),
                  onTap: null,
                ),
                SettingsTile(
                  icon: Icons.sync_problem_outlined,
                  title: 'Sync issues',
                  subtitle:
                      'Warn when background sync fails or GitHub needs reconnecting.',
                  trailing: Switch(
                    value: prefs.dailySyncAlertEnabled,
                    onChanged: (value) => _toggleSyncIssues(prefs, value),
                  ),
                  onTap: null,
                ),
                SettingsTile(
                  icon: Icons.cloud_done_outlined,
                  title: 'Sync completed',
                  subtitle:
                      'Optional once-a-day confirmation after a successful background refresh.',
                  trailing: Switch(
                    value: prefs.syncSuccessNotificationsEnabled,
                    onChanged: (value) => _toggleSyncCompleted(prefs, value),
                  ),
                  onTap: null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

