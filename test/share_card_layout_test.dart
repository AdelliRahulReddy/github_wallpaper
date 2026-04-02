import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/features/contributions/services/contribution_metrics.dart';
import 'package:github_wallpaper/features/contributions/widgets/share_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final Map<String, dynamic> mockStorage = {};

  Future<void> setupStorage() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel,
            (MethodCall call) async {
      switch (call.method) {
        case 'write':
          mockStorage[call.arguments['key']] = call.arguments['value'];
          return null;
        case 'read':
          return mockStorage[call.arguments['key']];
        case 'delete':
          mockStorage.remove(call.arguments['key']);
          return null;
        case 'deleteAll':
          mockStorage.clear();
          return null;
        case 'readAll':
          return mockStorage;
        case 'containsKey':
          return mockStorage.containsKey(call.arguments['key']);
        default:
          return null;
      }
    });
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  }

  CachedContributionData buildData() {
    final now = DateTime.now().toLocal();
    final start = now.subtract(const Duration(days: 120));
    final days = List.generate(
      120,
      (index) {
        final date = start.add(Duration(days: index));
        final recentStreakStart = now.subtract(const Duration(days: 13));
        final count = !date.isBefore(recentStreakStart)
            ? (index % 4) + 1
            : (index % 3 == 0)
                ? (index % 7) + 1
                : 0;
        return ContributionDay(
          date: date,
          contributionCount: count,
        );
      },
    );

    return CachedContributionData(
      username: 'adellirahulreddy',
      avatarUrl: null,
      totalContributions: 0,
      days: days,
      lastUpdated:
          DateTime.now().toLocal().subtract(const Duration(minutes: 23)),
      repositories: const [
        RepoContribution(
          nameWithOwner: 'owner/quiet-repo',
          url: 'https://github.com/owner/quiet-repo',
          isPrivate: false,
          commitCount: 6,
          primaryLanguageName: 'Markdown',
          primaryLanguageColor: '#083FA1',
          languages: [
            RepoLanguageSlice(name: 'Markdown', color: '#083FA1', size: 100),
          ],
        ),
        RepoContribution(
          nameWithOwner: 'owner/focus-repo',
          url: 'https://github.com/owner/focus-repo',
          isPrivate: false,
          commitCount: 42,
          primaryLanguageName: 'Dart',
          primaryLanguageColor: '#0175C2',
          languages: [
            RepoLanguageSlice(name: 'Dart', color: '#0175C2', size: 80),
            RepoLanguageSlice(name: 'Shell', color: '#89E051', size: 20),
          ],
        ),
        RepoContribution(
          nameWithOwner: 'owner/private-core',
          url: 'https://github.com/owner/private-core',
          isPrivate: true,
          commitCount: 12,
          primaryLanguageName: 'TypeScript',
          primaryLanguageColor: '#3178C6',
          languages: [
            RepoLanguageSlice(name: 'TypeScript', color: '#3178C6', size: 70),
            RepoLanguageSlice(name: 'YAML', color: '#CB171E', size: 30),
          ],
        ),
      ],
    );
  }

  Future<void> expectStoryTemplateRenders(
    WidgetTester tester, {
    required ShareCardFamily family,
  }) async {
    final errors = <String>[];
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details.exceptionAsString());
    };

    const hostSize = Size(420, 900);
    final data = buildData();

    try {
      await tester.binding.setSurfaceSize(hostSize);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(size: hostSize),
              child: Center(
                child: SizedBox(
                  width: 340,
                  child: buildShareCardPreview(
                    family: family,
                    data: data,
                    trend7d: const TrendSummary(current: 11, previous: 8),
                    trend30d: const TrendSummary(current: 44, previous: 31),
                    format: ShareExportFormat.story,
                    showBranding: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      if (family == ShareCardFamily.repoFocus) {
        expect(find.text('owner/focus-repo'), findsOneWidget);
        expect(find.text('owner/quiet-repo'), findsNothing);
      }

      expect(find.byType(FittedBox), findsNothing);
      expect(
        errors.where((error) => error.contains('A RenderFlex overflowed by')),
        isEmpty,
        reason: '${family.name} story: ${errors.join('\n')}',
      );
    } finally {
      FlutterError.onError = oldOnError;
      await tester.binding.setSurfaceSize(null);
    }
  }

  testWidgets('Share card fits mobile width without overflow', (tester) async {
    await setupStorage();

    final errors = <String>[];
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details.exceptionAsString());
    };

    addTearDown(() async {
      FlutterError.onError = oldOnError;
      await tester.binding.setSurfaceSize(null);
    });

    const size = Size(360, 800);
    final data = buildData();

    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(size: size),
            child: Center(
              child: SizedBox(
                width: 340,
                child: buildShareCardPreview(
                  family: ShareCardFamily.dailyFlex,
                  data: data,
                  trend7d: const TrendSummary(current: 4, previous: 4),
                  trend30d: const TrendSummary(current: 13, previous: 92),
                  format: ShareExportFormat.story,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    FlutterError.onError = oldOnError;

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data?.toLowerCase().contains('heatmap') ?? false),
      ),
      findsOneWidget,
    );
    expect(find.byType(FittedBox), findsNothing);
    expect(
      errors.where((error) => error.contains('A RenderFlex overflowed by')),
      isEmpty,
      reason: errors.join('\n'),
    );
  });

  testWidgets('Daily Flex story renders without overflow', (tester) async {
    await setupStorage();
    await expectStoryTemplateRenders(
      tester,
      family: ShareCardFamily.dailyFlex,
    );
  });

  testWidgets('Repo Focus story renders without overflow', (tester) async {
    await setupStorage();
    await expectStoryTemplateRenders(
      tester,
      family: ShareCardFamily.repoFocus,
    );
  });

  testWidgets('Streak Milestone story renders without overflow',
      (tester) async {
    await setupStorage();
    await expectStoryTemplateRenders(
      tester,
      family: ShareCardFamily.streakMilestone,
    );
  });

  testWidgets('Monthly Snapshot story renders without overflow',
      (tester) async {
    await setupStorage();
    await expectStoryTemplateRenders(
      tester,
      family: ShareCardFamily.monthlySnapshot,
    );
  });
}
