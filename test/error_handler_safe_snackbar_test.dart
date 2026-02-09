import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/app_utils.dart';

void main() {
  testWidgets(
      'ErrorHandler.showSuccess does not throw when messenger is disposed',
      (tester) async {
    final errors = <FlutterErrorDetails>[];
    final oldHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details);
    };
    addTearDown(() {
      FlutterError.onError = oldHandler;
    });

    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: messengerKey,
        home: const Scaffold(body: SizedBox()),
      ),
    );

    ErrorHandler.showSuccess(null, 'ok');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(errors, isEmpty);
  });

  testWidgets(
      'ErrorHandler.handle does not throw when context is disposed before frame',
      (tester) async {
    final errors = <FlutterErrorDetails>[];
    final oldHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details);
    };
    addTearDown(() {
      FlutterError.onError = oldHandler;
    });

    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: messengerKey,
        home: Builder(
          builder: (context) {
            captured = context;
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    );

    ErrorHandler.handle(captured, Exception('boom'));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(errors, isEmpty);
  });
}

