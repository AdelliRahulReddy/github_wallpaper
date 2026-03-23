part of 'main_nav_screen.dart';

extension _MainNavPageStateSurface on _MainNavPageState {
  Future<bool> _handleSetWallpaper(String target) async {
    if (_data == null) return false;

    try {
      final config = StorageService.getWallpaperConfig();
      final targetEnum = switch (target) {
        'home' => WallpaperTarget.lock,
        'lock' => WallpaperTarget.lock,
        'both' => WallpaperTarget.both,
        _ => WallpaperTarget.lock,
      };

      final didApply = await WallpaperService.generateAndSetWallpaper(
        data: _data!,
        config: config,
        target: targetEnum,
        forceApply: true,
      );
      if (Platform.isAndroid) {
        await StorageService.setHasAppliedWallpaper(true);
      }

      if (mounted) {
        ErrorHandler.showSuccess(
          context,
          Platform.isAndroid
              ? AppStrings.wallpaperApplied
              : AppStrings.wallpaperGenerated,
        );
      }
      return didApply;
    } catch (e) {
      if (mounted) {
        ErrorHandler.handle(context, e);
      }
      return false;
    }
  }

  Widget _buildMainNavScaffold(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final screens = [
      HomePage(
        data: _data,
        isLoading: _isLoading,
        loadError: _loadError,
        onRefresh: () => _syncData(silent: false, force: true),
        onOpenStats: () => MainNavPage.navIndex.value = 1,
      ),
      StatsPage(
        data: _data,
        isLoading: _isLoading,
        loadError: _loadError,
        onRefresh: () => _syncData(silent: false, force: true),
      ),
      CustomizePage(
        data: _data,
        onSetWallpaper: _handleSetWallpaper,
        onRequestSync: _requestSyncFromCustomize,
      ),
      SettingsPage(
        directUpdate: _data?.lastUpdated,
        onRequireSync: () => _syncData(silent: false, force: true),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: screens),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: colors.surface,
        indicatorColor: colors.primary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, size: AppTheme.iconMD),
            selectedIcon: Icon(
              Icons.dashboard_rounded,
              color: colors.primary,
              size: AppTheme.iconMD,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.query_stats_outlined, size: AppTheme.iconMD),
            selectedIcon: Icon(
              Icons.query_stats_rounded,
              color: colors.primary,
              size: AppTheme.iconMD,
            ),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.palette_outlined, size: AppTheme.iconMD),
            selectedIcon: Icon(
              Icons.palette_rounded,
              color: colors.primary,
              size: AppTheme.iconMD,
            ),
            label: 'Customize',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, size: AppTheme.iconMD),
            selectedIcon: Icon(
              Icons.settings_rounded,
              color: colors.primary,
              size: AppTheme.iconMD,
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
