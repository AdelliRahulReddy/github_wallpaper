// 🛠️ UTILITIES - Optimized
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:async'; // Added for Timer
import 'app_exceptions.dart';
import 'app_theme.dart';
final messengerKey = GlobalKey<ScaffoldMessengerState>();

// ERROR HANDLING
class ErrorHandler {
  static String getUserFriendlyMessage(dynamic e) {
    if (e is NetworkException ||
        e is SocketException ||
        e.toString().contains('socket')) {
      return AppStrings.errorNetwork;
    }
    if (e is TokenExpiredException || e.toString().contains('401')) {
      return AppStrings.errorInvalidToken;
    }
    if (e is AccessDeniedException || e.toString().contains('403')) {
      return 'Access denied';
    }
    if (e is UserNotFoundException) return AppStrings.errorUserNotFound;
    if (e is RateLimitException) return AppStrings.errorRateLimit;

    final msg = e.toString().replaceAll('Exception:', '').trim();
    return msg.isNotEmpty ? '${AppStrings.errorGeneric} ($msg)' : AppStrings.errorGeneric;
  }

  static void _showSnackBarSafely({
    required BuildContext? context,
    required SnackBar snackBar,
    bool clearExisting = true,
  }) {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _showSnackBarSafely(
          context: context,
          snackBar: snackBar,
          clearExisting: clearExisting,
        );
      });
      return;
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      final ScaffoldMessengerState? messenger = (context != null && context.mounted)
          ? (ScaffoldMessenger.maybeOf(context) ?? messengerKey.currentState)
          : messengerKey.currentState;

      if (messenger == null || !messenger.mounted) return;

      if (clearExisting) messenger.clearSnackBars();
      messenger.showSnackBar(snackBar);
    });
  }

  static void handle(BuildContext? c, dynamic e,
      {String? userMessage, bool showSnackBar = true, VoidCallback? onRetry}) {
    if (showSnackBar) {
      _showSnackBarSafely(
        context: c,
        snackBar: SnackBar(
          content: Text(userMessage ?? getUserFriendlyMessage(e)),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          action: onRetry != null
              ? SnackBarAction(
                  label: AppStrings.retry,
                  textColor: Colors.white,
                  onPressed: onRetry,
                )
              : null,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  static void showSuccess(BuildContext? c, String m) {
    _showSnackBarSafely(
      context: c,
      snackBar: SnackBar(
        content: Text(m),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }

  static void showLoading(BuildContext c, {String? message}) {
    if (c.mounted) showDialog(context: c, barrierDismissible: false, builder: (_) => PopScope(canPop: false, child: Center(child: Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(), if(message!=null) ...[const SizedBox(height: 16), Text(message)]]))))));
  }

  static void hideLoading(BuildContext c) {
    if (c.mounted && Navigator.canPop(c)) Navigator.of(c, rootNavigator: true).pop();
  }
}

// LOGGING
class AppLog {
  static void info(String m) {
    if (kDebugMode) {
      debugPrint("🟢 [INFO]: $m");
    } else {
      try { FirebaseCrashlytics.instance.log(m); } catch (_) {}
    }
  }

  // Sanitize sensitive data from error messages
  static String _sanitizeError(String msg) {
    return msg
      .replaceAll(RegExp(r'ghp_[a-zA-Z0-9_]+'), '[REDACTED_TOKEN]')
      .replaceAll(RegExp(r'gho_[a-zA-Z0-9_]+'), '[REDACTED_TOKEN]')
      .replaceAll(RegExp(r'ghu_[a-zA-Z0-9_]+'), '[REDACTED_TOKEN]')
      .replaceAll(RegExp(r'ghs_[a-zA-Z0-9_]+'), '[REDACTED_TOKEN]')
      .replaceAll(RegExp(r'ghr_[a-zA-Z0-9_]+'), '[REDACTED_TOKEN]')
      .replaceAll(RegExp(r'Bearer\s+\S+'), 'Bearer [REDACTED]')
      .replaceAll(RegExp(r'Authorization:\s*\S+'), 'Authorization: [REDACTED]')
      .replaceAll(RegExp(r'token\s*=\s*[^\s&]+', caseSensitive: false), 'token=[REDACTED]');
  }

  static void error(dynamic e, [StackTrace? s]) {
    if (kDebugMode) {
      debugPrint("🔴 [ERROR]: $e");
    }
    // Note: Crashlytics reporting moved to main.dart to include consent check
    // This method only sanitizes for debug logging
  }
}

// DEBOUNCER
class Debouncer {
  final Duration delay;
  Timer? _t;
  Debouncer({required this.delay});
  void run(VoidCallback action) {
    _t?.cancel();
    _t = Timer(delay, action);
  }
  void dispose() => _t?.cancel();
}

// VALIDATION
class ValidationUtils {
  static final _usernameRegex = RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9-]{0,37}[a-zA-Z0-9])?$');
  static final _tokenRegex = RegExp(r'^(ghp_|github_pat_|gho_|ghu_|ghs_|ghr_)[a-zA-Z0-9_]{10,}$');
  static final _phoneCleanRegex = RegExp(r'[^\d]');
  static const _reservedUsernames = ['admin', 'api', 'www', 'github', 'support', 'blog', 'about'];

  static String? username(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final clean = v.trim().toLowerCase();
    if (clean.length < 2) return 'Username too short (min 2 characters)';
    if (v.length > AppConstants.usernameMaxLength) return 'Too long';
    if (_reservedUsernames.contains(clean)) return 'Reserved username';
    if (v.contains('--') || !_usernameRegex.hasMatch(v)) return 'Invalid format';
    return null;
  }

  static String? token(String? v) => (v == null || !_tokenRegex.hasMatch(v.trim())) ? 'Invalid token' : null;
  
  static String? quote(String? v) =>
      (v != null && v.length > AppConstants.quoteMaxLength) ? 'Too long' : null;
  
  /// Sanitize custom quote to prevent control characters and injection
  static String sanitizeQuote(String input) {
    return input
        .replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '') // Remove control chars
        .replaceAll(RegExp(r'[<>{}]'), '') // Prevent injection
        .trim();
  }

  static String cleanPhone(String original) => original.replaceAll(_phoneCleanRegex, '');
}

// BACKWARD COMPAT (Deprecate later)
String? isValidUsernameFormat(String? v) => ValidationUtils.username(v);
String? isValidTokenFormat(String? v) => ValidationUtils.token(v);
String? isValidQuoteFormat(String? v) => ValidationUtils.quote(v);



// CONSTANTS & STRINGS
class AppStrings {
  static const appName = 'GitWall';
  static const appTagline = 'Your Code Journey, Visualized';
  static const onboardingTitle1 = 'Beautiful Contributions';
  static const onboardingDesc1 = 'Turn your GitHub contribution graph into aesthetic wallpapers for your Home and Lock screen.';
  static const onboardingTitle2 = 'Always Updated';
  static const onboardingDesc2 = 'Your wallpaper updates automatically in the background. Keep your coding streak visible!';
  static const onboardingTitle3 = 'Built by Developer';
  static const onboardingDesc3 = 'Loved the app? Reach out for support or just to say hi. Built with ❤️ by Rahulreddy.';
  static const connectGitHub = 'Connect GitHub';
  static const connectAccount = 'Connect Account';
  static const backToIntro = 'Back to Introduction';
  static const username = 'GitHub Username';
  static const token = 'Personal Access Token';
  static const needToken = 'Need a token? ';
  static const createHere = 'Create one here →';
  static const skip = 'Skip';
  static const next = 'Next';
  static const getStarted = 'Get Started';
  static const apply = 'Apply';
  static const cancel = 'Cancel';
  static const retry = 'Retry';
  static const save = 'Save';
  static const logout = 'Logout';
  static const clearCache = 'Clear Cache';
  static const statusInitializing = 'Initializing...';
  static const statusLoadingResources = 'Loading resources...';
  static const statusSettingUp = 'Setting up workspace...';
  static const statusAlmostReady = 'Almost ready...';
  static const statusLaunching = 'Launching...';
  static const settingUpWorkspace = 'Setting up your workspace...';
  static const generatingWallpaper = 'Generating wallpaper...';
  static const applyingWallpaper = 'Applying wallpaper...';
  static const refreshingData = 'Refreshing data...';
  static const wallpaperApplied = 'Wallpaper applied successfully!';
  static const wallpaperGenerated = 'Wallpaper image generated successfully';
  static const dataSynced = 'Data synced successfully';
  static const credentialsMissing = 'Credentials missing. Please login again.';
  static const settingsSaved = 'Settings saved';
  static const cacheCleared = 'Cache cleared successfully';
  static const errorGeneric = 'Something went wrong. Please try again.';
  static const errorNetwork = 'No internet connection';
  static const errorInvalidToken = 'Invalid GitHub token';
  static const errorUserNotFound = 'GitHub user not found';
  static const errorRateLimit = 'API rate limit exceeded';
  static const errorStorageInit = 'Failed to initialize local storage.\nPlease restart the app.';
  static const errorAppInit = 'Initialization Error';
  static const errorContextInit = 'Context-dependent initialization failed';
  static const supportEmail = 'adellirahulreddy@gmail.com';
  static const supportPhone = '+91 7032784208';
  static const supportFeedback = 'SUPPORT & FEEDBACK';
  static const developer = 'DEVELOPED BY';
  static const developerName = 'Adelli Rahulreddy';
  static const developerTagline = 'Building tools for developers';
  static const appVersion = '1.0.1';
  static const privacyPolicyUrl = 'https://adellirahulreddy.github.io/github_wallpaper/privacy_policy.html';
  static const whatsAppUrlScheme = 'https://wa.me/';
  static const defaultDeviceName = 'Mobile Device';
}

class AppConstants {
  static const double defaultWallpaperScale = 0.7, defaultWallpaperOpacity = 1.0, defaultCornerRadius = 2.0;
  static const double defaultWallpaperWidth = 1080.0, defaultWallpaperHeight = 1920.0, defaultPixelRatio = 1.0;
  static const double heatmapBoxSize = 15.0, heatmapBoxSpacing = 3.0, horizontalBuffer = 32.0;
  static const int heatmapWeeks = 53, heatmapDaysPerWeek = 7, heatmapTotalDays = 371, dashboardHeatmapDays = 180;
  static const int githubDataFetchDays = 370, minCachedContributionDays = 90;
  static const int pendingRefreshDebounceMinutes = 2, refreshCooldownMinutes = 15, resumeSyncThresholdMinutes=30, backgroundSyncThresholdHours=1;
  static const Duration cacheExpiry = Duration(hours: 6), apiTimeout = Duration(seconds: 30);
  static const String keyToken = 'gh_token', keyUsername = 'username', keyCachedData = 'cached_data_v2', keyWallpaperConfig = 'wp_config_v2';
  static const String keyCachedDataSensitive = 'cached_data_sensitive_v1'; // ✅ Encrypted sensitive cache
  static const String keyIncludePrivateRepos = 'include_private_repos_v1'; // ✅ User preference
  static const String keyCrashlyticsConsent = 'crashlytics_consent_v1'; // ✅ GDPR consent
  static const String keyLastBackgroundSync = 'last_bg_sync';
  static const String keyLastUpdate = 'last_update', keyAutoUpdate = 'auto_update', keyOnboarding='onboarding', keyWallpaperHash = 'wp_hash', keyWallpaperPath = 'wp_path', keyHasSeenDashboard = 'has_seen_dashboard';
  static const String keyHasAppliedWallpaper = 'has_applied_wallpaper';
  static const String keyFirstLoginGreetingPending = 'first_login_greeting_pending';
  static const String keyDimensionWidth='dim_w', keyDimensionHeight='dim_h', keyDimensionPixelRatio='dim_pr', keyDeviceModel='device_model';
  static const String keySafeInsetTop='safe_top', keySafeInsetBottom='safe_bottom', keySafeInsetLeft='safe_left', keySafeInsetRight='safe_right';
  static const String fcmTopicDailyUpdates = 'daily-updates';
  static const List<String> weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const String fallbackWeekday = 'None';
  static const String apiUrl = 'https://api.github.com/graphql';
  static const int intensity1 = 3, intensity2 = 6, intensity3 = 9, usernameMaxLength = 39, quoteMaxLength = 200, monthGridColumns = 7;
  static const double deviceClockBufferHeightFraction = 0.15, deviceClockBufferMinPx = 120.0, deviceClockBufferMaxPx = 300.0;
  static const double minWallpaperScale = 0.1, maxWallpaperScale = 10.0;
  static const int wallpaperScaleDivisions = 40;
  static bool isValidContributionLevel(int l) => l >= 0 && l <= 4;
}

enum RefreshSkipReason { noChanges, throttled, networkError, authError }

class RefreshDecision {
  final bool shouldProceed; final RefreshSkipReason? skipReason;
  const RefreshDecision.proceed() : shouldProceed = true, skipReason = null;
  const RefreshDecision.skip(this.skipReason) : shouldProceed = false;
}

class RefreshPolicy {
  static RefreshDecision shouldRefresh({required bool isBackground, required bool isAndroid, required bool autoUpdateEnabled, required bool hasPendingRefresh, DateTime? lastUpdate, String? username, String? token, bool hasConnectivity = true, DateTime? now}) {
    if (!isAndroid && isBackground) return const RefreshDecision.skip(RefreshSkipReason.noChanges);
    final nowUtc = (now ?? DateTime.now()).toUtc();
    if (hasPendingRefresh &&
        lastUpdate != null &&
        nowUtc.difference(lastUpdate.toUtc()).inMinutes <
            AppConstants.pendingRefreshDebounceMinutes) {
      return const RefreshDecision.skip(RefreshSkipReason.noChanges);
    }
    if (!autoUpdateEnabled && isBackground) return const RefreshDecision.skip(RefreshSkipReason.noChanges);
    if (isBackground &&
        lastUpdate != null &&
        nowUtc.difference(lastUpdate.toUtc()).inMinutes <
            AppConstants.refreshCooldownMinutes) {
      return const RefreshDecision.skip(RefreshSkipReason.throttled);
    }
    if (!hasConnectivity) return const RefreshDecision.skip(RefreshSkipReason.networkError);
    if (username == null ||
        token == null ||
        username.trim().isEmpty ||
        token.trim().isEmpty) {
      return const RefreshDecision.skip(RefreshSkipReason.authError);
    }
    return const RefreshDecision.proceed();
  }
}

// RENDER UTILS
class RenderUtils {
  static final _rc = <String, ui.Radius>{};
  static const _months = [
    'JANUARY',
    'FEBRUARY',
    'MARCH',
    'APRIL',
    'MAY',
    'JUNE',
    'JULY',
    'AUGUST',
    'SEPTEMBER',
    'OCTOBER',
    'NOVEMBER',
    'DECEMBER'
  ];
  
  static String headerTextForDate(DateTime d) =>
      '${_months[d.month - 1]} ${d.year}';

  static TextPainter drawText(ui.Canvas canvas, String text, TextStyle style, Offset offset, double maxWidth, {TextAlign textAlign = TextAlign.left, TextDirection textDirection = TextDirection.ltr, int? maxLines, bool paint = true}) {
    final tp = TextPainter(text: TextSpan(text: text, style: style), textAlign: textAlign, textDirection: textDirection, maxLines: maxLines)..layout(maxWidth: maxWidth);
    if (paint) {
      double dx = offset.dx;
      if (textAlign == TextAlign.center) dx += (maxWidth - tp.width) / 2;
      if (textAlign == TextAlign.right) dx += maxWidth - tp.width;
      tp.paint(canvas, Offset(dx, offset.dy));
    }
    return tp;
  }

  static Quartiles calculateQuartiles(List<int> counts) {
    final nz = counts.where((c) => c > 0).toList()..sort();
    if (nz.isEmpty) {
      return Quartiles(
          AppConstants.intensity1, AppConstants.intensity2, AppConstants.intensity3);
    }
    int p(double x) => nz[(nz.length * x).ceil().clamp(0, nz.length - 1)];
    final q1 = p(0.25), q2 = p(0.5);
    final t1 = q1 > 0 ? q1 : 1, t2 = q2 > t1 ? q2 : t1 + 1, t3 = p(0.75) > t2 ? p(0.75) : t2 + 1;
    return Quartiles(t1, t2, t3);
  }

  static int getContributionLevel(int c, {Quartiles? quartiles}) {
    if (c == 0) return 0;
    final b = quartiles ??
        Quartiles(
            AppConstants.intensity1, AppConstants.intensity2, AppConstants.intensity3);
    if (c <= b.q1) return 1; if (c <= b.q2) return 2; if (c <= b.q3) return 3; return 4;
  }
  
  static ui.Radius getCachedRadius(double r, double s) => _rc.putIfAbsent('${r}_$s', () => Radius.circular(r * s));
  static void clearCaches() => _rc.clear();
}

class AppDateUtils {
  static String formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime? parseDate(String? s) {
    if (s == null) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s);
    return m != null
        ? DateTime.utc(int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!))
        : DateTime.tryParse(s)?.toUtc();
  }
}

class Quartiles { final int q1, q2, q3; const Quartiles(this.q1, this.q2, this.q3); }
