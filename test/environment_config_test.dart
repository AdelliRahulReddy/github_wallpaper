import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/core/constants/environment_config.dart';
import 'package:github_wallpaper/core/errors/app_exceptions.dart';

void main() {
  group('AppConfig OAuth validation', () {
    test('accepts the configured redirect URI', () {
      expect(
        () => AppConfig.validateOAuthConfig(
          registeredRedirectUri: AppConfig.redirectUri,
        ),
        returnsNormally,
      );
    });

    test('rejects a mismatched registered redirect URI', () {
      expect(
        () => AppConfig.validateOAuthConfig(
          registeredRedirectUri: 'gitwall://wrong/callback',
        ),
        throwsA(isA<GitHubException>()),
      );
    });

    test('uses a valid HTTPS code exchange URL', () {
      final uri = Uri.parse(AppConfig.githubCodeExchangeUrl);

      expect(uri.isAbsolute, isTrue);
      expect(uri.scheme, 'https');
      expect(uri.host, isNotEmpty);
    });

    test('centralizes the Play Store listing URL', () {
      final listing = AppConfig.playStoreListingUri('com.example.gitwall');

      expect(
        listing.toString(),
        'https://play.google.com/store/apps/details?id=com.example.gitwall',
      );
    });
  });
}
