// ══════════════════════════════════════════════════════════════════════════
// ⚙️ SETTINGS PAGE - Account & Preferences
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:github_wallpaper/app_services.dart';
import 'package:github_wallpaper/app_theme.dart';
import 'package:github_wallpaper/app_utils.dart';
import 'package:github_wallpaper/app_state.dart';
import 'package:github_wallpaper/background_scheduler.dart';
import 'package:github_wallpaper/pages/onboarding_page.dart';
import 'package:github_wallpaper/ui_render.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  final DateTime? directUpdate;
  const SettingsPage({super.key, this.directUpdate});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _username;
  bool _autoUpdate = true;
  bool _crashlyticsConsent = true;
  bool _includePrivateRepos = true;
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
      _crashlyticsConsent = StorageService.getCrashlyticsConsent();
      _includePrivateRepos = StorageService.getIncludePrivateRepos();
     final lastUpdate = StorageService.getEffectiveLastSync();
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

    // Dialog is now fully closed — safe to update the outer widget tree
    tokenController.dispose();
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
      padding: AppTheme.pAll20,
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

          AppTheme.h16,

          // Crashlytics Consent Toggle
          _buildToggleRow(
            icon: Icons.bug_report_outlined,
            iconColor: AppTheme.warningOrange,
            title: AppStrings.crashReporting,
            subtitle: AppStrings.crashReportingSubtitle,
            value: _crashlyticsConsent,
            onChanged: (value) async {
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
              await StorageService.setIncludePrivateRepos(value);
              if (!value) {
                // Clear encrypted cache when disabled
                await StorageService.clearCache();
              }
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
        ],
      ),
    );
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
                style: TextStyle(
                  fontSize: AppTheme.fontMedium,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              AppTheme.h2,
              Text(
                subtitle,
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

          // App Version
          _buildSettingButton(
            icon: Icons.info_outline,
            iconColor: AppTheme.accentViolet,
            title: AppStrings.version,
            subtitle: _appVersion,
            onTap: null, // Read-only
          ),

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
            Text(
              AppStrings.logout,
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
