part of 'settings_screen.dart';

extension _SettingsPageStateView on _SettingsPageState {
  Widget _buildSettingsPage(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.settingsTokens;
    final isConnected = _username != null && !StorageService.hasAuthError();
    final membershipInfo = context.watch<MembershipState>().info ??
        StorageService.getCachedMembershipInfo();
    final themeMode = context.watch<ThemeModeState>();
    final themeLabel = switch (themeMode.mode) {
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
            _ProfileCard(
              avatarUrl: _avatarUrl,
              name: _displayName ?? _username ?? AppStrings.unknown,
              handle: _username == null ? null : '@$_username',
              statusLabel: isConnected ? 'Connected' : 'Disconnected',
              statusColor: isConnected ? scheme.secondary : scheme.error,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _ProfileScreen(
                      avatarUrl: _avatarUrl,
                      username: _username,
                    ),
                  ),
                );
                if (!mounted) return;
                _loadLocalProfile();
              },
            ),
            _SettingsSection(
              title: 'Membership',
              child: _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Upgrade to Pro',
                    subtitle: _upgradeTileSubtitle(membershipInfo),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MembershipPaywallPage(),
                      ),
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'Subscription',
                    subtitle: _membershipEntrySubtitle(membershipInfo),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MembershipAccessPage(),
                      ),
                    ),
                  ),
                  _SettingsTile(
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
            _SettingsSection(
              title: 'Preferences',
              child: _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  subtitle: themeLabel,
                  onTap: _openThemePicker,
                ),
                _SettingsTile(
                  icon: Icons.flag_outlined,
                  title: 'Weekly goal',
                  subtitle:
                      'Shown on the Home progress card and resets each week.',
                  trailing: Text(
                    '${context.watch<SettingsPreferencesState>().weeklyCommitGoal} commits',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () => _pickWeeklyGoal(
                    context.read<SettingsPreferencesState>(),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.wallpaper_outlined,
                  title: 'Wallpaper & Sync',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _WallpaperSyncScreen(
                        onSyncNow: widget.onRequireSync,
                        onReconnect: () async {
                          final ok =
                              await SettingsPage.showUpdateTokenDialog(context);
                          if (ok) widget.onRequireSync?.call();
                          if (!mounted) return;
                          _loadLocalProfile();
                        },
                        onDisconnect: _handleDisconnectGitHub,
                      ),
                    ),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: MembershipEntitlements.canUseReminders
                      ? 'Reminders, announcements, and sync alerts'
                      : 'Announcements and sync alerts',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const _NotificationsScreen()),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.help_outline,
                  title: 'Support',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _SupportScreen(version: _appVersion),
                    ),
                  ),
                ),
              ],
              ),
            ),
            _SettingsSection(
              title: 'About',
              child: _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.star_border,
                    title: 'Rate App',
                    onTap: _rateUs,
                  ),
                  _SettingsTile(
                    icon: Icons.share_outlined,
                    title: 'Share App',
                    onTap: _shareApp,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _SettingsSection(
              title: 'Session',
              child: _SettingsCard(
                children: [
                  _SettingsTile(
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
}
