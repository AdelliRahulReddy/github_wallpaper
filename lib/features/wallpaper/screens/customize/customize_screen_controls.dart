part of 'customize_screen.dart';

extension _CustomizePageStateControls on _CustomizePageState {
  Widget _buildCustomizationSection() {
    final scheme = Theme.of(context).colorScheme;
    final showAdvanced = !_config.autoFitWidth;

    return Container(
      padding: AppTheme.pagePadding(context),
      decoration: AppTheme.glassCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Quick Adjust',
                  style: TextStyle(
                    fontSize: AppTheme.fontBase,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: scheme.primary.withValues(alpha: 0.20)),
                ),
                child: Text(
                  _config.autoFitWidth ? 'Auto-fit' : 'Manual',
                  style: TextStyle(
                    fontSize: AppTheme.fontSmall,
                    fontWeight: FontWeight.w900,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          AppTheme.h12,
          _buildSlider(
            label: AppStrings.opacity,
            value: _config.opacity,
            min: 0.3,
            max: 1.0,
            divisions: 7,
            onChanged: (value) {
              _updateConfig(_config.copyWith(opacity: value));
            },
          ),
          AppTheme.h16,
          _buildSlider(
            label: AppStrings.cornerRadius,
            value: _config.cornerRadius,
            min: 0,
            max: 8,
            divisions: 8,
            onChanged: (value) {
              _updateConfig(_config.copyWith(cornerRadius: value));
            },
          ),
          AppTheme.h16,
          const Divider(),
          AppTheme.h12,
          _buildTextOverlaySection(scheme),
          AppTheme.h8,
          _buildStatsBarControls(scheme),
          AppTheme.h16,
          const Divider(),
          AppTheme.h12,
          _buildPreviewToolsSection(scheme),
          AppTheme.h16,
          _buildAdvancedLayoutSection(scheme, showAdvanced),
        ],
      ),
    );
  }
}
