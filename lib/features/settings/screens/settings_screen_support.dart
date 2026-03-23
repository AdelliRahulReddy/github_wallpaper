part of 'settings_screen.dart';

class _SupportScreen extends StatelessWidget {
  final String version;

  const _SupportScreen({required this.version});

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(AppStrings.privacyPolicyUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _contactEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppStrings.supportEmail,
      queryParameters: {'subject': '${AppStrings.appName} Support'},
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.settingsTokens;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: theme.scaffoldBackgroundColor,
        title: const Text('About & Support'),
      ),
      body: SingleChildScrollView(
        padding: tokens.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.rocket_launch_outlined,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.freeForeverBanner,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.help_outline,
                  title: 'Help / FAQ',
                  onTap: _openPrivacyPolicy,
                ),
                _SettingsTile(
                  icon: Icons.bug_report_outlined,
                  title: 'Report a bug',
                  onTap: _contactEmail,
                ),
                _SettingsTile(
                  icon: Icons.mail_outline,
                  title: 'Contact',
                  onTap: _contactEmail,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(child: Text('version $version')),
          ],
        ),
      ),
    );
  }
}
