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
  }

  CachedContributionData buildData() {
    final start = DateTime.now().toLocal().subtract(const Duration(days: 120));
    final days = List.generate(
      120,
      (index) => ContributionDay(
        date: start.add(Duration(days: index)),
        contributionCount: (index % 3 == 0) ? (index % 7) + 1 : 0,
      ),
    );

    return CachedContributionData(
      username: 'adellirahulreddy',
      avatarUrl: null,
      totalContributions: 0,
      days: days,
      lastUpdated: DateTime.now().toLocal().subtract(const Duration(minutes: 23)),
      repositories: const [],
    );
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ShareCard(
                data: data,
                trend7d: const TrendSummary(current: 4, previous: 4),
                trend30d: const TrendSummary(current: 13, previous: 92),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    FlutterError.onError = oldOnError;

    expect(find.text('Heatmap'), findsOneWidget);
    expect(
      errors.where((error) => error.contains('A RenderFlex overflowed by')),
      isEmpty,
      reason: errors.join('\n'),
    );
  });
}

