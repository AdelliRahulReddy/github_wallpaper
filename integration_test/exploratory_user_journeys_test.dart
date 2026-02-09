import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:github_wallpaper/app_models.dart';
import 'package:github_wallpaper/app_services.dart';
import 'package:github_wallpaper/main.dart';

CachedContributionData _seedContributionData({
  required String username,
  required int dayCount,
  DateTime? nowUtc,
}) {
  final now = (nowUtc ?? DateTime.now().toUtc());
  final rng = Random(42);
  final days = List.generate(dayCount, (i) {
    final d = now.subtract(Duration(days: dayCount - 1 - i));
    final count = rng.nextInt(6);
    return ContributionDay(date: d, contributionCount: count);
  });
  return CachedContributionData(
    username: username,
    avatarUrl: null,
    totalContributions: days.fold(0, (s, d) => s + d.contributionCount),
    days: days,
    lastUpdated: now,
    repositories: const [],
  );
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder,
    {Duration timeout = const Duration(seconds: 25)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for: $finder');
}

Future<void> _tryScreenshot(
    IntegrationTestWidgetsFlutterBinding binding, String name) async {
  try {
    await binding.takeScreenshot(name);
  } catch (_) {}
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await binding.convertFlutterSurfaceToImage();
  });

  testWidgets('Journey: onboarding → setup (validation smoke)',
      (WidgetTester tester) async {
    await StorageService.init();
    await StorageService.logout();

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle(const Duration(seconds: 8));

    await _pumpUntilFound(tester, find.text('Skip'));
    await _tryScreenshot(binding, '01_onboarding');

    await tester.tap(find.text('Skip').hitTestable(), warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await _pumpUntilFound(tester, find.text('Initialize Workspace'));
    await _tryScreenshot(binding, '02_setup_empty');

    final initButton = find.text('Initialize Workspace');
    await tester.ensureVisible(initButton);
    await tester.tap(initButton.hitTestable(), warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await _tryScreenshot(binding, '03_setup_validation_errors');
  });

  testWidgets('Journey: main tabs → settings toggle → logout',
      (WidgetTester tester) async {
    await StorageService.init();
    await StorageService.logout();

    const username = 'octocat';
    await StorageService.setUsername(username);
    await StorageService.setOnboardingComplete(true);
    await StorageService.setAutoUpdate(false);
    await StorageService.setPendingWallpaperRefresh(false);
    await StorageService.setCachedData(_seedContributionData(
      username: username,
      dayCount: 120,
    ));
    await StorageService.setLastUpdate(DateTime.now().toUtc());

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle(const Duration(seconds: 8));

    await _pumpUntilFound(tester, find.text('Dashboard'));
    await _tryScreenshot(binding, '10_main_dashboard');

    await tester.tap(find.text('Customize'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await _tryScreenshot(binding, '11_customize');

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await _tryScreenshot(binding, '12_settings');

    final autoUpdateSwitch = find.byType(Switch).first;
    if (autoUpdateSwitch.evaluate().isNotEmpty) {
      await tester.ensureVisible(autoUpdateSwitch);
      await tester.tap(autoUpdateSwitch, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await _tryScreenshot(binding, '13_settings_auto_update_toggled');
    }

    final logoutButton = find.text('Logout');
    await tester.ensureVisible(logoutButton);
    await tester.tap(logoutButton.hitTestable(), warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final confirm = find.widgetWithText(TextButton, 'Logout');
    if (confirm.evaluate().isNotEmpty) {
      await tester.tap(confirm);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    await _pumpUntilFound(tester, find.text('Skip'));
    await _tryScreenshot(binding, '14_post_logout_onboarding');
  });
}
