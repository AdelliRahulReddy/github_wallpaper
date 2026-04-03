// 🛠️ UTILITIES - Optimized
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'dart:async'; // Added for Timer
import 'package:github_wallpaper/core/errors/app_exceptions.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';

final messengerKey = GlobalKey<ScaffoldMessengerState>();

class SensitiveDataSanitizer {
  static final List<RegExp> _tokenPatterns = [
    RegExp(r'ghp_[a-zA-Z0-9_]+'),
    RegExp(r'gho_[a-zA-Z0-9_]+'),
    RegExp(r'ghu_[a-zA-Z0-9_]+'),
    RegExp(r'ghs_[a-zA-Z0-9_]+'),
    RegExp(r'ghr_[a-zA-Z0-9_]+'),
    RegExp(r'github_pat_[a-zA-Z0-9_]+'),
  ];

  static String sanitize(String msg) {
    var out = msg;
    for (final pattern in _tokenPatterns) {
      out = out.replaceAll(pattern, '[REDACTED_TOKEN]');
    }
    return out
        .replaceAll(RegExp(r'Bearer\s+\S+'), 'Bearer [REDACTED]')
        .replaceAll(
            RegExp(r'Authorization:\s*[^\s,]+'), 'Authorization: [REDACTED]')
        .replaceAll(RegExp(r'token\s*=\s*[^\s&]+', caseSensitive: false),
            'token=[REDACTED]');
  }
}

// ERROR HANDLING
class ErrorHandler {
  static String? getUserFriendlyMessage(dynamic e) {
    if (e is NetworkException ||
        e is SocketException ||
        e.toString().contains('socket')) {
      return AppStrings.errorNetwork;
    }
    if (e is GitHubException &&
        e.message == 'GitHub sign-in server is not deployed') {
      return 'GitHub sign-in backend is not deployed yet. Deploy exchangeGitHubCode or update GITHUB_CODE_EXCHANGE_URL.';
    }
    if (e is GitHubException &&
        e.message == 'GitHub sign-in server is missing OAuth secrets') {
      return 'GitHub sign-in backend is missing GITHUB_CLIENT_ID or GITHUB_CLIENT_SECRET in Firebase.';
    }
    if (e is GitHubException &&
        e.message == 'GitHub sign-in server timed out') {
      return 'GitHub sign-in server timed out. Check the deployed function URL and server health.';
    }
    if (e is TokenExpiredException || e.toString().contains('401')) {
      return 'GitHub authentication required';
    }
    if (e is AccessDeniedException || e.toString().contains('403')) {
      return AppStrings.errorAccessDenied;
    }
    if (e is UserNotFoundException) return AppStrings.errorUserNotFound;
    if (e is RateLimitException) return AppStrings.errorRateLimit;
    if (e is StorageException) return AppStrings.errorStorage;
    if (e is WallpaperException) return AppStrings.errorWallpaper;
    if (e is FlutterAppAuthUserCancelledException ||
        e.toString().contains('User cancelled flow')) {
      return null;
    }

    final msg = e.toString().replaceAll('Exception:', '').trim();
    return msg.isNotEmpty
        ? '${AppStrings.errorGeneric} ($msg)'
        : AppStrings.errorGeneric;
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
      final ScaffoldMessengerState? messenger = (context != null &&
              context.mounted)
          ? (ScaffoldMessenger.maybeOf(context) ?? messengerKey.currentState)
          : messengerKey.currentState;

      if (messenger == null || !messenger.mounted) return;

      if (clearExisting) messenger.clearSnackBars();
      messenger.showSnackBar(snackBar);
    });
  }

  static void handle(BuildContext? c, dynamic e,
      {String? userMessage, bool showSnackBar = true, VoidCallback? onRetry}) {
    if (e is FlutterAppAuthUserCancelledException ||
        e.toString().contains('User cancelled flow')) {
      return;
    }
    if (showSnackBar) {
      _showSnackBarSafely(
        context: c,
        snackBar: SnackBar(
          content: Text(userMessage ??
              getUserFriendlyMessage(e) ??
              AppStrings.errorGeneric),
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
    if (c.mounted) {
      showDialog(
          context: c,
          barrierDismissible: false,
          builder: (_) => PopScope(
              canPop: false,
              child: Center(
                  child: Card(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            const CircularProgressIndicator(),
                            if (message != null) ...[
                              const SizedBox(height: 16),
                              Text(message)
                            ]
                          ]))))));
    }
  }

  static void hideLoading(BuildContext c) {
    if (c.mounted && Navigator.canPop(c)) {
      Navigator.of(c, rootNavigator: true).pop();
    }
  }
}

// LOGGING
class AppLog {
  static void info(String m) {
    if (kDebugMode) {
      debugPrint("🟢 [INFO]: $m");
    } else {
      try {
        FirebaseCrashlytics.instance.log(SensitiveDataSanitizer.sanitize(m));
      } catch (_) {}
    }
  }

  // Sanitize sensitive data from error messages
  static String _sanitizeError(String msg) {
    return SensitiveDataSanitizer.sanitize(msg);
  }

  static void error(dynamic e, [StackTrace? s]) {
    final sanitizedMessage = _sanitizeError(e.toString());
    if (kDebugMode) {
      debugPrint("🔴 [ERROR]: $sanitizedMessage");
      return;
    }

    try {
      FirebaseCrashlytics.instance.log('ERROR: $sanitizedMessage');
      if (s != null) {
        FirebaseCrashlytics.instance.log(_sanitizeError(s.toString()));
      }
    } catch (_) {}
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
  static final _usernameRegex =
      RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9-]{0,37}[a-zA-Z0-9])?$');
  static final _phoneCleanRegex = RegExp(r'[^\d]');
  static const _reservedUsernames = [
    'admin',
    'api',
    'www',
    'github',
    'support',
    'blog',
    'about'
  ];

  static String? username(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final clean = v.trim().toLowerCase();
    if (clean.length < 2) return 'Username too short (min 2 characters)';
    if (v.length > AppConstants.usernameMaxLength) return 'Too long';
    if (_reservedUsernames.contains(clean)) return 'Reserved username';
    if (v.contains('--') || !_usernameRegex.hasMatch(v)) {
      return 'Invalid format';
    }
    return null;
  }

  static String? quote(String? v) =>
      (v != null && v.length > AppConstants.quoteMaxLength) ? 'Too long' : null;

  /// Sanitize custom quote to prevent control characters and injection
  static String sanitizeQuote(String input) {
    return input
        .replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '') // Remove control chars
        .replaceAll(RegExp(r'[<>{}]'), '') // Prevent injection
        .trim();
  }

  static String cleanPhone(String original) =>
      original.replaceAll(_phoneCleanRegex, '');
}

// BACKWARD COMPAT (Deprecate later)
String? isValidUsernameFormat(String? v) => ValidationUtils.username(v);
String? isValidQuoteFormat(String? v) => ValidationUtils.quote(v);

// CONSTANTS & STRINGS

class AppStrings {
  static const appName = 'GitWall';
  static const appTagline = 'Your Code Journey, Visualized';

  // Common
  static const ok = 'OK';
  static const cancel = 'Cancel';
  static const close = 'Close';
  static const retry = 'Retry';
  static const save = 'Save';
  static const next = 'Next';
  static const skip = 'Skip';
  static const continue_ = 'Continue';
  static const getStarted = 'Get Started';
  static const apply = 'Apply';
  static const applyWallpaper = 'Apply Wallpaper';
  static const syncNow = 'Sync Now';
  static const loading = 'Loading...';
  static const unknown = 'Unknown';
  static const error = 'Error';

  // Onboarding
  static const onboardingTagline = 'LIVE FROM GITHUB';
  static const onboardingTitle1 = 'Your GitHub activity\nbecomes wallpaper.';
  static const onboardingDesc1 =
      'GitWall turns your contribution rhythm into a personal wallpaper from the first launch.';
  static const onboardingTitle2 = 'Connect GitHub\nto continue.';
  static const onboardingDesc2 =
      'We use GitHub to generate your wallpaper and keep it in sync.';
  static const onboardingCtaSlide2 = 'Connect GitHub';
  static const onboardingHeatmapLabel = 'Your contribution streak';
  static const onboardingStreakBadge = '21-day streak 🔥';
  static const onboardingFeature1Title = 'Auto wallpaper sync';
  static const onboardingFeature1Desc =
      'Push code. Your wallpaper updates itself — no taps needed.';
  static const onboardingFeature2Title = 'Streak goals & reminders';
  static const onboardingFeature2Desc =
      'Set a target. Get reminded before you break your streak.';
  static const onboardingFeature3Title = 'Templates & palettes';
  static const onboardingFeature3Desc =
      'Pick a style and apply. Polished wallpapers in seconds.';
  static const onboardingFeature4Title = 'GitHub analytics dashboard';
  static const onboardingFeature4Desc =
      'Trends, languages, repos — your activity at a glance.';
  static const setupSubtitle = 'Connect your GitHub to generate your wallpaper';
  static const setupCta = 'Connect & Sync';
  static const setupSecurityNote =
      'Token stored in Android Keystore / iOS Keychain';

  // Home Page
  static const welcome = 'WELCOME 👋';
  static const welcomeBack = 'WELCOME BACK 👋';
  static const welcomeBackDots = 'WELCOME BACK 👋'; // Compatibility
  static const homeGetStartedSubtitle =
      'Pull to refresh to sync your GitHub activity.';
  static const overview = 'Overview';
  static const totalContributions = 'Total Contributions';
  static const totalContributionsSubtitle =
      'Cumulative commits across all years';
  static const currentStreak = 'Current streak';
  static const today = 'Today';
  static const longestStreak = 'Longest streak';
  static const activeRepos = 'Active repos';
  static const trend7d = '7-day trend';
  static const trend30d = '30-day trend';
  static const activityGraph = 'Activity graph';
  static const last6Months = 'Last 6 months';
  static const commits = 'commits';
  static const statCurrentShort = 'Current';
  static const statBestShort = 'Best';
  static const statTotalShort = 'Total';
  static const statTopShort = 'Top';
  static const less = 'Less';
  static const more = 'More';
  static const noActivityData = 'No activity data available';
  static const commitFrequency = 'Commit frequency';
  static const last30Days = 'Last 30 days';
  static const noRecentActivity = 'No recent activity to chart.';
  static const tapChartToInspect = 'Tap the chart to inspect a day.';
  static const activeRepositories = 'Active repositories';
  static const reposWithCommits = 'repositories with commits';
  static const noRepoActivity = 'No repository activity found for this period.';
  static const topLanguages = 'Top languages';
  static const languagesSubtitle = 'Estimated from your active repositories';
  static const noLanguageData = 'No language data available for this period.';
  static const activityInsights = 'Activity insights';
  static const insightsSubtitle =
      'Patterns across your recent contribution history';
  static const weekendVsWeekday = 'Weekend vs weekday';
  static const weekdays = 'Weekdays';
  static const weekends = 'Weekends';
  static const impactLevels = 'Impact levels';
  static const levelLow = 'Low';
  static const levelMed = 'Med';
  static const levelHigh = 'High';
  static const levelMax = 'Max';

  // Customize Page
  static const customize = 'Customize';
  static const setWallpaper = 'Wallpaper Target';
  static const homeScreen = 'Home Screen';
  static const lockScreen = 'Lock Screen';
  static const bothScreens = 'Both Screens';
  static const noDataAvailable = 'No data available';
  static const syncFirst = 'Sync your GitHub data first';
  static const statusBarArea = 'Status icons';
  static const systemClockArea = 'Lockscreen clock';
  static const gestureArea = 'Gesture zone';
  static const wallpaperResolution = 'Wallpaper:';
  static const textOverlay = 'Text Overlay';
  static const customQuote = 'Custom Quote';
  static const quoteHint = 'Enter your motivation...';
  static const scale = 'Scale';
  static const cornerRadius = 'Corner Radius';
  static const layoutNote =
      'GitWall keeps the layout clear of the clock, status icons, and bottom gesture area. Position controls adjust the content inside that safe space.';
  static const positionVertical = 'Position (Vertical, within safe area)';

  // Settings Page
  static const settings = 'Settings';
  static const settingsSubtitle =
      'Free app • Manage your account and preferences';
  static const account = 'Account';
  static const githubAccount = 'GitHub Account';
  static const lastSynced = 'Last synced:';
  static const preferences = 'Preferences';
  static const autoUpdate = 'Auto Wallpaper';
  static const autoUpdateSubtitle =
      'Updates your wallpaper on a schedule (works in background)';
  static const autoUpdateEnabled = '✅ Auto wallpaper enabled';
  static const autoUpdateDisabled = 'Auto wallpaper disabled';
  static const crashReporting = 'Crash Reporting';
  static const crashReportingSubtitle =
      'Help improve app stability (anonymous, sanitized)';
  static const crashReportingEnabled = 'Crash reporting enabled';
  static const crashReportingDisabled = 'Crash reporting disabled';
  static const includePrivateRepos = 'Include Private Repositories';
  static const includePrivateReposSubtitle =
      'Cache private repo names (encrypted locally)';
  static const privateReposCached = 'Private repos will be cached (encrypted)';
  static const privateRepoCacheCleared = 'Private repo cache cleared';
  static const streakGoals = 'Goals';
  static const streakGoal = 'Streak Goal';
  static const streakGoalSubtitle = 'Set a target to stay consistent';
  static const streakReminders = 'Streak Reminders';
  static const streakRemindersSubtitle =
      'Get a reminder if you have 0 commits today';
  static const streakSaved = 'Streak Saved';
  static const streakSavedSubtitle =
      'Celebrate when you save your streak after a reminder';
  static const celebrations = 'Celebrations';
  static const celebrationsSubtitle =
      'Milestones for streaks and contributions';
  static const weeklyDigest = 'Weekly Digest';
  static const weeklyDigestSubtitle = 'A weekly summary of your activity';
  static const digestTime = 'Digest Time';
  static const digestTimeSubtitle = 'Sunday local time';
  static const reminderTime = 'Reminder Time';
  static const reminderTimeSubtitle = 'Local time';
  static const supportUs = 'Support Us ☕';
  static const supportUsSubtitle = 'Optional support to help GitWall grow';
  static const freeForeverBanner =
      'GitWall is fully free. Every feature is included for every account.';
  static const data = 'Data';
  static const removeCachedData = 'Remove cached contribution data';
  static const clearCache = 'Clear Cache';
  static const about = 'About';
  static const version = 'Version';
  static const privacyPolicy = 'Privacy Policy';
  static const readPrivacyPolicy = 'Read our privacy policy';
  static const developer = 'Developer';
  static const needHelp = 'Need Help?';
  static const chatOnWhatsApp = 'Chat on WhatsApp';
  static const logoutConfirmTitle = 'Logout';
  static const logoutConfirmMessage =
      'Are you sure you want to logout? This will clear all your data.';
  static const logout = 'Logout';
  static const clearCacheConfirmTitle = 'Clear Cache';
  static const clearCacheConfirmMessage =
      'This will remove cached contribution data. You\'ll need to sync again.';
  static const clear = 'Clear';

  // Onboarding (legacy/shared)
  static const connectGitHub = 'Connect GitHub';
  static const connectAccount = 'Connect Account';
  static const backToIntro = 'Back to Introduction';
  static const username = 'GitHub Username';

  // Status/Process
  static const statusInitializing = 'Initializing...';
  static const statusLoadingResources = 'Loading resources...';
  static const statusSettingUp = 'Setting up workspace...';
  static const statusAlmostReady = 'Almost ready...';
  static const statusLaunching = 'Launching...';
  static const settingUpWorkspace = 'Setting up your workspace...';
  static const generatingWallpaper = 'Generating wallpaper...';
  static const applyingWallpaper = 'Applying wallpaper...';
  static const refreshingData = 'Refreshing data...';
  static const wallpaperApplied = 'Auto wallpaper set';
  static const wallpaperGenerated = 'Wallpaper image generated successfully';
  static const dataSynced = 'Data synced successfully';
  static const credentialsMissing = 'Credentials missing. Please login again.';
  static const settingsSaved = 'Settings saved';
  static const cacheCleared = 'Cache cleared successfully';

  // Errors
  static const errorGeneric = 'Something went wrong. Please try again.';
  static const errorNetwork = 'No internet connection';
  static const errorAccessDenied = 'Access denied';
  static const errorUserNotFound = 'GitHub user not found';
  static const errorRateLimit = 'API rate limit exceeded';
  static const errorStorage = 'Storage error. Please restart the app.';
  static const errorWallpaper = 'Wallpaper failed. Please try again.';
  static const errorStorageInit =
      'Failed to initialize local storage.\nPlease restart the app.';
  static const errorAppInit = 'Initialization Error';
  static const errorContextInit = 'Context-dependent initialization failed';
  static const shareError = 'Failed to share card. Please try again.';
  static const loadError =
      'Failed to load code history. Check your connection.';
  static const unknownError = 'An unexpected error occurred.';
  static const tryAgain = 'Try Again';

  // Info
  static const supportEmail = 'adellirahulreddy@gmail.com';
  static const supportPhone = '+91 7032784208';
  static const supportFeedback = 'SUPPORT & FEEDBACK';
  static const developerTitle = 'DEVELOPED BY';
  static const developerName = 'Adelli Rahulreddy';
  static const developerTagline = 'Building tools for developers';
  static const appVersion = '1.0.1';
  static const privacyPolicyUrl =
      'https://adellirahulreddy.github.io/github_wallpaper/privacy_policy.html';
  static const whatsAppUrlScheme = 'https://wa.me/';
}

class AppConstants {
  static const double defaultWallpaperScale = 0.7,
      defaultWallpaperOpacity = 1.0,
      defaultCornerRadius = 2.0;
  static const double defaultWallpaperWidth = 1080.0,
      defaultWallpaperHeight = 1920.0,
      defaultPixelRatio = 1.0;
  static const double heatmapBoxSize = 15.0,
      heatmapBoxSpacing = 3.0,
      horizontalBuffer = 32.0;
  static const int heatmapWeeks = 53,
      heatmapDaysPerWeek = 7,
      heatmapTotalDays = 371,
      dashboardHeatmapDays = 180;
  static const int githubDataFetchDays = 370, minCachedContributionDays = 90;
  static const int pendingRefreshDebounceMinutes = 2,
      syncThrottleMinutes = 30,
      refreshCooldownMinutes = 15;

  // Default background sync interval for interval mode.
  static const int autoUpdateIntervalMinutes = 300;
  static const int dailyScheduleCheckIntervalMinutes = 60;
  static const int reminderCheckIntervalMinutes = 30;

  static const String keyUpdateScheduleMode = 'update_schedule_mode_v1';
  static const String keyUpdateScheduleHour = 'update_schedule_hour_v1';
  static const String keyUpdateScheduleMinute = 'update_schedule_minute_v1';
  static const String keyAutoApplyAfterSync = 'auto_apply_after_sync_v1';
  static const String keyLastWallpaperUpdate = 'last_wallpaper_update_v1';
  static const String keyUpdateScheduleIntervalMinutes =
      'update_schedule_interval_minutes_v1';
  static const String keyUpdateScheduleLastDailyKey =
      'update_schedule_last_daily_key_v1';
  static const String keySafePreviewEnabled = 'safe_preview_enabled_v1';

  static const Duration cacheExpiry = Duration(hours: 6),
      apiTimeout = Duration(seconds: 30);
  static const String keyToken = 'gh_token',
      keyUsername = 'username',
      keyAppUserId = 'app_user_id_v1',
      keyLegacyAppUserId = 'legacy_app_user_id_v1',
      keyLegacyFirebaseUid = 'legacy_firebase_uid_v1',
      keyGitHubProviderId = 'github_provider_id_v1',
      keyDisplayName = 'display_name_v1',
      keyUserEmail = 'user_email_v1',
      keyCachedData = 'cached_data_v2',
      keyWallpaperConfig = 'wp_config_v2';
  static const String keyCachedDataSensitive =
      'cached_data_sensitive_v1'; // ✅ Encrypted sensitive cache
  static const String keyIncludePrivateRepos =
      'include_private_repos_v1'; // ✅ User preference
  static const String keyCrashlyticsConsent =
      'crashlytics_consent_v1'; // ✅ GDPR consent
  static const String keyLastBackgroundSync = 'last_bg_sync'; // Legacy cleanup
  static const String keyLastUpdate = 'last_update',
      keyLastSuccessfulUpdate = 'last_successful_update',
      keyAutoUpdate = 'auto_update',
      keyOnboarding = 'onboarding',
      keyWallpaperHash = 'wp_hash',
      keyWallpaperPath = 'wp_path',
      keyLastWallpaperTarget = 'wp_target',
      keyHasSeenDashboard = 'has_seen_dashboard';
  static const String keyHasAppliedWallpaper = 'has_applied_wallpaper';
  static const String keyFirstLoginGreetingPending =
      'first_login_greeting_pending';
  static const String keyPostLoginSetupComplete =
      'post_login_setup_complete_v1';
  static const String keyDimensionWidth = 'dim_w',
      keyDimensionHeight = 'dim_h',
      keyDimensionPixelRatio = 'dim_pr';
  static const String keySafeInsetTop = 'safe_top',
      keySafeInsetBottom = 'safe_bottom',
      keySafeInsetLeft = 'safe_left',
      keySafeInsetRight = 'safe_right';
  static const String keyStreakGoalDays = 'streak_goal_days_v1';
  static const String keyWeeklyCommitGoal = 'weekly_commit_goal_v1';
  static const String keyRecentActivityLimit = 'recent_activity_limit_v1';
  static const String keyStreakReminderEnabled = 'streak_reminder_enabled_v1';
  static const String keyStreakReminderHour = 'streak_reminder_hour_v1';
  static const String keyStreakReminderMinute = 'streak_reminder_minute_v1';
  static const String keyStreakReminderLastSentDay =
      'streak_reminder_last_sent_day_v1';
  static const String keyStreakSavedEnabled = 'streak_saved_enabled_v1';
  static const String keyStreakSavedLastSentDay =
      'streak_saved_last_sent_day_v1';
  static const String keyCelebrationsEnabled = 'celebrations_enabled_v1';
  static const String keyCelebrationsLastStreakMilestone =
      'celebrations_last_streak_v1';
  static const String keyCelebrationsLastTotalMilestone =
      'celebrations_last_total_v1';
  static const String keyWeeklyDigestEnabled = 'weekly_digest_enabled_v1';
  static const String keyWeeklyDigestHour = 'weekly_digest_hour_v1';
  static const String keyWeeklyDigestMinute = 'weekly_digest_minute_v1';
  static const String keyWeeklyDigestLastSentWeek =
      'weekly_digest_last_week_v1';
  static const String keyDailySyncAlertEnabled = 'daily_sync_alert_enabled_v1';
  static const String keySyncSuccessNotificationsEnabled =
      'sync_success_notifications_enabled_v1';
  static const String keySyncSuccessLastSentDay =
      'sync_success_last_sent_day_v1';
  static const String keyAdminBroadcastNotificationsEnabled =
      'admin_broadcast_notifications_enabled_v1';
  static const String keyThemeMode = 'theme_mode_v1';
  static const String keySeenLongestStreak = 'seen_longest_streak_v1';
  static const String keySeenStreakMilestone = 'seen_streak_milestone_v1';
  static const String keyCodingLevel = 'coding_level_v1';
  static const String keyQuoteTone = 'quote_tone_v1';
  static const String keyCachedQuote = 'cached_quote_v2';
  static const String keyCachedQuoteDay = 'cached_quote_day_v2';
  static const String keyCachedQuoteState = 'cached_quote_state_v2';
  static const String keyQuoteHistory = 'quote_history_v2';
  static const String keyQuoteActivitySnapshot = 'quote_activity_snapshot_v2';
  static const String keyCachedAiQuote = 'cached_ai_quote_v1';
  static const String keyCachedAiQuoteDay = 'cached_ai_quote_day_v1';
  static const String keyHasAuthError = 'has_auth_error_v1';
  static const List<String> weekdays = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat'
  ];
  static const String fallbackWeekday = 'None';
  static const String apiUrl = 'https://api.github.com/graphql';
  static const int intensity1 = 3,
      intensity2 = 6,
      intensity3 = 9,
      usernameMaxLength = 39,
      displayNameMaxLength = 40,
      quoteMaxLength = 200,
      monthGridColumns = 7;
  static const double lockTopReserveHeightFraction = 0.105,
      lockTopReserveMinPx = 160.0,
      lockTopReserveMaxPx = 280.0,
      lockBottomReserveHeightFraction = 0.072,
      lockBottomReserveMinPx = 96.0,
      lockBottomReserveMaxPx = 176.0,
      homeTopReserveHeightFraction = 0.018,
      homeTopReserveMinPx = 10.0,
      homeTopReserveMaxPx = 42.0,
      homeBottomReserveHeightFraction = 0.014,
      homeBottomReserveMinPx = 8.0,
      homeBottomReserveMaxPx = 28.0;
  static const double minWallpaperScale = 0.1, maxWallpaperScale = 10.0;
  static const double quickNumberTileMinHeight = 125.0;
  static const int wallpaperScaleDivisions = 40;
  static const int minWeeklyCommitGoal = 1;
  static const int maxWeeklyCommitGoal = 365;
  static const int defaultWeeklyCommitGoal = 20;
  static const int minRecentActivityLimit = 5;
  static const int maxRecentActivityLimit = 20;
  static const int defaultRecentActivityLimit = 6;
  static bool isValidContributionLevel(int l) => l >= 0 && l <= 4;
}

enum RefreshSkipReason { noChanges, throttled, networkError, authError }

class RefreshDecision {
  final bool shouldProceed;
  final RefreshSkipReason? skipReason;
  const RefreshDecision.proceed()
      : shouldProceed = true,
        skipReason = null;
  const RefreshDecision.skip(this.skipReason) : shouldProceed = false;
}

class RefreshPolicy {
  static RefreshDecision shouldRefresh(
      {required bool isBackground,
      bool isAutomatic = false,
      required bool isAndroid,
      required bool autoUpdateEnabled,
      required bool hasPendingRefresh,
      DateTime? lastUpdate,
      String? username,
      String? token,
      bool hasAuthError = false,
      bool hasConnectivity = true,
      DateTime? now,
      required UpdateScheduleMode scheduleMode,
      required int scheduleHour,
      required int scheduleMinute,
      required int scheduleIntervalMinutes,
      required String? lastDailyKey}) {
    if (!isAndroid && isBackground) {
      return const RefreshDecision.skip(RefreshSkipReason.noChanges);
    }
    final nowUtc = (now ?? DateTime.now()).toUtc();
    if (hasPendingRefresh &&
        lastUpdate != null &&
        nowUtc.difference(lastUpdate.toUtc()).inMinutes <
            AppConstants.pendingRefreshDebounceMinutes) {
      return const RefreshDecision.skip(RefreshSkipReason.noChanges);
    }
    if (!autoUpdateEnabled && (isBackground || isAutomatic)) {
      return const RefreshDecision.skip(RefreshSkipReason.noChanges);
    }
    if (hasAuthError) {
      return const RefreshDecision.skip(RefreshSkipReason.authError);
    }

    if ((isBackground || isAutomatic) && !hasPendingRefresh) {
      final localNow = (now ?? DateTime.now());
      final localKey = AppDateUtils.formatDate(localNow);
      if (scheduleMode == UpdateScheduleMode.autoDaily) {
        if (lastDailyKey == localKey) {
          return const RefreshDecision.skip(RefreshSkipReason.noChanges);
        }
        final start = DateTime(localNow.year, localNow.month, localNow.day,
            scheduleHour, scheduleMinute);
        final end = start.add(const Duration(minutes: 110));
        if (localNow.isBefore(start) || localNow.isAfter(end)) {
          return const RefreshDecision.skip(RefreshSkipReason.noChanges);
        }
      } else {
        if (lastUpdate != null &&
            nowUtc.difference(lastUpdate.toUtc()).inMinutes <
                scheduleIntervalMinutes) {
          return const RefreshDecision.skip(RefreshSkipReason.noChanges);
        }
      }
    }

    if ((isBackground || isAutomatic) &&
        lastUpdate != null &&
        nowUtc.difference(lastUpdate.toUtc()).inMinutes <
            AppConstants.refreshCooldownMinutes) {
      return const RefreshDecision.skip(RefreshSkipReason.throttled);
    }
    if (!hasConnectivity) {
      return const RefreshDecision.skip(RefreshSkipReason.networkError);
    }
    if (username == null ||
        token == null ||
        username.trim().isEmpty ||
        token.trim().isEmpty) {
      return const RefreshDecision.skip(RefreshSkipReason.authError);
    }
    return const RefreshDecision.proceed();
  }
}

enum UpdateScheduleMode { autoDaily, interval }

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

  static TextPainter drawText(ui.Canvas canvas, String text, TextStyle style,
      Offset offset, double maxWidth,
      {TextAlign textAlign = TextAlign.left,
      TextDirection textDirection = TextDirection.ltr,
      int? maxLines,
      bool paint = true}) {
    final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textAlign: textAlign,
        textDirection: textDirection,
        maxLines: maxLines)
      ..layout(maxWidth: maxWidth);
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
      return Quartiles(AppConstants.intensity1, AppConstants.intensity2,
          AppConstants.intensity3);
    }
    int p(double x) => nz[(nz.length * x).ceil().clamp(0, nz.length - 1)];
    final q1 = p(0.25), q2 = p(0.5);
    final t1 = q1 > 0 ? q1 : 1,
        t2 = q2 > t1 ? q2 : t1 + 1,
        t3 = p(0.75) > t2 ? p(0.75) : t2 + 1;
    return Quartiles(t1, t2, t3);
  }

  static int getContributionLevel(int c, {Quartiles? quartiles}) {
    if (c == 0) return 0;
    final b = quartiles ??
        Quartiles(AppConstants.intensity1, AppConstants.intensity2,
            AppConstants.intensity3);
    if (c <= b.q1) return 1;
    if (c <= b.q2) return 2;
    if (c <= b.q3) return 3;
    return 4;
  }

  static ui.Radius getCachedRadius(double r, double s) =>
      _rc.putIfAbsent('${r}_$s', () => Radius.circular(r * s));
  static void clearCaches() => _rc.clear();
}

class AppDateUtils {
  static String formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime? parseDate(String? s) {
    if (s == null) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s);
    return m != null
        ? DateTime.utc(int.parse(m.group(1)!), int.parse(m.group(2)!),
                int.parse(m.group(3)!))
            .toLocal()
        : DateTime.tryParse(s)?.toLocal();
  }
}

class AppColorUtils {
  static Color? parseHexColor(String? hex) {
    if (hex == null) return null;
    final cleaned = hex.trim();
    if (cleaned.isEmpty) return null;
    final normalized = cleaned.startsWith('#') ? cleaned.substring(1) : cleaned;
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return null;
    if (normalized.length == 6) {
      return Color(0xFF000000 | value);
    }
    if (normalized.length == 8) {
      return Color(value);
    }
    return null;
  }
}

class Quartiles {
  final int q1, q2, q3;
  const Quartiles(this.q1, this.q2, this.q3);
}
