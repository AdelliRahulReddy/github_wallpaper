import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/features/settings/widgets/settings_widgets.dart';

class ProfileCard extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final String? handle;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback onTap;

  const ProfileCard({
    super.key,
    required this.avatarUrl,
    required this.name,
    required this.handle,
    required this.statusLabel,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final image = (avatarUrl == null || avatarUrl!.trim().isEmpty)
        ? null
        : NetworkImage(avatarUrl!);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing20),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  backgroundImage: image,
                  child: image == null
                      ? Icon(Icons.person, color: scheme.primary)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (handle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          handle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                StatusChip(label: statusLabel, color: statusColor),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right,
                  color: scheme.onSurface.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  final String? avatarUrl;
  final String? username;

  const ProfilePage({
    super.key,
    required this.avatarUrl,
    required this.username,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _displayName;

  @override
  void initState() {
    super.initState();
    _displayName = StorageService.getDisplayName();
  }

  String get _effectiveName {
    final preferred = _displayName?.trim();
    if (preferred != null && preferred.isNotEmpty) {
      return preferred;
    }
    final username = widget.username?.trim();
    if (username != null && username.isNotEmpty) {
      return username;
    }
    return AppStrings.unknown;
  }

  Future<void> _copyUsername() async {
    final username = widget.username?.trim();
    if (username == null || username.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: username));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GitHub username copied'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _editDisplayName() async {
    final updatedName = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _EditDisplayNamePage(
          initialValue: _displayName ?? widget.username ?? '',
          canResetToGitHub: (_displayName ?? '').trim().isNotEmpty,
        ),
      ),
    );

    if (!mounted || updatedName == null) return;

    final normalizedName = updatedName.replaceAll(RegExp(r'\s+'), ' ').trim();
    await StorageService.setDisplayName(normalizedName);
    final savedName = StorageService.getDisplayName();
    if (!mounted) return;

    setState(() => _displayName = savedName);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          savedName == null
              ? 'Using GitHub username on Home'
              : 'Display name updated',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.settingsTokens;
    final email = StorageService.getUserEmail();
    final image = (widget.avatarUrl == null || widget.avatarUrl!.trim().isEmpty)
        ? null
        : NetworkImage(widget.avatarUrl!);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: theme.scaffoldBackgroundColor,
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: tokens.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: scheme.primary.withValues(alpha: 0.12),
                      backgroundImage: image,
                      child: image == null
                          ? Icon(Icons.person, color: scheme.primary)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _effectiveName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                          if (widget.username != null &&
                              widget.username!.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              '@${widget.username}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (email != null && email.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SettingsSection(
              title: 'Account',
              child: SettingsCard(
                children: [
                  SettingsTile(
                    icon: Icons.person_outline,
                    title: 'Display name',
                    subtitle: _displayName == null
                        ? 'Using your GitHub username on Home'
                        : 'Shown on Home as $_displayName',
                    trailing: Icon(
                      Icons.edit_outlined,
                      color: scheme.onSurfaceVariant,
                    ),
                    onTap: _editDisplayName,
                  ),
                  SettingsTile(
                    icon: Icons.code,
                    title: 'GitHub username',
                    trailing: Text(
                      widget.username == null
                          ? AppStrings.unknown
                          : '@${widget.username}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    onTap: _copyUsername,
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

class _EditDisplayNamePage extends StatefulWidget {
  final String initialValue;
  final bool canResetToGitHub;

  const _EditDisplayNamePage({
    required this.initialValue,
    required this.canResetToGitHub,
  });

  @override
  State<_EditDisplayNamePage> createState() => _EditDisplayNamePageState();
}

class _EditDisplayNamePageState extends State<_EditDisplayNamePage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(_controller.text);
  }

  void _useGitHubName() {
    Navigator.of(context).pop('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: theme.scaffoldBackgroundColor,
        title: const Text('Display name'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: AppTheme.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose how your name appears on Home.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            AppTheme.h16,
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: AppConstants.displayNameMaxLength,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'[\r\n]')),
                LengthLimitingTextInputFormatter(
                  AppConstants.displayNameMaxLength,
                ),
              ],
              decoration: const InputDecoration(
                hintText: 'How your name should appear',
                helperText: 'Leave empty to use your GitHub username.',
              ),
              onSubmitted: (_) => _save(),
            ),
            if (widget.canResetToGitHub) ...[
              AppTheme.h8,
              OutlinedButton(
                onPressed: _useGitHubName,
                child: const Text('Use GitHub username'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
