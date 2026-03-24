import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:github_wallpaper/core/errors/app_exceptions.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/features/contributions/services/contribution_metrics.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/features/contributions/services/daily_quotes.dart';
import 'package:github_wallpaper/app/services/notification_service.dart';
import 'package:github_wallpaper/app/services/refresh_result.dart';
import 'package:github_wallpaper/app/services/telemetry_service.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/features/wallpaper/services/wallpaper_service.dart';
import 'package:github_wallpaper/features/wallpaper/services/widget_service.dart';


class ContributionRepository {
  static final http.Client _c = http.Client();

  static Future<http.Response> _viewerReq(String token, Duration timeout) {
    return _c
        .post(
          Uri.parse(AppConstants.apiUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'query': 'query{viewer{login}}'}),
        )
        .timeout(timeout);
  }

  static Future<CachedContributionData> getContributions(
      {required String username,
      required String token,
      bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = StorageService.getCachedData();
      if (cached != null &&
          !cached.isStale() &&
          cached.username.toLowerCase() == username.toLowerCase()) {
        return cached;
      }
    } else {
      StorageService.clearMemoryCache();
    }

    try {
      final res = await _req(username, token);
      final data = jsonDecode(res.body);
      if (res.statusCode != 200 || data['errors'] != null) {
        if (res.statusCode == 401) throw TokenExpiredException();
        if (res.statusCode == 403) throw AccessDeniedException();
        if (res.statusCode == 429) throw RateLimitException();
        final errors = data['errors'];
        if (errors is List && errors.isNotEmpty) {
          final msg = errors.first['message']?.toString().toLowerCase() ?? '';
          if (msg.contains('rate limit')) throw RateLimitException();
          if (msg.contains('bad credentials') || msg.contains('unauthorized')) {
            throw TokenExpiredException();
          }
        }
        throw GitHubException('API Error: ${res.statusCode}',
            statusCode: res.statusCode, details: res.body);
      }
      if (data['data']?['user'] == null) throw UserNotFoundException();

      final parsed = _parse(data, username);

      await StorageService.setCachedData(parsed);
      await StorageService.recordSyncSuccess();
      unawaited(WidgetService.updateFromData(parsed));
      unawaited(_postSyncNotifications(parsed));

      return parsed;
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      rethrow;
    }
  }

  static Future<RefreshResult> syncGitHubData({
    bool force = false,
    bool isBackground = false,
  }) async {
    final username = StorageService.getUsername();
    final token = await StorageService.getToken();
    if (username == null || token == null || username.trim().isEmpty) {
      await StorageService.setHasAuthError(true);
      if (isBackground && StorageService.getDailySyncAlertEnabled()) {
        await NotificationService.showAuthErrorNotification();
      }
      return RefreshResult.authError;
    }

    final lastSync = StorageService.getEffectiveLastSync();
    if (!force && lastSync != null) {
      final diff = DateTime.now().toUtc().difference(lastSync.toUtc());
      if (diff.inMinutes < AppConstants.syncThrottleMinutes) {
        return RefreshResult.throttled;
      }
    }

    try {
      final data = await getContributions(
        username: username,
        token: token,
        forceRefresh: true,
      );
      await DailyQuoteService.ensureDailyQuote(data: data);
      final target = StorageService.getLastWallpaperTarget();
      if (StorageService.hasAppliedWallpaper() &&
          StorageService.getAutoApplyAfterSync()) {
        await WallpaperService.generateAndSetWallpaper(
          data: data,
          config: StorageService.getWallpaperConfig(),
          target: target,
          forceApply: force,
        );
      }
      await StorageService.setHasAuthError(false);
      await StorageService.consumePendingWallpaperRefresh();
      if (isBackground && StorageService.getSyncSuccessNotificationsEnabled()) {
        final successDayKey =
            AppDateUtils.formatDate(DateTime.now().toLocal());
        if (StorageService.getSyncSuccessLastSentDay() != successDayKey) {
          await NotificationService.showSyncSuccessNotification(
            syncedAt: DateTime.now().toLocal(),
          );
          await StorageService.setSyncSuccessLastSentDay(successDayKey);
        }
      }
      return RefreshResult.success;
    } on TokenExpiredException {
      await StorageService.setHasAuthError(true);
      if (isBackground && StorageService.getDailySyncAlertEnabled()) {
        await NotificationService.showAuthErrorNotification();
      }
      return RefreshResult.authError;
    } on AccessDeniedException {
      await StorageService.setHasAuthError(true);
      if (isBackground && StorageService.getDailySyncAlertEnabled()) {
        await NotificationService.showAuthErrorNotification();
      }
      return RefreshResult.authError;
    } on RateLimitException {
      return RefreshResult.throttled;
    } on NetworkException catch (e, s) {
      unawaited(TelemetryService.logSyncFailure(e, s));
      if (isBackground && StorageService.getDailySyncAlertEnabled()) {
        await NotificationService.showSyncFailureNotification();
      }
      return RefreshResult.networkError;
    } on SocketException catch (e, s) {
      unawaited(TelemetryService.logSyncFailure(e, s));
      if (isBackground && StorageService.getDailySyncAlertEnabled()) {
        await NotificationService.showSyncFailureNotification();
      }
      return RefreshResult.networkError;
    } catch (e, s) {
      AppLog.error('syncGitHubData failed: $e', s);
      unawaited(TelemetryService.logSyncFailure(e, s));
      if (isBackground && StorageService.getDailySyncAlertEnabled()) {
        await NotificationService.showSyncFailureNotification();
      }
      return RefreshResult.unknownError;
    }
  }

  static Future<http.Response> _req(String u, String t) async {
    const q =
        r'''query($login:String!,$from:DateTime!,$to:DateTime!){user(login:$login){avatarUrl contributionsCollection(from:$from,to:$to){contributionCalendar{totalContributions weeks{contributionDays{date contributionCount contributionLevel}}} commitContributionsByRepository(maxRepositories:100){repository{nameWithOwner url isPrivate primaryLanguage{name color} languages(first:20,orderBy:{field:SIZE,direction:DESC}){edges{size node{name color}}}} contributions{totalCount}}}}}''';
    final now = DateTime.now().toUtc();
    var a = 0;
    while (true) {
      try {
        final r = await _c
            .post(Uri.parse(AppConstants.apiUrl),
                headers: {
                  'Authorization': 'Bearer $t',
                  'Content-Type': 'application/json'
                },
                body: jsonEncode({
                  'query': q,
                  'variables': {
                    'login': u,
                    'from': now
                        .subtract(
                            Duration(days: AppConstants.githubDataFetchDays))
                        .toIso8601String(),
                    'to': now.toIso8601String()
                  }
                }))
            .timeout(AppConstants.apiTimeout);
        if (r.statusCode >= 500 && ++a < 3) {
          await Future.delayed(Duration(seconds: 1 << a));
          continue;
        }
        return r;
      } catch (e) {
        if (++a < 3) {
          await Future.delayed(Duration(seconds: 1 << a));
          continue;
        }
        rethrow;
      }
    }
  }

  static CachedContributionData _parse(Map<String, dynamic> j, String u) =>
      _parseGitHubResponse(j, u);

  static Future<void> _postSyncNotifications(CachedContributionData data) =>
      _dispatchPostSyncNotifications(data);

  static int _greatestMilestoneAtOrBelow(int value, List<int> milestones) =>
      _greatestMilestoneAtOrBelowValue(value, milestones);

  static Future<void> checkAuthStatus() => _checkGitHubAuthStatus();

  static void dispose() => _disposeGitHubClient();
}

CachedContributionData _parseGitHubResponse(
  Map<String, dynamic> payload,
  String username,
) {
  try {
    final user = payload['data']?['user'];
    if (user == null) throw UserNotFoundException();

    final avatarUrl = user['avatarUrl'] as String?;
    final collection = user['contributionsCollection'];
    if (collection == null) {
      throw GitHubException('Incomplete data: contributionsCollection missing');
    }

    final calendar = collection['contributionCalendar'];
    if (calendar == null) {
      throw GitHubException('Incomplete data: contributionCalendar missing');
    }

    final days = <ContributionDay>[];
    final weeks = calendar['weeks'] as List?;
    if (weeks != null) {
      for (final week in weeks) {
        final contributionDays = week['contributionDays'] as List?;
        if (contributionDays == null) continue;
        for (final day in contributionDays) {
          days.add(ContributionDay.fromJson(day));
        }
      }
    }

    final repos = <RepoContribution>[];
    final repoContribs = collection['commitContributionsByRepository'] as List?;
    if (repoContribs != null) {
      for (final repoContribution in repoContribs) {
        final contributionCount =
            repoContribution['contributions']?['totalCount'];
        final repository = repoContribution['repository'];
        if (contributionCount == null || contributionCount <= 0) continue;
        if (repository == null) continue;

        final languages = <RepoLanguageSlice>[];
        final edges = repository['languages']?['edges'] as List?;
        if (edges != null) {
          for (final language in edges) {
            if (language['node'] != null) {
              languages.add(
                RepoLanguageSlice(
                  name: language['node']['name'] ?? 'Unknown',
                  color: language['node']['color'],
                  size: language['size'] ?? 0,
                ),
              );
            }
          }
        }

        repos.add(
          RepoContribution(
            nameWithOwner: repository['nameWithOwner'] ?? 'Unknown',
            url: repository['url'] ?? '',
            isPrivate: repository['isPrivate'] ?? false,
            commitCount: contributionCount,
            primaryLanguageName: repository['primaryLanguage']?['name'],
            primaryLanguageColor: repository['primaryLanguage']?['color'],
            languages: languages,
          ),
        );
      }
    }

    repos.sort((a, b) => b.commitCount.compareTo(a.commitCount));
    return CachedContributionData(
      username: username,
      avatarUrl: avatarUrl,
      totalContributions: calendar['totalContributions'] ?? 0,
      days: days,
      lastUpdated: DateTime.now().toLocal(),
      repositories: repos,
    );
  } catch (e) {
    throw GitHubException('Parse Error: $e');
  }
}

Future<void> _dispatchPostSyncNotifications(CachedContributionData data) async {
  try {
    final now = DateTime.now().toLocal();
    final dayKey = AppDateUtils.formatDate(now);

    if (StorageService.getStreakSavedEnabled() &&
        StorageService.getStreakReminderLastSentDay() == dayKey &&
        data.todayCommits > 0 &&
        StorageService.getStreakSavedLastSentDay() != dayKey) {
      await NotificationService.showStreakSavedNotification(
        currentStreak: data.currentStreak,
      );
      await StorageService.setStreakSavedLastSentDay(dayKey);
    }

    if (StorageService.getCelebrationsEnabled()) {
      final streakMilestones = [7, 14, 30, 50, 100, 365];
      final totalMilestones = [500, 1000, 2500, 5000, 10000];

      final lastStreak = StorageService.getLastCelebratedStreakMilestone();
      final hitStreak = ContributionRepository._greatestMilestoneAtOrBelow(
        data.currentStreak,
        streakMilestones,
      );
      if (hitStreak > lastStreak) {
        await NotificationService.showCelebrationNotification(
          title: '🔥 $hitStreak‑day streak',
          body: 'Consistency looks good on you.',
        );
        await StorageService.setLastCelebratedStreakMilestone(hitStreak);
      }

      final lastTotal = StorageService.getLastCelebratedTotalMilestone();
      final hitTotal = ContributionRepository._greatestMilestoneAtOrBelow(
        data.totalContributions,
        totalMilestones,
      );
      if (hitTotal > lastTotal) {
        await NotificationService.showCelebrationNotification(
          title:
              '🚀 ${PresentationFormatter.formatCompactNumber(hitTotal)} contributions',
          body: 'Big numbers. Bigger momentum.',
        );
        await StorageService.setLastCelebratedTotalMilestone(hitTotal);
      }
    }
  } catch (e, s) {
    AppLog.error(e, s);
  }
}

int _greatestMilestoneAtOrBelowValue(int value, List<int> milestones) {
  var best = 0;
  for (final milestone in milestones) {
    if (milestone <= value && milestone > best) {
      best = milestone;
    }
  }
  return best;
}

Future<void> _checkGitHubAuthStatus() async {
  final token = await StorageService.getToken();
  if (token == null) return;

  try {
    final response = await ContributionRepository._viewerReq(
      token,
      const Duration(seconds: 5),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw TokenExpiredException();
    }
    if (response.statusCode == 200 && StorageService.hasAuthError()) {
      await StorageService.setHasAuthError(false);
    }
  } catch (e) {
    if (e is TokenExpiredException) rethrow;
    AppLog.error(e);
  }
}

void _disposeGitHubClient() => ContributionRepository._c.close();


