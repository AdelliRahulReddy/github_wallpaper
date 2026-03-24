import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/features/contributions/pages/home_page.dart';
import 'package:github_wallpaper/features/contributions/pages/stats_page.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
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
    await StorageService.saveDeviceMetrics(
      width: 1080,
      height: 2400,
      pixelRatio: 3.0,
      safeInsets: const EdgeInsets.only(top: 48, bottom: 34),
    );
  }

  CachedContributionData buildData() {
    final start = DateTime.now().toLocal().subtract(const Duration(days: 370));
    final days = List.generate(
      370,
      (i) => ContributionDay(
        date: start.add(Duration(days: i)),
        contributionCount: (i % 6 == 0) ? (i % 17) + 1 : 0,
      ),
    );
    return CachedContributionData(
      username: 'testuser',
      avatarUrl: null,
      totalContributions: 0,
      days: days,
      lastUpdated: DateTime.now().toLocal(),
      repositories: const [],
    );
  }

  testWidgets('Home and Stats do not overflow on mobile sizes', (tester) async {
    await setupStorage();

    final errors = <String>[];
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details.toString());
    };
    addTearDown(() async {
      FlutterError.onError = oldOnError;
      await tester.binding.setSurfaceSize(null);
    });

    final data = buildData();

    Future<void> pumpAt(Widget child, Size size, double textScale) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(textScale),
              ),
              child: TickerMode(enabled: false, child: child),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(seconds: 1));
    }

    final home = HomePage(
      data: data,
      isLoading: false,
      loadError: null,
      onRefresh: () async {},
      onOpenStats: () {},
    );
    final stats = StatsPage(
      data: data,
      isLoading: false,
      loadError: null,
      onRefresh: () async {},
    );

    for (final size in const [
      Size(320, 640),
      Size(360, 740),
      Size(390, 844),
    ]) {
      await pumpAt(home, size, 1.0);
      await pumpAt(home, size, 1.2);
      await pumpAt(home, size, 1.5);
      await pumpAt(stats, size, 1.0);
      await pumpAt(stats, size, 1.2);
      await pumpAt(stats, size, 1.5);
    }

    FlutterError.onError = oldOnError;
    if (errors.isNotEmpty) {
      final b = StringBuffer();
      for (final e in errors.take(6)) {
        b.writeln(e);
        b.writeln('---');
      }
      fail('Flutter errors captured:\n$b');
    }
  });
}
