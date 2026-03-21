import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import 'package:github_wallpaper/state/app_state.dart';
import 'package:github_wallpaper/state/paywall_controller.dart';
import 'package:github_wallpaper/utils/app_theme.dart';
import 'package:github_wallpaper/utils/app_utils.dart';
import 'package:github_wallpaper/config/environment_config.dart' as app_config;
import 'package:github_wallpaper/services/background_scheduler.dart';
import 'package:github_wallpaper/services/bootstrap_service.dart';
import 'package:github_wallpaper/services/github_service.dart';
import 'package:github_wallpaper/services/storage_service.dart';
import 'package:github_wallpaper/services/wallpaper_service.dart';
import 'package:github_wallpaper/screens/onboarding_screen.dart';
import 'package:github_wallpaper/screens/main_nav_screen.dart';
import 'package:github_wallpaper/screens/splash_screen.dart';
import 'package:github_wallpaper/services/subscription_service.dart';

void _recordErrorIfConsented(Object error, StackTrace stack,
    {bool fatal = true}) {
  if (!StorageService.getCrashlyticsConsent()) return;
  try {
    final sanitizedMsg = SensitiveDataSanitizer.sanitize(error.toString());
    FirebaseCrashlytics.instance
        .recordError(Exception(sanitizedMsg), stack, fatal: fatal);
  } catch (e, s) {
    AppLog.error(e, s);
  }
}

void _recordFlutterErrorIfConsented(FlutterErrorDetails details) {
  if (!StorageService.getCrashlyticsConsent()) return;
  try {
    final sanitizedMsg =
        SensitiveDataSanitizer.sanitize(details.exception.toString());
    FirebaseCrashlytics.instance.recordFlutterFatalError(
      FlutterErrorDetails(
        exception: Exception(sanitizedMsg),
        stack: details.stack,
        library: details.library,
        context: details.context,
      ),
    );
  } catch (e, s) {
    AppLog.error(e, s);
  }
}

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
      _recordFlutterErrorIfConsented(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLog.error(error, stack);
      _recordErrorIfConsented(error, stack, fatal: true);
      return true;
    };

    runApp(const MyApp());
  }, (error, stack) {
    AppLog.error(error, stack);
    _recordErrorIfConsented(error, stack, fatal: true);
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _lifecycleObserver = AppLifecycleObserver();
  final ProState _proState = ProState();

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _proState),
        ChangeNotifierProxyProvider<ProState, PaywallController>(
          create: (context) => PaywallController(context.read<ProState>()),
          update: (context, proState, controller) =>
              controller!..updateProState(proState),
        ),
        ChangeNotifierProvider(create: (_) => SettingsPreferencesState()),
        ChangeNotifierProvider(create: (_) => ThemeModeState()),
      ],
      child: Consumer<ThemeModeState>(
        builder: (context, themeMode, _) => MaterialApp(
          scaffoldMessengerKey: messengerKey,
          title: AppStrings.appName,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: themeMode.mode,
          themeAnimationDuration: AppTheme.durationFast,
          themeAnimationCurve: Curves.easeOut,
          debugShowCheckedModeBanner: false,
          home: const AppInitializer(),
        ),
      ),
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
    } catch (e, s) {
      AppLog.error(e, s);
    }
  }

  Future<void> _runPendingRefresh(int runId) async {
    try {
      final canAutoApply = StorageService.getAutoUpdate() &&
          StorageService.hasAppliedWallpaper();
      if (!canAutoApply) {
        await StorageService.consumePendingWallpaperRefresh();
        return;
      }
      await WallpaperService.refreshWallpaper(
        syncAction: GitHubService.syncGitHubData,
      );
    } catch (e, s) {
      if (runId == _initRunId) {
        AppLog.error(e, s);
      }
    }
  }

  Future<void> _startInitialization() async {
    final runId = ++_initRunId;
    app_config.AppConfig.validateOAuthConfig();
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
      await SubscriptionService.initialize();
      await context.read<ProState>().refresh();
      await StorageService.setProEnabled(context.read<ProState>().isProOrTrial);
      await StorageService.recordAppSessionStart();

      final loggedIn = await StorageService.hasAuthenticatedSession();
      final pendingRefresh =
          loggedIn && StorageService.hasPendingWallpaperRefresh();

      setState(() {
        _isLoggedIn = loggedIn;
        _isInitialized = true;
      });

      // Initialize WorkManager for guaranteed background updates
      await BackgroundScheduler.initialize();

      // Schedule periodic updates if auto-update is enabled
      if (StorageService.getAutoUpdate()) {
        await BackgroundScheduler.scheduleUpdates();
      }
      if (StorageService.getStreakReminderEnabled()) {
        await BackgroundScheduler.scheduleStreakReminders();
      }

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
    }
  }
}
