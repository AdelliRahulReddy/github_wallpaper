import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/features/contributions/repositories/contribution_repository.dart';
import 'package:github_wallpaper/app/services/refresh_result.dart';
import 'package:github_wallpaper/features/contributions/services/achievement_service.dart';
import 'package:github_wallpaper/features/wallpaper/services/device_config_service.dart';
import 'package:github_wallpaper/features/wallpaper/services/wallpaper_service.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/errors/app_exceptions.dart';
import 'package:github_wallpaper/features/contributions/pages/home_page.dart';
import 'package:github_wallpaper/features/contributions/pages/stats_page.dart';
import 'package:github_wallpaper/features/wallpaper/pages/customize_page.dart';
import 'package:github_wallpaper/features/settings/pages/settings_page.dart';

class MainNavPage extends StatefulWidget {
  const MainNavPage({super.key});

  static final ValueNotifier<int> navIndex = ValueNotifier<int>(0);

  @override
  State<MainNavPage> createState() => _MainNavPageState();
}

class _MainNavPageState extends State<MainNavPage> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  CachedContributionData? _data;
  bool _isLoading = false;
  String? _loadError;
  late final VoidCallback _requestSyncFromCustomize;

  @override
  void initState() {
    super.initState();
    _selectedIndex = MainNavPage.navIndex.value;
    WidgetsBinding.instance.addObserver(this);
    MainNavPage.navIndex.addListener(_handleExternalIndexChange);
    _requestSyncFromCustomize = () {
      _onItemTapped(0);
      _syncData(force: true);
    };
    _loadData();
  }

  void _handleExternalIndexChange() {
    final next = MainNavPage.navIndex.value;
    if (next != _selectedIndex && mounted) {
      setState(() => _selectedIndex = next);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MainNavPage.navIndex.removeListener(_handleExternalIndexChange);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAutoUpdate();
    }
  }

  Future<void> _checkAutoUpdate() async {
    if (!mounted) return;

    await DeviceConfigService.initializeFromPlatformDispatcher();
    if (!mounted) return;

    if (await _shouldRefreshStaleForegroundData()) {
      AppLog.info('Foreground refresh triggered on resume');
      _syncData(silent: true);
      return;
    }

    if (!await _shouldRunAutomaticSync()) return;

    AppLog.info('Auto-sync triggered on resume');
    _syncData(silent: true);
  }

  Future<void> _loadData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final cached = StorageService.getCachedData();

      if (cached != null) {
        setState(() {
          _data = cached;
          _loadError = null;
        });

        if (cached.days.length < AppConstants.minCachedContributionDays) {
          await _syncData(silent: true, force: true);
        } else {
          setState(() {
            _isLoading = false;
          });
          _checkBackgroundSync();
          unawaited(_silentAuthCheck());
        }
      } else {
        await _syncData(force: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = ErrorHandler.getUserFriendlyMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  void _checkBackgroundSync() {
    unawaited(_checkAutomaticSyncOnLoad());
  }

  Future<void> _checkAutomaticSyncOnLoad() async {
    if (!mounted) return;
    if (await _shouldRefreshStaleForegroundData()) {
      AppLog.info('Foreground refresh triggered on app open');
      await _syncData(silent: true);
      return;
    }
    if (!await _shouldRunAutomaticSync()) return;

    AppLog.info('Automatic sync triggered on load');
    await _syncData(silent: true);
  }

  Future<bool> _shouldRefreshStaleForegroundData() async {
    final currentData = _data;
    if (currentData == null || !currentData.isStale()) {
      return false;
    }
    if (StorageService.hasAuthError()) {
      return false;
    }
    return StorageService.hasAuthenticatedSession();
  }

  Future<bool> _shouldRunAutomaticSync() async {
    final dailyTime = StorageService.getUpdateDailyTime();
    final decision = RefreshPolicy.shouldRefresh(
      isBackground: false,
      isAutomatic: true,
      isAndroid: Platform.isAndroid,
      autoUpdateEnabled: StorageService.getAutoUpdate(),
      hasPendingRefresh: StorageService.hasPendingWallpaperRefresh(),
      lastUpdate: StorageService.getEffectiveLastSync(),
      username: StorageService.getUsername(),
      token: await StorageService.getToken(),
      hasAuthError: StorageService.hasAuthError(),
      scheduleMode: StorageService.getUpdateScheduleMode(),
      scheduleHour: dailyTime.hour,
      scheduleMinute: dailyTime.minute,
      scheduleIntervalMinutes: StorageService.getUpdateIntervalMinutes(),
      lastDailyKey: StorageService.getUpdateScheduleLastDailyKey(),
    );
    return decision.shouldProceed;
  }

  Future<void> _silentAuthCheck() async {
    try {
      // Very cheap validation to catch tokens revoked while app was closed
      await ContributionRepository.checkAuthStatus();
    } on TokenExpiredException {
      await StorageService.setHasAuthError(true);
      if (mounted) setState(() {}); // Trigger rebuild to show banner
    } catch (e, s) {
      AppLog.error(e, s);
    }
  }

  Future<void> _syncData({bool silent = false, bool force = false}) async {
    if (!mounted) return;
    if (_isLoading && !force) return;

    setState(() {
      _isLoading = true;
      if (!silent) _loadError = null;
    });

    try {
      final previous = _data;
      final result = await ContributionRepository.syncGitHubData(
        force: force,
        isBackground: false,
      );

      if (result == RefreshResult.authError) {
        await StorageService.setHasAuthError(true);
        if (mounted) {
          setState(() {
            _isLoading = false;
            if (!silent && _data == null) {
              _loadError = 'GitHub authentication required';
            }
          });
        }
        return;
      }

      final newData = StorageService.getCachedData();
      if (newData == null) {
        throw GitHubException('No cached data after sync');
      }

      if (StorageService.hasAuthError()) {
        await StorageService.setHasAuthError(false);
      }

      if (mounted) {
        setState(() {
          _data = newData;
          _isLoading = false;
        });

        if (!silent) {
          await AchievementService.maybeNotify(context,
              previous: previous, current: newData);
          if (result == RefreshResult.throttled) {
            ErrorHandler.showSuccess(
                context, 'Sync skipped (recently updated)');
          } else {
            ErrorHandler.showSuccess(context, AppStrings.dataSynced);
          }
        }
      }
    } catch (e) {
      if (e is TokenExpiredException || e is AccessDeniedException) {
        await StorageService.setHasAuthError(true);
      }
      if (mounted) {
        if (!silent) {
          setState(() {
            _loadError = ErrorHandler.getUserFriendlyMessage(e);
            _isLoading = false;
          });
        } else {
          // Even if silent, we should trigger a rebuild so the banner appears!
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _onItemTapped(int index) {
    HapticFeedback.selectionClick();
    MainNavPage.navIndex.value = index;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) => _buildMainNavScaffold(context);
}

extension _MainNavPageStateSurface on _MainNavPageState {
  Future<bool> _handleSetWallpaper(String _) async {
    if (_data == null) return false;

    try {
      final config = StorageService.getWallpaperConfig();
      final targetEnum = WallpaperTarget.lock;

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
