import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'app_services.dart';
import 'app_theme.dart';
import 'firebase_options.dart';
import 'app_utils.dart';
import 'pages/onboarding_page.dart';
import 'pages/main_nav_page.dart';
import 'pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 5. SystemChrome Configuration Timing: Set early to avoid flash of unstyled UI
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
      title: AppStrings.appName,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system,
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
  bool _storageReady = false;
  bool _firebaseReady = false;
  bool _firebaseServicesReady = false;

  bool _isInitialized = false;
  bool _isLoggedIn = false;
  String? _error;
  double _initProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _startInitialization();
  }

  Future<void> _startInitialization() async {
    final startTime = DateTime.now();
    try {
      Object? storageError;
      StackTrace? storageStack;

      if (!_storageReady) {
        try {
          await StorageService.init().timeout(const Duration(seconds: 10));
          _storageReady = true;
          if (mounted) setState(() => _initProgress = 0.3);
        } catch (e, stack) {
          storageError = e;
          storageStack = stack;
          _storageReady = false;
        }
      }

      if (!_firebaseReady) {
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          ).timeout(const Duration(seconds: 15));
          _firebaseReady = true;
          if (mounted) setState(() => _initProgress = 0.6);

          await FirebaseCrashlytics.instance
              .setCrashlyticsCollectionEnabled(!kDebugMode);

          FlutterError.onError =
              FirebaseCrashlytics.instance.recordFlutterFatalError;
        } catch (_) {}
      }

      if (!_storageReady) {
        if (_firebaseReady && storageError != null) {
          await FirebaseCrashlytics.instance.recordError(
            storageError,
            storageStack,
            reason: 'Storage init failed during boot',
            fatal: true,
          );
        }
        throw storageError ?? Exception('Storage initialization failed');
      }

      if (_firebaseReady && !_firebaseServicesReady) {
        await _initFirebaseServices();
        _firebaseServicesReady = true;
        if (mounted) setState(() => _initProgress = 0.8);
      }

      // 2 & 3. Remove delay and add timeout to AppConfig
      await AppConfig.initializeFromPlatformDispatcher().timeout(const Duration(seconds: 2), onTimeout: (){});

      final loggedIn = StorageService.isOnboardingComplete();
      final pendingWallpaperRefresh =
          loggedIn && StorageService.hasPendingWallpaperRefresh();

      // Ensure minimum splash duration of 4 seconds
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < const Duration(seconds: 4)) {
        await Future.delayed(const Duration(seconds: 4) - elapsed);
      }

      if (mounted) {
        setState(() {
          _initProgress = 1.0;
          _isLoggedIn = loggedIn;
          _isInitialized = true;
        });
      }

      if (pendingWallpaperRefresh) {
        unawaited(() async {
          await StorageService.consumePendingWallpaperRefresh();
          await WallpaperService.refreshWallpaper();
        }());
      }
    } catch (e) {

      if (mounted) {
        final friendlyMsg = ErrorHandler.getUserFriendlyMessage(e);
        setState(() => _error = friendlyMsg);
      }

      // 3. Unsafe Firebase Service Calls: Verify readiness before recording
      if (_firebaseReady) {
        FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
      }
    }
  }

  Future<void> _initFirebaseServices() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    // 2. App Check Initialization Order
    try {
      await FirebaseAppCheck.instance.activate(
        // ignore: deprecated_member_use
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        // ignore: deprecated_member_use
        appleProvider:
            kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      // debugPrint('AppCheck init failed: $e');
      // Non-fatal, allow app to start even if AppCheck fails (might limit API access but UI should load)
    }

    try {
      await FcmService.init().timeout(const Duration(seconds: 5));
    } catch (e) {
      // debugPrint('FCM init failed: $e');
      // FCM is optional, do not block app start
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return SplashScreen(
        progress: _initProgress,
        error: _error,
        onRetry: () {
          setState(() {
            _error = null;
            _initProgress = 0.0;
            _isInitialized = false;
            _firebaseServicesReady = false;
          });
          _startInitialization();
        },
      );
    }

    if (!_isInitialized) {
      return SplashScreen(progress: _initProgress);
    }

    return _isLoggedIn ? const MainNavPage() : const OnboardingPage();
  }
}
