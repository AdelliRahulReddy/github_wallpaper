import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/features/contributions/widgets/stats_sections.dart';

void main() {
  testWidgets('Locked most active days preview does not overflow on mobile',
      (tester) async {
    final errors = <String>[];
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details.exceptionAsString());
    };

    addTearDown(() async {
      FlutterError.onError = oldOnError;
      await tester.binding.setSurfaceSize(null);
    });

    final year = DateTime.now().year;
    final yearDays = List.generate(
      28,
      (index) => ContributionDay(
        date: DateTime(year, 1, 1).add(Duration(days: index)),
        contributionCount: (index % 4 == 0) ? (index % 6) + 1 : 0,
      ),
    );

    const size = Size(320, 640);
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(1.1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StatsLockedPreview(
                title: 'Most Active Days is Pro',
                body: 'Weekday performance patterns are part of Pro.',
                onTap: () {},
                child: StatsMostActiveDaysCard(
                  yearDays: yearDays,
                  year: year,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Most Active Days is Pro'), findsOneWidget);
    expect(
      errors.where((error) => error.contains('A RenderFlex overflowed by')),
      isEmpty,
    );
  });
}

