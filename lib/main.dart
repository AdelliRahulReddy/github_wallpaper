import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_services.dart';
import 'app_theme.dart';
import 'app_utils.dart';
import 'pages/onboarding_page.dart';
import 'pages/main_nav_page.dart';
import 'pages/splash_screen.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.lightBg,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: messengerKey,
      title: AppStrings.appName,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  bool _isLoggedIn = false;
  String? _error;
  double _initProgress = 0.0;
  String _appVersion = AppStrings.appVersion;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _startInitialization();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (_) {}
  }

  Future<void> _startInitialization() async {
    final success = await BootstrapService.boot(
      onProgress: (p) {
        if (mounted) setState(() => _initProgress = p);
      },
      onError: (e) {
        if (mounted) setState(() => _error = e);
      },
    );

    if (success && mounted) {
      final loggedIn = StorageService.isOnboardingComplete();
      final pendingRefresh = loggedIn && StorageService.hasPendingWallpaperRefresh();
      
      setState(() {
        _isLoggedIn = loggedIn;
        _isInitialized = true;
      });

      if (pendingRefresh) {
        unawaited(() async {
          await StorageService.consumePendingWallpaperRefresh();
          await WallpaperService.refreshWallpaper();
        }());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return SplashScreen(
        progress: _initProgress,
        appVersion: _appVersion,
        error: _error,
        onRetry: () {
          setState(() {
            _error = null;
            _initProgress = 0.0;
            _isInitialized = false;
          });
          _startInitialization();
        },
      );
    }

    if (!_isInitialized) {
      return SplashScreen(progress: _initProgress, appVersion: _appVersion);
    }

    return _isLoggedIn ? const MainNavPage() : const OnboardingPage();
  }
}
