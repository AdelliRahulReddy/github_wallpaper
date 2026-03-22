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

  // TODO: Replace with your own GitHub OAuth App credentials for local development.
  // 1. Create a GitHub OAuth App: https://github.com/settings/developers
  // 2. Use 'gitwall://oauth/callback' as the Authorization callback URL.
  // 3. Paste your Client ID and Client Secret below.
  // NOTE: Do not commit these credentials to version control.
  static const String githubClientId = 'YOv23liLsYG4d5Xiv10H6';

  static const String redirectUri = 'gitwall://oauth/callback';

  static const String githubClientSecret =
      '4a271d9c1b20fc012f3ff90a0bcc3593ffea8b73';
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static void validateOAuthConfig({String? registeredRedirectUri}) {
    const id = githubClientId;
    const secret = githubClientSecret;
    const loadedRedirectUri = redirectUri;

    if (id.isEmpty || id.startsWith('YOUR_')) {
      throw GitHubException(
        'Missing GitHub OAuth Configuration',
        details:
            'Please set your GITHUB_CLIENT_ID in lib/config/environment_config.dart',
      );
    }
    if (secret.isEmpty || secret.startsWith('YOUR_')) {
      throw GitHubException(
        'Missing GitHub OAuth Configuration',
        details:
            'Please set your GITHUB_CLIENT_SECRET in lib/config/environment_config.dart. '
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
