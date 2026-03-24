import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'package:github_wallpaper/core/constants/firebase_options.dart';
import 'package:github_wallpaper/core/errors/app_exceptions.dart';
import 'package:github_wallpaper/features/wallpaper/services/device_config_service.dart';
import 'package:github_wallpaper/features/auth/services/oauth_service.dart';
import 'package:github_wallpaper/app/services/remote_config_service.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/app/services/notification_service.dart';
import 'package:github_wallpaper/features/contributions/services/daily_quotes.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';

class BootstrapService {
  static Future<bool> boot({
    required Function(double) onProgress,
    required Function(String) onError,
  }) async {
    try {
      await StorageService.init().timeout(const Duration(seconds: 10));
      onProgress(0.1);

      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 15));
      }
      onProgress(0.3);

      await _ensureFirebaseSession();

      await RemoteConfigService().init();
      onProgress(0.5);

      if (await StorageService.hasAuthenticatedSession()) {
        final cachedData = StorageService.getCachedData();
        if (cachedData != null) {
          unawaited(DailyQuoteService.ensureDailyQuote(data: cachedData));
        }
      }
      onProgress(0.53);

      await NotificationService.init();
      onProgress(0.55);
      unawaited(NotificationService.initPushMessaging());

      final crashlyticsConsent = StorageService.getCrashlyticsConsent();
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode && crashlyticsConsent,
      );
      onProgress(0.6);
      onProgress(0.8);

      await DeviceConfigService.initializeFromPlatformDispatcher()
          .timeout(const Duration(seconds: 2), onTimeout: () {});
      onProgress(1.0);
      return true;
    } catch (e, stack) {
      AppLog.error(e, stack);
      onError(
          ErrorHandler.getUserFriendlyMessage(e) ?? AppStrings.errorGeneric);
      return false;
    }
  }

  static Future<void> _ensureFirebaseSession() async {
    final auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;
    if (currentUser != null && !currentUser.isAnonymous) {
      await StorageService.syncAuthenticatedAppUserId(user: currentUser);
      return;
    }

    final hasStoredSession = await StorageService.hasAuthenticatedSession();
    if (hasStoredSession) {
      final token = await StorageService.getToken();
      if (token != null && token.trim().isNotEmpty) {
        try {
          final session =
              await OAuthService.restoreFirebaseSessionFromStoredToken(token);
          await StorageService.syncAuthenticatedAppUserId();
          await StorageService.setUsername(session.username);
          await StorageService.setUserEmail(session.email);
          await StorageService.setHasAuthError(false);
          return;
        } catch (e, s) {
          AppLog.error('Firebase session restore failed: $e', s);
          if (_isPermanentRestoreFailure(e)) {
            await StorageService.setHasAuthError(true);
          }
        }
      }
    }

    if (auth.currentUser == null) {
      try {
        await auth.signInAnonymously();
      } catch (_) {}
    }
  }

  static bool _isPermanentRestoreFailure(dynamic error) {
    if (error is TokenExpiredException || error is AccessDeniedException) {
      return true;
    }

    if (error is GitHubException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return true;
      }

      final message = error.message.toLowerCase();
      return message.contains('gitHub request failed (401)'.toLowerCase()) ||
          message.contains('gitHub request failed (403)'.toLowerCase()) ||
          message.contains('token expired') ||
          message.contains('token invalid') ||
          message.contains('bad credentials');
    }

    return false;
  }
}

