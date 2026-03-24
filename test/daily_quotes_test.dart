import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/features/contributions/services/daily_quotes.dart';

void main() {
  group('DailyQuoteService bucket mapping', () {
    test('normalizes legacy tone values', () {
      expect(DailyQuoteService.normalizeTone('friendly'), 'Friendly');
      expect(DailyQuoteService.normalizeTone('Roast'), 'Roast');
      expect(DailyQuoteService.normalizeTone('something else'), 'Motivational');
    });

    test('normalizes legacy coding level values', () {
      expect(DailyQuoteService.normalizeCodingLevel('New to coding'), 'New');
      expect(DailyQuoteService.normalizeCodingLevel('Beginner'), 'Beginner');
      expect(
          DailyQuoteService.normalizeCodingLevel('Regular coder'), 'Regular');
      expect(DailyQuoteService.normalizeCodingLevel('Hardcore developer'),
          'Hardcore');
    });

    test('maps streak buckets correctly', () {
      expect(DailyQuoteService.streakBucket(0), '0d');
      expect(DailyQuoteService.streakBucket(2), '1_3d');
      expect(DailyQuoteService.streakBucket(6), '4_7d');
      expect(DailyQuoteService.streakBucket(12), '8_14d');
      expect(DailyQuoteService.streakBucket(25), '15_30d');
      expect(DailyQuoteService.streakBucket(45), '31_60d');
      expect(DailyQuoteService.streakBucket(88), '61_100d');
      expect(DailyQuoteService.streakBucket(150), '100pd');
    });

    test('maps commit buckets correctly', () {
      expect(DailyQuoteService.commitsBucket(0), '0c');
      expect(DailyQuoteService.commitsBucket(2), '1_2c');
      expect(DailyQuoteService.commitsBucket(5), '3_5c');
      expect(DailyQuoteService.commitsBucket(6), '6pc');
    });

    test('builds stable profile keys for pooled quote docs', () {
      final key = DailyQuoteService.buildProfileKey(
        streak: 18,
        commitsToday: 2,
        tone: 'Motivational',
        codingLevel: 'Regular coder',
      );

      expect(key, '15_30d_Motivational_Regular_1_2c');
    });
  });
}

