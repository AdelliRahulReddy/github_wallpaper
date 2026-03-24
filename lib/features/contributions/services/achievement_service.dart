import 'package:flutter/material.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/features/contributions/services/contribution_metrics.dart';

class AchievementService {
  static const List<int> _streakMilestones = [3, 7, 14, 21, 30, 50, 75, 100];

  static List<HomeAchievement> buildHomeAchievements({
    required CachedContributionData data,
    required int weeklyGoal,
    DateTime? now,
  }) {
    final currentTime = (now ?? DateTime.now()).toLocal();
    final today =
        DateTime(currentTime.year, currentTime.month, currentTime.day);
    final weekStart = today.subtract(const Duration(days: 6));

    var weeklyTotal = 0;
    var weekActiveDays = 0;
    for (final contributionDay in data.days) {
      final localDate = contributionDay.date.toLocal();
      final day = DateTime(localDate.year, localDate.month, localDate.day);
      final inCurrentWeek = !day.isBefore(weekStart) && !day.isAfter(today);
      if (!inCurrentWeek) continue;

      weeklyTotal += contributionDay.contributionCount;
      if (contributionDay.contributionCount > 0) {
        weekActiveDays += 1;
      }
    }

    final peakDay = ContributionAnalyzer.findPeakDay(
      data.days,
      dateOf: (day) => day.date,
      countOf: (day) => day.contributionCount,
    );

    return [
      HomeAchievement(
        icon: Icons.local_fire_department_outlined,
        title: 'Week\nWarrior',
        isUnlocked: weekActiveDays >= 4,
        requirementLabel: '$weekActiveDays/4 active days this week',
      ),
      HomeAchievement(
        icon: Icons.flash_on_outlined,
        title: 'Speed\nDemon',
        isUnlocked: data.stats.todayContributions >= 5,
        requirementLabel: '${data.stats.todayContributions}/5 commits today',
      ),
      HomeAchievement(
        icon: Icons.gps_fixed,
        title: 'Goal\nCrusher',
        isUnlocked: weeklyTotal >= weeklyGoal,
        requirementLabel: '$weeklyTotal/$weeklyGoal weekly commits',
      ),
      HomeAchievement(
        icon: Icons.emoji_events_outlined,
        title: 'Century\nClub',
        isUnlocked: data.totalContributions >= 100,
        requirementLabel: '${data.totalContributions}/100 recent commits',
      ),
      HomeAchievement(
        icon: Icons.bolt_outlined,
        title: 'Peak\nPerformer',
        isUnlocked: (peakDay?.count ?? 0) >= 10,
        requirementLabel: '${peakDay?.count ?? 0}/10 commits in one day',
      ),
      HomeAchievement(
        icon: Icons.timeline_outlined,
        title: 'Streak\nStarter',
        isUnlocked: data.stats.currentStreak >= 3,
        requirementLabel: '${data.stats.currentStreak}/3 current streak',
      ),
      HomeAchievement(
        icon: Icons.military_tech_outlined,
        title: 'Champion\nStreak',
        isUnlocked: data.stats.longestStreak >= 14,
        requirementLabel: '${data.stats.longestStreak}/14 recent best streak',
      ),
      HomeAchievement(
        icon: Icons.diamond_outlined,
        title: 'Consistent\nCoder',
        isUnlocked: data.stats.activeDaysCount >= 30,
        requirementLabel: '${data.stats.activeDaysCount}/30 recent active days',
      ),
    ];
  }

  static Future<void> maybeNotify(
    BuildContext context, {
    CachedContributionData? previous,
    required CachedContributionData current,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final prevLongest = previous?.stats.longestStreak ?? 0;
    final currLongest = current.stats.longestStreak;
    final seenLongest = StorageService.getSeenLongestStreak();

    if (currLongest > prevLongest && currLongest > seenLongest) {
      await StorageService.setSeenLongestStreak(currLongest);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('New longest streak achieved'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    final currStreak = current.stats.currentStreak;
    final seenMilestone = StorageService.getSeenStreakMilestone();
    final reached = _streakMilestones.where((m) => m <= currStreak).fold<int>(
        0, (best, m) => m > best ? m : best);

    if (reached > 0 && reached > seenMilestone) {
      await StorageService.setSeenStreakMilestone(reached);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Streak milestone: $reached days'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

@immutable
class HomeAchievement {
  final IconData icon;
  final String title;
  final bool isUnlocked;
  final String requirementLabel;

  const HomeAchievement({
    required this.icon,
    required this.title,
    required this.isUnlocked,
    required this.requirementLabel,
  });
}

