import 'package:home_widget/home_widget.dart';
import 'package:github_wallpaper/app_models.dart';
import 'package:github_wallpaper/app_utils.dart';

class WidgetService {
  static const String _androidProviderName = 'GitWallWidgetProvider';
  static const String _iosProviderName = 'GitWallWidget';

  static Future<void> updateFromData(CachedContributionData data) async {
    try {
      await HomeWidget.saveWidgetData<int>(
          'gitwall_current_streak', data.currentStreak);
      await HomeWidget.saveWidgetData<int>(
          'gitwall_today_commits', data.todayCommits);
      await HomeWidget.saveWidgetData<int>(
          'gitwall_total_contributions', data.totalContributions);
      await HomeWidget.saveWidgetData<String>('gitwall_username', data.username);
      await HomeWidget.updateWidget(
        androidName: _androidProviderName,
        iOSName: _iosProviderName,
      );
    } catch (e) {
      AppLog.error('Widget update failed: $e');
    }
  }
}

