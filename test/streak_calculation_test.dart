import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/data/models/app_models.dart';
import 'package:github_wallpaper/shared/state/app_state.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';

void main() {
  group('ContributionAnalyzer Streaks & Today', () {
    test('identifies Today correctly in local timezone', () {
      final days = [
        ContributionDay(date: DateTime.utc(2026, 2, 13), contributionCount: 5),
        ContributionDay(date: DateTime.utc(2026, 2, 14), contributionCount: 10),
      ];

      final results = ContributionAnalyzer.analyzeContributions(
        days,
        dateOf: (d) => d.date,
        countOf: (d) => d.contributionCount,
        nowUtc: DateTime.utc(2026, 2, 13, 23, 0),
      );

      expect(results['todayContributions'], 10);
      expect(results['currentStreak'], 2);
    });

    test('streak breaks correctly on missed day', () {
      final days = [
        ContributionDay(date: DateTime.utc(2026, 2, 11), contributionCount: 5),
        ContributionDay(date: DateTime.utc(2026, 2, 12), contributionCount: 5),
        // Missed Feb 13
        ContributionDay(date: DateTime.utc(2026, 2, 14), contributionCount: 10),
      ];

      final results = ContributionAnalyzer.analyzeContributions(
        days,
        dateOf: (d) => d.date,
        countOf: (d) => d.contributionCount,
        nowUtc: DateTime(2026, 2, 14, 12, 0).toUtc(),
      );

      // Streak should be 1 (only today) because 13th was missed.
      expect(results['currentStreak'], 1);
      expect(results['longestStreak'], 2); // 11th and 12th
    });

    test('grace period (yesterday) maintains streak', () {
       final days = [
        ContributionDay(date: DateTime.utc(2026, 2, 12), contributionCount: 5),
        ContributionDay(date: DateTime.utc(2026, 2, 13), contributionCount: 5),
        // No contributions on Feb 14 (Yet)
      ];

      final results = ContributionAnalyzer.analyzeContributions(
        days,
        dateOf: (d) => d.date,
        countOf: (d) => d.contributionCount,
        nowUtc: DateTime(2026, 2, 14, 12, 0).toUtc(), // Today is Feb 14
      );

      // Streak should still be 2 because 13th has contributions (grace period)
      expect(results['currentStreak'], 2);
    });

    test('parses GitHub day keys as UTC then converts to local', () {
      final parsed = AppDateUtils.parseDate('2026-02-14');
      final expected = DateTime.utc(2026, 2, 14).toLocal();
      expect(parsed, isNotNull);
      expect(parsed!.year, expected.year);
      expect(parsed.month, expected.month);
      expect(parsed.day, expected.day);
    });
  });
}
