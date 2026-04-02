import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:github_wallpaper/core/errors/app_exceptions.dart';
import 'package:github_wallpaper/features/auth/services/oauth_service.dart';

void main() {
  group('OAuthSession.fromExchangePayload', () {
    test('parses a successful exchange payload', () {
      final session = OAuthSession.fromExchangePayload({
        'accessToken': 'gho_123',
        'username': 'octocat',
        'email': 'octocat@example.com',
        'firebaseCustomToken': 'firebase-token',
        'internalUserId': 'gw_usr_abcdefghijklmnopqrstuvwx',
      });

      expect(session.accessToken, 'gho_123');
      expect(session.username, 'octocat');
      expect(session.email, 'octocat@example.com');
      expect(session.firebaseCustomToken, 'firebase-token');
      expect(session.internalUserId, 'gw_usr_abcdefghijklmnopqrstuvwx');
    });

    test('throws when access token is missing', () {
      expect(
        () => OAuthSession.fromExchangePayload({
          'username': 'octocat',
          'firebaseCustomToken': 'firebase-token',
        }),
        throwsA(isA<GitHubException>()),
      );
    });

    test('throws when firebase custom token is missing', () {
      expect(
        () => OAuthSession.fromExchangePayload({
          'accessToken': 'gho_123',
          'username': 'octocat',
        }),
        throwsA(isA<GitHubException>()),
      );
    });
  });

  group('OAuthService.validateExchangeEndpointResponse', () {
    test('accepts deployed exchange endpoint preflight response', () {
      expect(
        () => OAuthService.validateExchangeEndpointResponse(
          http.Response(
            '{"message":"authorizationCode, codeVerifier, and redirectUri are required"}',
            400,
          ),
        ),
        returnsNormally,
      );
    });

    test('throws a clear error when exchange endpoint is missing', () {
      expect(
        () => OAuthService.validateExchangeEndpointResponse(
          http.Response('<html><title>404</title></html>', 404),
        ),
        throwsA(
          isA<GitHubException>().having(
            (e) => e.message,
            'message',
            'GitHub sign-in server is not deployed',
          ),
        ),
      );
    });

    test('throws a clear error when OAuth secrets are missing', () {
      expect(
        () => OAuthService.validateExchangeEndpointResponse(
          http.Response(
            '{"message":"GitHub OAuth secrets are not configured"}',
            500,
          ),
        ),
        throwsA(
          isA<GitHubException>().having(
            (e) => e.message,
            'message',
            'GitHub sign-in server is missing OAuth secrets',
          ),
        ),
      );
    });
  });
}
