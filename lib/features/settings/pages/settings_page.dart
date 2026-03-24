import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:github_wallpaper/app/pages/main_nav_page.dart';
import 'package:github_wallpaper/core/constants/environment_config.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/features/auth/services/oauth_service.dart';
import 'package:github_wallpaper/features/membership/models/membership_models.dart';
import 'package:github_wallpaper/features/auth/pages/setup_page.dart';
import 'package:github_wallpaper/features/membership/controllers/membership_controller.dart';
import 'package:github_wallpaper/features/membership/pages/membership_access_page.dart';
import 'package:github_wallpaper/features/membership/pages/membership_paywall_page.dart';
import 'package:github_wallpaper/features/settings/controllers/settings_controller.dart';
import 'package:github_wallpaper/features/settings/controllers/theme_controller.dart';
import 'package:github_wallpaper/features/settings/pages/notifications_page.dart';
import 'package:github_wallpaper/features/settings/pages/profile_page.dart';
import 'package:github_wallpaper/features/settings/pages/support_page.dart';
import 'package:github_wallpaper/features/settings/pages/wallpaper_sync_page.dart';
import 'package:github_wallpaper/features/settings/widgets/settings_widgets.dart';
import 'package:github_wallpaper/app/services/background_scheduler.dart';
import 'package:github_wallpaper/features/membership/services/membership_entitlements.dart';
import 'package:github_wallpaper/features/membership/services/membership_service.dart';
import 'package:github_wallpaper/app/services/notification_service.dart';
import 'package:github_wallpaper/features/membership/services/revenuecat_service.dart';
import 'package:github_wallpaper/features/wallpaper/services/widget_service.dart';

class SettingsPage extends StatefulWidget {
  final DateTime? directUpdate;
  final VoidCallback? onRequireSync;

  const SettingsPage({
    super.key,
    this.directUpdate,
    this.onRequireSync,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();

  static Future<bool> showUpdateTokenDialog(BuildContext context) async {
    try {
      final session = await OAuthService.signInWithGitHub();
      await StorageService.syncAuthenticatedAppUserId();
      await StorageService.setToken(session.accessToken);
      await StorageService.setUsername(session.username);
      await StorageService.setUserEmail(session.email);
      await StorageService.setHasAuthError(false);
      await RevenueCatService.initializeForCurrentUser();
      final membershipInfo = await MembershipService.refresh(force: true);
      unawaited(NotificationService.initPushMessaging());
      await NotificationService.refreshAdminBroadcastSubscription();
      unawaited(WidgetService.refreshFromCache());
      if (context.mounted) {
        context.read<MembershipController>().setMembershipInfo(membershipInfo);
        context.read<SettingsController>().refreshFromStorage();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GitHub account reconnected'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return true;
    } catch (error) {
      if (context.mounted) {
        ErrorHandler.handle(context, error);
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
      context.read<SettingsController>().refreshFromStorage();
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
    await WidgetService.clear();
    if (mounted) {
      context.read<MembershipController>().clear();
      context.read<SettingsController>().refreshFromStorage();
    }

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
          'This will clear your GitHub session. You can reconnect anytime.',
        ),
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
    final packageName = info.packageName;
    final url = AppConfig.playStoreListingUri(packageName);
    await Share.share('${AppStrings.appName}\n$url');
  }

  Future<void> _rateUs() async {
    final info = await PackageInfo.fromPlatform();
    final packageName = info.packageName;
    final url = AppConfig.playStoreListingUri(packageName);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _pickWeeklyGoal(SettingsController prefs) async {
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
    final themeController = context.read<ThemeController>();

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
                  trailing: themeController.mode == mode
                      ? Icon(Icons.check, color: scheme.primary)
                      : null,
                  onTap: () async {
                    await themeController.setMode(mode);
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

  String _upgradeTileSubtitle(MembershipInfo? info) {
    if (info == null || info.plan == MembershipPlan.free) {
      return 'Unlock templates, advanced stats, and Pro tools.';
    }
    if (info.plan == MembershipPlan.couponPro) {
      final expiry = info.proAccessExpiresAt;
      return expiry == null
          ? 'Coupon access is active.'
          : 'Coupon access is active until ${expiry.day}/${expiry.month}/${expiry.year}.';
    }
    return 'Pro is already unlocked on this account.';
  }

  String _membershipEntrySubtitle(MembershipInfo? info) {
    if (info == null) {
      return 'Manage billing, restore purchases, and coupon access.';
    }
    switch (info.plan) {
      case MembershipPlan.couponPro:
        final expiry = info.proAccessExpiresAt;
        return expiry == null
            ? 'Coupon access is active.'
            : 'Coupon access is active until ${expiry.day}/${expiry.month}/${expiry.year}.';
      case MembershipPlan.pro:
        return 'Manage your active Pro access and billing.';
      case MembershipPlan.free:
        return 'Manage billing, restore purchases, and coupon access.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.settingsTokens;
    final isConnected = _username != null && !StorageService.hasAuthError();
    final membershipInfo = context.watch<MembershipController>().info ??
        StorageService.getCachedMembershipInfo();
    final themeController = context.watch<ThemeController>();
    final themeLabel = switch (themeController.mode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
    };

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: theme.scaffoldBackgroundColor,
        leading: BackButton(onPressed: _goBack),
        title: Text(AppStrings.settings),
      ),
      body: SingleChildScrollView(
        padding: tokens.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileCard(
              avatarUrl: _avatarUrl,
              name: _displayName ?? _username ?? AppStrings.unknown,
              handle: _username == null ? null : '@$_username',
              statusLabel: isConnected ? 'Connected' : 'Disconnected',
              statusColor: isConnected ? scheme.secondary : scheme.error,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(
                      avatarUrl: _avatarUrl,
                      username: _username,
                    ),
                  ),
                );
                if (!mounted) return;
                _loadLocalProfile();
              },
            ),
            SettingsSection(
              title: 'Membership',
              child: SettingsCard(
                children: [
                  SettingsTile(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Upgrade to Pro',
                    subtitle: _upgradeTileSubtitle(membershipInfo),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MembershipPaywallPage(),
                      ),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'Subscription',
                    subtitle: _membershipEntrySubtitle(membershipInfo),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MembershipAccessPage(),
                      ),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Redeem Coupon',
                    subtitle:
                        'Apply an admin-issued coupon from the main settings surface.',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MembershipAccessPage(
                          initialAction: MembershipAccessAction.redeemCoupon,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SettingsSection(
              title: 'Preferences',
              child: SettingsCard(
                children: [
                  SettingsTile(
                    icon: Icons.palette_outlined,
                    title: 'Appearance',
                    subtitle: themeLabel,
                    onTap: _openThemePicker,
                  ),
                  SettingsTile(
                    icon: Icons.flag_outlined,
                    title: 'Weekly goal',
                    subtitle:
                        'Shown on the Home progress card and resets each week.',
                    trailing: Text(
                      '${context.watch<SettingsController>().weeklyCommitGoal} commits',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    onTap: () => _pickWeeklyGoal(
                      context.read<SettingsController>(),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.wallpaper_outlined,
                    title: 'Wallpaper & Sync',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WallpaperSyncPage(
                          onSyncNow: widget.onRequireSync,
                          onReconnect: () async {
                            final ok = await SettingsPage.showUpdateTokenDialog(
                                context);
                            if (ok) widget.onRequireSync?.call();
                            if (!mounted) return;
                            _loadLocalProfile();
                          },
                          onDisconnect: _handleDisconnectGitHub,
                        ),
                      ),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: MembershipEntitlements.canUseReminders
                        ? 'Reminders, announcements, and sync alerts'
                        : 'Announcements and sync alerts',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsPage(),
                      ),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.help_outline,
                    title: 'Support',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SupportPage(version: _appVersion),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SettingsSection(
              title: 'About',
              child: SettingsCard(
                children: [
                  SettingsTile(
                    icon: Icons.star_border,
                    title: 'Rate App',
                    onTap: _rateUs,
                  ),
                  SettingsTile(
                    icon: Icons.share_outlined,
                    title: 'Share App',
                    onTap: _shareApp,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SettingsSection(
              title: 'Session',
              child: SettingsCard(
                children: [
                  SettingsTile(
                    icon: Icons.logout,
                    iconColor: scheme.error,
                    title: AppStrings.logout,
                    titleColor: scheme.error,
                    onTap: _handleLogout,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'version $_appVersion',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
