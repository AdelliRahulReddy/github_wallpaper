import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/features/wallpaper/pages/customize_page.dart';
import 'package:github_wallpaper/features/wallpaper/widgets/ui_render.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final Map<String, dynamic> mockStorage = {};

  Future<void> setupStorage({
    double width = 1080,
    double height = 2400,
    double pixelRatio = 3.0,
    EdgeInsets safeInsets = const EdgeInsets.only(top: 48, bottom: 34),
  }) async {
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
      width: width,
      height: height,
      pixelRatio: pixelRatio,
      safeInsets: safeInsets,
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
      username: 'adellirahulreddydev',
      totalContributions: 0,
      days: days,
      lastUpdated: DateTime.utc(2026, 3, 1),
      repositories: const [],
    );
  }

  CachedContributionData buildDataAround(
    DateTime startUtc, {
    int totalDays = 430,
    Set<int> activeOffsets = const <int>{},
  }) {
    final days = List.generate(
      totalDays,
      (i) => ContributionDay(
        date: startUtc.add(Duration(days: i)),
        contributionCount: activeOffsets.contains(i) ? (i % 5) + 1 : 0,
      ),
    );
    return CachedContributionData(
      username: 'calendaruser',
      totalContributions: days.fold<int>(
        0,
        (sum, day) => sum + day.contributionCount,
      ),
      days: days,
      lastUpdated: startUtc.add(Duration(days: totalDays - 1)),
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

  testWidgets('Customize preview paints on narrow logical wallpaper metrics',
      (tester) async {
    await setupStorage(
      width: 360,
      height: 800,
      pixelRatio: 2.75,
      safeInsets: const EdgeInsets.only(top: 28, bottom: 18),
    );

    final errors = <FlutterErrorDetails>[];
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details);
    };
    addTearDown(() async {
      FlutterError.onError = oldOnError;
      await tester.binding.setSurfaceSize(null);
    });

    const size = Size(360, 800);
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(size: size),
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

    FlutterError.onError = oldOnError;
    if (errors.isNotEmpty) {
      final b = StringBuffer();
      for (final e in errors.take(5)) {
        b.writeln(e.toString());
        b.writeln('---');
      }
      fail('Flutter errors captured:\n$b');
    }

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('customize-preview-canvas')),
      findsOneWidget,
    );
  });

  testWidgets('Customize landscape split keeps preview near 50-50',
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

    const size = Size(960, 640);
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(size: size),
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

    FlutterError.onError = oldOnError;
    if (errors.isNotEmpty) {
      final b = StringBuffer();
      for (final e in errors.take(5)) {
        b.writeln(e.toString());
        b.writeln('---');
      }
      fail('Flutter errors captured:\n$b');
    }

    final previewSize = tester.getSize(
      find.byKey(const ValueKey('customize-preview-panel')),
    );
    final controlsSize = tester.getSize(
      find.byKey(const ValueKey('customize-controls-panel')),
    );
    final previewRatio =
        previewSize.width / (previewSize.width + controlsSize.width);

    expect(previewRatio, closeTo(0.5, 0.05));
  });

  testWidgets('Customize portrait split keeps preview near 50-50',
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

    const size = Size(360, 760);
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(size: size),
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

    FlutterError.onError = oldOnError;
    if (errors.isNotEmpty) {
      final b = StringBuffer();
      for (final e in errors.take(5)) {
        b.writeln(e.toString());
        b.writeln('---');
      }
      fail('Flutter errors captured:\n$b');
    }

    final previewSize = tester.getSize(
      find.byKey(const ValueKey('customize-preview-panel')),
    );
    final controlsSize = tester.getSize(
      find.byKey(const ValueKey('customize-controls-panel')),
    );
    final previewRatio =
        previewSize.height / (previewSize.height + controlsSize.height);

    expect(previewRatio, closeTo(0.5, 0.05));
    expect(
      tester
          .getSize(find.byKey(const ValueKey('customize-preview-canvas')))
          .height,
      greaterThan(200),
    );
  });

  testWidgets('Customize stacks the action group in the control flow',
      (tester) async {
    await setupStorage();

    const size = Size(360, 760);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(size: size),
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

    expect(find.text('Templates'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('customize-action-group')), findsOneWidget);
    expect(find.byKey(const ValueKey('customize-action-dock')), findsNothing);
    expect(find.text('Wallpaper Preview'), findsNothing);
    expect(find.text('Matched to this device'), findsNothing);

    final actionGroup = find.byKey(const ValueKey('customize-action-group'));
    await tester.ensureVisible(actionGroup);
    await tester.pumpAndSettle();

    final autoRect = tester.getRect(find.text('Auto wallpaper'));
    final buttonRect = tester.getRect(find.text('Set Lock Screen'));

    expect(find.text('Auto wallpaper'), findsOneWidget);
    expect(find.text('Set Lock Screen'), findsOneWidget);
    expect(buttonRect.top, greaterThan(autoRect.bottom));
  });

  testWidgets('Customize applies the lock wallpaper directly', (tester) async {
    await setupStorage();

    String? appliedTarget;

    const size = Size(360, 760);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(size: size),
            child: CustomizePage(
              data: buildData(),
              onSetWallpaper: (target) async {
                appliedTarget = target;
                return false;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Templates'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('wallpaper-target-selector')), findsNothing);
    expect(find.text('Set Lock Screen'), findsOneWidget);

    final applyButton = find.text('Set Lock Screen');
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton, warnIfMissed: false);
    await tester.pump();

    expect(appliedTarget, 'lock');
  });

  testWidgets('Customize persists lock target and shows failure feedback',
      (tester) async {
    await setupStorage();

    String? appliedTarget;

    const size = Size(360, 760);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(size: size),
            child: CustomizePage(
              data: buildData(),
              onSetWallpaper: (target) async {
                appliedTarget = target;
                return false;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final applyButton = find.text('Set Lock Screen');
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(appliedTarget, 'lock');
    expect(StorageService.getLastWallpaperTarget(), WallpaperTarget.lock);
    expect(
      find.text(
        'Wallpaper could not be applied. Try again on the lock screen.',
      ),
      findsOneWidget,
    );
  });

  test('Wallpaper renderer generates full layouts for lock and home', () async {
    await setupStorage();
    final data = buildData();

    for (final target in [WallpaperTarget.lock, WallpaperTarget.home]) {
      final config = WallpaperConfig.defaults().copyWith(
        isDarkMode: true,
        themeId: target == WallpaperTarget.home ? 'mono' : 'tokyo_night',
        templateId:
            target == WallpaperTarget.home ? 'quiet_grid_home' : 'heatmap_hero',
        densityMode: target == WallpaperTarget.home
            ? WallpaperDensityMode.sparse
            : WallpaperDensityMode.power,
        heroFocus: target == WallpaperTarget.home
            ? WallpaperHeroFocus.grid
            : WallpaperHeroFocus.stats,
        showQuickStatsBar: true,
        statTopLanguage: false,
      );

      final bytes = await generateWallpaperTask({
        'data': jsonEncode(data.toJson()),
        'config': jsonEncode(config.toJson()),
        'target': target.name,
        'width': 1080.0,
        'height': 2400.0,
        'pixelRatio': 1.0,
      });

      assert(bytes.isNotEmpty);
      expect(bytes.length, greaterThan(2000));
    }
  });

  test('lock calendar aligns to current month grid with Monday start', () {
    final data = buildDataAround(DateTime.utc(2025, 9, 1));
    final cells = MonthHeatmapRenderer.buildCalendarCells(
      data: data,
      todayUtc: DateTime.utc(2025, 10, 15),
      target: WallpaperTarget.lock,
    );

    expect(cells, hasLength(35));
    expect(cells.first.date.weekday, DateTime.monday);
    expect(cells.first.date, DateTime.utc(2025, 9, 29));
    expect(cells.last.date, DateTime.utc(2025, 11, 2));
    expect(cells.first.isInFocusMonth, isFalse);
    expect(
      cells
          .firstWhere((cell) => cell.date == DateTime.utc(2025, 10, 1))
          .isInFocusMonth,
      isTrue,
    );
    expect(cells.last.isInFocusMonth, isFalse);
  });

  test('lock calendar expands to six weeks when month shape requires it', () {
    final data = buildDataAround(DateTime.utc(2024, 12, 1));
    final cells = MonthHeatmapRenderer.buildCalendarCells(
      data: data,
      todayUtc: DateTime.utc(2025, 3, 2),
      target: WallpaperTarget.lock,
    );

    expect(cells, hasLength(42));
    expect(cells.first.date, DateTime.utc(2025, 2, 24));
    expect(cells.last.date, DateTime.utc(2025, 4, 6));
  });

  test('home calendar uses compact 5-week grid with Monday start', () {
    final data = buildDataAround(DateTime.utc(2025, 9, 1));
    final cells = MonthHeatmapRenderer.buildCalendarCells(
      data: data,
      todayUtc: DateTime.utc(2025, 10, 15),
      target: WallpaperTarget.home,
    );

    expect(cells, hasLength(35));
    expect(cells.first.date.weekday, DateTime.monday);
    expect(cells.first.date, DateTime.utc(2025, 9, 15));
    expect(cells.last.date, DateTime.utc(2025, 10, 19));
  });

  test('calendar marks month transitions clearly across month boundaries', () {
    final data = buildDataAround(DateTime.utc(2025, 1, 15));
    final cells = MonthHeatmapRenderer.buildCalendarCells(
      data: data,
      todayUtc: DateTime.utc(2025, 3, 2),
      target: WallpaperTarget.lock,
    );

    final marchCell = cells.firstWhere(
      (cell) => cell.date == DateTime.utc(2025, 3, 1),
    );

    expect(marchCell.startsNewMonth, isTrue);
    expect(marchCell.shortMonthLabel, 'MAR');
  });

  test('calendar keeps leap day distinguishable', () {
    final leapStart = DateTime.utc(2023, 11, 1);
    final leapOffset = DateTime.utc(2024, 2, 29).difference(leapStart).inDays;
    final data = buildDataAround(
      leapStart,
      activeOffsets: <int>{leapOffset},
    );
    final cells = MonthHeatmapRenderer.buildCalendarCells(
      data: data,
      todayUtc: DateTime.utc(2024, 2, 29),
      target: WallpaperTarget.lock,
    );

    final leapDay = cells.firstWhere(
      (cell) => cell.date == DateTime.utc(2024, 2, 29),
    );

    expect(leapDay.isToday, isTrue);
    expect(
      leapDay.accessibilityLabel,
      contains('Today, Thursday, February 29, 2024, 1 contribution'),
    );
  });

  test('calendar stays clear across year boundaries', () {
    final data = buildDataAround(DateTime.utc(2025, 8, 1));
    final cells = MonthHeatmapRenderer.buildCalendarCells(
      data: data,
      todayUtc: DateTime.utc(2026, 1, 2),
      target: WallpaperTarget.lock,
    );

    final dec31 = cells.firstWhere(
      (cell) => cell.date == DateTime.utc(2025, 12, 31),
    );
    final jan1 = cells.firstWhere(
      (cell) => cell.date == DateTime.utc(2026, 1, 1),
    );

    expect(dec31.shortMonthLabel, 'DEC');
    expect(jan1.startsNewMonth, isTrue);
    expect(jan1.shortMonthLabel, 'JAN');
  });

  test('calendar accessibility label announces range and current day clearly',
      () {
    final data = buildDataAround(DateTime.utc(2025, 9, 1));
    final label = MonthHeatmapRenderer.buildCalendarAccessibilityLabel(
      data: data,
      todayUtc: DateTime.utc(2025, 10, 15),
      target: WallpaperTarget.lock,
    );

    expect(
      label,
      'October 2025 calendar from September 29, 2025 to November 2, 2025. Today is Today, Wednesday, October 15, 2025, 0 contributions.',
    );
  });
}
