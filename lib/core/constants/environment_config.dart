import 'package:github_wallpaper/core/errors/app_exceptions.dart';

class AppConfig {
  static const String firebaseProjectId = 'gitwall-d63cc';
  static const String firebaseFunctionsRegion = 'us-central1';
  static const String playStoreSubscriptionsUrl = String.fromEnvironment(
    'PLAY_STORE_SUBSCRIPTIONS_URL',
    defaultValue: 'https://play.google.com/store/account/subscriptions',
  );
  static const String githubClientId = String.fromEnvironment(
    'GITHUB_CLIENT_ID',
    defaultValue: 'Ov23liLsYG4d5Xiv10H6',
  );
  static const String redirectUri = String.fromEnvironment(
    'GITHUB_REDIRECT_URI',
    defaultValue: 'gitwall://oauth/callback',
  );
  static const String githubCodeExchangeUrl = String.fromEnvironment(
    'GITHUB_CODE_EXCHANGE_URL',
    defaultValue:
        'https://us-central1-gitwall-d63cc.cloudfunctions.net/exchangeGitHubCode',
  );
  static const String adminBroadcastAckUrl = String.fromEnvironment(
    'ADMIN_BROADCAST_ACK_URL',
    defaultValue:
        'https://us-central1-gitwall-d63cc.cloudfunctions.net/ackAdminBroadcastEvent',
  );
  static const String clientLogIngestUrl = String.fromEnvironment(
    'CLIENT_LOG_INGEST_URL',
    defaultValue:
        'https://us-central1-gitwall-d63cc.cloudfunctions.net/ingestClientLog',
  );
  static const String couponRedeemUrl = String.fromEnvironment(
    'COUPON_REDEEM_URL',
    defaultValue:
        'https://us-central1-gitwall-d63cc.cloudfunctions.net/redeemCouponCode',
  );
  static const String revenueCatGooglePublicKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_PUBLIC_KEY',
    defaultValue: 'goog_uOrOeEbviaYqcfNwfGcyRGQvxiU',
  );
  static const String revenueCatProEntitlementId = String.fromEnvironment(
    'REVENUECAT_PRO_ENTITLEMENT_ID',
    defaultValue: 'pro',
  );
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  static const String supportUsUrl = String.fromEnvironment(
    'SUPPORT_US_URL',
    defaultValue: 'https://buymeacoffee.com/',
  );

  static Uri playStoreListingUri(String packageName) => Uri.https(
        'play.google.com',
        '/store/apps/details',
        {'id': packageName},
      );

  static Uri get playStoreSubscriptionsUri =>
      Uri.parse(playStoreSubscriptionsUrl);

  static void validateOAuthConfig({String? registeredRedirectUri}) {
    const id = githubClientId;
    const loadedRedirectUri = redirectUri;
    const exchangeUrl = githubCodeExchangeUrl;

    if (id.isEmpty || id.startsWith('YOUR_')) {
      throw GitHubException(
        'Missing GitHub OAuth Configuration',
        details:
            'Please provide GITHUB_CLIENT_ID via dart-define or update the safe app config default.',
      );
    }
    if (loadedRedirectUri.isEmpty) {
      throw GitHubException(
        'Missing GitHub OAuth Configuration',
        details: 'GITHUB_REDIRECT_URI environment variable is not set. '
            'Default value is gitwall://oauth/callback.',
      );
    }
    final parsedExchangeUrl = Uri.tryParse(exchangeUrl);
    if (parsedExchangeUrl == null ||
        !parsedExchangeUrl.isAbsolute ||
        (parsedExchangeUrl.scheme != 'https' &&
            parsedExchangeUrl.scheme != 'http')) {
      throw GitHubException(
        'Missing GitHub OAuth Configuration',
        details:
            'GITHUB_CODE_EXCHANGE_URL must point to your deployed HTTPS Cloud Function.',
      );
    }

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
