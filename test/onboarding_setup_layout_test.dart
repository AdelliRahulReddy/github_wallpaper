import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/features/auth/pages/onboarding_page.dart';
import 'package:github_wallpaper/features/auth/pages/setup_page.dart';

Future<void> _pumpAtSize(
  WidgetTester tester, {
  required Size size,
  required Widget child,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });

  final errors = <FlutterErrorDetails>[];
  final old = FlutterError.onError;
  FlutterError.onError = (details) {
    errors.add(details);
  };

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      home: child,
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));

  FlutterError.onError = old;

  final thrown = tester.takeException();
  expect(thrown, isNull);
  expect(errors, isEmpty);
}

void main() {
  testWidgets('Onboarding page has no overflow at common sizes',
      (WidgetTester tester) async {
    for (final size in const [
      Size(320, 568),
      Size(360, 640),
      Size(375, 812),
      Size(411, 891),
    ]) {
      await _pumpAtSize(tester, size: size, child: const OnboardingPage());
    }
  });

  testWidgets('Setup page has no overflow at common sizes',
      (WidgetTester tester) async {
    for (final size in const [
      Size(320, 568),
      Size(360, 640),
      Size(375, 812),
      Size(411, 891),
    ]) {
      await _pumpAtSize(tester, size: size, child: const SetupPage());
    }
  });
}
