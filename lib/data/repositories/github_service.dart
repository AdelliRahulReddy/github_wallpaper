import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:github_wallpaper/core/errors/app_exceptions.dart';
import 'package:github_wallpaper/data/models/app_models.dart';
import 'package:github_wallpaper/shared/state/app_state.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/shared/services/daily_quotes.dart';
import 'package:github_wallpaper/shared/services/notification_service.dart';
import 'package:github_wallpaper/shared/services/refresh_result.dart';
import 'package:github_wallpaper/shared/services/telemetry_service.dart';
import 'package:github_wallpaper/data/datasources/local/storage_service.dart';
import 'package:github_wallpaper/shared/services/wallpaper_service.dart';
import 'package:github_wallpaper/shared/services/widget_service.dart';

part 'github_service_part.dart';

class GitHubService {
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
