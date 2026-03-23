part of 'settings_screen.dart';

class _WallpaperSyncScreen extends StatefulWidget {
  final VoidCallback? onSyncNow;
  final Future<void> Function()? onReconnect;
  final VoidCallback? onDisconnect;

  const _WallpaperSyncScreen({
    required this.onSyncNow,
    required this.onReconnect,
    required this.onDisconnect,
  });

  @override
  State<_WallpaperSyncScreen> createState() => _WallpaperSyncScreenState();
}

class _WallpaperSyncScreenState extends State<_WallpaperSyncScreen> {
  bool _autoUpdate = StorageService.getAutoUpdate();
  UpdateScheduleMode _scheduleMode = StorageService.getUpdateScheduleMode();
  TimeOfDay _dailyTime = StorageService.getUpdateDailyTime();
  WallpaperTarget _target = StorageService.getLastWallpaperTarget();
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

  Future<void> _setAutoUpdate(bool v) async {
    setState(() => _autoUpdate = v);
    await StorageService.setAutoUpdate(v);
    if (v) {
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
        hour: picked.hour, minute: picked.minute);
    await BackgroundScheduler.scheduleUpdates();
  }

  Future<void> _setTarget(WallpaperTarget t) async {
    setState(() => _target = t);
    await StorageService.setLastWallpaperTarget(t);
  }

  Future<void> _setAutoApplyAfterSync(bool v) async {
    setState(() => _autoApplyAfterSync = v);
    await StorageService.setAutoApplyAfterSync(v);
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
            _SettingsSection(
              title: 'Automation',
              child: _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Auto-update',
                    subtitle: _autoUpdate ? 'On' : 'Off',
                    trailing:
                        Switch(value: _autoUpdate, onChanged: _setAutoUpdate),
                    onTap: null,
                  ),
                  _SettingsTile(
                    icon: Icons.event_repeat_outlined,
                    title: 'Frequency',
                    subtitle: _isDaily ? 'Daily' : 'Weekly',
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<bool>(
                        value: _isDaily,
                        items: [
                          const DropdownMenuItem(
                              value: true, child: Text('Daily')),
                          const DropdownMenuItem(
                            value: false,
                            child: Text('Weekly'),
                          ),
                        ],
                        onChanged: (v) async {
                          if (v == null) return;
                          if (v) {
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
                    _SettingsTile(
                      icon: Icons.schedule,
                      title: 'Time',
                      trailing: Text(
                        _dailyTime.format(context),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      onTap: _pickDailyTime,
                    ),
                ],
              ),
            ),
            _SettingsSection(
              title: 'Behavior',
              child: _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.smartphone_outlined,
                    title: 'Apply to',
                    subtitle: _target == WallpaperTarget.both
                        ? 'Both is an advanced option'
                        : 'Lock is recommended',
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<WallpaperTarget>(
                        value: _target,
                        items: const [
                          DropdownMenuItem(
                            value: WallpaperTarget.lock,
                            child: Text('Lock'),
                          ),
                          DropdownMenuItem(
                            value: WallpaperTarget.both,
                            child: Text('Both (Advanced)'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          _setTarget(v);
                        },
                      ),
                    ),
                    onTap: null,
                  ),
                  _SettingsTile(
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
            _SettingsSection(
              title: 'Status',
              child: _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.link_outlined,
                    title: 'GitHub connection',
                    trailing: _StatusChip(
                      label: isConnected ? 'Connected' : 'Disconnected',
                      color: isConnected ? scheme.secondary : scheme.error,
                    ),
                    onTap: null,
                  ),
                  _SettingsTile(
                    icon: Icons.sync,
                    title: 'Last sync time',
                    trailing: Text(
                      _timeLabel(_lastSyncUtc),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    onTap: null,
                  ),
                  _SettingsTile(
                    icon: Icons.wallpaper_outlined,
                    title: 'Last wallpaper update',
                    trailing: Text(
                      _timeLabel(_lastWallpaperUtc),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    onTap: null,
                  ),
                ],
              ),
            ),
            _SettingsSection(
              title: 'GitHub',
              child: _SettingsCard(
                children: [
                  _SettingsTile(
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
                  _SettingsTile(
                    icon: Icons.link_off,
                    iconColor: scheme.error,
                    title: 'Disconnect GitHub',
                    titleColor: scheme.error,
                    onTap: widget.onDisconnect,
                  ),
                ],
              ),
            ),
            _SettingsSection(
              title: 'Action',
              child: _SettingsCard(
                children: [
                  _SettingsTile(
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
