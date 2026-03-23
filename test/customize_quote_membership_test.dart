import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/data/datasources/local/storage_service.dart';
import 'package:github_wallpaper/data/models/app_models.dart';
import 'package:github_wallpaper/data/models/membership_models.dart';
import 'package:github_wallpaper/features/wallpaper/screens/customize/customize_screen.dart';
import 'package:github_wallpaper/shared/state/membership_state.dart';
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
      40,
      (i) => ContributionDay(
        date: start.add(Duration(days: i)),
        contributionCount: i.isEven ? 2 : 0,
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

  testWidgets('Customize shows locked live quote action for free users',
      (tester) async {
    final membershipState = MembershipState()
      ..setMembershipInfo(MembershipInfo.free());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: membershipState),
        ],
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

    final textOverlay = find.text('Text Overlay');
    await tester.ensureVisible(textOverlay);
    await tester.tap(textOverlay, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Generate Live Quote'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsWidgets);
  });

  testWidgets('Customize shows live quote action for pro users',
      (tester) async {
    final membershipState = MembershipState()
      ..setMembershipInfo(
        MembershipInfo(
          plan: MembershipPlan.pro,
        ),
      );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: membershipState),
        ],
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

    final textOverlay = find.text('Text Overlay');
    await tester.ensureVisible(textOverlay);
    await tester.tap(textOverlay, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Generate Live Quote'), findsOneWidget);
  });
}
