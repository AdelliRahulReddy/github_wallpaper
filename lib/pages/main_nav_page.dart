import 'dart:io';
import 'package:flutter/material.dart';
import 'package:github_wallpaper/app_services.dart';
import 'package:github_wallpaper/app_models.dart';
import 'package:github_wallpaper/app_utils.dart';
import 'package:github_wallpaper/app_theme.dart';

import 'home_page.dart';
import 'customize_page.dart';
import 'settings_page.dart';

class MainNavPage extends StatefulWidget {
  const MainNavPage({super.key});

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
    _requestSyncFromCustomize = () {
      _onItemTapped(0);
      _syncData(force: true);
    };
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkAutoUpdate();
  }

  Future<void> _checkAutoUpdate() async {
    if (!mounted) return;

    await AppConfig.initializeFromPlatformDispatcher();
    if (!mounted) return;

    if (!StorageService.getAutoUpdate()) return;
    final lastUpdate = StorageService.getLastUpdate();
    if (lastUpdate != null) {
      final diff = DateTime.now().difference(lastUpdate);
      if (diff.inMinutes > AppConstants.resumeSyncThresholdMinutes) {
        _syncData(silent: true);
      }
    }
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
        if (cached.days.length < AppConstants.minCachedContributionDays) {
          await _syncData(force: true);
        } else {
          setState(() {
            _data = cached;
            _loadError = null;
            _isLoading = false;
          });
          _checkBackgroundSync();
        }
      } else {
        await _syncData(force: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString().replaceAll('Exception:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  void _checkBackgroundSync() {
    if (!StorageService.getAutoUpdate()) return;
    final lastUpdate = StorageService.getLastUpdate();
    if (lastUpdate != null) {
      final diff = DateTime.now().difference(lastUpdate);
      if (diff.inHours >= AppConstants.backgroundSyncThresholdHours) {
        _syncData(silent: true);
      }
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
      final username = StorageService.getUsername();
      final token = await StorageService.getToken();

      if (username == null || token == null) {
        throw Exception('Credentials missing. Please login again.');
      }

      final newData = await GitHubService.getContributions(
        username: username,
        token: token,
        forceRefresh: force,
      );

      await StorageService.setCachedData(newData);
      await StorageService.setLastUpdate(DateTime.now());

      if (mounted) {
        setState(() {
          _data = newData;
          _isLoading = false;
        });

        if (!silent) {
          ErrorHandler.showSuccess(context, 'Data synced successfully');
        }
      }
    } catch (e) {
      if (mounted) {
        if (!silent) {
          setState(() {
            _loadError = e.toString().replaceAll('Exception:', '').trim();
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<bool> _handleSetWallpaper(String target) async {
    if (_data == null) return false;

    try {
      final config = StorageService.getWallpaperConfig();

      WallpaperTarget targetEnum;
      switch (target) {
        case 'home':
          targetEnum = WallpaperTarget.home;
          break;
        case 'lock':
          targetEnum = WallpaperTarget.lock;
          break;
        default:
          targetEnum = WallpaperTarget.both;
      }

      final didApply = await WallpaperService.generateAndSetWallpaper(
        data: _data!,
        config: config,
        target: targetEnum,
        forceApply: true,
      );

      if (mounted) {
        if (Platform.isAndroid) {
          ErrorHandler.showSuccess(context, AppStrings.wallpaperApplied);
        } else {
          ErrorHandler.showSuccess(
              context, 'Wallpaper image generated successfully');
        }
      }
      return didApply;
    } catch (e) {
      if (mounted) ErrorHandler.handle(context, e);
      return false;
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    final screens = [
      HomePage(
          data: _data,
          isLoading: _isLoading,
          loadError: _loadError,
          onRefresh: () => _syncData(silent: false)),
      CustomizePage(
          data: _data,
          onSetWallpaper: _handleSetWallpaper,
          onRequestSync: _requestSyncFromCustomize),
      const SettingsPage(),
    ];

    return Scaffold(
      body: SafeArea(
          child: IndexedStack(index: _selectedIndex, children: screens)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: cs.surface,
        indicatorColor: cs.primary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, size: 24),
            selectedIcon:
                Icon(Icons.dashboard_rounded, color: cs.primary, size: 24),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.palette_outlined, size: 24),
            selectedIcon:
                Icon(Icons.palette_rounded, color: cs.primary, size: 24),
            label: 'Customize',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, size: 24),
            selectedIcon:
                Icon(Icons.settings_rounded, color: cs.primary, size: 24),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
