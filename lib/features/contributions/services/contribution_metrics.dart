import 'package:github_wallpaper/core/utils/app_utils.dart';

class PresentationFormatter {
  static String getGreeting() {
    final hour = DateTime.now().hour;
    return hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
  }

  static String formatCompactNumber(int number) => number >= 1000000
      ? '${(number / 1000000).toStringAsFixed(1)}m'
      : number >= 1000
          ? '${(number / 1000).toStringAsFixed(1)}k'
          : '$number';

  static String formatTimeSince(DateTime date) => timeAgo(date, long: true);

  static String formatTimeAgoCompact(DateTime date) =>
      timeAgo(date, long: false);

  static String timeAgo(DateTime date, {bool long = false}) {
    final now = DateTime.now().toLocal();
    final target = date.toLocal();
    final diff = now.difference(target);

    if (diff.inSeconds.abs() > 300) {
      AppLog.info(
        'Clock drift detected: now=$now, target=$target, diff=${diff.inMinutes}m',
      );
    }

    if (diff.inMinutes < 1) {
      return long ? 'Just now' : 'just now';
    }
    if (diff.inMinutes < 60) {
      return long ? '${diff.inMinutes} min ago' : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return long ? '${diff.inHours} hr ago' : '${diff.inHours}h ago';
    }
    return long ? '${diff.inDays} days ago' : '${diff.inDays}d ago';
  }
}

class TrendSummary {
  final int current;
  final int previous;

  const TrendSummary({
    required this.current,
    required this.previous,
  });

  double get deltaRatio => previous <= 0
      ? (current <= 0 ? 0.0 : 1.0)
      : (current - previous) / previous;

  String get deltaLabel =>
      '${deltaRatio > 0 ? '+' : ''}${(deltaRatio * 100).toStringAsFixed(0)}% vs prev';
}

class ContributionAnalyzer {
  static Map<String, dynamic> analyzeContributions(
    List<dynamic> days, {
    required DateTime? nowUtc,
    required DateTime Function(dynamic) dateOf,
    required int Function(dynamic) countOf,
  }) {
    final now = (nowUtc ?? DateTime.now()).toLocal();
    final sortedDays = List.from(days)
      ..sort((a, b) => dateOf(a).compareTo(dateOf(b)));

    final dayMap = <String, int>{};
    for (final day in days) {
      final raw = dateOf(day).toLocal();
      dayMap[AppDateUtils.formatDate(DateTime(raw.year, raw.month, raw.day))] =
          countOf(day);
    }

    final todayUtc = DateTime(now.year, now.month, now.day);
    final todayStr = AppDateUtils.formatDate(todayUtc);

    var currentStreak = 0;
    var checkDate = todayUtc;

    if ((dayMap[todayStr] ?? 0) <= 0) {
      checkDate = todayUtc.subtract(const Duration(days: 1));
    }

    while (true) {
      final dateStr = AppDateUtils.formatDate(checkDate);
      if ((dayMap[dateStr] ?? 0) > 0) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    var longestStreak = 0;
    var totalContributions = 0;
    var activeDaysCount = 0;
    var peakDayContributions = 0;
    var tempStreak = 0;
    DateTime? prevDate;

    for (final day in sortedDays) {
      final raw = dateOf(day).toLocal();
      final date = DateTime(raw.year, raw.month, raw.day);
      final count = countOf(day);

      if (count > 0) {
        totalContributions += count;
        activeDaysCount++;
        if (count > peakDayContributions) peakDayContributions = count;

        if (prevDate != null) {
          final diff = date.difference(prevDate).inDays;
          if (diff == 1) {
            tempStreak++;
          } else {
            if (tempStreak > longestStreak) longestStreak = tempStreak;
            tempStreak = 1;
          }
        } else {
          tempStreak = 1;
        }
        prevDate = date;
      } else {
        if (tempStreak > longestStreak) longestStreak = tempStreak;
        tempStreak = 0;
        prevDate = null;
      }
    }

    if (tempStreak > longestStreak) longestStreak = tempStreak;

    final weekdayCounts = <int, int>{};
    for (final entry in dayMap.entries) {
      final date = AppDateUtils.parseDate(entry.key)!;
      weekdayCounts[date.weekday] =
          (weekdayCounts[date.weekday] ?? 0) + entry.value;
    }

    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    var mostActiveWeekday = AppConstants.fallbackWeekday;
    if (totalContributions > 0) {
      var maxWeekday = 1;
      var maxWeekdayCount = -1;
      for (var index = 1; index <= 7; index++) {
        final count = weekdayCounts[index] ?? 0;
        if (count > maxWeekdayCount) {
          maxWeekdayCount = count;
          maxWeekday = index;
        }
      }
      mostActiveWeekday = weekdays[maxWeekday - 1];
    }

    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalContributions': totalContributions,
      'activeDaysCount': activeDaysCount,
      'peakDayContributions': peakDayContributions,
      'todayContributions': dayMap[todayStr] ?? 0,
      'mostActiveWeekday': mostActiveWeekday,
    };
  }

  static ({DateTime date, int count})? findPeakDay<T>(
    List<T> days, {
    required DateTime Function(T) dateOf,
    required int Function(T) countOf,
  }) {
    DateTime? bestDate;
    var bestCount = 0;

    for (final day in days) {
      final count = countOf(day);
      if (count <= 0) continue;

      final rawDate = dateOf(day).toLocal();
      final normalizedDate = DateTime(rawDate.year, rawDate.month, rawDate.day);

      if (count > bestCount ||
          (count == bestCount &&
              bestDate != null &&
              normalizedDate.isAfter(bestDate))) {
        bestCount = count;
        bestDate = normalizedDate;
      }
    }

    if (bestDate == null || bestCount <= 0) return null;
    return (date: bestDate, count: bestCount);
  }

  static double averagePerActiveDay<T>(
    List<T> days, {
    required int Function(T) countOf,
  }) {
    var total = 0;
    var activeDays = 0;

    for (final day in days) {
      final count = countOf(day);
      if (count <= 0) continue;
      total += count;
      activeDays += 1;
    }

    if (activeDays == 0) return 0;
    return total / activeDays;
  }

  static TrendSummary computeTrend(
    List<dynamic> days, {
    required int window,
    required DateTime Function(dynamic) dateOf,
    required int Function(dynamic) countOf,
  }) {
    final nowUtc = DateTime.now().toLocal();
    final today = DateTime(nowUtc.year, nowUtc.month, nowUtc.day);

    var current = 0;
    var previous = 0;

    final currentStart = today.subtract(Duration(days: window - 1));
    final previousStart = today.subtract(Duration(days: (window * 2) - 1));

    for (final day in days) {
      final raw = dateOf(day).toLocal();
      final date = DateTime(raw.year, raw.month, raw.day);
      final count = countOf(day);

      if (!date.isBefore(currentStart) && !date.isAfter(today)) {
        current += count;
      } else if (!date.isBefore(previousStart) && date.isBefore(currentStart)) {
        previous += count;
      }
    }

    return TrendSummary(current: current, previous: previous);
  }
}

class CacheValidator {
  static bool isStale(
    DateTime lastUpdated, {
    Duration threshold = const Duration(hours: 6),
  }) {
    final now = DateTime.now().toLocal();
    return now.difference(lastUpdated.toLocal()).abs() > threshold;
  }
}
