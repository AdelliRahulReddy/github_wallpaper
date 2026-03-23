part of 'app_utils.dart';

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
  static const applyWallpaper = 'Set Auto Wallpaper';
  static const syncNow = 'Sync Now';
  static const loading = 'Loading...';
  static const unknown = 'Unknown';
  static const error = 'Error';

  // Onboarding
  static const onboardingTagline = 'FOR DEVS';
  static const onboardingTitle1 = 'Your streak.\nYour screen.';
  static const onboardingDesc1 =
      'Every commit updates your wallpaper. Your consistency, always on display.';
  static const onboardingTitle2 = 'Built for\ndevelopers.';
  static const onboardingDesc2 =
      'Auto-sync, streak goals, weekly digests — everything a serious developer needs.';
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
      'Pick a style and apply. Premium look in seconds.';
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
  static const setWallpaper = 'Set Auto Wallpaper';
  static const homeScreen = 'Home Screen';
  static const lockScreen = 'Lock Screen';
  static const bothScreens = 'Both Screens';
  static const noDataAvailable = 'No data available';
  static const syncFirst = 'Sync your GitHub data first';
  static const statusBarArea = 'Status icons';
  static const systemClockArea = 'Lockscreen clock';
  static const gestureArea = 'Gesture zone';
  static const wallpaperResolution = 'Wallpaper:';
  static const autoFitWidth = 'Auto Fit Width';
  static const autoFixDevice = 'Auto Fix for Device';
  static const textOverlay = 'Text Overlay';
  static const customQuote = 'Custom Quote';
  static const quoteHint = 'Enter your motivation...';
  static const quoteSize = 'Quote Size';
  static const quoteOpacity = 'Quote Opacity';
  static const scale = 'Scale';
  static const opacity = 'Opacity';
  static const cornerRadius = 'Corner Radius';
  static const layoutNote =
      'GitWall keeps the layout clear of the clock, status icons, and bottom gesture area. Position controls adjust the content inside that safe space.';
  static const positionVertical = 'Position (Vertical, within safe area)';
  static const positionHorizontal = 'Position (Horizontal, within safe area)';

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
      'GitWall starts on a real Free plan. Pro unlocks the advanced developer features.';
  static const membership = 'Membership';
  static const membershipRedeemCoupon = 'Redeem coupon';
  static const membershipCouponHint = 'Enter coupon code';
  static const membershipCouponApplied =
      'Coupon applied. Pro access unlocked.';
  static const membershipCouponInvalid = 'Coupon invalid or already used.';
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
