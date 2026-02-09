// ══════════════════════════════════════════════════════════════════════════
// ⚙️ SETTINGS PAGE - Account & Preferences
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:github_wallpaper/app_services.dart';
import 'package:github_wallpaper/app_theme.dart';
import 'package:github_wallpaper/app_utils.dart';
import 'package:github_wallpaper/app_state.dart';
import 'package:github_wallpaper/pages/onboarding_page.dart';
import 'package:github_wallpaper/ui_render.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _username;
  bool _autoUpdate = true;
  DateTime? _lastUpdate;
  String _appVersion = AppStrings.appVersion;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
  }

  void _loadSettings() {
    setState(() {
      _username = StorageService.getUsername();
      _autoUpdate = StorageService.getAutoUpdate();
      _lastUpdate = StorageService.getLastUpdate();
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
        title: const Text('Logout'),
        content: const Text(
            'Are you sure you want to logout? This will clear all your data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;

      await StorageService.logout();

      if (!mounted) return;

      // Clear entire navigation stack so user can't go back
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
        (route) => false,
      );
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
            'This will remove cached contribution data. You\'ll need to sync again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.clearCache();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared successfully')),
      );
      _loadSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: AppTheme.pAll20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTheme.h16,

          AppSectionHeader(
            title: 'Settings',
            subtitle: 'Manage your account and preferences',
            trailing: Icon(Icons.tune_rounded, color: scheme.primary),
          ),

          AppTheme.h24,

          // Account Section
          _buildAccountSection(),

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

  Widget _buildAccountSection() {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: 'Account'),
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
                      _username ?? 'Unknown',
                      style: TextStyle(
                        fontSize: AppTheme.fontLarge,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    AppTheme.h4,
                    Text(
                      'GitHub Account',
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
          if (_lastUpdate != null)
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
                    'Last synced: ${PresentationFormatter.formatTimeSince(_lastUpdate!)}',
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
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // PREFERENCES SECTION
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildPreferencesSection() {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: 'Preferences'),
          AppTheme.h16,

          // Auto Update Toggle
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: AppTheme.brSmall,
                  border:
                      Border.all(color: scheme.primary.withValues(alpha: 0.20)),
                ),
                child: Icon(
                  Icons.autorenew,
                  color: scheme.primary,
                  size: 20,
                ),
              ),
              AppTheme.w16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto Update',
                      style: TextStyle(
                        fontSize: AppTheme.fontMedium,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    AppTheme.h2,
                    Text(
                      'Refresh wallpaper when push notification arrives',
                      style: TextStyle(
                        fontSize: AppTheme.fontBody,
                        color: scheme.onSurface.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _autoUpdate,
                onChanged: (value) async {
                  await StorageService.setAutoUpdate(value);
                  await FcmService.syncTopicSubscription();
                  if (mounted) {
                    setState(() => _autoUpdate = value);
                  }
                },
              ),
            ],
          ),
        ],
      ),
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
          const AppSectionHeader(title: 'Data'),
          AppTheme.h16,

          // Clear Cache Button
          _buildSettingButton(
            icon: Icons.cleaning_services,
            iconColor: AppTheme.warningOrange,
            title: 'Clear Cache',
            subtitle: 'Remove cached contribution data',
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
          const AppSectionHeader(title: 'About'),
          AppTheme.h16,

          // App Version
          _buildSettingButton(
            icon: Icons.info_outline,
            iconColor: AppTheme.accentViolet,
            title: 'Version',
            subtitle: _appVersion,
            onTap: null, // Read-only
          ),

          AppTheme.h12,

          // Privacy Policy
          _buildSettingButton(
            icon: Icons.privacy_tip_outlined,
            iconColor: AppTheme.primaryBlue,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
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
            title: 'Developer',
            subtitle: AppStrings.developerName,
            onTap: null, // Read-only
          ),

          AppTheme.h12,

          // Help & Support
          _buildSettingButton(
            icon: Icons.chat_bubble_outline,
            iconColor: AppTheme.successGreen,
            title: 'Need Help?',
            subtitle: 'Chat on WhatsApp',
            trailing: Icons.open_in_new,
            onTap: () async {
              if (!context.mounted) return;
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final phone =
                  ValidationUtils.cleanPhone(AppStrings.supportPhone);
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
    return InkWell(
      onTap: onTap,
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
                    style: TextStyle(
                      fontSize: AppTheme.fontMedium,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  AppTheme.h2,
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppTheme.fontSmall,
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
            const Text(
              'Logout',
              style: TextStyle(
                fontSize: AppTheme.fontLarge,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
