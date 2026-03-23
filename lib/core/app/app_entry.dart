import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:github_wallpaper/shared/state/app_state.dart';
import 'package:github_wallpaper/shared/state/membership_state.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/core/constants/environment_config.dart'
    as app_config;
import 'package:github_wallpaper/shared/services/background_scheduler.dart';
import 'package:github_wallpaper/shared/services/bootstrap_service.dart';
import 'package:github_wallpaper/data/repositories/github_service.dart';
import 'package:github_wallpaper/data/datasources/local/storage_service.dart';
import 'package:github_wallpaper/data/datasources/remote/remote_config_service.dart';
import 'package:github_wallpaper/shared/services/notification_service.dart';
import 'package:github_wallpaper/shared/services/telemetry_service.dart';
import 'package:github_wallpaper/shared/services/wallpaper_service.dart';
import 'package:github_wallpaper/features/auth/screens/onboarding_screen.dart';
import 'package:github_wallpaper/features/auth/screens/setup_screen.dart';
import 'package:github_wallpaper/core/app/main_nav_screen.dart';
import 'package:github_wallpaper/features/auth/screens/splash_screen.dart';

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
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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
      unawaited(
        TelemetryService.logClientError(details.exception, details.stack),
      );
      _recordFlutterErrorIfConsented(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLog.error(error, stack);
      unawaited(TelemetryService.logClientError(error, stack));
      _recordErrorIfConsented(error, stack, fatal: true);
      return true;
    };

    runApp(const MyApp());
  }, (error, stack) {
    AppLog.error(error, stack);
    unawaited(TelemetryService.logClientError(error, stack));
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
        ChangeNotifierProvider(create: (_) => SettingsPreferencesState()),
        ChangeNotifierProvider(create: (_) => ThemeModeState()),
        ChangeNotifierProvider(create: (_) => MembershipState()),
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
  final RemoteConfigService _remoteConfig = RemoteConfigService();
  bool _isInitialized = false;
  bool _isLoggedIn = false;
  String? _error;
  double _initProgress = 0.0;
  String _appVersion = AppStrings.appVersion;
  int _initRunId = 0;

  @override
  void initState() {
    super.initState();
    _remoteConfig.addListener(_handleRemoteConfigChanged);
    _loadAppVersion();
    _startInitialization();
  }

  @override
  void dispose() {
    _initRunId++;
    _remoteConfig.removeListener(_handleRemoteConfigChanged);
    super.dispose();
  }

  void _handleRemoteConfigChanged() {
    if (!mounted || !_isInitialized) return;
    setState(() {});
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
    try {
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
        if (mounted) {
          context.read<MembershipState>().refreshFromStorage();
        }
        final loggedIn = await StorageService.hasAuthenticatedSession();
        final hasUsableCache = StorageService.getCachedData() != null;
        final canEnterMainNav =
            loggedIn && (!StorageService.hasAuthError() || hasUsableCache);
        final hasOperationalSession =
            canEnterMainNav && !StorageService.hasAuthError();
        final pendingRefresh = canEnterMainNav &&
            !StorageService.hasAuthError() &&
            StorageService.hasPendingWallpaperRefresh();

        setState(() {
          _isLoggedIn = canEnterMainNav;
          _isInitialized = true;
        });

        // Initialize WorkManager for guaranteed background updates
        await BackgroundScheduler.initialize();

        // Schedule periodic updates if auto-update is enabled
        if (hasOperationalSession && StorageService.getAutoUpdate()) {
          await BackgroundScheduler.scheduleUpdates();
        }
        if (canEnterMainNav && BackgroundScheduler.shouldScheduleReminderChecks()) {
          await BackgroundScheduler.scheduleStreakReminders();
        }

        if (pendingRefresh) {
          unawaited(_runPendingRefresh(runId));
        }
      }
    } catch (e) {
      // The global error handler already logs and reports to Crashlytics.
      // We just need to update the UI state to show the error.
      if (mounted && runId == _initRunId) {
        setState(() {
          _error = e.toString();
        });
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

    if (_remoteConfig.maintenanceMode) {
      return _AdminStateScreen(
        icon: Icons.construction_rounded,
        accent: AppTheme.warningOrange,
        title: 'Maintenance Mode',
        message: _remoteConfig.maintenanceMessage.trim().isNotEmpty
            ? _remoteConfig.maintenanceMessage.trim()
            : "We'll be back soon.",
        footer:
            'This screen updates from admin config in real time. Turn maintenance mode off to reopen the app.',
      );
    }

    if (_shouldForceUpdate()) {
      return _AdminStateScreen(
        icon: Icons.system_update_rounded,
        accent: AppTheme.primaryBlue,
        title: 'Update Required',
        message: _remoteConfig.forceUpdateMessage.trim().isNotEmpty
            ? _remoteConfig.forceUpdateMessage.trim()
            : 'Please update GitWall to continue.',
        footer:
            'Current version: $_appVersion • Minimum version: ${_remoteConfig.forceUpdateMinVersion}',
      );
    }

    if (_isLoggedIn) {
      return const MainNavPage();
    }

    return StorageService.isOnboardingComplete()
        ? const SetupPage()
        : const OnboardingPage();
  }

  bool _shouldForceUpdate() {
    if (!_remoteConfig.forceUpdateEnabled) return false;
    return _compareVersions(
          _appVersion,
          _remoteConfig.forceUpdateMinVersion,
        ) <
        0;
  }

  int _compareVersions(String current, String minimum) {
    final currentParts = _parseVersionParts(current);
    final minimumParts = _parseVersionParts(minimum);
    final maxLength = currentParts.length > minimumParts.length
        ? currentParts.length
        : minimumParts.length;

    for (var index = 0; index < maxLength; index++) {
      final currentValue =
          index < currentParts.length ? currentParts[index] : 0;
      final minimumValue =
          index < minimumParts.length ? minimumParts[index] : 0;
      if (currentValue != minimumValue) {
        return currentValue.compareTo(minimumValue);
      }
    }

    return 0;
  }

  List<int> _parseVersionParts(String version) {
    final normalized = version.trim();
    if (normalized.isEmpty) return const [0];

    return normalized
        .split('.')
        .map(
            (part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
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

class _AdminStateScreen extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String message;
  final String footer;

  const _AdminStateScreen({
    required this.icon,
    required this.accent,
    required this.title,
    required this.message,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppTheme.pagePadding(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Container(
                padding: AppTheme.pAll24,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: AppTheme.brXL,
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: AppTheme.brXL,
                      ),
                      child: Icon(icon, size: 36, color: accent),
                    ),
                    AppTheme.h20,
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    AppTheme.h12,
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: AppTheme.heightRelaxed,
                          ),
                    ),
                    AppTheme.h20,
                    Text(
                      footer,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
