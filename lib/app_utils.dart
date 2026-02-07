// 🛠️ UTILITIES - Optimized
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:async'; // Added for Timer
import 'app_exceptions.dart';
import 'app_theme.dart';
import 'main.dart';

// ERROR HANDLING
class ErrorHandler {
  static String getUserFriendlyMessage(dynamic e) {
    if (e is NetworkException ||
        e is SocketException ||
        e.toString().contains('socket')) {
      return 'No internet connection.';
    }
    if (e is TokenExpiredException || e.toString().contains('401')) {
      return 'Invalid or expired GitHub token.';
    }
    if (e is AccessDeniedException || e.toString().contains('403')) {
      return 'Access denied.';
    }
    if (e is UserNotFoundException) return 'User not found.';
    if (e is RateLimitException) return 'Rate limit exceeded.';

    final msg = e.toString().replaceAll('Exception:', '').trim();
    return msg.isNotEmpty ? 'Something went wrong. ($msg)' : 'Something went wrong.';
  }

  static void handle(BuildContext? c, dynamic e,
      {String? userMessage, bool showSnackBar = true, VoidCallback? onRetry}) {
    if (showSnackBar) {
      messengerKey.currentState?.clearSnackBars();
      messengerKey.currentState?.showSnackBar(SnackBar(
          content: Text(userMessage ?? getUserFriendlyMessage(e)),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          action: onRetry != null
              ? SnackBarAction(
                  label: 'Retry', textColor: Colors.white, onPressed: onRetry)
              : null,
          duration: const Duration(seconds: 4)));
    }
  }

  static void showSuccess(BuildContext? c, String m) {
    messengerKey.currentState?.clearSnackBars();
    messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(m), backgroundColor: AppTheme.successGreen));
  }

  static void showLoading(BuildContext c, {String? message}) {
    if (c.mounted) showDialog(context: c, barrierDismissible: false, builder: (_) => PopScope(canPop: false, child: Center(child: Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(), if(message!=null) ...[const SizedBox(height: 16), Text(message)]]))))));
  }

  static void hideLoading(BuildContext c) {
    if (c.mounted && Navigator.canPop(c)) Navigator.of(c, rootNavigator: true).pop();
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
// VALIDATION
final _uRgx = RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9-]{0,37}[a-zA-Z0-9])?$');
final _tRgx = RegExp(r'^(ghp_|github_pat_|gho_|ghu_|ghs_|ghr_)[a-zA-Z0-9_]{10,}$');

String? isValidUsernameFormat(String? v) {
  if (v == null || v.trim().isEmpty) return 'Required';
  if (v.length > 39) return 'Too long';
  if (v.contains('--') || !_uRgx.hasMatch(v)) return 'Invalid format';
  return null;
}
String? isValidTokenFormat(String? v) => (v == null || !_tRgx.hasMatch(v.trim())) ? 'Invalid token' : null;
String? isValidQuoteFormat(String? v) => (v!=null && v.length>200) ? 'Too long' : null;



// CONSTANTS & STRINGS
class AppStrings {
  static const appName = 'GitHub Wallpaper';
  static const appTagline = 'Your Code Journey, Visualized';
  static const onboardingTitle1 = 'Beautiful Contributions';
  static const onboardingDesc1 = 'Turn your GitHub contribution graph into aesthetic wallpapers for your Home and Lock screen.';
  static const onboardingTitle2 = 'Always Updated';
  static const onboardingDesc2 = 'Your wallpaper updates automatically in the background. Keep your coding streak visible!';
  static const onboardingTitle3 = 'Built by Developer';
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
  static const settingUpWorkspace = 'Setting up your workspace...';
  static const generatingWallpaper = 'Generating wallpaper...';
  static const applyingWallpaper = 'Applying wallpaper...';
  static const refreshingData = 'Refreshing data...';
  static const wallpaperApplied = 'Wallpaper applied successfully!';
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
  static const supportEmail = 'support@rahulreddy.dev';
  static const supportPhone = '+91 7032784208';
  static const supportFeedback = 'SUPPORT & FEEDBACK';
  static const developer = 'DEVELOPED BY';
  static const developerName = 'Adelli Rahulreddy';
  static const developerTagline = 'Building tools for developers';
  static const appVersion = '1.0.2';
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
  static const String keyLastUpdate = 'last_update', keyAutoUpdate = 'auto_update', keyOnboarding='onboarding', keyWallpaperHash = 'wp_hash', keyWallpaperPath = 'wp_path';
  static const String keyDimensionWidth='dim_w', keyDimensionHeight='dim_h', keyDimensionPixelRatio='dim_pr', keyDeviceModel='device_model';
  static const String keySafeInsetTop='safe_top', keySafeInsetBottom='safe_bottom', keySafeInsetLeft='safe_left', keySafeInsetRight='safe_right';
  static const String fcmTopicDailyUpdates = 'daily-updates';
  static const List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const String fallbackWeekday = 'None';
  static const String apiUrl = 'https://api.github.com/graphql';
  static const int intensity1 = 3, intensity2 = 6, intensity3 = 9, usernameMaxLength = 39, quoteMaxLength = 200, monthGridColumns = 7;
  static const double deviceClockBufferHeightFraction = 0.15, deviceClockBufferMinPx = 120.0, deviceClockBufferMaxPx = 300.0;
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
    if (hasPendingRefresh && lastUpdate != null && nowUtc.difference(lastUpdate.toUtc()).inMinutes < 2) return const RefreshDecision.skip(RefreshSkipReason.noChanges);
    if (!autoUpdateEnabled && isBackground) return const RefreshDecision.skip(RefreshSkipReason.noChanges);
    if (isBackground && lastUpdate != null && nowUtc.difference(lastUpdate.toUtc()).inMinutes < 15) return const RefreshDecision.skip(RefreshSkipReason.throttled);
    if (!hasConnectivity) return const RefreshDecision.skip(RefreshSkipReason.networkError);
    if (username == null || token == null) return const RefreshDecision.skip(RefreshSkipReason.authError);
    return const RefreshDecision.proceed();
  }
}

// RENDER UTILS
class RenderUtils {
  static final _rc = <String, ui.Radius>{};
  
  static String headerTextForDate(DateTime d) => "${['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'][d.month - 1]} ${d.year}";

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
    if (nz.isEmpty) return Quartiles(3, 6, 9);
    int p(double x) => nz[(nz.length * x).ceil().clamp(0, nz.length - 1)];
    final q1 = p(0.25), q2 = p(0.5);
    final t1 = q1 > 0 ? q1 : 1, t2 = q2 > t1 ? q2 : t1 + 1, t3 = p(0.75) > t2 ? p(0.75) : t2 + 1;
    return Quartiles(t1, t2, t3);
  }

  static int getContributionLevel(int c, {Quartiles? quartiles}) {
    if (c == 0) return 0;
    final b = quartiles ?? Quartiles(3, 6, 9);
    if (c <= b.q1) return 1; if (c <= b.q2) return 2; if (c <= b.q3) return 3; return 4;
  }
  
  static ui.Radius getCachedRadius(double r, double s) => _rc.putIfAbsent('${r}_$s', () => Radius.circular(r * s));
  static void clearCaches() => _rc.clear();
}

class Quartiles { final int q1, q2, q3; const Quartiles(this.q1, this.q2, this.q3); }
