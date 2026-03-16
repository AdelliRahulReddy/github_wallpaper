// ══════════════════════════════════════════════════════════════════════════
// ⚙️ SETTINGS PAGE - Account & Preferences
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:github_wallpaper/app_services.dart';
import 'package:github_wallpaper/app_theme.dart';
import 'package:github_wallpaper/app_utils.dart';
import 'package:github_wallpaper/app_state.dart';
import 'package:github_wallpaper/background_scheduler.dart';
import 'package:github_wallpaper/pages/onboarding_page.dart';
import 'package:github_wallpaper/pages/wrapped_page.dart';
import 'package:github_wallpaper/ui_render.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  final DateTime? directUpdate;
  final VoidCallback? onRequireSync;

  const SettingsPage({super.key, this.directUpdate, this.onRequireSync});

  @override
  State<SettingsPage> createState() => _SettingsPageState();

  static Future<bool> showUpdateTokenDialog(BuildContext context) async {
    final tokenController = TextEditingController();
    bool tokenVisible = false;
    bool isLoading = false;
    String? errorMsg;

    bool saved = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final scheme = Theme.of(ctx).colorScheme;
            return AlertDialog(
              title: const Text('Update GitHub Token'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paste your new Personal Access Token below.',
                    style: TextStyle(
                      fontSize: AppTheme.fontBody,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  AppTheme.h16,
                  TextFormField(
                    controller: tokenController,
                    obscureText: !tokenVisible,
                    decoration: InputDecoration(
                      hintText: 'ghp_...',
                      prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          tokenVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () => setDialogState(() => tokenVisible = !tokenVisible),
                      ),
                    ),
                  ),
                  if (errorMsg != null) ...[
                    AppTheme.h8,
                    Text(
                      errorMsg!,
                      style: TextStyle(
                        fontSize: AppTheme.fontBody,
                        color: scheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final newToken = tokenController.text.trim();
                          if (newToken.isEmpty) {
                            setDialogState(() => errorMsg = 'Token cannot be empty.');
                            return;
                          }
                          setDialogState(() {
                            isLoading = true;
                            errorMsg = null;
                          });
                          final valid = await GitHubService.validateToken(newToken);
                          if (!valid) {
                            setDialogState(() {
                              isLoading = false;
                              errorMsg = 'Invalid or expired token. Please try again.';
                            });
                            return;
                          }
                          await StorageService.setToken(newToken);
                          await StorageService.setHasAuthError(false);
                          saved = true; // Signal to outer code
                          if (dialogContext.mounted) Navigator.pop(dialogContext);
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    tokenController.dispose();
    return saved;
  }
}

class _SettingsPageState extends State<SettingsPage> {
  String? _username;
  bool _autoUpdate = true;
  UpdateScheduleMode _updateScheduleMode = UpdateScheduleMode.autoDaily;
  TimeOfDay _updateDailyTime = const TimeOfDay(hour: 9, minute: 0);
  int _updateIntervalMinutes = AppConstants.autoUpdateIntervalMinutes;
  bool _crashlyticsConsent = true;
  bool _includePrivateRepos = true;
  bool _streakRemindersEnabled = false;
  int _streakGoalDays = 30;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _streakSavedEnabled = false;
  bool _celebrationsEnabled = false;
  bool _weeklyDigestEnabled = false;
  TimeOfDay _digestTime = const TimeOfDay(hour: 20, minute: 30);
  DateTime? _lastUpdate;
  String _appVersion = AppStrings.appVersion;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
  }

  Future<void> _loadSettings() async {
    final username = StorageService.getUsername();
    final autoUpdate = StorageService.getAutoUpdate();
    final updateScheduleMode = StorageService.getUpdateScheduleMode();
    final updateDailyTime = StorageService.getUpdateDailyTime();
    final updateIntervalMinutes = StorageService.getUpdateIntervalMinutes();
    var crashlyticsConsent = StorageService.getCrashlyticsConsent();
    final includePrivateRepos = StorageService.getIncludePrivateRepos();
    final streakGoalDays = StorageService.getStreakGoalDays();
    final streakRemindersEnabled = StorageService.getStreakReminderEnabled();
    final reminderTime = StorageService.getStreakReminderTime();
    final streakSavedEnabled = StorageService.getStreakSavedEnabled();
    final celebrationsEnabled = StorageService.getCelebrationsEnabled();
    final weeklyDigestEnabled = StorageService.getWeeklyDigestEnabled();
    final digestTime = StorageService.getWeeklyDigestTime();
    final lastUpdate = StorageService.getEffectiveLastSync();

    // If key has never been set, default to false until user explicitly consents
    if (!StorageService.hasCrashlyticsConsentBeenSet()) {
      crashlyticsConsent = false;
      await StorageService.setCrashlyticsConsent(false);
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    }

    if (!mounted) return;
    setState(() {
      _username = username;
      _autoUpdate = autoUpdate;
      _updateScheduleMode = updateScheduleMode;
      _updateDailyTime = updateDailyTime;
      _updateIntervalMinutes = updateIntervalMinutes;
      _crashlyticsConsent = crashlyticsConsent;
      _includePrivateRepos = includePrivateRepos;
      _streakGoalDays = streakGoalDays;
      _streakRemindersEnabled = streakRemindersEnabled;
      _reminderTime = reminderTime;
      _streakSavedEnabled = streakSavedEnabled;
      _celebrationsEnabled = celebrationsEnabled;
      _weeklyDigestEnabled = weeklyDigestEnabled;
      _digestTime = digestTime;
      _lastUpdate = lastUpdate;
    });
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (_) {
      // Fallback to hardcoded version
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.logoutConfirmTitle),
        content: Text(
            AppStrings.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: Text(AppStrings.logout),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;

      // Ensure background update lifecycle is fully torn down on logout.
      await StorageService.setAutoUpdate(false);
      await FcmService.syncTopicSubscription();
      await BackgroundScheduler.cancelUpdates();
      await BackgroundScheduler.cancelStreakReminders();
      await StorageService.setHasAuthError(false);
      await StorageService.logout();

      if (!mounted) return;

      // Clear entire navigation stack so user can't go back
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
        (route) => false,
      );
    }
  }


  Future<void> _handleUpdateToken() async {
    final saved = await SettingsPage.showUpdateTokenDialog(context);
    if (saved && mounted) {
      setState(() {}); // Re-read hasAuthError → banner disappears
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token updated successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.clearCacheConfirmTitle),
        content: Text(AppStrings.clearCacheConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.clear),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.clearCache();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.cacheCleared)),
      );
      _loadSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lastEffectiveUpdate = widget.directUpdate ?? _lastUpdate;
    return SingleChildScrollView(
      padding: AppTheme.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTheme.h16,

          AppSectionHeader(
            title: AppStrings.settings,
            subtitle: AppStrings.settingsSubtitle,
            trailing: Icon(Icons.tune_rounded, color: scheme.primary),
          ),

          AppTheme.h24,

          // Account Section
          _buildAccountSection(lastEffectiveUpdate),

          AppTheme.h20,

          // Preferences Section
          _buildPreferencesSection(),

          AppTheme.h20,

          // Data Section
          _buildDataSection(),
          AppTheme.h20,

          // About Section
          _buildAboutSection(),
          AppTheme.h20,

          // Logout Button
          _buildLogoutButton(),
          AppTheme.h40,
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // ACCOUNT SECTION
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildAccountSection(DateTime? lastUpdate) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: AppStrings.account),
          AppTheme.h16,

          // Username
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: AppTheme.brMedium,
                  border:
                      Border.all(color: scheme.primary.withValues(alpha: 0.20)),
                ),
                child: Icon(
                  Icons.person,
                  color: scheme.primary,
                  size: 24,
                ),
              ),
              AppTheme.w16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _username ?? AppStrings.unknown,
                      style: TextStyle(
                        fontSize: AppTheme.fontLarge,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    AppTheme.h4,
                    Text(
                      AppStrings.githubAccount,
                      style: TextStyle(
                        fontSize: AppTheme.fontBody,
                        color: scheme.onSurface.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          AppTheme.h16,

          // Last Sync
          if (lastUpdate != null)
            Container(
              padding: AppTheme.pAll12,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: AppTheme.brSmall,
                border:
                    Border.all(color: scheme.outline.withValues(alpha: 0.55)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sync,
                    size: 18,
                    color: scheme.onSurface.withValues(alpha: 0.72),
                  ),
                  AppTheme.w8,
                  Text(
                    '${AppStrings.lastSynced} ${PresentationFormatter.formatTimeSince(lastUpdate)}',
                    style: TextStyle(
                      fontSize: AppTheme.fontBody,
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          AppTheme.h12,

          // Update Token Row
          _buildSettingButton(
            icon: Icons.vpn_key_outlined,
            iconColor: AppTheme.warningOrange,
            title: 'Update GitHub Token',
            subtitle: 'Replace your current access token',
            onTap: _handleUpdateToken,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // PREFERENCES SECTION
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildPreferencesSection() {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: AppStrings.preferences),
          AppTheme.h16,

          // Auto Update Toggle
          _buildToggleRow(
            icon: Icons.autorenew,
            iconColor: scheme.primary,
            title: AppStrings.autoUpdate,
            subtitle: AppStrings.autoUpdateSubtitle,
            value: _autoUpdate,
            onChanged: (value) async {
              HapticFeedback.selectionClick();
              await StorageService.setAutoUpdate(value);
              await FcmService.syncTopicSubscription();

              // Schedule or cancel WorkManager background tasks
              if (value) {
                await BackgroundScheduler.scheduleUpdates();
              } else {
                await BackgroundScheduler.cancelUpdates();
              }

              if (mounted) {
                setState(() => _autoUpdate = value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value
                        ? AppStrings.autoUpdateEnabled
                        : AppStrings.autoUpdateDisabled),
                  ),
                );
              }
            },
          ),

          if (_autoUpdate) ...[
            AppTheme.h12,
            Text(
              'Note: Android may delay background updates depending on battery optimization, Doze, and network conditions.',
              style: tt.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            AppTheme.h12,
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Update schedule',
                    style: tt.titleSmall?.copyWith(color: scheme.onSurface),
                  ),
                ),
                SegmentedButton<UpdateScheduleMode>(
                  segments: const [
                    ButtonSegment(
                      value: UpdateScheduleMode.autoDaily,
                      label: Text('Daily'),
                      icon: Icon(Icons.event_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: UpdateScheduleMode.interval,
                      label: Text('Interval'),
                      icon: Icon(Icons.timer_rounded, size: 16),
                    ),
                  ],
                  selected: {_updateScheduleMode},
                  onSelectionChanged: (s) async {
                    HapticFeedback.selectionClick();
                    final next = s.first;
                    await StorageService.setUpdateScheduleMode(next);
                    await BackgroundScheduler.scheduleUpdates();
                    if (mounted) setState(() => _updateScheduleMode = next);
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            AppTheme.h12,
            if (_updateScheduleMode == UpdateScheduleMode.autoDaily)
              _buildSettingButton(
                icon: Icons.schedule_rounded,
                iconColor: scheme.secondary,
                title: 'Daily time',
                subtitle: 'Around ${_updateDailyTime.format(context)}',
                trailing: Icons.chevron_right_rounded,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _updateDailyTime,
                  );
                  if (picked == null) return;
                  HapticFeedback.selectionClick();
                  await StorageService.setUpdateDailyTime(
                    hour: picked.hour,
                    minute: picked.minute,
                  );
                  await BackgroundScheduler.scheduleUpdates();
                  if (mounted) setState(() => _updateDailyTime = picked);
                },
              )
            else
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scheme.secondary.withValues(alpha: 0.12),
                      borderRadius: AppTheme.brSmall,
                      border:
                          Border.all(color: scheme.secondary.withValues(alpha: 0.20)),
                    ),
                    child: Icon(Icons.timer_rounded,
                        color: scheme.secondary, size: 20),
                  ),
                  AppTheme.w16,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Interval',
                            style:
                                tt.titleSmall?.copyWith(color: scheme.onSurface)),
                        AppTheme.h2,
                        Text('Refresh every $_updateIntervalMinutes minutes',
                            style: tt.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.72),
                            )),
                      ],
                    ),
                  ),
                  DropdownButton<int>(
                    value: _updateIntervalMinutes,
                    items: const [
                      DropdownMenuItem(value: 30, child: Text('30m')),
                      DropdownMenuItem(value: 60, child: Text('60m')),
                      DropdownMenuItem(value: 120, child: Text('2h')),
                      DropdownMenuItem(value: 240, child: Text('4h')),
                    ],
                    onChanged: (v) async {
                      if (v == null) return;
                      HapticFeedback.selectionClick();
                      await StorageService.setUpdateIntervalMinutes(v);
                      await BackgroundScheduler.scheduleUpdates();
                      if (mounted) setState(() => _updateIntervalMinutes = v);
                    },
                  ),
                ],
              ),
            AppTheme.h16,
          ],

          AppTheme.h16,

          // Crashlytics Consent Toggle
          _buildToggleRow(
            icon: Icons.bug_report_outlined,
            iconColor: AppTheme.warningOrange,
            title: AppStrings.crashReporting,
            subtitle: AppStrings.crashReportingSubtitle,
            value: _crashlyticsConsent,
            onChanged: (value) async {
              HapticFeedback.selectionClick();
              await StorageService.setCrashlyticsConsent(value);
              await FirebaseCrashlytics.instance
                  .setCrashlyticsCollectionEnabled(!kDebugMode && value);
              if (mounted) {
                setState(() => _crashlyticsConsent = value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value
                        ? AppStrings.crashReportingEnabled
                        : AppStrings.crashReportingDisabled),
                  ),
                );
              }
            },
          ),

          AppTheme.h16,

          // Include Private Repos Toggle
          _buildToggleRow(
            icon: Icons.lock_outline,
            iconColor: AppTheme.accentViolet,
            title: AppStrings.includePrivateRepos,
            subtitle: AppStrings.includePrivateReposSubtitle,
            value: _includePrivateRepos,
            onChanged: (value) async {
              HapticFeedback.selectionClick();
              await StorageService.setIncludePrivateRepos(value);
              // Trigger sync to adjust data representation right away
              if (value) widget.onRequireSync?.call();
              if (mounted) {
                setState(() => _includePrivateRepos = value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value
                        ? AppStrings.privateReposCached
                        : AppStrings.privateRepoCacheCleared),
                  ),
                );
              }
            },
          ),
          AppTheme.h16,
          const Divider(),
          AppTheme.h16,
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: AppTheme.brSmall,
                  border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
                ),
                child: Icon(Icons.flag_rounded, color: scheme.primary, size: 20),
              ),
              AppTheme.w16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.streakGoal,
                      style: TextStyle(
                        fontSize: AppTheme.fontMedium,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    AppTheme.h2,
                    Text(
                      AppStrings.streakGoalSubtitle,
                      style: TextStyle(
                        fontSize: AppTheme.fontBody,
                        color: scheme.onSurface.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownButton<int>(
                value: _streakGoalDays,
                items: const [
                  DropdownMenuItem(value: 7, child: Text('7d')),
                  DropdownMenuItem(value: 14, child: Text('14d')),
                  DropdownMenuItem(value: 30, child: Text('30d')),
                  DropdownMenuItem(value: 60, child: Text('60d')),
                  DropdownMenuItem(value: 100, child: Text('100d')),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  HapticFeedback.selectionClick();
                  await StorageService.setStreakGoalDays(v);
                  if (mounted) setState(() => _streakGoalDays = v);
                },
              ),
            ],
          ),
          AppTheme.h16,
          _buildToggleRow(
            icon: Icons.notifications_active_outlined,
            iconColor: AppTheme.warningOrange,
            title: AppStrings.streakReminders,
            subtitle: AppStrings.streakRemindersSubtitle,
            value: _streakRemindersEnabled,
            onChanged: (value) async {
              HapticFeedback.selectionClick();
              await StorageService.setStreakReminderEnabled(value);
              if (value) await _requestNotificationPermission();
              await _syncNotificationScheduler();
              if (mounted) setState(() => _streakRemindersEnabled = value);
            },
          ),
          AppTheme.h16,
          _buildSettingButton(
            icon: Icons.schedule_rounded,
            iconColor: scheme.secondary,
            title: AppStrings.reminderTime,
            subtitle:
                '${AppStrings.reminderTimeSubtitle}: ${_reminderTime.format(context)}',
            onTap: !_streakRemindersEnabled
                ? null
                : () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _reminderTime,
                    );
                    if (picked == null) return;
                    HapticFeedback.selectionClick();
                    await StorageService.setStreakReminderTime(
                        hour: picked.hour, minute: picked.minute);
                    if (mounted) setState(() => _reminderTime = picked);
                  },
          ),
          AppTheme.h16,
          _buildToggleRow(
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppTheme.successGreen,
            title: AppStrings.streakSaved,
            subtitle: AppStrings.streakSavedSubtitle,
            value: _streakSavedEnabled,
            onChanged: (value) async {
              HapticFeedback.selectionClick();
              await StorageService.setStreakSavedEnabled(value);
              if (value) await _requestNotificationPermission();
              if (mounted) setState(() => _streakSavedEnabled = value);
            },
          ),
          AppTheme.h16,
          _buildToggleRow(
            icon: Icons.celebration_rounded,
            iconColor: AppTheme.accentViolet,
            title: AppStrings.celebrations,
            subtitle: AppStrings.celebrationsSubtitle,
            value: _celebrationsEnabled,
            onChanged: (value) async {
              HapticFeedback.selectionClick();
              await StorageService.setCelebrationsEnabled(value);
              if (value) await _requestNotificationPermission();
              if (mounted) setState(() => _celebrationsEnabled = value);
            },
          ),
          AppTheme.h16,
          _buildToggleRow(
            icon: Icons.calendar_month_rounded,
            iconColor: scheme.primary,
            title: AppStrings.weeklyDigest,
            subtitle: AppStrings.weeklyDigestSubtitle,
            value: _weeklyDigestEnabled,
            onChanged: (value) async {
              HapticFeedback.selectionClick();
              await StorageService.setWeeklyDigestEnabled(value);
              if (value) await _requestNotificationPermission();
              await _syncNotificationScheduler();
              if (mounted) setState(() => _weeklyDigestEnabled = value);
            },
          ),
          AppTheme.h16,
          _buildSettingButton(
            icon: Icons.schedule_rounded,
            iconColor: scheme.primary,
            title: AppStrings.digestTime,
            subtitle: '${AppStrings.digestTimeSubtitle}: ${_digestTime.format(context)}',
            onTap: !_weeklyDigestEnabled
                ? null
                : () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _digestTime,
                    );
                    if (picked == null) return;
                    HapticFeedback.selectionClick();
                    await StorageService.setWeeklyDigestTime(
                        hour: picked.hour, minute: picked.minute);
                    if (mounted) setState(() => _digestTime = picked);
                  },
          ),
        ],
      ),
    );
  }

  Future<void> _requestNotificationPermission() async {
    await NotificationService.requestPermissions();
  }

  Future<void> _syncNotificationScheduler() async {
    final shouldRun =
        StorageService.getStreakReminderEnabled() || StorageService.getWeeklyDigestEnabled();
    if (shouldRun) {
      await BackgroundScheduler.scheduleStreakReminders();
    } else {
      await BackgroundScheduler.cancelStreakReminders();
    }
  }

  Widget _buildToggleRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: AppTheme.brSmall,
            border: Border.all(color: iconColor.withValues(alpha: 0.20)),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        AppTheme.w16,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: tt.titleSmall?.copyWith(color: scheme.onSurface),
              ),
              AppTheme.h2,
              Text(
                subtitle,
                style: tt.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // DATA SECTION
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildDataSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: AppStrings.data),
          AppTheme.h16,

          // Clear Cache Button
          _buildSettingButton(
            icon: Icons.cleaning_services,
            iconColor: AppTheme.warningOrange,
            title: AppStrings.clearCache,
            subtitle: AppStrings.removeCachedData,
            onTap: _clearCache,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // ABOUT SECTION
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildAboutSection() {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: AppStrings.about),
          AppTheme.h16,

          _buildSettingButton(
            icon: Icons.auto_awesome_rounded,
            iconColor: scheme.primary,
            title: 'Wrapped',
            subtitle: 'Your year in code',
            trailing: Icons.chevron_right_rounded,
            onTap: () {
              final cached = StorageService.getCachedData();
              if (cached == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sync your data first to view Wrapped.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => WrappedPage(data: cached)),
              );
            },
          ),

          AppTheme.h12,

          // Help & Support
          _buildSettingButton(
            icon: Icons.chat_bubble_outline,
            iconColor: AppTheme.successGreen,
            title: AppStrings.needHelp,
            subtitle: AppStrings.chatOnWhatsApp,
            trailing: Icons.open_in_new,
            onTap: () async {
              if (!context.mounted) return;
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final phone = ValidationUtils.cleanPhone(AppStrings.supportPhone);
              final uri = Uri.parse('${AppStrings.whatsAppUrlScheme}$phone');

              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  throw Exception('Could not launch WhatsApp');
                }
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      ErrorHandler.getUserFriendlyMessage(e),
                    ),
                    backgroundColor: AppTheme.errorRed,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),

          if (kDebugMode) ...[
            AppTheme.h12,
            _buildSettingButton(
              icon: Icons.restart_alt_rounded,
              iconColor: AppTheme.warningOrange,
              title: 'Replay onboarding (Debug)',
              subtitle: 'Force-show onboarding to verify recent UI updates',
              trailing: Icons.chevron_right_rounded,
              onTap: () async {
                HapticFeedback.lightImpact();
                await StorageService.setOnboardingComplete(false);
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const OnboardingPage()),
                  (r) => false,
                );
              },
            ),
          ],

          AppTheme.h12,

          // Privacy Policy
          _buildSettingButton(
            icon: Icons.privacy_tip_outlined,
            iconColor: AppTheme.successGreen,
            title: AppStrings.privacyPolicy,
            subtitle: AppStrings.readPrivacyPolicy,
            trailing: Icons.open_in_new,
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final uri = Uri.parse(AppStrings.privacyPolicyUrl);
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  throw Exception('Could not launch Privacy Policy');
                }
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(ErrorHandler.getUserFriendlyMessage(e)),
                    backgroundColor: AppTheme.errorRed,
                  ),
                );
              }
            },
          ),

          AppTheme.h12,

          // Developer
          _buildSettingButton(
            icon: Icons.code,
            iconColor: scheme.secondary,
            title: AppStrings.developer,
            subtitle: AppStrings.developerName,
            onTap: null, // Read-only
          ),

          AppTheme.h12,

          // App Version
          _buildSettingButton(
            icon: Icons.info_outline,
            iconColor: AppTheme.accentViolet,
            title: AppStrings.version,
            subtitle: _appVersion,
            onTap: null, // Read-only
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // SETTING BUTTON WIDGET
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildSettingButton({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    IconData? trailing,
    VoidCallback? onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap != null ? () {
        HapticFeedback.lightImpact();
        onTap();
      } : null,
      borderRadius: AppTheme.brSmall,
      child: Padding(
        padding: AppTheme.pSymV8,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: AppTheme.brSmall,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            AppTheme.w16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: tt.titleSmall?.copyWith(color: scheme.onSurface),
                  ),
                  AppTheme.h2,
                  Text(
                    subtitle,
                    style: tt.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Icon(
                trailing,
                color: scheme.onSurface.withValues(alpha: 0.72),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // LOGOUT BUTTON
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: _handleLogout,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.errorRed,
          side: const BorderSide(color: AppTheme.errorRed, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.brMedium,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, size: 20),
            AppTheme.w8,
            Text(
              AppStrings.logout,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
