part of 'app_utils.dart';

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
  static const String keyDimensionWidth = 'dim_w',
      keyDimensionHeight = 'dim_h',
      keyDimensionPixelRatio = 'dim_pr';
  static const String keySafeInsetTop = 'safe_top',
      keySafeInsetBottom = 'safe_bottom',
      keySafeInsetLeft = 'safe_left',
      keySafeInsetRight = 'safe_right';
  static const String keyStreakGoalDays = 'streak_goal_days_v1';
  static const String keyWeeklyCommitGoal = 'weekly_commit_goal_v1';
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
  static const String keyCachedAiQuote = 'cached_ai_quote_v1';
  static const String keyCachedAiQuoteDay = 'cached_ai_quote_day_v1';
  static const String keyMembershipInfo = 'membership_info_v1';
  static const String keyMembershipLastValidatedAt =
      'membership_last_validated_at_v1';
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
  static const double lockTopReserveHeightFraction = 0.075,
      lockTopReserveMinPx = 96.0,
      lockTopReserveMaxPx = 176.0,
      lockBottomReserveHeightFraction = 0.04,
      lockBottomReserveMinPx = 28.0,
      lockBottomReserveMaxPx = 84.0,
      homeTopReserveHeightFraction = 0.018,
      homeTopReserveMinPx = 10.0,
      homeTopReserveMaxPx = 42.0,
      homeBottomReserveHeightFraction = 0.014,
      homeBottomReserveMinPx = 8.0,
      homeBottomReserveMaxPx = 28.0;
  static const double minWallpaperScale = 0.1, maxWallpaperScale = 10.0;
  static const int wallpaperScaleDivisions = 40;
  static bool isValidContributionLevel(int l) => l >= 0 && l <= 4;
}
