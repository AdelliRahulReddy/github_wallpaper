import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/features/contributions/pages/home_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  setUp(() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
  });

  testWidgets('Shows Welcome for first-time login', (tester) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(AppConstants.keyUsername, 'octocat');
    await p.setBool(AppConstants.keyFirstLoginGreetingPending, true);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: HomePage(
          data: null,
          isLoading: false,
          loadError: null,
          onRefresh: () async {},
          onOpenStats: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('Shows Welcome back for returning users', (tester) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(AppConstants.keyUsername, 'octocat');
    await p.setBool(AppConstants.keyFirstLoginGreetingPending, false);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: HomePage(
          data: null,
          isLoading: false,
          loadError: null,
          onRefresh: () async {},
          onOpenStats: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(HomePage), findsOneWidget);
  });
}

