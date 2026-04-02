import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:home_widget/home_widget.dart';

import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/core/constants/firebase_options.dart';
import 'package:github_wallpaper/core/constants/environment_config.dart'
    as app_config;
import 'package:github_wallpaper/features/settings/controllers/settings_controller.dart';
import 'package:github_wallpaper/features/settings/controllers/theme_controller.dart';
import 'package:github_wallpaper/app/services/background_scheduler.dart';
import 'package:github_wallpaper/app/services/bootstrap_service.dart';
import 'package:github_wallpaper/features/contributions/repositories/contribution_repository.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/app/services/remote_config_service.dart';
import 'package:github_wallpaper/app/services/notification_service.dart';
import 'package:github_wallpaper/app/services/telemetry_service.dart';
import 'package:github_wallpaper/app/product/services/product_analytics.dart';
import 'package:github_wallpaper/features/wallpaper/services/wallpaper_service.dart';
import 'package:github_wallpaper/features/wallpaper/services/widget_service.dart';
import 'package:github_wallpaper/features/auth/pages/onboarding_page.dart';
import 'package:github_wallpaper/app/pages/main_nav_page.dart';

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
    await StorageService.init();
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
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
        ChangeNotifierProvider(create: (_) => SettingsController()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
      ],
      child: Consumer<ThemeController>(
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
  String _appVersion = AppStrings.appVersion;
  int _initRunId = 0;
  StreamSubscription<Uri?>? _widgetLaunchSubscription;
  Uri? _pendingWidgetLaunch;
  String? _lastHandledWidgetLaunch;
  DateTime? _lastHandledWidgetLaunchAt;

  @override
  void initState() {
    super.initState();
    _remoteConfig.addListener(_handleRemoteConfigChanged);
    _listenForWidgetLaunches();
    _loadAppVersion();
    unawaited(_primeInitialShell());
  }

  @override
  void dispose() {
    _initRunId++;
    _widgetLaunchSubscription?.cancel();
    _remoteConfig.removeListener(_handleRemoteConfigChanged);
    super.dispose();
  }

  void _listenForWidgetLaunches() {
    _widgetLaunchSubscription = HomeWidget.widgetClicked.listen(
      _queueWidgetLaunch,
      onError: (Object error, StackTrace stackTrace) {
        AppLog.error(error, stackTrace);
      },
    );

    HomeWidget.initiallyLaunchedFromHomeWidget()
        .then(_queueWidgetLaunch)
        .catchError((Object error, StackTrace stackTrace) {
      AppLog.error(error, stackTrace);
    });
  }

  void _queueWidgetLaunch(Uri? uri) {
    if (!_isWidgetLaunchUri(uri)) {
      return;
    }

    _pendingWidgetLaunch = uri;
    if (_isInitialized) {
      _flushPendingWidgetLaunch();
    }
  }

  bool _isWidgetLaunchUri(Uri? uri) {
    return uri != null && uri.scheme == 'gitwall' && uri.host == 'widget';
  }

  void _flushPendingWidgetLaunch() {
    final uri = _pendingWidgetLaunch;
    if (!_isInitialized || uri == null || !_isWidgetLaunchUri(uri)) {
      return;
    }

    final rawUri = uri.toString();
    final now = DateTime.now();
    if (_lastHandledWidgetLaunch == rawUri &&
        _lastHandledWidgetLaunchAt != null &&
        now.difference(_lastHandledWidgetLaunchAt!) <
            const Duration(seconds: 2)) {
      _pendingWidgetLaunch = null;
      return;
    }

    _pendingWidgetLaunch = null;
    _lastHandledWidgetLaunch = rawUri;
    _lastHandledWidgetLaunchAt = now;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_handleWidgetLaunch(uri));
    });
  }

  Future<void> _handleWidgetLaunch(Uri uri) async {
    if (!_isLoggedIn || _remoteConfig.maintenanceMode || _shouldForceUpdate()) {
      return;
    }

    final destination =
        uri.pathSegments.isEmpty ? '' : uri.pathSegments.first.toLowerCase();
    unawaited(
      ProductAnalytics.track(
        ProductEventName.widgetTapped,
        properties: {'destination': destination},
      ),
    );
    switch (destination) {
      case 'home':
        MainNavPage.navIndex.value = 0;
        return;
      case 'stats':
        MainNavPage.navIndex.value = 1;
        return;
      case 'setup':
      default:
        MainNavPage.navIndex.value = 0;
    }
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
        syncAction: ContributionRepository.syncGitHubData,
      );
    } catch (e, s) {
      if (runId == _initRunId) {
        AppLog.error(e, s);
      }
    }
  }

  Future<void> _primeInitialShell() async {
    await _resolveInitialShell();
    if (!mounted) return;
    unawaited(_startInitialization());
  }

  Future<void> _resolveInitialShell() async {
    try {
      final loggedIn = await StorageService.hasAuthenticatedSession();
      final hasUsableCache = StorageService.getCachedData() != null;
      final canEnterMainNav =
          loggedIn && (!StorageService.hasAuthError() || hasUsableCache);
      if (!mounted) return;
      setState(() {
        _isLoggedIn = canEnterMainNav;
        _isInitialized = true;
        _error = null;
      });
      _flushPendingWidgetLaunch();
    } catch (e, s) {
      AppLog.error(e, s);
      if (!mounted) return;
      setState(() {
        _isLoggedIn = false;
        _isInitialized = true;
      });
    }
  }

  Future<void> _startInitialization() async {
    final runId = ++_initRunId;
    try {
      app_config.AppConfig.validateOAuthConfig();
      final success = await BootstrapService.boot(
        onProgress: (_) {},
        onError: (e) {
          if (!mounted || runId != _initRunId || _isInitialized) return;
          setState(() => _error = e);
        },
      );

      if (!mounted || runId != _initRunId) return;

      if (success) {
        unawaited(WidgetService.refreshFromCache());
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
        _flushPendingWidgetLaunch();

        // Initialize WorkManager for guaranteed background updates
        await BackgroundScheduler.initialize();

        // Schedule periodic updates if auto-update is enabled
        if (hasOperationalSession && StorageService.getAutoUpdate()) {
          await BackgroundScheduler.scheduleUpdates();
        }
        if (canEnterMainNav &&
            BackgroundScheduler.shouldScheduleReminderChecks()) {
          await BackgroundScheduler.scheduleStreakReminders();
        }

        if (pendingRefresh) {
          unawaited(_runPendingRefresh(runId));
        }
      }
    } catch (e) {
      // The global error handler already logs and reports to Crashlytics.
      // We just need to update the UI state to show the error.
      if (mounted && runId == _initRunId && !_isInitialized) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && !_isInitialized) {
      return _AdminStateScreen(
        icon: Icons.sync_problem_rounded,
        accent: AppTheme.errorRed,
        title: 'Startup Error',
        message: _error!,
        footer: 'Retry initialization to continue into GitWall.',
        primaryActionLabel: 'Try Again',
        onPrimaryAction: () {
          setState(() {
            _error = null;
            _isInitialized = false;
          });
          unawaited(_primeInitialShell());
        },
      );
    }

    if (!_isInitialized) {
      return const _BootstrapLaunchScreen();
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

    return const GitHubConnectPage();
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
      ContributionRepository.dispose();
    }
  }
}

class _AdminStateScreen extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String message;
  final String footer;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;

  const _AdminStateScreen({
    required this.icon,
    required this.accent,
    required this.title,
    required this.message,
    required this.footer,
    this.primaryActionLabel,
    this.onPrimaryAction,
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
                    if (primaryActionLabel != null &&
                        onPrimaryAction != null) ...[
                      AppTheme.h20,
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: onPrimaryAction,
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: scheme.onPrimary,
                            minimumSize: const Size.fromHeight(52),
                          ),
                          child: Text(primaryActionLabel!),
                        ),
                      ),
                    ],
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

class _BootstrapLaunchScreen extends StatelessWidget {
  const _BootstrapLaunchScreen();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.darkBg,
      child: Center(
        child: Image.asset(
          'assets/logo.png',
          width: 112,
          height: 112,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
