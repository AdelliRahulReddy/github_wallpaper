part of 'customize_screen.dart';

extension _CustomizePageStateTemplates on _CustomizePageState {
  Widget _buildTemplatePicker() {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isAppDark = Theme.of(context).brightness == Brightness.dark;
    final templates = WallpaperTemplates.all;

    return Container(
      padding: AppTheme.pagePadding(context),
      decoration: AppTheme.glassCard(
        context,
        opacity: isAppDark ? 0.18 : 0.12,
        tint: scheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '🧩  Templates',
                  style: tt.titleLarge?.copyWith(color: scheme.onSurface),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _updateConfig(
                    _config.copyWith(autoFitWidth: true),
                    preserveTemplateSelection: true,
                  );
                  _fitToWidth(preserveTemplateSelection: true);
                },
                icon: const Icon(Icons.fit_screen_rounded, size: 16),
                label: const Text('Auto-fit'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          AppTheme.h12,
          if (!MembershipEntitlements.hasProAccess)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Free includes the essentials. Locked templates stay visible so you can preview the Pro set.',
                style: tt.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ),
          SizedBox(
            height: 112,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                final isUnlocked =
                    MembershipEntitlements.isTemplateUnlocked(template.id);
                final isSelected = _config.templateId == template.id;

                return Padding(
                  padding: EdgeInsets.only(
                      right: index == templates.length - 1 ? 0 : 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: AppTheme.brLarge,
                      onTap: () => _applyTemplate(template),
                      child: AnimatedContainer(
                        duration: AppTheme.durationFast,
                        width: 200,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: AppTheme.brLarge,
                          border: Border.all(
                            color: isSelected
                                ? scheme.primary
                                : scheme.outlineVariant
                                    .withValues(alpha: isAppDark ? 0.65 : 0.45),
                            width: isSelected ? 2 : 1,
                          ),
                          color: isSelected
                              ? scheme.primary
                                  .withValues(alpha: isAppDark ? 0.18 : 0.08)
                              : (isAppDark
                                  ? scheme.surface.withValues(alpha: 0.85)
                                  : scheme.surfaceContainerHighest
                                      .withValues(alpha: 0.55)),
                        ),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${template.emoji} ${template.label}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: tt.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: isSelected
                                        ? scheme.primary
                                        : scheme.onSurface,
                                  ),
                                ),
                                Text(
                                  template.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: tt.bodySmall?.copyWith(
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.65),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            if (!isUnlocked)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        scheme.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: scheme.primary
                                          .withValues(alpha: 0.18),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.lock_rounded,
                                        size: 12,
                                        color: scheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Pro',
                                        style: tt.labelSmall?.copyWith(
                                          color: scheme.primary,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
