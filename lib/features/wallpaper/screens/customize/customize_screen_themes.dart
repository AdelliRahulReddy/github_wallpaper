part of 'customize_screen.dart';

extension _CustomizePageStateThemes on _CustomizePageState {
  Widget _buildThemePicker() {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isAppDark = Theme.of(context).brightness == Brightness.dark;

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
                  '🎨  Color Style',
                  style: textTheme.titleLarge?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Tooltip(
                      message: 'Preview mode',
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode_rounded, size: 16),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode_rounded, size: 16),
                          ),
                        ],
                        selected: {_config.isDarkMode},
                        onSelectionChanged: (selection) {
                          HapticFeedback.selectionClick();
                          _updateConfig(
                            _config.copyWith(isDarkMode: selection.first),
                          );
                        },
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          AppTheme.h12,
          Text(
            MembershipEntitlements.hasProAccess
                ? 'Swipe to explore • Tap to apply'
                : 'Swipe to explore • Free palettes apply instantly, Pro palettes open access',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          AppTheme.h12,
          _buildThemeGallery(
            scheme: scheme,
            textTheme: textTheme,
            isAppDark: isAppDark,
          ),
        ],
      ),
    );
  }
}
