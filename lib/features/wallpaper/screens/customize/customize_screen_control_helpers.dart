part of 'customize_screen.dart';

extension _CustomizePageStateControlHelpers on _CustomizePageState {
  Widget _buildMetricToggle({
    required String label,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppTheme.fontBody,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: scheme.primary,
            onChanged: !enabled
                ? null
                : (v) {
                    HapticFeedback.selectionClick();
                    onChanged(v);
                  },
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // SLIDER WIDGET
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppTheme.fontBase,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ),
            AppTheme.w12,
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                fontSize: AppTheme.fontSmall,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ],
        ),
        AppTheme.h8,
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: scheme.primary,
            inactiveTrackColor: scheme.outline.withValues(alpha: 0.6),
            thumbColor: scheme.primary,
            overlayColor: scheme.primary.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: (double val) {
              HapticFeedback.selectionClick();
              onChanged(val);
            },
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // APPLY BUTTON
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildApplyButton() {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: Semantics(
        button: true,
        enabled: !_isGenerating,
        label: AppStrings.applyWallpaper,
        child: ElevatedButton(
          onPressed: _isGenerating
              ? null
              : () {
                  HapticFeedback.heavyImpact();
                  _saveAndApply();
                },
          child: _isGenerating
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.onPrimary,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 22),
                    AppTheme.w8,
                    Flexible(
                      child: Text(
                        AppStrings.applyWallpaper,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppTheme.fontLarge,
                          fontWeight: FontWeight.w600,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
