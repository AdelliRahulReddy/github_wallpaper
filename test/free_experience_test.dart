import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/features/contributions/pages/stats_page.dart';
import 'package:github_wallpaper/features/settings/controllers/settings_controller.dart';
import 'package:github_wallpaper/features/settings/controllers/theme_controller.dart';
import 'package:github_wallpaper/features/settings/pages/settings_page.dart';
import 'package:github_wallpaper/features/wallpaper/pages/customize_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final Map<String, dynamic> mockStorage = {};

  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> setupStorage() async {
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
    await StorageService.saveDeviceMetrics(
      width: 1080,
      height: 2400,
      pixelRatio: 3.0,
      safeInsets: const EdgeInsets.only(top: 48, bottom: 34),
    );
  }

  CachedContributionData buildData() {
    final currentYear = DateTime.now().toLocal().year;
    final start = DateTime.utc(currentYear - 1, 1, 1);
    final days = List.generate(
      430,
      (index) => ContributionDay(
        date: start.add(Duration(days: index)),
        contributionCount: index % 11 == 0 ? 8 : 0,
      ),
    );

    return CachedContributionData(
      username: 'testuser',
      totalContributions: days.fold<int>(
        0,
        (sum, day) => sum + day.contributionCount,
      ),
      days: days,
      lastUpdated: DateTime.utc(currentYear, 3, 1),
      repositories: const [],
    );
  }

  setUp(() async {
    mockStorage.clear();
    await setupStorage();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  testWidgets('Settings removes monetization actions and still opens support',
      (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsController()),
          ChangeNotifierProvider(create: (_) => ThemeController()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Upgrade to Pro'), findsNothing);
    expect(find.text('Restore Purchase'), findsNothing);
    expect(find.text('Subscription'), findsNothing);
    expect(find.text('Redeem Coupon'), findsNothing);

    final supportTile = find.widgetWithText(ListTile, 'Support');
    await tester.ensureVisible(supportTile);
    await tester.tap(supportTile, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('About & Support'), findsOneWidget);
    expect(find.text(AppStrings.freeForeverBanner), findsOneWidget);
  });

  testWidgets('Customize shows included templates without locked messaging',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: CustomizePage(
            data: buildData(),
            onSetWallpaper: (_) async => true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Templates'), findsWidgets);
    expect(find.textContaining('Minimal Dark'), findsWidgets);
    expect(find.text('Swipe to explore • Tap to apply'), findsOneWidget);
    expect(find.textContaining('Locked templates stay visible'), findsNothing);
  });

  testWidgets('Stats allows switching to previous years without account tiers',
      (tester) async {
    final data = buildData();
    final previousYear = data.days.first.date.toLocal().year;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: StatsPage(
          data: data,
          isLoading: false,
          loadError: null,
          onRefresh: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.expand_more_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('$previousYear').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('contributions in $previousYear'),
      findsOneWidget,
    );
  });
}
