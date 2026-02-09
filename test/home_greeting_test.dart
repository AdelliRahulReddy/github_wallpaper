import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:github_wallpaper/app_services.dart';
import 'package:github_wallpaper/app_theme.dart';
import 'package:github_wallpaper/app_utils.dart';
import 'package:github_wallpaper/pages/home_page.dart';

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
        ),
      ),
    );
    await tester.pump();

    expect(find.text('WELCOME 👋'), findsOneWidget);
    expect(find.text('WELCOME BACK 👋'), findsNothing);
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
        ),
      ),
    );
    await tester.pump();

    expect(find.text('WELCOME BACK 👋'), findsOneWidget);
    expect(find.text('WELCOME 👋'), findsNothing);
  });
}
