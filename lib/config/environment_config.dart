import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:github_wallpaper/exceptions/app_exceptions.dart';

class AppConfig {
  static const String _revenueCatApiKey =
      String.fromEnvironment('REVENUECAT_API_KEY', defaultValue: '');
  static const String _revenueCatApiKeyAlt =
      String.fromEnvironment('revenueCatApiKey', defaultValue: '');
  static const String _revenueCatApiKeyAndroid =
      String.fromEnvironment('REVENUECAT_API_KEY_ANDROID', defaultValue: '');
  static const String _revenueCatApiKeyAndroidAlt =
      String.fromEnvironment('revenueCatApiKeyAndroid', defaultValue: '');
  static const String _revenueCatApiKeyIos =
      String.fromEnvironment('REVENUECAT_API_KEY_IOS', defaultValue: '');
  static const String _revenueCatApiKeyIosAlt =
      String.fromEnvironment('revenueCatApiKeyIos', defaultValue: '');

  static const String _debugRevenueCatApiKeyAndroid =
      'goog_uOrOeEbviaYqcfNwfGcyRGQvxiU';

  static String get revenueCatApiKey {
    if (Platform.isAndroid) {
      if (_revenueCatApiKeyAndroid.isNotEmpty) return _revenueCatApiKeyAndroid;
      if (_revenueCatApiKeyAndroidAlt.isNotEmpty) {
        return _revenueCatApiKeyAndroidAlt;
      }
    }
    if (Platform.isIOS) {
      if (_revenueCatApiKeyIos.isNotEmpty) return _revenueCatApiKeyIos;
      if (_revenueCatApiKeyIosAlt.isNotEmpty) return _revenueCatApiKeyIosAlt;
    }
    if (_revenueCatApiKey.isNotEmpty) return _revenueCatApiKey;
    if (_revenueCatApiKeyAlt.isNotEmpty) return _revenueCatApiKeyAlt;
    if (kDebugMode && Platform.isAndroid) return _debugRevenueCatApiKeyAndroid;
    return '';
  }

  static const String githubClientId = String.fromEnvironment(
    'GITHUB_CLIENT_ID',
    defaultValue: '',
  );
  static const String redirectUri = String.fromEnvironment(
    'GITHUB_REDIRECT_URI',
    defaultValue: 'gitwall://oauth/callback',
  );
  static const String githubClientSecret = String.fromEnvironment(
    'GITHUB_CLIENT_SECRET',
    defaultValue: '',
  );
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static void validateOAuthConfig({String? registeredRedirectUri}) {
    const id = githubClientId;
    const secret = githubClientSecret;
    const loadedRedirectUri = redirectUri;

    if (id.isEmpty) {
      throw GitHubException(
        'Missing GitHub OAuth Configuration',
        details: 'GITHUB_CLIENT_ID environment variable is not set.',
      );
    }
    if (secret.isEmpty) {
      throw GitHubException(
        'Missing GitHub OAuth Configuration',
        details: 'GITHUB_CLIENT_SECRET environment variable is not set. '
            'This is required for token exchange.',
      );
    }
    if (loadedRedirectUri.isEmpty) {
      throw GitHubException(
        'Missing GitHub OAuth Configuration',
        details: 'GITHUB_REDIRECT_URI environment variable is not set. '
            'Default value is gitwall://oauth/callback.',
      );
    }

    // Validate registered redirect URI match if provided
    if (registeredRedirectUri != null &&
        registeredRedirectUri.trim().isNotEmpty &&
        loadedRedirectUri != registeredRedirectUri.trim()) {
      throw GitHubException(
        'GitHub Redirect URI Mismatch',
        details: 'The configured GITHUB_REDIRECT_URI ($loadedRedirectUri) does '
            'not match the registered URI ($registeredRedirectUri) in GitHub Settings.',
      );
    }
  }
}
