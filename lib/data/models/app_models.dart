// 📊 DATA MODELS - Optimized
import 'package:flutter/foundation.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/shared/state/app_state.dart';
import 'package:github_wallpaper/data/models/theme_presets.dart';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';


part 'app_models_repository_models.dart';
part 'app_models_cached_data.dart';
part 'app_models_wallpaper_config.dart';

enum WallpaperTarget {
  home,
  lock,
  both;

  int toManagerConstant() {
    switch (this) {
      case WallpaperTarget.home:
        return WallpaperManagerPlus.homeScreen;
      case WallpaperTarget.lock:
        return WallpaperManagerPlus.lockScreen;
      case WallpaperTarget.both:
        return WallpaperManagerPlus.bothScreens;
    }
  }
}

// Helper to get formatted date string for keys
String _dateStr(DateTime d) => AppDateUtils.formatDate(d);
String? _str(dynamic v) =>
    (v is String && v.trim().isNotEmpty) ? v.trim() : null;
double _dbl(dynamic v, double d, double min, double max) =>
    ((v is num ? v.toDouble() : d).clamp(min, max)).toDouble();
DateTime _requiredContributionDate(dynamic raw) {
  final parsed = AppDateUtils.parseDate(raw?.toString());
  if (parsed == null) {
    throw FormatException('Invalid contribution date: $raw');
  }
  return parsed;
}

@immutable
class ContributionDay {
  final DateTime date;
  final int contributionCount;
  final String? contributionLevel;
  const ContributionDay(
      {required this.date,
      required this.contributionCount,
      this.contributionLevel});

  factory ContributionDay.fromJson(Map<String, dynamic> j) => ContributionDay(
      date: _requiredContributionDate(j['date']),
      contributionCount: (j['contributionCount'] as num?)?.toInt() ?? 0,
      contributionLevel: (j['contributionLevel'] as String?));

  Map<String, dynamic> toJson() => {
        'date': AppDateUtils.formatDate(date),
        'contributionCount': contributionCount,
        'contributionLevel': contributionLevel
      };

  bool get isActive => contributionCount > 0;
  String get dateKey => _dateStr(date);

  static int _lvl(String? l) {
    switch (l) {
      case 'FOURTH_QUARTILE':
        return 4;
      case 'THIRD_QUARTILE':
        return 3;
      case 'SECOND_QUARTILE':
        return 2;
      case 'FIRST_QUARTILE':
        return 1;
      default:
        return 0;
    }
  }

  static String? strongestLevel(String? a, String? b) =>
      _lvl(b) > _lvl(a) ? b : a;
}

@immutable
class ContributionStats {
  final int currentStreak,
      longestStreak,
      todayContributions,
      activeDaysCount,
      peakDayContributions,
      totalContributions;
  final String mostActiveWeekday;
  const ContributionStats(
      {required this.currentStreak,
      required this.longestStreak,
      required this.todayContributions,
      required this.activeDaysCount,
      required this.peakDayContributions,
      required this.totalContributions,
      required this.mostActiveWeekday});

  factory ContributionStats.fromDays(List<ContributionDay> days,
      {DateTime? nowUtc}) {
    final s = ContributionAnalyzer.analyzeContributions(days,
        nowUtc: nowUtc,
        dateOf: (d) => d.date,
        countOf: (d) => d.contributionCount);
    return ContributionStats(
        currentStreak: s['currentStreak'],
        longestStreak: s['longestStreak'],
        todayContributions: s['todayContributions'],
        activeDaysCount: s['activeDaysCount'],
        peakDayContributions: s['peakDayContributions'],
        totalContributions: s['totalContributions'],
        mostActiveWeekday: s['mostActiveWeekday']);
  }
}
