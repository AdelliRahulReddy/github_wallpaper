part of 'settings_screen.dart';

class _SettingsSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.settingsTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: tokens.sectionHeaderPadding,
          child: Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurface
                  .withValues(alpha: tokens.sectionTitleOpacity),
            ),
          ),
        ),
        Padding(
          padding: tokens.sectionCardPadding,
          child: child,
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final builtChildren = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      builtChildren.add(children[i]);
      if (i == children.length - 1) continue;
      builtChildren.add(const SizedBox(height: 4));
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: builtChildren,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.settingsTokens;
    return Chip(
      side: BorderSide.none,
      backgroundColor: color.withValues(alpha: tokens.chipBackgroundOpacity),
      label: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(color: color),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    this.iconColor,
    required this.title,
    this.titleColor,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.settingsTokens;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: 2,
      ),
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap?.call();
            },
      leading: Icon(
        icon,
        size: tokens.leadingIconSize,
        color: iconColor ?? scheme.primary,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(color: titleColor),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    scheme.onSurface.withValues(alpha: tokens.subtitleOpacity),
              ),
            ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right,
            size: tokens.leadingIconSize,
            color: scheme.onSurface.withValues(alpha: tokens.chevronOpacity),
          ),
    );
  }
}
