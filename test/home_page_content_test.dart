import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/features/contributions/pages/home_page.dart';
import 'package:github_wallpaper/features/contributions/pages/stats_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final Map<String, dynamic> mockStorage = {};

  DateTime firstWeekdayOfYear(int year, int weekday) {
    final start = DateTime(year, 1, 1);
    final offset =
        (weekday - start.weekday + DateTime.daysPerWeek) % DateTime.daysPerWeek;
    return start.add(Duration(days: offset));
  }

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
    final currentYear = now.year;
    final monday = firstWeekdayOfYear(currentYear, DateTime.monday);
    final tuesday = firstWeekdayOfYear(currentYear, DateTime.tuesday);

    return CachedContributionData(
      username: 'octocat',
      totalContributions: 0,
      days: [
        ContributionDay(
            date: DateTime(currentYear - 1, 12, 31), contributionCount: 3),
        ContributionDay(date: monday, contributionCount: 5),
        ContributionDay(
          date: monday.add(const Duration(days: DateTime.daysPerWeek)),
          contributionCount: 4,
        ),
        ContributionDay(
          date: monday.add(const Duration(days: DateTime.daysPerWeek * 2)),
          contributionCount: 3,
        ),
        ContributionDay(date: tuesday, contributionCount: 2),
      ],
      lastUpdated: now,
      repositories: const [],
    );
  }

  testWidgets('Home surfaces stats CTA and clarified summary metrics',
      (tester) async {
    await setupStorage();

    var openedStats = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: HomePage(
            data: buildData(),
            isLoading: false,
            loadError: null,
            onRefresh: () async {},
            onOpenStats: () => openedStats = true,
            onOpenStudio: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('View more stats'), findsOneWidget);
    expect(find.textContaining('Best streak'), findsOneWidget);
    expect(find.text('All-time'), findsOneWidget);
    expect(find.text('This year'), findsOneWidget);
    expect(find.text('Best weekday'), findsOneWidget);
    expect(find.text('Monday'), findsOneWidget);

    await tester.tap(find.text('View more stats'));
    await tester.pump();

    expect(openedStats, isTrue);
  });

  testWidgets('Home and Stats use skeleton loading states', (tester) async {
    await setupStorage();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: HomePage(
          data: null,
          isLoading: true,
          loadError: null,
          onRefresh: () async {},
          onOpenInsights: () {},
          onOpenStudio: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('home-page-skeleton')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: StatsPage(
          data: null,
          isLoading: true,
          loadError: null,
          onRefresh: () async {},
        ),
      ),
    );

    expect(find.byKey(const Key('stats-page-skeleton')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Home exposes semantics for primary metrics and stats CTA',
      (tester) async {
    await setupStorage();

    final semanticsHandle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: HomePage(
            data: buildData(),
            isLoading: false,
            loadError: null,
            onRefresh: () async {},
            onOpenStats: () {},
            onOpenStudio: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel("Today's contribution count"), findsOneWidget);
    expect(find.bySemanticsLabel('Current streak'), findsOneWidget);
    expect(find.bySemanticsLabel('Weekly goal'), findsOneWidget);
    expect(find.bySemanticsLabel('View more stats'), findsOneWidget);

    semanticsHandle.dispose();
  });

  testWidgets('Home exposes reconnect semantics when auth needs attention',
      (tester) async {
    await setupStorage();
    await StorageService.setHasAuthError(true);
    addTearDown(() async => StorageService.setHasAuthError(false));

    final semanticsHandle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: HomePage(
            data: buildData(),
            isLoading: false,
            loadError: null,
            onRefresh: () async {},
            onOpenStats: () {},
            onOpenStudio: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Reconnect GitHub'), findsOneWidget);

    semanticsHandle.dispose();
  });
}
