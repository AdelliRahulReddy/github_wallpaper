import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/app_models.dart';
import 'package:github_wallpaper/app_services.dart';
import 'package:github_wallpaper/app_theme.dart';
import 'package:github_wallpaper/pages/customize_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final Map<String, dynamic> mockStorage = {};

  Future<void> setupStorage() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (MethodCall call) async {
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
        contributionCount: i % 13 == 0 ? 12 : 0,
      ),
    );
    return CachedContributionData(
      username: 'testuser',
      totalContributions: 0,
      days: days,
      lastUpdated: DateTime.utc(2026, 3, 1),
      repositories: const [],
    );
  }

  testWidgets('Customize preview does not overflow at narrow sizes',
      (tester) async {
    await setupStorage();

    final errors = <FlutterErrorDetails>[];
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details);
    };
    addTearDown(() async {
      FlutterError.onError = oldOnError;
      await tester.binding.setSurfaceSize(null);
    });

    Future<void> pumpAt(Size size, double textScale) async {
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
              child: CustomizePage(
                data: buildData(),
                onSetWallpaper: (_) async => true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    await pumpAt(const Size(320, 640), 1.0);
    await pumpAt(const Size(280, 520), 1.0);
    await pumpAt(const Size(320, 640), 1.3);

    FlutterError.onError = oldOnError;
    if (errors.isNotEmpty) {
      final b = StringBuffer();
      for (final e in errors.take(5)) {
        b.writeln(e.toString());
        b.writeln('---');
      }
      fail('Flutter errors captured:\n$b');
    }
  });
}
