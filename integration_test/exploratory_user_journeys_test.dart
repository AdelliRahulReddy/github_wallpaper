import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/app/app_entry.dart';

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

Future<void> _tapVisible(
  WidgetTester tester,
  Finder finder, {
  Duration settleFor = const Duration(seconds: 2),
}) async {
  final target = finder.hitTestable().first;
  await tester.ensureVisible(target);
  await tester.tap(target, warnIfMissed: false);
  await tester.pumpAndSettle(settleFor);
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
    await StorageService.setOnboardingComplete(false);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle(const Duration(seconds: 8));

    await _pumpUntilFound(tester, find.text('Skip'));
    await _tryScreenshot(binding, '01_onboarding');

    await _tapVisible(
      tester,
      find.text('Skip'),
      settleFor: const Duration(seconds: 3),
    );

    await _pumpUntilFound(tester, find.text('Continue with GitHub'));
    await _tryScreenshot(binding, '02_setup_empty');

    await _tapVisible(tester, find.text('Continue with GitHub'));
    await _tryScreenshot(binding, '03_setup_validation_errors');
  });

  testWidgets('Journey: main tabs → settings toggle → logout',
      (WidgetTester tester) async {
    await StorageService.init();
    await StorageService.logout();

    const username = 'octocat';
    await StorageService.setUsername(username);
    await StorageService.setToken('ghp_integration_smoke_token');
    await StorageService.setOnboardingComplete(true);
    await StorageService.setAutoUpdate(false);
    await StorageService.setPendingWallpaperRefresh(false);
    await StorageService.setCachedData(_seedContributionData(
      username: username,
      dayCount: 120,
    ));
    await StorageService.recordSyncSuccess();

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle(const Duration(seconds: 8));

    await _pumpUntilFound(tester, find.text('Home'));
    await _tryScreenshot(binding, '10_main_dashboard');

    await _tapVisible(tester, find.text('Customize'));
    await _tryScreenshot(binding, '11_customize');

    await _tapVisible(tester, find.text('Settings'));
    await _tryScreenshot(binding, '12_settings');

    final autoUpdateSwitch = find.byType(Switch).first;
    if (autoUpdateSwitch.evaluate().isNotEmpty) {
      await _tapVisible(tester, autoUpdateSwitch);
      await _tryScreenshot(binding, '13_settings_auto_update_toggled');
    }

    final logoutButton = find.text('Logout');
    await _tapVisible(
      tester,
      logoutButton,
      settleFor: const Duration(seconds: 1),
    );

    final confirm = find.widgetWithText(TextButton, 'Logout');
    if (confirm.evaluate().isNotEmpty) {
      await _tapVisible(tester, confirm);
    }

    await _pumpUntilFound(tester, find.text('Continue with GitHub'));
    await _tryScreenshot(binding, '14_post_logout_setup');
  });
}
