import 'package:flutter/foundation.dart';

import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/features/contributions/services/contribution_metrics.dart';

@immutable
class ClockTime {
  final int hour;
  final int minute;

  const ClockTime({
    required this.hour,
    required this.minute,
  });

  String get label =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

@immutable
class RawSnapshot {
  final CachedContributionData data;

  const RawSnapshot._(this.data);

  factory RawSnapshot.fromData(CachedContributionData data) =>
      RawSnapshot._(data);

  String get username => data.username;
  String? get avatarUrl => data.avatarUrl;
  DateTime get lastUpdated => data.lastUpdated;
  List<ContributionDay> get days => data.days;
  List<RepoContribution> get repositories => data.repositories;
  List<LanguageUsage> get topLanguages => data.topLanguages;
}

@immutable
class InsightSnapshot {
  final DateTime generatedAt;
  final int totalContributions;
  final int currentStreak;
  final int longestStreak;
  final int todayContributions;
  final int activeDaysCount;
  final int weeklyTotal;
  final int previousWeeklyTotal;
  final int monthlyTotal;
  final int previousMonthlyTotal;
  final int activeDaysThisWeek;
  final int activeDaysThisMonth;
  final int bestWeekTotal;
  final DateTime? peakDayDate;
  final int peakDayCount;
  final String mostActiveWeekday;
  final double averagePerActiveDay;
  final double consistencyScore;
  final TrendSummary trend7d;
  final TrendSummary trend30d;
  final RepoContribution? topRepository;
  final LanguageUsage? topLanguage;
  final int? streakMilestone;
  final int? contributionMilestone;

  const InsightSnapshot({
    required this.generatedAt,
    required this.totalContributions,
    required this.currentStreak,
    required this.longestStreak,
    required this.todayContributions,
    required this.activeDaysCount,
    required this.weeklyTotal,
    required this.previousWeeklyTotal,
    required this.monthlyTotal,
    required this.previousMonthlyTotal,
    required this.activeDaysThisWeek,
    required this.activeDaysThisMonth,
    required this.bestWeekTotal,
    required this.peakDayDate,
    required this.peakDayCount,
    required this.mostActiveWeekday,
    required this.averagePerActiveDay,
    required this.consistencyScore,
    required this.trend7d,
    required this.trend30d,
    required this.topRepository,
    required this.topLanguage,
    required this.streakMilestone,
    required this.contributionMilestone,
  });
}

@immutable
class PreferenceState {
  final WallpaperConfig wallpaperConfig;
  final WallpaperTarget lastWallpaperTarget;
  final bool autoUpdate;
  final bool autoApplyAfterSync;
  final UpdateScheduleMode updateScheduleMode;
  final ClockTime updateDailyTime;
  final int updateIntervalMinutes;
  final bool safePreviewEnabled;
  final int weeklyCommitGoal;
  final bool streakReminderEnabled;
  final bool weeklyDigestEnabled;
  final String codingLevel;
  final String quoteTone;

  const PreferenceState({
    required this.wallpaperConfig,
    required this.lastWallpaperTarget,
    required this.autoUpdate,
    required this.autoApplyAfterSync,
    required this.updateScheduleMode,
    required this.updateDailyTime,
    required this.updateIntervalMinutes,
    required this.safePreviewEnabled,
    required this.weeklyCommitGoal,
    required this.streakReminderEnabled,
    required this.weeklyDigestEnabled,
    required this.codingLevel,
    required this.quoteTone,
  });
}

enum EntitledFeature {
  aiQuotes,
  advancedStats,
  wrapped,
  reminders,
  watermarkFreeSharing,
  themes,
  templates,
  widgetRouting,
}

@immutable
class EntitlementState {
  final Set<EntitledFeature> enabledFeatures;
  final List<String> availableThemeIds;
  final List<String> availableTemplateIds;

  const EntitlementState({
    required this.enabledFeatures,
    required this.availableThemeIds,
    required this.availableTemplateIds,
  });

  bool hasFeature(EntitledFeature feature) => enabledFeatures.contains(feature);
}

enum SyncStatus {
  idle,
  checking,
  fresh,
  stale,
  syncing,
  synced,
  failed,
  authRequired,
}

enum SyncFailureType {
  none,
  auth,
  network,
  throttled,
  unknown,
}

enum SyncMode {
  fullSync,
  freshnessCheck,
  recoverySync,
  renderOnlyRefresh,
  scheduledSync,
}

@immutable
class SyncState {
  final SyncStatus status;
  final SyncMode mode;
  final SyncFailureType failureType;
  final DateTime? lastAttemptAt;
  final DateTime? lastSuccessfulSyncAt;
  final bool hasCachedData;
  final bool hasPendingRefresh;
  final bool hasAuthError;
  final bool isStale;
  final String? message;

  const SyncState({
    required this.status,
    required this.mode,
    required this.failureType,
    required this.lastAttemptAt,
    required this.lastSuccessfulSyncAt,
    required this.hasCachedData,
    required this.hasPendingRefresh,
    required this.hasAuthError,
    required this.isStale,
    this.message,
  });

  bool get isHealthy =>
      status != SyncStatus.failed && status != SyncStatus.authRequired;
  bool get requiresUserAction =>
      status == SyncStatus.authRequired ||
      (status == SyncStatus.failed && failureType == SyncFailureType.auth);

  SyncState copyWith({
    SyncStatus? status,
    SyncMode? mode,
    SyncFailureType? failureType,
    DateTime? lastAttemptAt,
    bool clearLastAttemptAt = false,
    DateTime? lastSuccessfulSyncAt,
    bool clearLastSuccessfulSyncAt = false,
    bool? hasCachedData,
    bool? hasPendingRefresh,
    bool? hasAuthError,
    bool? isStale,
    String? message,
    bool clearMessage = false,
  }) {
    return SyncState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      failureType: failureType ?? this.failureType,
      lastAttemptAt:
          clearLastAttemptAt ? null : (lastAttemptAt ?? this.lastAttemptAt),
      lastSuccessfulSyncAt: clearLastSuccessfulSyncAt
          ? null
          : (lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt),
      hasCachedData: hasCachedData ?? this.hasCachedData,
      hasPendingRefresh: hasPendingRefresh ?? this.hasPendingRefresh,
      hasAuthError: hasAuthError ?? this.hasAuthError,
      isStale: isStale ?? this.isStale,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

@immutable
class ProductSnapshot {
  final RawSnapshot? raw;
  final InsightSnapshot? insights;
  final PreferenceState preferences;
  final EntitlementState entitlements;
  final SyncState sync;

  const ProductSnapshot({
    required this.raw,
    required this.insights,
    required this.preferences,
    required this.entitlements,
    required this.sync,
  });

  bool get hasData => raw != null && insights != null;
}
