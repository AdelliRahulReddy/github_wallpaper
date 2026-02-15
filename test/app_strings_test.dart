import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/app_utils.dart';

void main() {
  group('AppStrings Sanity Tests', () {
    test('core app identity strings are defined', () {
      expect(AppStrings.appName, isNotEmpty);
      expect(AppStrings.appTagline, isNotEmpty);
      expect(AppStrings.developerName, isNotEmpty);
    });

    test('labels and buttons are defined', () {
      expect(AppStrings.welcome, isNotEmpty);
      expect(AppStrings.welcomeBack, isNotEmpty);
      expect(AppStrings.syncNow, isNotEmpty);
      expect(AppStrings.getStarted, isNotEmpty);
    });

    test('settings strings are defined', () {
      expect(AppStrings.settings, isNotEmpty);
      expect(AppStrings.autoUpdate, isNotEmpty);
      expect(AppStrings.crashReporting, isNotEmpty);
    });

    test('error messages are defined', () {
      expect(AppStrings.errorGeneric, isNotEmpty);
      expect(AppStrings.errorNetwork, isNotEmpty);
      expect(AppStrings.errorInvalidToken, isNotEmpty);
    });

    test('newly centralized keys exist', () {
      expect(AppStrings.logout, isNotEmpty);
      expect(AppStrings.clearCache, isNotEmpty);
      expect(AppStrings.logoutConfirmTitle, isNotEmpty);
      expect(AppStrings.clearCacheConfirmTitle, isNotEmpty);
    });
  });
}
