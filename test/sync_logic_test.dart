import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/features/contributions/services/contribution_metrics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

void main() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final Map<String, dynamic> mockStorage = {};

  setupMethodChannelMock() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'write':
          mockStorage[methodCall.arguments['key']] =
              methodCall.arguments['value'];
          return null;
        case 'read':
          return mockStorage[methodCall.arguments['key']];
        case 'delete':
          mockStorage.remove(methodCall.arguments['key']);
          return null;
        case 'deleteAll':
          mockStorage.clear();
          return null;
        case 'readAll':
          return mockStorage;
        case 'containsKey':
          return mockStorage.containsKey(methodCall.arguments['key']);
        default:
          return null;
      }
    });
  }

  group('Sync Logic & StorageService Tests', () {
    setUp(() async {
      setupMethodChannelMock();
      SharedPreferences.setMockInitialValues({});
      await StorageService.init();
    });

    test('StorageService persists and retrieves settings correctly', () async {
      await StorageService.setUsername('testuser');
      expect(StorageService.getUsername(), 'testuser');

      await StorageService.setAutoUpdate(false);
      expect(StorageService.getAutoUpdate(), isFalse);

      await StorageService.setIncludePrivateRepos(true);
      expect(StorageService.getIncludePrivateRepos(), isTrue);
    });

    test('StorageService handles logout correctly', () async {
      await StorageService.setUsername('testuser');
      await StorageService.setToken('ghp_testToken12345');
      await StorageService.setHasAuthError(true);
      await StorageService.setSyncSuccessNotificationsEnabled(true);
      await StorageService.setSyncSuccessLastSentDay('2026-03-24');

      await StorageService.logout();

      expect(StorageService.getUsername(), isNull);
      expect(await StorageService.hasToken(), isFalse);
      expect(StorageService.hasAuthError(), isFalse);
      expect(StorageService.getSyncSuccessNotificationsEnabled(), isFalse);
      expect(StorageService.getSyncSuccessLastSentDay(), isNull);
    });

    test('StorageService session gate requires onboarding, token, and username',
        () async {
      await StorageService.setOnboardingComplete(true);
      expect(await StorageService.hasAuthenticatedSession(), isFalse);

      await StorageService.setToken('ghp_testToken12345');
      expect(await StorageService.hasAuthenticatedSession(), isFalse);

      await StorageService.setUsername('testuser');
      expect(await StorageService.hasAuthenticatedSession(), isTrue);

      await StorageService.setOnboardingComplete(false);
      expect(await StorageService.hasAuthenticatedSession(), isFalse);
    });

    test('PresentationFormatter handles formatTimeSince correctly', () {
      final now = DateTime.now();
      expect(PresentationFormatter.formatTimeSince(now), 'Just now');

      final minAgo = now.subtract(const Duration(minutes: 5));
      expect(PresentationFormatter.formatTimeSince(minAgo), '5 min ago');

      final hourAgo = now.subtract(const Duration(hours: 2));
      expect(PresentationFormatter.formatTimeSince(hourAgo), '2 hr ago');
    });
  });
}
