import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:github_wallpaper/data/datasources/local/storage_service.dart';
import 'package:github_wallpaper/data/repositories/github_service.dart';
import 'package:github_wallpaper/shared/services/refresh_result.dart';
import 'package:github_wallpaper/shared/services/achievement_service.dart';
import 'package:github_wallpaper/data/datasources/local/device_config_service.dart';
import 'package:github_wallpaper/shared/services/wallpaper_service.dart';
import 'package:github_wallpaper/data/models/app_models.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/errors/app_exceptions.dart';
import 'package:github_wallpaper/features/wallpaper/screens/home/home_page.dart';
import 'package:github_wallpaper/features/wallpaper/screens/stats/stats_page.dart';
import 'package:github_wallpaper/features/wallpaper/screens/customize/customize_screen.dart';
import 'package:github_wallpaper/features/settings/screens/settings_screen.dart';

part 'main_nav_screen_part.dart';

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
    if (!await _shouldRunAutomaticSync()) return;

    AppLog.info('Automatic sync triggered on load');
    await _syncData(silent: true);
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
      await GitHubService.checkAuthStatus();
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
      final result = await GitHubService.syncGitHubData(
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
