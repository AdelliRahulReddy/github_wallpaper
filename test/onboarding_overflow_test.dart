import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/features/auth/pages/onboarding_page.dart';

void main() {
  testWidgets('GitHub connect page does not overflow on small widths',
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
          home: const GitHubConnectPage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 800));
      while (tester.takeException() != null) {}
      expect(find.text('Connect on GitHub'), findsOneWidget);
      while (tester.takeException() != null) {}
    } finally {
      FlutterError.onError = oldHandler;
    }

    final overflowErrors = errors.where(
        (e) => e.exceptionAsString().contains('A RenderFlex overflowed by'));
    expect(overflowErrors, isEmpty);
  });
}
