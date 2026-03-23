import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'package:github_wallpaper/core/constants/environment_config.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/data/datasources/local/storage_service.dart';

class TelemetryService {
  static const Set<String> _allowedTypes = {
    'sync_failure',
    'wallpaper_failure',
    'background_job_failure',
    'client_error',
  };

  static Future<void> logError(String type, dynamic error,
      [StackTrace? stack]) async {
    if (!_allowedTypes.contains(type)) {
      if (kDebugMode) {
        AppLog.error('Telemetry: Unsupported error type $type');
      }
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (kDebugMode) {
          AppLog.info('Telemetry: Skipping $type log because no Firebase user exists.');
        }
        return;
      }

      final username = StorageService.getUsername() ?? 'unknown';
      PackageInfo? packageInfo;
      try {
        packageInfo = await PackageInfo.fromPlatform();
      } catch (_) {}
      final idToken = await user.getIdToken();

      final response = await http.post(
        Uri.parse(AppConfig.clientLogIngestUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'type': type,
          'error': SensitiveDataSanitizer.sanitize(error.toString()),
          'stack': stack != null
              ? SensitiveDataSanitizer.sanitize(stack.toString())
              : null,
          'username': username,
          'appVersion': packageInfo?.version ?? 'unknown',
          'buildNumber': packageInfo?.buildNumber ?? 'unknown',
          'platform': _platformLabel(),
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (kDebugMode) {
          AppLog.error(
            'Telemetry ingest failed (${response.statusCode}): ${response.body}',
          );
        }
        return;
      }

      if (kDebugMode) {
        AppLog.info('Telemetry: Logged $type error to backend');
      }
    } catch (e) {
      if (kDebugMode) {
        AppLog.error('Telemetry: Failed to log error: $e');
      }
    }
  }

  static Future<void> logSyncFailure(dynamic error, [StackTrace? stack]) =>
      logError('sync_failure', error, stack);

  static Future<void> logWallpaperFailure(dynamic error, [StackTrace? stack]) =>
      logError('wallpaper_failure', error, stack);

  static Future<void> logBackgroundJobFailure(dynamic error,
          [StackTrace? stack]) =>
      logError('background_job_failure', error, stack);

  static Future<void> logClientError(dynamic error, [StackTrace? stack]) =>
      logError('client_error', error, stack);

  static String _platformLabel() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return defaultTargetPlatform.name;
  }
}
