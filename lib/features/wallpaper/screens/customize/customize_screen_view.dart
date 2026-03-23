part of 'customize_screen.dart';

extension _CustomizePageStateView on _CustomizePageState {
  Widget _buildCustomizePage(BuildContext context) {
    if (widget.data == null) {
      return _buildNoDataState();
    }

    final scheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;
    final textScale = media.textScaler.scale(1.0);
    final previewFlex = textScale > 1.2 ? 6 : 7;
    final controlsFlex = textScale > 1.2 ? 6 : 5;

    final previewPanel = Container(
      width: double.infinity,
      padding: AppTheme.pagePadding(context).copyWith(top: 12, bottom: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outline.withValues(alpha: 0.55)),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(child: _buildPreviewSection()),
    );

    final controlsPanel = Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: AppTheme.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionHeader(
                title: AppStrings.customize,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore_rounded),
                      tooltip: 'Reset to Defaults',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _updateConfig(
                          WallpaperConfig.defaults(),
                          preserveTemplateSelection: true,
                          syncQuoteField: true,
                        );
                        _setPreviewTarget(WallpaperTarget.lock);
                        _fitToWidth(preserveTemplateSelection: true);
                        _syncThemeGalleryToCurrentSelection();
                      },
                    ),
                    Icon(Icons.wallpaper_rounded, color: scheme.primary),
                  ],
                ),
              ),
              AppTheme.h16,
              _buildTemplatePicker(),
              AppTheme.h12,
              _buildThemePicker(),
              AppTheme.h12,
              AppCard(
                padding: AppTheme.pAll16,
                child: _buildCustomizationSection(),
              ),
              AppTheme.h32,
              _buildApplyButton(),
              AppTheme.h32,
            ],
          ),
        ),
      ),
    );

    if (isLandscape) {
      return Row(
        children: [
          Expanded(child: previewPanel),
          AppTheme.w12,
          Expanded(child: controlsPanel),
        ],
      );
    }

    return Column(
      children: [
        Expanded(flex: previewFlex, child: previewPanel),
        Expanded(flex: controlsFlex, child: controlsPanel),
      ],
    );
  }
}
