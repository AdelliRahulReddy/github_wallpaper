import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;

import 'package:github_wallpaper/core/errors/app_exceptions.dart';
import 'package:github_wallpaper/core/constants/environment_config.dart'
    as app_config;

class OAuthSession {
  final String accessToken;
  final String username;
  final String? email;
  final String firebaseCustomToken;
  final String internalUserId;
  final String? githubProviderId;

  const OAuthSession({
    required this.accessToken,
    required this.username,
    required this.email,
    required this.firebaseCustomToken,
    required this.internalUserId,
    required this.githubProviderId,
  });

  factory OAuthSession.fromExchangePayload(Map<String, dynamic> payload) {
    final accessToken = payload['accessToken']?.toString().trim() ?? '';
    final username = payload['username']?.toString().trim() ?? '';
    final firebaseCustomToken =
        payload['firebaseCustomToken']?.toString().trim() ?? '';
    final rawEmail = payload['email']?.toString().trim();
    final internalUserId = payload['internalUserId']?.toString().trim() ?? '';
    final githubProviderId = payload['githubProviderId']?.toString().trim();

    if (accessToken.isEmpty) {
      throw GitHubException('GitHub token missing from exchange response');
    }
    if (username.isEmpty) {
      throw GitHubException('GitHub username missing from exchange response');
    }
    if (firebaseCustomToken.isEmpty) {
      throw GitHubException(
        'Firebase custom token missing from exchange response',
      );
    }
    if (internalUserId.isEmpty) {
      throw GitHubException(
        'Canonical GitWall user id missing from exchange response',
      );
    }

    return OAuthSession(
      accessToken: accessToken,
      username: username,
      email: (rawEmail == null || rawEmail.isEmpty) ? null : rawEmail,
      firebaseCustomToken: firebaseCustomToken,
      internalUserId: internalUserId,
      githubProviderId: (githubProviderId == null || githubProviderId.isEmpty)
          ? null
          : githubProviderId,
    );
  }
}

class OAuthService {
  static const _authEndpoint = 'https://github.com/login/oauth/authorize';
  static const _tokenEndpoint = 'https://github.com/login/oauth/access_token';
  static const _exchangeTimeout = Duration(seconds: 20);
  static const _warmupTtl = Duration(minutes: 5);
  static final FlutterAppAuth _appAuth = FlutterAppAuth();
  static Future<void>? _exchangeWarmup;
  static DateTime? _exchangeReadyAt;

  static Future<OAuthSession> signInWithGitHub() async {
    app_config.AppConfig.validateOAuthConfig();
    if (!_hasFreshExchangeWarmup) {
      unawaited(prewarmExchangeEndpoint().catchError((_) {}));
    }

    const githubClientId = app_config.AppConfig.githubClientId;
    const redirectUri = app_config.AppConfig.redirectUri;
    final AuthorizationResponse response = await _appAuth.authorize(
      AuthorizationRequest(
        githubClientId.trim(),
        redirectUri.trim(),
        serviceConfiguration: const AuthorizationServiceConfiguration(
          authorizationEndpoint: _authEndpoint,
          tokenEndpoint: _tokenEndpoint,
        ),
        scopes: const ['read:user', 'user:email'],
      ),
    );

    final authorizationCode = response.authorizationCode?.trim();
    if (authorizationCode == null || authorizationCode.isEmpty) {
      throw GitHubException('Authorization code missing from GitHub response');
    }

    final codeVerifier = response.codeVerifier?.trim();
    if (codeVerifier == null || codeVerifier.isEmpty) {
      throw GitHubException('PKCE code verifier missing from GitHub response');
    }

    return _exchangeAndSignIn(
      authorizationCode: authorizationCode,
      codeVerifier: codeVerifier,
    );
  }

  static Future<OAuthSession> restoreFirebaseSessionFromStoredToken(
    String accessToken,
  ) {
    final token = accessToken.trim();
    if (token.isEmpty) {
      throw GitHubException('Stored GitHub token is missing');
    }
    return _exchangeAndSignIn(accessToken: token);
  }

  static Future<OAuthSession> _exchangeAndSignIn({
    String? authorizationCode,
    String? codeVerifier,
    String? accessToken,
  }) async {
    final response = await _postExchangeRequest(
      {
        if (authorizationCode != null) 'authorizationCode': authorizationCode,
        if (codeVerifier != null) 'codeVerifier': codeVerifier,
        if (accessToken != null) 'accessToken': accessToken,
        'redirectUri': app_config.AppConfig.redirectUri,
      },
    );

    final session = _parseExchangeResponse(response);
    _exchangeReadyAt = DateTime.now();
    try {
      await FirebaseAuth.instance.signInWithCustomToken(
        session.firebaseCustomToken,
      );
    } on FirebaseAuthException catch (e) {
      throw GitHubException(
        'Failed to create Firebase session',
        details: e.message,
      );
    }
    return session;
  }

  static Future<void> prewarmExchangeEndpoint({bool force = false}) {
    if (!force && _hasFreshExchangeWarmup) {
      return Future<void>.value();
    }

    final inFlight = _exchangeWarmup;
    if (!force && inFlight != null) {
      return inFlight;
    }

    late final Future<void> future;
    future = _verifyExchangeEndpointReady().then((_) {
      _exchangeReadyAt = DateTime.now();
    }).whenComplete(() {
      if (identical(_exchangeWarmup, future)) {
        _exchangeWarmup = null;
      }
    });
    _exchangeWarmup = future;
    return future;
  }

  static bool get _hasFreshExchangeWarmup {
    final readyAt = _exchangeReadyAt;
    if (readyAt == null) return false;
    return DateTime.now().difference(readyAt) < _warmupTtl;
  }

  static Future<void> _verifyExchangeEndpointReady() async {
    final response = await _postExchangeRequest(const {});
    validateExchangeEndpointResponse(response);
  }

  static Future<http.Response> _postExchangeRequest(
    Map<String, dynamic> body,
  ) async {
    try {
      return await http
          .post(
            Uri.parse(app_config.AppConfig.githubCodeExchangeUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(_exchangeTimeout);
    } on SocketException {
      throw NetworkException(
        'Unable to reach the GitHub sign-in server. Check your internet connection.',
      );
    } on TimeoutException {
      throw GitHubException(
        'GitHub sign-in server timed out',
        details:
            'The OAuth exchange service did not respond in time. Check the deployed function URL and server health.',
      );
    } on http.ClientException catch (e) {
      throw NetworkException(e.message);
    }
  }

  @visibleForTesting
  static void validateExchangeEndpointResponse(http.Response response) {
    final payload = _tryDecodeJsonMap(response.body);
    final message = payload?['message']?.toString().trim();
    final details = payload?['details']?.toString().trim();

    final isReadyResponse = response.statusCode == 400 &&
        message ==
            'authorizationCode, codeVerifier, and redirectUri are required';
    if (isReadyResponse) {
      return;
    }

    if (response.statusCode == 404) {
      throw GitHubException(
        'GitHub sign-in server is not deployed',
        statusCode: response.statusCode,
        details:
            'exchangeGitHubCode is missing or GITHUB_CODE_EXCHANGE_URL points to the wrong Firebase project/region.',
      );
    }

    if (response.statusCode == 500 &&
        message == 'GitHub OAuth secrets are not configured') {
      throw GitHubException(
        'GitHub sign-in server is missing OAuth secrets',
        statusCode: response.statusCode,
        details:
            'Set GITHUB_CLIENT_ID and GITHUB_CLIENT_SECRET in Firebase Functions secrets before signing in.',
      );
    }

    if (response.statusCode >= 400) {
      throw GitHubException(
        message?.isNotEmpty == true
            ? message!
            : 'GitHub sign-in server is unavailable',
        statusCode: response.statusCode,
        details: details?.isNotEmpty == true
            ? details
            : _fallbackResponseDetails(response),
      );
    }
  }

  static OAuthSession _parseExchangeResponse(http.Response response) {
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw GitHubException(
        'GitHub sign-in failed',
        statusCode: response.statusCode,
        details: response.body,
      );
    }

    if (response.statusCode != 200) {
      throw GitHubException(
        payload['message']?.toString().trim().isNotEmpty == true
            ? payload['message'].toString().trim()
            : 'GitHub sign-in failed',
        statusCode: response.statusCode,
        details: payload['details']?.toString() ?? response.body,
      );
    }

    return OAuthSession.fromExchangePayload(payload);
  }

  static Map<String, dynamic>? _tryDecodeJsonMap(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static String _fallbackResponseDetails(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) {
      return 'HTTP ${response.statusCode}';
    }
    if (body.length <= 240) {
      return body;
    }
    return '${body.substring(0, 240)}...';
  }
}
