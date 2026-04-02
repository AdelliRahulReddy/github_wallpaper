import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/features/auth/widgets/onboarding_content.dart';

void main() {
  testWidgets('Onboarding preparing state stays compact on small screens',
      (tester) async {
    final errors = <FlutterErrorDetails>[];
    final oldHandler = FlutterError.onError;
    FlutterError.onError = (details) => errors.add(details);

    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: const OnboardingPreparingState(
                  accent: AppTheme.primaryBlue,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Preparing your GitWall'), findsOneWidget);
      expect(
        find.text(
            'Syncing your activity and getting the first wallpaper ready.'),
        findsOneWidget,
      );
    } finally {
      FlutterError.onError = oldHandler;
    }

    final thrown = tester.takeException();
    expect(thrown, isNull);
    expect(errors, isEmpty);
  });
}
