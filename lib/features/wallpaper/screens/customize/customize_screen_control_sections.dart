part of 'customize_screen.dart';

extension _CustomizePageStateControlSections on _CustomizePageState {
  Widget _buildTextOverlaySection(ColorScheme scheme) {
    final hasProAccess =
        context.watch<MembershipState?>()?.hasProAccess ?? false;

    return ExpansionTile(
      key: ValueKey('text-overlay-${_config.customQuote.isNotEmpty}'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      initiallyExpanded: _config.customQuote.isNotEmpty,
      title: Text(
        AppStrings.textOverlay,
        style: TextStyle(
          fontSize: AppTheme.fontBase,
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
      ),
      subtitle: Text(
        _config.customQuote.isEmpty ? 'Optional quote layer' : 'Quote enabled',
        style: TextStyle(
          fontSize: AppTheme.fontCaption,
          color: scheme.onSurface.withValues(alpha: 0.7),
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        AppTheme.h8,
        Text(
          'Text stays inside the safe area so it does not clash with the lockscreen clock or bottom gesture space.',
          style: TextStyle(
            fontSize: AppTheme.fontCaption,
            color: scheme.onSurface.withValues(alpha: 0.68),
            height: 1.35,
          ),
        ),
        AppTheme.h8,
        TextField(
          controller: _quoteController,
          maxLength: AppConstants.quoteMaxLength,
          decoration: const InputDecoration(
            labelText: AppStrings.customQuote,
            hintText: AppStrings.quoteHint,
          ),
          onChanged: _setQuoteText,
        ),
        AppTheme.h8,
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _isGeneratingQuote
                ? null
                : () async {
                    if (hasProAccess) {
                      await _generateQuote();
                      return;
                    }
                    await _promptForLockedAccess(
                      featureName: 'Live Quote Generation',
                      featureDescription:
                          'Generate fresh AI quotes from Customize instead of using only the daily fallback quote.',
                    );
                  },
            icon: _isGeneratingQuote
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  )
                : Icon(
                    hasProAccess ? Icons.auto_awesome : Icons.lock_rounded,
                    size: 16,
                  ),
            label: Text(
              _isGeneratingQuote
                  ? 'Generating Quote...'
                  : 'Generate Live Quote',
              style: const TextStyle(fontSize: AppTheme.fontBody),
            ),
            style: TextButton.styleFrom(
              padding: AppTheme.pZero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        if (_config.customQuote.isNotEmpty) ...[
          AppTheme.h8,
          _buildSlider(
            label: AppStrings.quoteSize,
            value: _config.quoteFontSize,
            min: 10.0,
            max: 40.0,
            divisions: 15,
            onChanged: (value) {
              _updateConfig(_config.copyWith(quoteFontSize: value));
            },
          ),
          AppTheme.h12,
          _buildSlider(
            label: AppStrings.quoteOpacity,
            value: _config.quoteOpacity,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            onChanged: (value) {
              _updateConfig(_config.copyWith(quoteOpacity: value));
            },
          ),
        ],
        AppTheme.h8,
      ],
    );
  }

  Widget _buildStatsBarControls(ColorScheme scheme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Show bottom info bar',
                style: TextStyle(
                  fontSize: AppTheme.fontBase,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ),
            Switch(
              value: _config.showQuickStatsBar,
              activeThumbColor: scheme.primary,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                _updateConfig(_config.copyWith(showQuickStatsBar: value));
              },
            ),
          ],
        ),
        AppTheme.h8,
        _buildMetricToggle(
          label: 'Current streak',
          value: _config.statCurrentStreak,
          enabled: _config.showQuickStatsBar,
          onChanged: (value) =>
              _updateConfig(_config.copyWith(statCurrentStreak: value)),
        ),
        AppTheme.h8,
        _buildMetricToggle(
          label: 'Longest streak',
          value: _config.statLongestStreak,
          enabled: _config.showQuickStatsBar,
          onChanged: (value) =>
              _updateConfig(_config.copyWith(statLongestStreak: value)),
        ),
        AppTheme.h8,
        _buildMetricToggle(
          label: 'Total commits',
          value: _config.statTotalCommits,
          enabled: _config.showQuickStatsBar,
          onChanged: (value) =>
              _updateConfig(_config.copyWith(statTotalCommits: value)),
        ),
        AppTheme.h8,
        _buildMetricToggle(
          label: 'Top language',
          value: _config.statTopLanguage,
          enabled: _config.showQuickStatsBar,
          onChanged: (value) =>
              _updateConfig(_config.copyWith(statTopLanguage: value)),
        ),
      ],
    );
  }

  Widget _buildPreviewToolsSection(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Safe preview guides',
                style: TextStyle(
                  fontSize: AppTheme.fontBase,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ),
            Switch(
              value: _safePreviewEnabled,
              activeThumbColor: scheme.primary,
              onChanged: _toggleSafePreview,
            ),
          ],
        ),
        Text(
          'Guides show where Android system UI can cover the wallpaper.',
          style: TextStyle(
            fontSize: AppTheme.fontCaption,
            color: scheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        AppTheme.h8,
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed:
                _isRefreshingDeviceProfile ? null : _refreshDeviceProfile,
            icon: _isRefreshingDeviceProfile
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, size: 16),
            label: Text(
              _isRefreshingDeviceProfile
                  ? 'Refreshing Device Fit...'
                  : 'Refresh Device Fit',
              style: const TextStyle(fontSize: AppTheme.fontBody),
            ),
            style: TextButton.styleFrom(
              padding: AppTheme.pZero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedLayoutSection(ColorScheme scheme, bool showAdvanced) {
    return ExpansionTile(
      key: ValueKey('advanced-layout-${_config.autoFitWidth}'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      initiallyExpanded: showAdvanced,
      title: Text(
        'Advanced Layout',
        style: TextStyle(
          fontSize: AppTheme.fontBase,
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
      ),
      subtitle: Text(
        _config.autoFitWidth
            ? 'Auto-fit keeps the layout inside the safe area'
            : 'Manual scale and position controls',
        style: TextStyle(
          fontSize: AppTheme.fontCaption,
          color: scheme.onSurface.withValues(alpha: 0.7),
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                AppStrings.autoFitWidth,
                style: TextStyle(
                  fontSize: AppTheme.fontBase,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ),
            Switch(
              value: _config.autoFitWidth,
              activeThumbColor: scheme.primary,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                _updateConfig(_config.copyWith(autoFitWidth: value));
                if (value) {
                  _fitToWidth();
                }
              },
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              _fitToWidth();
            },
            icon: const Icon(Icons.fit_screen, size: 16),
            label: const Text(
              AppStrings.autoFixDevice,
              style: TextStyle(fontSize: AppTheme.fontBody),
            ),
            style: TextButton.styleFrom(
              padding: AppTheme.pZero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        AppTheme.h12,
        Text(
          AppStrings.scale,
          style: TextStyle(
            fontSize: AppTheme.fontBase,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
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
            value: _config.scale,
            min: 0.5,
            max: 8.0,
            divisions: 75,
            onChanged: _config.autoFitWidth
                ? null
                : (value) {
                    _updateConfig(_config.copyWith(scale: value));
                  },
          ),
        ),
        AppTheme.h12,
        Text(
          AppStrings.layoutNote,
          style: TextStyle(
            fontSize: AppTheme.fontCaption,
            color: scheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        AppTheme.h12,
        _buildSlider(
          label: AppStrings.positionVertical,
          value: _config.verticalPosition,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          onChanged: (value) {
            _updateConfig(_config.copyWith(verticalPosition: value));
          },
        ),
        AppTheme.h20,
        _buildSlider(
          label: AppStrings.positionHorizontal,
          value: _config.horizontalPosition,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          onChanged: (value) {
            _updateConfig(_config.copyWith(horizontalPosition: value));
          },
        ),
        AppTheme.h8,
      ],
    );
  }
}
