import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/app_models.dart';
import 'package:github_wallpaper/app_state.dart';

void main() {
  group('ContributionAnalyzer Streaks & Today', () {
    test('identifies Today correctly in local time', () {
      final days = [
        ContributionDay(date: DateTime.utc(2026, 2, 13), contributionCount: 5),
        ContributionDay(date: DateTime.utc(2026, 2, 14), contributionCount: 10),
      ];

      // Simulated local time: Feb 14, 01:00 AM. 
      // We want to ensure that even if UTC is still Feb 13, 
      // if local time is Feb 14, it treats Feb 14 as "Today".
      
      // Since analyzeContributions uses nowUtc?.toLocal(), we provide a time 
      // that is Feb 14 in local time.
      final localNow = DateTime(2026, 2, 14, 1, 0); 
      
      final results = ContributionAnalyzer.analyzeContributions(
        days,
        dateOf: (d) => d.date,
        countOf: (d) => d.contributionCount,
        nowUtc: localNow.toUtc(), 
      );

      // It should use nowUtc.toLocal() which is 2026-02-14
      expect(results['todayContributions'], 10);
      expect(results['currentStreak'], 2); // 13th and 14th
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
  });
}
