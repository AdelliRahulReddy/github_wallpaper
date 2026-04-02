import 'package:flutter_test/flutter_test.dart';

import 'package:github_wallpaper/app/product/models/product_models.dart';
import 'package:github_wallpaper/app/product/services/entitlement_engine.dart';
import 'package:github_wallpaper/app/product/services/insight_engine.dart';
import 'package:github_wallpaper/app/product/services/surface_builders.dart';
import 'package:github_wallpaper/app/product/services/sync_engine.dart';
import 'package:github_wallpaper/app/services/refresh_result.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';

void main() {
  PreferenceState buildPreferences() {
    return PreferenceState(
      wallpaperConfig: WallpaperConfig.defaults(),
      lastWallpaperTarget: WallpaperTarget.lock,
      autoUpdate: true,
      autoApplyAfterSync: true,
      updateScheduleMode: UpdateScheduleMode.autoDaily,
      updateDailyTime: const ClockTime(hour: 9, minute: 0),
      updateIntervalMinutes: 300,
      safePreviewEnabled: true,
      weeklyCommitGoal: 20,
      streakReminderEnabled: true,
      weeklyDigestEnabled: false,
      codingLevel: 'Regular coder',
      quoteTone: 'Motivational',
    );
  }

  CachedContributionData buildData({
    required DateTime anchor,
  }) {
    final days = <ContributionDay>[];
    for (var offset = 39; offset >= 0; offset--) {
      final date = DateTime(anchor.year, anchor.month, anchor.day)
          .subtract(Duration(days: offset));
      final count = switch (offset) {
        0 => 4,
        1 => 3,
        2 => 2,
        3 => 1,
        4 => 0,
        5 => 5,
        6 => 2,
        12 => 7,
        18 => 6,
        _ => offset % 9 == 0 ? 3 : 0,
      };
      days.add(ContributionDay(date: date, contributionCount: count));
    }

    final currentYear = anchor.year;
    days.addAll([
      ContributionDay(
        date: DateTime(currentYear - 1, 11, 15),
        contributionCount: 6,
      ),
      ContributionDay(
        date: DateTime(currentYear - 1, 12, 20),
        contributionCount: 4,
      ),
    ]);

    return CachedContributionData(
      username: 'testuser',
      totalContributions: days.fold<int>(
        0,
        (sum, day) => sum + day.contributionCount,
      ),
      days: days,
      lastUpdated: anchor,
      repositories: const [
        RepoContribution(
          nameWithOwner: 'team/gitwall',
          isPrivate: false,
          commitCount: 42,
          primaryLanguageName: 'Dart',
          primaryLanguageColor: '#0175C2',
          languages: [
            RepoLanguageSlice(name: 'Dart', color: '#0175C2', size: 80),
            RepoLanguageSlice(name: 'Swift', color: '#F05138', size: 20),
          ],
        ),
        RepoContribution(
          nameWithOwner: 'team/docs',
          isPrivate: false,
          commitCount: 10,
          primaryLanguageName: 'Markdown',
          languages: [
            RepoLanguageSlice(name: 'Markdown', size: 100),
          ],
        ),
      ],
    );
  }

  ProductSnapshot buildSnapshot({
    required CachedContributionData? data,
    required SyncState syncState,
  }) {
    final raw = data == null ? null : RawSnapshot.fromData(data);
    return ProductSnapshot(
      raw: raw,
      insights:
          raw == null ? null : InsightEngine.build(raw, now: raw.lastUpdated),
      preferences: buildPreferences(),
      entitlements: EntitlementEngine.resolve(),
      sync: syncState,
    );
  }

  test('InsightEngine produces shared insight snapshot fields', () {
    final anchor = DateTime.now().toLocal();
    final data = buildData(anchor: anchor);

    final insights = InsightEngine.build(
      RawSnapshot.fromData(data),
      now: anchor,
    );

    expect(insights.weeklyTotal, greaterThan(0));
    expect(insights.monthlyTotal, greaterThanOrEqualTo(insights.weeklyTotal));
    expect(insights.activeDaysThisWeek, inInclusiveRange(1, 7));
    expect(insights.topRepository?.nameWithOwner, 'team/gitwall');
    expect(insights.topLanguage?.name, 'Dart');
    expect(insights.consistencyScore, inInclusiveRange(0, 100));
  });

  test('SyncEngine exposes sync lifecycle and auth failures', () {
    final anchor = DateTime.now().toUtc();
    final data = buildData(anchor: anchor.toLocal());
    final base = SyncEngine.fromStorage(
      data: data,
      lastSuccessfulSyncAt: anchor.subtract(const Duration(hours: 1)),
      hasAuthError: false,
      hasPendingRefresh: false,
      now: anchor,
    );
    final syncing = SyncEngine.begin(base, mode: SyncMode.fullSync, at: anchor);
    final success = SyncEngine.complete(
      syncing,
      result: RefreshResult.success,
      data: data,
      at: anchor,
    );
    final authFailure = SyncEngine.complete(
      syncing,
      result: RefreshResult.authError,
      data: data,
      at: anchor,
    );

    expect(syncing.status, SyncStatus.syncing);
    expect(success.status, anyOf(SyncStatus.synced, SyncStatus.stale));
    expect(success.failureType, SyncFailureType.none);
    expect(authFailure.status, SyncStatus.authRequired);
    expect(authFailure.requiresUserAction, isTrue);
  });

  test('StatsBuilder keeps previous-year selection available for every account',
      () {
    final anchor = DateTime.now().toLocal();
    final data = buildData(anchor: anchor);
    final syncState = SyncEngine.fromStorage(
      data: data,
      lastSuccessfulSyncAt: anchor.toUtc(),
      hasAuthError: false,
      hasPendingRefresh: false,
      now: anchor,
    );
    final previousYear = anchor.year - 1;

    final surface = StatsBuilder.build(
      buildSnapshot(
        data: data,
        syncState: syncState,
      ),
      selectedYear: previousYear,
    );

    expect(surface, isNotNull);
    expect(surface!.selectedYear, previousYear);
    expect(surface.canUseAdvancedStats, isTrue);
    expect(surface.canViewWrapped, isTrue);
  });

  test(
      'WidgetBuilder frames widget as a live glance surface and keeps stats routing',
      () {
    final anchor = DateTime.now().toLocal();
    final data = buildData(anchor: anchor);
    final liveSync = SyncEngine.fromStorage(
      data: data,
      lastSuccessfulSyncAt: anchor.toUtc(),
      hasAuthError: false,
      hasPendingRefresh: false,
      now: anchor,
    );
    final emptySync = SyncEngine.fromStorage(
      data: null,
      lastSuccessfulSyncAt: null,
      hasAuthError: false,
      hasPendingRefresh: false,
      now: anchor,
    );

    final liveWidget = WidgetBuilder.build(
      buildSnapshot(
        data: data,
        syncState: liveSync,
      ),
    );
    final emptyWidget = WidgetBuilder.build(
      buildSnapshot(
        data: null,
        syncState: emptySync,
      ),
    );

    expect(liveWidget.badge, 'LIVE');
    expect(liveWidget.route, contains('/stats'));
    expect(liveWidget.status, contains('glance'));
    expect(emptyWidget.badge, 'SYNC');
    expect(emptyWidget.route, contains('/home'));
    expect(emptyWidget.status, contains('Sync once'));
  });
}
