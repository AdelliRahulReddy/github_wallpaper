import 'package:home_widget/home_widget.dart';

import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';

class WidgetService {
  WidgetService._();

  static const String _androidProviderName = 'GitWallWidgetProvider';
  static const String _iosProviderName = 'GitWallWidget';

  static const String _keyCurrentStreak = 'gitwall_current_streak';
  static const String _keyTodayCommits = 'gitwall_today_commits';
  static const String _keyTotalContributions = 'gitwall_total_contributions';
  static const String _keyUsername = 'gitwall_username';
  static const String _keyBadge = 'gitwall_widget_badge';
  static const String _keyStatus = 'gitwall_widget_status';
  static const String _keyRoute = 'gitwall_widget_route';

  static Future<void> updateFromData(CachedContributionData data) async {
    final hasProAccess =
        StorageService.getCachedMembershipInfo()?.hasProAccess ?? false;
    final route = hasProAccess
        ? 'gitwall://widget/stats?source=home_widget'
        : 'gitwall://widget/paywall?source=home_widget';
    final status = hasProAccess
        ? (data.isStale()
            ? 'Tap to open Pro stats. Data is cached.'
            : 'Tap to open your Pro insight panel.')
        : 'Tap to unlock full widget insights with Pro.';

    await _persistWidgetState(
      currentStreak: data.currentStreak,
      todayCommits: data.todayCommits,
      totalContributions: data.totalContributions,
      username: data.username,
      badge: hasProAccess ? 'PRO' : 'FREE',
      status: status,
      route: route,
    );
  }

  static Future<void> refreshFromCache() async {
    final cachedData = StorageService.getCachedData();
    if (cachedData != null) {
      await updateFromData(cachedData);
      return;
    }

    final username = StorageService.getUsername()?.trim();
    if (username != null && username.isNotEmpty) {
      await _persistWidgetState(
        currentStreak: 0,
        todayCommits: 0,
        totalContributions: 0,
        username: username,
        badge: 'SYNC',
        status: 'Open GitWall to fetch your latest GitHub data.',
        route: 'gitwall://widget/stats?source=home_widget',
      );
      return;
    }

    await clear();
  }

  static Future<void> clear() async {
    await _persistWidgetState(
      currentStreak: 0,
      todayCommits: 0,
      totalContributions: 0,
      username: 'GitWall',
      badge: 'OPEN',
      status: 'Connect GitHub to start syncing your contribution widget.',
      route: 'gitwall://widget/setup?source=home_widget',
    );
  }

  static Future<void> _persistWidgetState({
    required int currentStreak,
    required int todayCommits,
    required int totalContributions,
    required String username,
    required String badge,
    required String status,
    required String route,
  }) async {
    try {
      await Future.wait([
        HomeWidget.saveWidgetData<int>(_keyCurrentStreak, currentStreak),
        HomeWidget.saveWidgetData<int>(_keyTodayCommits, todayCommits),
        HomeWidget.saveWidgetData<int>(
          _keyTotalContributions,
          totalContributions,
        ),
        HomeWidget.saveWidgetData<String>(_keyUsername, username),
        HomeWidget.saveWidgetData<String>(_keyBadge, badge),
        HomeWidget.saveWidgetData<String>(_keyStatus, status),
        HomeWidget.saveWidgetData<String>(_keyRoute, route),
      ]);
      await HomeWidget.updateWidget(
        androidName: _androidProviderName,
        iOSName: _iosProviderName,
      );
    } catch (e, s) {
      AppLog.error('Widget update failed: $e', s);
    }
  }
}
