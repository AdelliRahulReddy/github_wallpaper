import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/features/wallpaper/pages/customize_page.dart';
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
    final currentYear = DateTime.now().toUtc().year;
    final start = DateTime.utc(currentYear, 1, 1);
    final days = List.generate(
      40,
      (index) => ContributionDay(
        date: start.add(Duration(days: index)),
        contributionCount: index.isEven ? 2 : 0,
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

  testWidgets('Customize exposes live quote generation without tiers',
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

    final textOverlay = find.text('Text Overlay');
    await tester.ensureVisible(textOverlay);
    await tester.tap(textOverlay, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Generate Live Quote'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsNothing);
  });
}
