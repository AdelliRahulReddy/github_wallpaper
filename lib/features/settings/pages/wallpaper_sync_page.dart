import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/features/settings/widgets/settings_widgets.dart';
import 'package:github_wallpaper/app/services/background_scheduler.dart';
import 'package:github_wallpaper/features/contributions/services/contribution_metrics.dart';

class WallpaperSyncPage extends StatefulWidget {
  final VoidCallback? onSyncNow;
  final Future<void> Function()? onReconnect;
  final VoidCallback? onDisconnect;

  const WallpaperSyncPage({
    super.key,
    required this.onSyncNow,
    required this.onReconnect,
    required this.onDisconnect,
  });

  @override
  State<WallpaperSyncPage> createState() => _WallpaperSyncPageState();
}

class _WallpaperSyncPageState extends State<WallpaperSyncPage> {
  bool _autoUpdate = StorageService.getAutoUpdate();
  UpdateScheduleMode _scheduleMode = StorageService.getUpdateScheduleMode();
  TimeOfDay _dailyTime = StorageService.getUpdateDailyTime();
  bool _autoApplyAfterSync = StorageService.getAutoApplyAfterSync();

  DateTime? _lastSyncUtc = StorageService.getEffectiveLastSync();
  DateTime? _lastWallpaperUtc = StorageService.getLastWallpaperUpdate();

  bool get _isDaily => _scheduleMode == UpdateScheduleMode.autoDaily;

  Future<void> _refreshStatus() async {
    if (!mounted) return;
    setState(() {
      _lastSyncUtc = StorageService.getEffectiveLastSync();
      _lastWallpaperUtc = StorageService.getLastWallpaperUpdate();
    });
  }

  Future<void> _setAutoUpdate(bool value) async {
    setState(() => _autoUpdate = value);
    await StorageService.setAutoUpdate(value);
    if (value) {
      await BackgroundScheduler.scheduleUpdates();
    } else {
      await BackgroundScheduler.cancelUpdates();
    }
  }

  Future<void> _setFrequencyDaily() async {
    setState(() => _scheduleMode = UpdateScheduleMode.autoDaily);
    await StorageService.setUpdateScheduleMode(UpdateScheduleMode.autoDaily);
    await BackgroundScheduler.scheduleUpdates();
  }

  Future<void> _setFrequencyWeekly() async {
    setState(() => _scheduleMode = UpdateScheduleMode.interval);
    await StorageService.setUpdateScheduleMode(UpdateScheduleMode.interval);
    await StorageService.setUpdateIntervalMinutes(7 * 24 * 60);
    await BackgroundScheduler.scheduleUpdates();
  }

  Future<void> _pickDailyTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _dailyTime);
    if (!mounted || picked == null) return;
    setState(() => _dailyTime = picked);
    await StorageService.setUpdateDailyTime(
      hour: picked.hour,
      minute: picked.minute,
    );
    await BackgroundScheduler.scheduleUpdates();
  }

  Future<void> _setAutoApplyAfterSync(bool value) async {
    setState(() => _autoApplyAfterSync = value);
    await StorageService.setAutoApplyAfterSync(value);
  }

  String _timeLabel(DateTime? utc) {
    if (utc == null) return 'Never';
    return PresentationFormatter.formatTimeSince(utc.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.settingsTokens;
    final isConnected =
        StorageService.getUsername() != null && !StorageService.hasAuthError();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: theme.scaffoldBackgroundColor,
        title: const Text('Wallpaper & Sync'),
        actions: [
          IconButton(
            onPressed: _refreshStatus,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh status',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: tokens.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsSection(
              title: 'Automation',
              child: SettingsCard(
                children: [
                  SettingsTile(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Auto-update',
                    subtitle: _autoUpdate ? 'On' : 'Off',
                    trailing: Switch(
                      value: _autoUpdate,
                      onChanged: _setAutoUpdate,
                    ),
                    onTap: null,
                  ),
                  SettingsTile(
                    icon: Icons.event_repeat_outlined,
                    title: 'Frequency',
                    subtitle: _isDaily ? 'Daily' : 'Weekly',
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<bool>(
                        value: _isDaily,
                        items: const [
                          DropdownMenuItem(value: true, child: Text('Daily')),
                          DropdownMenuItem(
                            value: false,
                            child: Text('Weekly'),
                          ),
                        ],
                        onChanged: (value) async {
                          if (value == null) return;
                          if (value) {
                            await _setFrequencyDaily();
                            return;
                          }
                          await _setFrequencyWeekly();
                        },
                      ),
                    ),
                    onTap: null,
                  ),
                  if (_isDaily)
                    SettingsTile(
                      icon: Icons.schedule,
                      title: 'Time',
                      trailing: Text(
                        _dailyTime.format(context),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      onTap: _pickDailyTime,
                    ),
                ],
              ),
            ),
            SettingsSection(
              title: 'Behavior',
              child: SettingsCard(
                children: [
                  SettingsTile(
                    icon: Icons.smartphone_outlined,
                    title: 'Wallpaper target',
                    subtitle: 'Lock screen only',
                    trailing: Text(
                      'Lock',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: null,
                  ),
                  SettingsTile(
                    icon: Icons.check_circle_outline,
                    title: 'Auto-apply after sync',
                    subtitle: _autoApplyAfterSync ? 'On' : 'Off',
                    trailing: Switch(
                      value: _autoApplyAfterSync,
                      onChanged: _setAutoApplyAfterSync,
                    ),
                    onTap: null,
                  ),
                ],
              ),
            ),
            SettingsSection(
              title: 'Status',
              child: SettingsCard(
                children: [
                  SettingsTile(
                    icon: Icons.link_outlined,
                    title: 'GitHub connection',
                    trailing: StatusChip(
                      label: isConnected ? 'Connected' : 'Disconnected',
                      color: isConnected ? scheme.secondary : scheme.error,
                    ),
                    onTap: null,
                  ),
                  SettingsTile(
                    icon: Icons.sync,
                    title: 'Last sync time',
                    trailing: Text(
                      _timeLabel(_lastSyncUtc),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    onTap: null,
                  ),
                  SettingsTile(
                    icon: Icons.wallpaper_outlined,
                    title: 'Last wallpaper update',
                    trailing: Text(
                      _timeLabel(_lastWallpaperUtc),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    onTap: null,
                  ),
                ],
              ),
            ),
            SettingsSection(
              title: 'GitHub',
              child: SettingsCard(
                children: [
                  SettingsTile(
                    icon: Icons.login,
                    title: isConnected ? 'Reconnect GitHub' : 'Connect GitHub',
                    subtitle:
                        'Refresh your GitHub session for sync and data access.',
                    onTap: widget.onReconnect == null
                        ? null
                        : () async {
                            HapticFeedback.lightImpact();
                            await widget.onReconnect?.call();
                            if (!mounted) return;
                            setState(() {});
                            await _refreshStatus();
                          },
                  ),
                  SettingsTile(
                    icon: Icons.link_off,
                    iconColor: scheme.error,
                    title: 'Disconnect GitHub',
                    titleColor: scheme.error,
                    onTap: widget.onDisconnect,
                  ),
                ],
              ),
            ),
            SettingsSection(
              title: 'Action',
              child: SettingsCard(
                children: [
                  SettingsTile(
                    icon: Icons.sync,
                    title: 'Sync now',
                    onTap: widget.onSyncNow == null
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            widget.onSyncNow?.call();
                            _refreshStatus();
                          },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
