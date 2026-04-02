import 'package:github_wallpaper/app/product/models/product_models.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/features/contributions/services/contribution_metrics.dart';

class InsightEngine {
  static const List<int> _streakMilestones = [7, 14, 30, 50, 100, 365];
  static const List<int> _totalContributionMilestones = [
    100,
    250,
    500,
    1000,
    2500,
    5000,
    10000,
  ];

  static InsightSnapshot build(RawSnapshot raw, {DateTime? now}) {
    final source = raw.data;
    final today = _normalizeDate((now ?? DateTime.now()).toLocal());
    final weekStart = today.subtract(const Duration(days: 6));
    final previousWeekStart = today.subtract(const Duration(days: 13));
    final monthStart = today.subtract(const Duration(days: 29));
    final previousMonthStart = today.subtract(const Duration(days: 59));

    final weeklyTotal = _sumRange(source.days, weekStart, today);
    final previousWeeklyTotal = _sumRange(
      source.days,
      previousWeekStart,
      weekStart.subtract(const Duration(days: 1)),
    );
    final monthlyTotal = _sumRange(source.days, monthStart, today);
    final previousMonthlyTotal = _sumRange(
      source.days,
      previousMonthStart,
      monthStart.subtract(const Duration(days: 1)),
    );
    final activeDaysThisWeek =
        _activeDaysInRange(source.days, weekStart, today);
    final activeDaysThisMonth =
        _activeDaysInRange(source.days, monthStart, today);
    final bestWeekTotal = _bestRollingWindowTotal(source.days, windowDays: 7);
    final peakDay = ContributionAnalyzer.findPeakDay<ContributionDay>(
      source.days,
      dateOf: (day) => day.date,
      countOf: (day) => day.contributionCount,
    );
    final averagePerActiveDay = ContributionAnalyzer.averagePerActiveDay(
      source.days,
      countOf: (day) => day.contributionCount,
    );
    final consistencyScore = source.days.isEmpty
        ? 0.0
        : ((activeDaysThisWeek / 7) * 100).clamp(0, 100).toDouble();

    return InsightSnapshot(
      generatedAt: today,
      totalContributions: source.totalContributions,
      currentStreak: source.currentStreak,
      longestStreak: source.longestStreak,
      todayContributions: source.todayCommits,
      activeDaysCount: source.activeDaysCount,
      weeklyTotal: weeklyTotal,
      previousWeeklyTotal: previousWeeklyTotal,
      monthlyTotal: monthlyTotal,
      previousMonthlyTotal: previousMonthlyTotal,
      activeDaysThisWeek: activeDaysThisWeek,
      activeDaysThisMonth: activeDaysThisMonth,
      bestWeekTotal: bestWeekTotal,
      peakDayDate: peakDay?.date,
      peakDayCount: peakDay?.count ?? 0,
      mostActiveWeekday: source.mostActiveWeekday,
      averagePerActiveDay: averagePerActiveDay,
      consistencyScore: consistencyScore,
      trend7d: ContributionAnalyzer.computeTrend(
        source.days,
        window: 7,
        dateOf: (day) => day.date,
        countOf: (day) => day.contributionCount,
      ),
      trend30d: ContributionAnalyzer.computeTrend(
        source.days,
        window: 30,
        dateOf: (day) => day.date,
        countOf: (day) => day.contributionCount,
      ),
      topRepository:
          source.repositories.where((repo) => repo.commitCount > 0).firstOrNull,
      topLanguage: source.topLanguages.firstOrNull,
      streakMilestone:
          _greatestMilestoneAtOrBelow(source.currentStreak, _streakMilestones),
      contributionMilestone: _greatestMilestoneAtOrBelow(
        source.totalContributions,
        _totalContributionMilestones,
      ),
    );
  }

  static DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static int _sumRange(
    List<ContributionDay> days,
    DateTime start,
    DateTime end,
  ) {
    var total = 0;
    for (final day in days) {
      final date = _normalizeDate(day.date.toLocal());
      if (date.isBefore(start) || date.isAfter(end)) {
        continue;
      }
      total += day.contributionCount;
    }
    return total;
  }

  static int _activeDaysInRange(
    List<ContributionDay> days,
    DateTime start,
    DateTime end,
  ) {
    var activeDays = 0;
    for (final day in days) {
      final date = _normalizeDate(day.date.toLocal());
      if (date.isBefore(start) || date.isAfter(end)) {
        continue;
      }
      if (day.contributionCount > 0) {
        activeDays += 1;
      }
    }
    return activeDays;
  }

  static int _bestRollingWindowTotal(
    List<ContributionDay> days, {
    required int windowDays,
  }) {
    if (days.isEmpty || windowDays <= 0) {
      return 0;
    }

    final normalized = days.toList()..sort((a, b) => a.date.compareTo(b.date));
    var best = 0;
    for (var index = 0; index < normalized.length; index++) {
      final start = _normalizeDate(normalized[index].date.toLocal());
      final end = start.add(Duration(days: windowDays - 1));
      final total = _sumRange(normalized, start, end);
      if (total > best) {
        best = total;
      }
    }
    return best;
  }

  static int? _greatestMilestoneAtOrBelow(int value, List<int> milestones) {
    var best = 0;
    for (final milestone in milestones) {
      if (milestone <= value && milestone > best) {
        best = milestone;
      }
    }
    return best == 0 ? null : best;
  }
}
