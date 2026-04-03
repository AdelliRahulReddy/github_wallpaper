import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/features/contributions/data/curated_quote_pool.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/features/contributions/models/quote_models.dart';
import 'package:github_wallpaper/features/contributions/services/daily_quotes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final Map<String, dynamic> mockSecureStorage = {};

  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> setupStorage() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel,
            (MethodCall call) async {
      switch (call.method) {
        case 'write':
          mockSecureStorage[call.arguments['key']] = call.arguments['value'];
          return null;
        case 'read':
          return mockSecureStorage[call.arguments['key']];
        case 'delete':
          mockSecureStorage.remove(call.arguments['key']);
          return null;
        case 'deleteAll':
          mockSecureStorage.clear();
          return null;
        case 'readAll':
          return mockSecureStorage;
        case 'containsKey':
          return mockSecureStorage.containsKey(call.arguments['key']);
        default:
          return null;
      }
    });

    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  }

  CachedContributionData buildData({
    required DateTime anchor,
    required int todayCommits,
    required int streakLength,
    int weeklyActiveDays = 5,
    int dominantRepoCommits = 24,
    int secondaryRepoCommits = 6,
  }) {
    final days = <ContributionDay>[];
    for (var offset = 29; offset >= 0; offset--) {
      final date = DateTime(anchor.year, anchor.month, anchor.day)
          .subtract(Duration(days: offset));
      int count = 0;
      if (offset == 0) {
        count = todayCommits;
      } else if (offset < streakLength) {
        count = offset.isEven ? 2 : 1;
      } else if (offset < 7 && (7 - offset) <= weeklyActiveDays) {
        count = 1;
      } else if (offset % 8 == 0) {
        count = 2;
      }
      days.add(ContributionDay(date: date, contributionCount: count));
    }

    return CachedContributionData(
      username: 'testuser',
      totalContributions: days.fold<int>(
        0,
        (sum, day) => sum + day.contributionCount,
      ),
      days: days,
      lastUpdated: anchor,
      repositories: [
        RepoContribution(
          nameWithOwner: 'team/main',
          isPrivate: false,
          commitCount: dominantRepoCommits,
          primaryLanguageName: 'Dart',
          languages: const [
            RepoLanguageSlice(name: 'Dart', color: '#0175C2', size: 80),
          ],
        ),
        RepoContribution(
          nameWithOwner: 'team/support',
          isPrivate: false,
          commitCount: secondaryRepoCommits,
          primaryLanguageName: 'Markdown',
          languages: const [
            RepoLanguageSlice(name: 'Markdown', color: '#083FA1', size: 40),
          ],
        ),
      ],
    );
  }

  setUp(() async {
    mockSecureStorage.clear();
    await setupStorage();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

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
        DailyQuoteService.normalizeCodingLevel('Regular coder'),
        'Regular',
      );
      expect(
        DailyQuoteService.normalizeCodingLevel('Hardcore developer'),
        'Hardcore',
      );
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

    test('maps weekly buckets correctly', () {
      expect(DailyQuoteService.weeklyBucket(0), 'idle');
      expect(DailyQuoteService.weeklyBucket(6), 'warming');
      expect(DailyQuoteService.weeklyBucket(14), 'steady');
      expect(DailyQuoteService.weeklyBucket(24), 'surging');
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

  test('curated quote pool stays within local cap', () {
    expect(curatedQuotePool.length, greaterThanOrEqualTo(500));
    expect(curatedQuotePool.length, lessThanOrEqualTo(maxCuratedQuoteCount));
  });

  test(
      'activity profile derives protect and focus categories from usage pattern',
      () {
    final anchor = DateTime.now().toLocal();
    final data = buildData(
      anchor: anchor,
      todayCommits: 0,
      streakLength: 9,
      weeklyActiveDays: 5,
      dominantRepoCommits: 36,
      secondaryRepoCommits: 4,
    );

    final profile = DailyQuoteService.buildActivityProfile(
      data: data,
      tone: 'Friendly',
      codingLevel: 'Regular coder',
      now: anchor,
    );

    expect(profile.categories.first, QuoteCategory.protect);
    expect(profile.categories, contains(QuoteCategory.focus));
    expect(profile.categories, contains(QuoteCategory.consistency));
  });

  test('ensureDailyQuoteResult caches same-day quote and rotates on refresh',
      () async {
    final anchor = DateTime.now().toLocal();
    final data = buildData(
      anchor: anchor,
      todayCommits: 3,
      streakLength: 11,
      weeklyActiveDays: 6,
    );

    await StorageService.setQuoteTone('Motivational');
    await StorageService.setCodingLevel('Regular coder');

    final first = await DailyQuoteService.ensureDailyQuoteResult(data: data);
    final second = await DailyQuoteService.ensureDailyQuoteResult(data: data);
    final refreshed = await DailyQuoteService.ensureDailyQuoteResult(
      data: data,
      forceRegenerate: true,
    );

    expect(first.usedFallback, isFalse);
    expect(second.fromCache, isTrue);
    expect(second.quote, first.quote);
    expect(refreshed.fromCache, isFalse);
    expect(refreshed.quote, isNotEmpty);
    expect(refreshed.quote, isNot(first.quote));
  });
}
