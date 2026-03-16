import 'app_utils.dart';

class PresentationFormatter {
  static String getGreeting() { final h = DateTime.now().hour; return h<12?'Good Morning':h<17?'Good Afternoon':'Good Evening'; }
  static String formatCompactNumber(int n) => n>=1000000?'${(n/1000000).toStringAsFixed(1)}m':n>=1000?'${(n/1000).toStringAsFixed(1)}k':'$n';
  static String formatTimeSince(DateTime d) => timeAgo(d, long:true);
  static String formatTimeAgoCompact(DateTime d) => timeAgo(d, long:false);
  static String timeAgo(DateTime d, {bool long=false}) {
    final now = DateTime.now().toUtc();
    final target = d.toUtc();
    final diff = now.difference(target);
    
    if (diff.inSeconds.abs() > 300) {
      AppLog.info('Clock drift detected: now=$now, target=$target, diff=${diff.inMinutes}m');
    }

    if(diff.inMinutes<1) return long?'Just now':'just now';
    if(diff.inMinutes<60) return long?'${diff.inMinutes} min ago (UTC)':'${diff.inMinutes}m ago (UTC)';
    if(diff.inHours<24) return long?'${diff.inHours} hr ago (UTC)':'${diff.inHours}h ago (UTC)';
    return long?'${diff.inDays} days ago (UTC)':'${diff.inDays}d ago (UTC)';
  }
}

class TrendSummary {
  final int current, previous; const TrendSummary({required this.current, required this.previous});
  double get deltaRatio => previous<=0 ? (current<=0?0.0:1.0) : (current-previous)/previous;
  String get deltaLabel => '${deltaRatio>0?'+':''}${(deltaRatio*100).toStringAsFixed(0)}% vs prev';
}

class ContributionAnalyzer {
  static Map<String, dynamic> analyzeContributions(List<dynamic> days,
      {required DateTime? nowUtc,
      required DateTime Function(dynamic) dateOf,
      required int Function(dynamic) countOf}) {
    final now = nowUtc ?? DateTime.now().toUtc();
    final sortedDays = List.from(days)..sort((a, b) => dateOf(a).compareTo(dateOf(b)));
    
    // 1. Create a map for easy O(1) date lookup
    final dayMap = <String, int>{};
    for (var d in days) {
      final raw = dateOf(d).toUtc();
      dayMap[AppDateUtils.formatDate(DateTime.utc(raw.year, raw.month, raw.day))] =
          countOf(d);
    }

    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final todayStr = AppDateUtils.formatDate(todayUtc);

    // 2. Identify Current Streak
    int currentStreak = 0;
    DateTime checkDate = todayUtc;
    
    // If today is 0, we can still have a streak from yesterday (grace period)
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

    // 3. Identify Longest Streak, Total, Peak, etc.
    int longestStreak = 0;
    int totalContributions = 0;
    int activeDaysCount = 0;
    int peakDayContributions = 0;
    int tempStreak = 0;
    DateTime? prevDate;

    for (var d in sortedDays) {
      final raw = dateOf(d).toUtc();
      final date = DateTime.utc(raw.year, raw.month, raw.day);
      final count = countOf(d);
      
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

    // 4. Weekday analysis
    final weekdayCounts = <int, int>{};
    for (var entry in dayMap.entries) {
      final date = AppDateUtils.parseDate(entry.key)!;
      weekdayCounts[date.weekday] = (weekdayCounts[date.weekday] ?? 0) + entry.value;
    }
    
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    int maxWeekday = 1;
    int maxWCount = -1;
    for (int i = 1; i <= 7; i++) {
       final c = weekdayCounts[i] ?? 0;
       if (c > maxWCount) {
         maxWCount = c;
         maxWeekday = i;
       }
    }

    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalContributions': totalContributions,
      'activeDaysCount': activeDaysCount,
      'peakDayContributions': peakDayContributions,
      'todayContributions': dayMap[todayStr] ?? 0,
      'mostActiveWeekday': weekdays[maxWeekday - 1],
    };
  }

  static TrendSummary computeTrend(List<dynamic> days,
      {required int window,
      required DateTime Function(dynamic) dateOf,
      required int Function(dynamic) countOf}) {
    final nowUtc = DateTime.now().toUtc();
    final today = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
    
    int current = 0;
    int previous = 0;
    
    final currentStart = today.subtract(Duration(days: window));
    final previousStart = today.subtract(Duration(days: window * 2));
    
    for (var d in days) {
      final raw = dateOf(d).toUtc();
      final date = DateTime.utc(raw.year, raw.month, raw.day);
      final count = countOf(d);
      
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
  static bool isStale(DateTime lastUpdated, {Duration threshold = const Duration(hours: 6)}) {
    final now = DateTime.now().toUtc();
    return now.difference(lastUpdated.toUtc()).abs() > threshold;
  }
}
