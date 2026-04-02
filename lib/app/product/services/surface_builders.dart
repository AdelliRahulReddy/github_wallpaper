import 'package:flutter/foundation.dart';

import 'package:github_wallpaper/app/product/models/product_models.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/features/contributions/services/contribution_metrics.dart';

@immutable
class HomeSurfaceModel {
  final String username;
  final int todayCommits;
  final int currentStreak;
  final int weeklyTotal;
  final int weeklyGoal;
  final DateTime? lastSyncAt;
  final bool hasAuthIssue;
  final bool wallpaperNeedsRefresh;

  const HomeSurfaceModel({
    required this.username,
    required this.todayCommits,
    required this.currentStreak,
    required this.weeklyTotal,
    required this.weeklyGoal,
    required this.lastSyncAt,
    required this.hasAuthIssue,
    required this.wallpaperNeedsRefresh,
  });
}

@immutable
class StatsSurfaceModel {
  final List<int> availableYears;
  final int selectedYear;
  final List<ContributionDay> yearDays;
  final List<int> currentYearMonthlyTotals;
  final List<int> previousYearMonthlyTotals;
  final ContributionStats yearStats;
  final int yearTotal;
  final String subtitle;
  final bool isCurrentYear;
  final bool canUseAdvancedStats;
  final bool canViewWrapped;

  const StatsSurfaceModel({
    required this.availableYears,
    required this.selectedYear,
    required this.yearDays,
    required this.currentYearMonthlyTotals,
    required this.previousYearMonthlyTotals,
    required this.yearStats,
    required this.yearTotal,
    required this.subtitle,
    required this.isCurrentYear,
    required this.canUseAdvancedStats,
    required this.canViewWrapped,
  });
}

@immutable
class WallpaperSurfaceModel {
  final String themeId;
  final String templateId;
  final WallpaperTarget target;
  final bool canUseTheme;
  final bool canUseTemplate;
  final bool shouldReRenderOnly;

  const WallpaperSurfaceModel({
    required this.themeId,
    required this.templateId,
    required this.target,
    required this.canUseTheme,
    required this.canUseTemplate,
    required this.shouldReRenderOnly,
  });
}

@immutable
class ShareSurfaceModel {
  final String username;
  final int totalContributions;
  final int currentStreak;
  final bool shouldWatermark;

  const ShareSurfaceModel({
    required this.username,
    required this.totalContributions,
    required this.currentStreak,
    required this.shouldWatermark,
  });
}

@immutable
class WidgetSurfaceModel {
  final int currentStreak;
  final int todayCommits;
  final int totalContributions;
  final String username;
  final String badge;
  final String status;
  final String route;

  const WidgetSurfaceModel({
    required this.currentStreak,
    required this.todayCommits,
    required this.totalContributions,
    required this.username,
    required this.badge,
    required this.status,
    required this.route,
  });
}

@immutable
class SettingsHealthSurfaceModel {
  final bool isConnected;
  final bool hasAuthIssue;
  final bool autoUpdateEnabled;
  final bool remindersEnabled;
  final bool wallpaperRecentlyUpdated;
  final DateTime? lastSyncAt;
  final DateTime? lastWallpaperUpdateAt;

  const SettingsHealthSurfaceModel({
    required this.isConnected,
    required this.hasAuthIssue,
    required this.autoUpdateEnabled,
    required this.remindersEnabled,
    required this.wallpaperRecentlyUpdated,
    required this.lastSyncAt,
    required this.lastWallpaperUpdateAt,
  });
}

class HomeBuilder {
  static HomeSurfaceModel build(ProductSnapshot snapshot) {
    return HomeSurfaceModel(
      username: snapshot.raw?.username ?? 'GitWall',
      todayCommits: snapshot.insights?.todayContributions ?? 0,
      currentStreak: snapshot.insights?.currentStreak ?? 0,
      weeklyTotal: snapshot.insights?.weeklyTotal ?? 0,
      weeklyGoal: snapshot.preferences.weeklyCommitGoal,
      lastSyncAt: snapshot.sync.lastSuccessfulSyncAt,
      hasAuthIssue: snapshot.sync.hasAuthError,
      wallpaperNeedsRefresh:
          snapshot.sync.hasPendingRefresh || snapshot.sync.isStale,
    );
  }
}

class StatsBuilder {
  static StatsSurfaceModel? build(
    ProductSnapshot snapshot, {
    int? selectedYear,
  }) {
    final raw = snapshot.raw?.data;
    if (raw == null) return null;

    final years = <int>{
      for (final day in raw.days) day.date.toLocal().year,
    }.toList()
      ..sort();
    final availableYears = years.reversed.toList(growable: false);
    if (availableYears.isEmpty) return null;

    final currentYear = DateTime.now().toLocal().year;
    final resolvedYear = snapshot.entitlements.hasFeature(
              EntitledFeature.advancedStats,
            ) &&
            selectedYear != null &&
            availableYears.contains(selectedYear)
        ? selectedYear
        : (availableYears.contains(currentYear)
            ? currentYear
            : availableYears.first);

    final yearDays = raw.days
        .where((day) => day.date.toLocal().year == resolvedYear)
        .toList(growable: false);
    final now = DateTime.now().toLocal();
    final cutoff = resolvedYear == currentYear
        ? DateTime(now.year, now.month, now.day)
        : DateTime(resolvedYear, 12, 31);
    final yearStats = ContributionStats.fromDays(
      yearDays,
      nowUtc: cutoff.toUtc(),
    );
    final yearTotal = yearDays.fold<int>(
      0,
      (sum, day) => sum + day.contributionCount,
    );
    final subtitle = resolvedYear == currentYear
        ? '${PresentationFormatter.formatCompactNumber(yearTotal)} contributions this year'
        : '${PresentationFormatter.formatCompactNumber(yearTotal)} contributions in $resolvedYear';

    return StatsSurfaceModel(
      availableYears: availableYears,
      selectedYear: resolvedYear,
      yearDays: yearDays,
      currentYearMonthlyTotals: _monthlyTotalsForYear(raw.days, resolvedYear),
      previousYearMonthlyTotals:
          _monthlyTotalsForYear(raw.days, resolvedYear - 1),
      yearStats: yearStats,
      yearTotal: yearTotal,
      subtitle: subtitle,
      isCurrentYear: resolvedYear == currentYear,
      canUseAdvancedStats:
          snapshot.entitlements.hasFeature(EntitledFeature.advancedStats),
      canViewWrapped: snapshot.entitlements.hasFeature(EntitledFeature.wrapped),
    );
  }

  static List<int> _monthlyTotalsForYear(List<ContributionDay> days, int year) {
    final totals = List<int>.filled(12, 0);
    for (final day in days) {
      final date = day.date.toLocal();
      if (date.year == year) {
        totals[date.month - 1] += day.contributionCount;
      }
    }
    return totals;
  }
}

class WallpaperBuilder {
  static WallpaperSurfaceModel build(ProductSnapshot snapshot) {
    final config = snapshot.preferences.wallpaperConfig;
    final entitlements = snapshot.entitlements;

    return WallpaperSurfaceModel(
      themeId: config.themeId,
      templateId: config.templateId,
      target: snapshot.preferences.lastWallpaperTarget,
      canUseTheme: entitlements.availableThemeIds.contains(config.themeId),
      canUseTemplate:
          entitlements.availableTemplateIds.contains(config.templateId),
      shouldReRenderOnly: snapshot.raw != null,
    );
  }
}

class ShareBuilder {
  static ShareSurfaceModel build(ProductSnapshot snapshot) {
    return ShareSurfaceModel(
      username: snapshot.raw?.username ?? 'GitWall',
      totalContributions: snapshot.insights?.totalContributions ?? 0,
      currentStreak: snapshot.insights?.currentStreak ?? 0,
      shouldWatermark: !snapshot.entitlements
          .hasFeature(EntitledFeature.watermarkFreeSharing),
    );
  }
}

class WidgetBuilder {
  static WidgetSurfaceModel build(ProductSnapshot snapshot) {
    final isStale = snapshot.sync.isStale;
    final hasData = snapshot.hasData;
    final hasAuthIssue = snapshot.sync.hasAuthError;

    return WidgetSurfaceModel(
      currentStreak: snapshot.insights?.currentStreak ?? 0,
      todayCommits: snapshot.insights?.todayContributions ?? 0,
      totalContributions: snapshot.insights?.totalContributions ?? 0,
      username: snapshot.raw?.username ?? 'GitWall',
      badge: hasData ? 'LIVE' : 'SYNC',
      status: hasData
          ? (hasAuthIssue
              ? 'Your last good snapshot is still here. Tap to reconnect GitHub and keep it trustworthy.'
              : (isStale
                  ? 'Your latest snapshot is cached. Open GitWall to refresh it.'
                  : 'A quick glance at streak, today, and freshness. Tap to keep the habit moving.'))
          : 'Sync once in GitWall to turn this into a live contribution surface.',
      route: hasData
          ? (hasAuthIssue
              ? 'gitwall://widget/home?source=home_widget&state=reconnect'
              : 'gitwall://widget/stats?source=home_widget')
          : 'gitwall://widget/home?source=home_widget&state=sync',
    );
  }
}

class SettingsHealthBuilder {
  static SettingsHealthSurfaceModel build(ProductSnapshot snapshot) {
    final lastWallpaperUpdateAt =
        snapshot.preferences.autoApplyAfterSync && snapshot.raw != null
            ? snapshot.raw!.lastUpdated
            : null;
    return SettingsHealthSurfaceModel(
      isConnected:
          (snapshot.raw != null || StorageService.getUsername() != null) &&
              !snapshot.sync.hasAuthError,
      hasAuthIssue: snapshot.sync.hasAuthError,
      autoUpdateEnabled: snapshot.preferences.autoUpdate,
      remindersEnabled: snapshot.preferences.streakReminderEnabled ||
          snapshot.preferences.weeklyDigestEnabled,
      wallpaperRecentlyUpdated:
          lastWallpaperUpdateAt != null && !snapshot.sync.isStale,
      lastSyncAt: snapshot.sync.lastSuccessfulSyncAt,
      lastWallpaperUpdateAt: lastWallpaperUpdateAt,
    );
  }
}
