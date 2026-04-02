import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/features/contributions/pages/home_page.dart';
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
    final start = DateTime.now().toLocal().subtract(const Duration(days: 120));
    final days = List.generate(
      120,
      (i) => ContributionDay(
        date: start.add(Duration(days: i)),
        contributionCount: (i % 4 == 0) ? (i % 9) + 1 : 0,
      ),
    );

    return CachedContributionData(
      username: 'octocat',
      totalContributions: 0,
      days: days,
      lastUpdated: DateTime.now().toLocal(),
      repositories: const [],
    );
  }

  testWidgets('Home share button opens share chooser sheet', (tester) async {
    await setupStorage();
    final data = buildData();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: HomePage(
            data: data,
            isLoading: false,
            loadError: null,
            onRefresh: () async {},
            onOpenInsights: () {},
            onOpenStudio: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Share'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Share this moment'), findsOneWidget);
    expect(find.text('Use best fit'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    expect(find.byKey(const Key('share-primary-cta')), findsOneWidget);
    expect(find.byKey(const Key('share-family-rail')), findsOneWidget);
    expect(find.text('Daily Flex'), findsWidgets);
    expect(find.text('Repo Focus'), findsWidgets);
    expect(find.text('Streak Milestone'), findsWidgets);
    expect(find.byType(ChoiceChip), findsNothing);

    await tester.drag(
      find.byKey(const Key('share-family-rail')),
      const Offset(-240, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Monthly Snapshot'), findsWidgets);
    expect(find.text('Wrapped'), findsNothing);
    expect(find.text('Social 4:5'), findsNothing);
    expect(find.text('Square 1:1'), findsNothing);
  });
}
