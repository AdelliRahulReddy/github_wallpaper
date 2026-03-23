import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/data/models/app_models.dart';
import 'package:github_wallpaper/features/wallpaper/screens/customize/customize_screen.dart';
import 'package:github_wallpaper/features/settings/screens/settings_screen.dart';
import 'package:github_wallpaper/data/datasources/local/storage_service.dart';
import 'package:github_wallpaper/shared/state/app_state.dart';
import 'package:github_wallpaper/shared/state/membership_state.dart';
import 'package:github_wallpaper/data/models/membership_models.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
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
    final start = DateTime.utc(2025, 1, 1);
    final days = List.generate(
      370,
      (i) => ContributionDay(
        date: start.add(Duration(days: i)),
        contributionCount: i % 11 == 0 ? 8 : 0,
      ),
    );

    return CachedContributionData(
      username: 'testuser',
      totalContributions: days.fold<int>(
        0,
        (sum, day) => sum + day.contributionCount,
      ),
      days: days,
      lastUpdated: DateTime.utc(2026, 3, 1),
      repositories: const [],
    );
  }

  setUp(() async {
    mockStorage.clear();
    await setupStorage();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  testWidgets('Settings shows cleaned membership actions and support screen',
      (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsPreferencesState()),
          ChangeNotifierProvider(create: (_) => ThemeModeState()),
          ChangeNotifierProvider(create: (_) => MembershipState()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.supportUs), findsNothing);
    expect(find.text('Upgrade to Pro'), findsOneWidget);
    expect(find.text('Restore Purchase'), findsNothing);
    expect(find.text('Subscription'), findsOneWidget);
    expect(find.text('Redeem Coupon'), findsOneWidget);
    expect(find.text('Weekly goal'), findsOneWidget);
    expect(find.text('See Pro'), findsNothing);

    final supportTile = find.text('Support');
    await tester.ensureVisible(supportTile);
    await tester.tap(supportTile, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('About & Support'), findsOneWidget);
    expect(find.text(AppStrings.freeForeverBanner), findsOneWidget);
  });
  testWidgets('Customize shows locked Pro templates to free users',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => MembershipState(),
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: CustomizePage(
              data: buildData(),
              onSetWallpaper: (_) async => true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('🧩  Templates'), findsOneWidget);
    expect(find.textContaining('Minimal Dark'), findsOneWidget);
    expect(find.textContaining('Code Centric'), findsOneWidget);
    expect(find.text('Pro'), findsWidgets);
  });

  testWidgets('Settings opens membership access as a parent screen',
      (tester) async {
    const membershipInfo = MembershipInfo(
      plan: MembershipPlan.free,
    );
    await StorageService.setCachedMembershipInfo(membershipInfo);
    final membershipState = MembershipState()
      ..setMembershipInfo(membershipInfo);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsPreferencesState()),
          ChangeNotifierProvider(create: (_) => ThemeModeState()),
          ChangeNotifierProvider.value(value: membershipState),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Subscription'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);

    await tester.tap(find.text('Subscription'));
    await tester.pumpAndSettle();

    expect(find.text('Subscription Details'), findsWidgets);
    expect(find.text('Restore Purchase'), findsOneWidget);
  });

  testWidgets('Free users see coupon and restore actions in access page',
      (tester) async {
    const membershipInfo = MembershipInfo(
      plan: MembershipPlan.free,
    );
    await StorageService.setCachedMembershipInfo(membershipInfo);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsPreferencesState()),
          ChangeNotifierProvider(create: (_) => ThemeModeState()),
          ChangeNotifierProvider(create: (_) => MembershipState()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Subscription'));
    await tester.pumpAndSettle();

    expect(find.text('Redeem Coupon'), findsOneWidget);
    expect(find.text('Restore Purchase'), findsOneWidget);
    expect(find.textContaining('Free plan active'), findsOneWidget);
  });
}
