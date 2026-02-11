import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_services.dart';
import 'app_theme.dart';
import 'app_utils.dart';
import 'pages/onboarding_page.dart';
import 'pages/main_nav_page.dart';
import 'pages/splash_screen.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppTheme.lightBg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      AppLog.error(details.exception, details.stack);
      // Sanitize and report to Crashlytics with consent check
      if (StorageService.getCrashlyticsConsent()) {
        try {
          final sanitizedMsg = details.exception.toString()
            .replaceAll(RegExp(r'ghp_[a-zA-Z0-9_]+'), '[REDACTED_TOKEN]')
            .replaceAll(RegExp(r'gho_[a-zA-Z0-9_]+'), '[REDACTED_TOKEN]')
            .replaceAll(RegExp(r'ghs_[a-zA-Z0-9_]+'), '[REDACTED_TOKEN]')
            .replaceAll(RegExp(r'Bearer\s+\S+'), 'Bearer [REDACTED]');
          FirebaseCrashlytics.instance.recordFlutterFatalError(
            FlutterErrorDetails(
              exception: Exception(sanitizedMsg),
              stack: details.stack,
              library: details.library,
              context: details.context,
            ),
          );
        } catch (_) {}
      }
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLog.error(error, stack);
      // Sanitize and report to Crashlytics with consent check
      if (StorageService.getCrashlyticsConsent()) {
        try {
          final sanitizedMsg = error.toString()
            .replaceAll(RegExp(r'ghp_[a-zA-Z0-9_]+'), '[REDACTED_TOKEN]')
            .replaceAll(RegExp(r'gho_[a-zA-Z0-9_]+'), '[REDACTED_TOKEN]')
            .replaceAll(RegExp(r'ghs_[a-zA-Z0-9_]+'), '[REDACTED_TOKEN]')
            .replaceAll(RegExp(r'Bearer\s+\S+'), 'Bearer [REDACTED]');
          FirebaseCrashlytics.instance.recordError(Exception(sanitizedMsg), stack, fatal: true);
        } catch (_) {}
      }
      return true;
    };

    runApp(const MyApp());
  }, (error, stack) {
    AppLog.error(error, stack);
    // Sanitize and report to Crashlytics with consent check
    if (StorageService.getCrashlyticsConsent()) {
      try {
        final sanitizedMsg = error.toString()
          .replaceAll(RegExp(r'ghp_[a-zA-Z0-9_]+'), '[REDACTED_TOKEN]')
          .replaceAll(RegExp(r'gho_[a-zA-Z0-9_]+'), '[REDACTED_TOKEN]')
          .replaceAll(RegExp(r'ghs_[a-zA-Z0-9_]+'), '[REDACTED_TOKEN]')
          .replaceAll(RegExp(r'Bearer\s+\S+'), 'Bearer [REDACTED]');
        FirebaseCrashlytics.instance.recordError(Exception(sanitizedMsg), stack, fatal: true);
      } catch (_) {}
    }
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _lifecycleObserver = AppLifecycleObserver();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

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
  int _initRunId = 0;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _startInitialization();
  }

  @override
  void dispose() {
    _initRunId++;
    super.dispose();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (_) {}
  }

  Future<void> _runPendingRefresh(int runId) async {
    try {
      final canAutoApply = StorageService.getAutoUpdate() &&
          StorageService.hasAppliedWallpaper();
      if (!canAutoApply) {
        await StorageService.consumePendingWallpaperRefresh();
        return;
      }
      await WallpaperService.refreshWallpaper();
    } catch (e, s) {
      if (runId == _initRunId) {
        AppLog.error(e, s);
      }
    }
  }

  Future<void> _startInitialization() async {
    final runId = ++_initRunId;
    final success = await BootstrapService.boot(
      onProgress: (p) {
        if (!mounted || runId != _initRunId) return;
        setState(() => _initProgress = p);
      },
      onError: (e) {
        if (!mounted || runId != _initRunId) return;
        setState(() => _error = e);
      },
    );

    if (!mounted || runId != _initRunId) return;

    if (success) {
      final loggedIn = StorageService.isOnboardingComplete();
      final pendingRefresh =
          loggedIn && StorageService.hasPendingWallpaperRefresh();

      setState(() {
        _isLoggedIn = loggedIn;
        _isInitialized = true;
      });

      if (pendingRefresh) {
        unawaited(_runPendingRefresh(runId));
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

class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      GitHubService.dispose();
      FcmService.dispose();
    }
  }
}
