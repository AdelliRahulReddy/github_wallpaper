import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/features/contributions/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CachedContributionData buildData() {
    final anchor = DateTime.now().toLocal();
    final start = DateTime(anchor.year, anchor.month, anchor.day)
        .subtract(const Duration(days: 59));
    final days = List.generate(
      60,
      (i) => ContributionDay(
        date: start.add(Duration(days: i)),
        contributionCount: i % 5 == 0 ? 3 : 0,
      ),
    );

    return CachedContributionData(
      username: 'octocat',
      totalContributions: days.fold<int>(
        0,
        (sum, day) => sum + day.contributionCount,
      ),
      days: days,
      lastUpdated: anchor,
      repositories: const [],
    );
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  setUp(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  testWidgets('Home shows rich free stats without setup or utility cards',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: HomePage(
          data: buildData(),
          isLoading: false,
          loadError: null,
          onRefresh: () async {},
          onOpenInsights: () {},
          onOpenStudio: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('Connection'), findsNothing);
    expect(find.text('Data'), findsNothing);
    expect(find.text('Plan'), findsNothing);
    expect(find.text('FREE STATS'), findsNothing);
    expect(find.text('Sync healthy'), findsNothing);
    expect(find.text('Wallpaper'), findsNothing);
    expect(find.text('Your dashboard is ready'), findsNothing);
  });
}
