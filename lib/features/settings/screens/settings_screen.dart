import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:github_wallpaper/shared/services/background_scheduler.dart';
import 'package:github_wallpaper/shared/services/membership_entitlements.dart';
import 'package:github_wallpaper/shared/services/membership_service.dart';
import 'package:github_wallpaper/shared/services/revenuecat_service.dart';
import 'package:github_wallpaper/data/datasources/remote/oauth_service.dart';
import 'package:github_wallpaper/data/datasources/local/storage_service.dart';
import 'package:github_wallpaper/core/app/main_nav_screen.dart';
import 'package:github_wallpaper/features/auth/screens/setup_screen.dart';
import 'package:github_wallpaper/features/settings/screens/membership_access_page.dart';
import 'package:github_wallpaper/features/settings/screens/membership_paywall_page.dart';
import 'package:github_wallpaper/data/models/app_models.dart';
import 'package:github_wallpaper/data/models/membership_models.dart';
import 'package:github_wallpaper/shared/state/app_state.dart';
import 'package:github_wallpaper/shared/state/membership_state.dart';
import 'package:github_wallpaper/shared/services/notification_service.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

part 'settings_screen_view.dart';
part 'settings_screen_profile.dart';
part 'settings_screen_support.dart';
part 'settings_screen_notifications.dart';
part 'settings_screen_wallpaper_sync.dart';
part 'settings_screen_components.dart';

class SettingsPage extends StatefulWidget {
  final DateTime? directUpdate;
  final VoidCallback? onRequireSync;

  const SettingsPage({super.key, this.directUpdate, this.onRequireSync});

  @override
  State<SettingsPage> createState() => _SettingsPageState();

  static Future<bool> showUpdateTokenDialog(BuildContext context) async {
    try {
      final session = await OAuthService.signInWithGitHub();
      await StorageService.setToken(session.accessToken);
      await StorageService.setUsername(session.username);
      await StorageService.setUserEmail(session.email);
      await StorageService.setHasAuthError(false);
      await RevenueCatService.initializeForCurrentUser();
      await MembershipService.refresh(force: true);
      await NotificationService.refreshAdminBroadcastSubscription();
      if (context.mounted) {
        context.read<SettingsPreferencesState>().refreshFromStorage();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GitHub account reconnected'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.handle(context, e);
      }
      return false;
    }
  }
}

class _SettingsPageState extends State<SettingsPage> {
  String _appVersion = AppStrings.appVersion;
  String? _username;
  String? _displayName;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadLocalProfile();
    _loadAppVersion();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SettingsPreferencesState>().refreshFromStorage();
    });
  }

  void _loadLocalProfile() {
    final cached = StorageService.getCachedData();
    setState(() {
      _username = StorageService.getUsername();
      _displayName = StorageService.getDisplayName();
      _avatarUrl = cached?.avatarUrl;
    });
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (_) {}
  }

  Future<void> _resetSessionAndOpenSetup() async {
    await StorageService.setAutoUpdate(false);
    await BackgroundScheduler.cancelUpdates();
    await BackgroundScheduler.cancelStreakReminders();
    await StorageService.setHasAuthError(false);
    await RevenueCatService.logOut();
    await StorageService.logout();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SetupPage()),
      (route) => false,
    );
  }

  Future<void> _handleLogout() async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.logoutConfirmTitle),
        content: Text(AppStrings.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            child: Text(AppStrings.logout),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;
    await _resetSessionAndOpenSetup();
  }

  Future<void> _handleDisconnectGitHub() async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect GitHub'),
        content: const Text(
            'This will clear your GitHub session. You can reconnect anytime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;
    await _resetSessionAndOpenSetup();
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    MainNavPage.navIndex.value = 0;
  }

  Future<void> _shareApp() async {
    final info = await PackageInfo.fromPlatform();
    final pkg = info.packageName;
    final url = Uri.parse('https://play.google.com/store/apps/details?id=$pkg');
    await Share.share('${AppStrings.appName}\n$url');
  }

  Future<void> _rateUs() async {
    final info = await PackageInfo.fromPlatform();
    final pkg = info.packageName;
    final url = Uri.parse('https://play.google.com/store/apps/details?id=$pkg');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _pickWeeklyGoal(SettingsPreferencesState prefs) async {
    var tempGoal = prefs.weeklyCommitGoal;
    final result = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Weekly goal',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  '$tempGoal commits',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Slider(
                  min: 5,
                  max: 100,
                  divisions: 19,
                  value: tempGoal.toDouble(),
                  label: '$tempGoal',
                  onChanged: (value) {
                    setSheetState(() => tempGoal = (value / 5).round() * 5);
                  },
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(tempGoal),
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!mounted || result == null) return;
    await prefs.setWeeklyCommitGoal(result);
  }

  void _openThemePicker() {
    final scheme = Theme.of(context).colorScheme;
    final themeMode = context.read<ThemeModeState>();

    String labelFor(ThemeMode mode) => switch (mode) {
          ThemeMode.light => 'Light',
          ThemeMode.dark => 'Dark',
          ThemeMode.system => 'System',
        };

    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values
              .map(
                (mode) => ListTile(
                  title: Text(labelFor(mode)),
                  trailing: themeMode.mode == mode
                      ? Icon(Icons.check, color: scheme.primary)
                      : null,
                  onTap: () async {
                    await themeMode.setMode(mode);
                    if (!mounted) return;
                    Navigator.of(context).pop();
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _buildSettingsPage(context);
}
