import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/app_theme.dart';
import 'package:github_wallpaper/app_utils.dart';
import 'package:github_wallpaper/pages/onboarding_page.dart';

void main() {
  testWidgets('Onboarding + early access does not overflow on small widths',
      (tester) async {
    final errors = <FlutterErrorDetails>[];
    final oldHandler = FlutterError.onError;
    FlutterError.onError = (details) => errors.add(details);

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: const OnboardingPage(),
        ),
      );
    await tester.pump(const Duration(milliseconds: 800));
      while (tester.takeException() != null) {}

      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1200);
    await tester.pump(const Duration(milliseconds: 800));
      while (tester.takeException() != null) {}

      await tester.tap(find.text(AppStrings.onboardingCtaSlide2));
    await tester.pump(const Duration(milliseconds: 800));
      while (tester.takeException() != null) {}

      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1200);
    await tester.pump(const Duration(milliseconds: 800));
      while (tester.takeException() != null) {}
    } finally {
      FlutterError.onError = oldHandler;
    }

    final overflowErrors = errors.where((e) =>
        e.exceptionAsString().contains('A RenderFlex overflowed by'));
    expect(overflowErrors, isEmpty);
  });
}
