import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/app_utils.dart';

void main() {
  group('RefreshPolicy.shouldRefresh', () {
    test('skips when pending refresh is too recent', () {
      final now = DateTime.utc(2026, 1, 1, 10, 0, 0);
      final decision = RefreshPolicy.shouldRefresh(
        isBackground: true,
        isAndroid: true,
        autoUpdateEnabled: true,
        hasPendingRefresh: true,
        lastUpdate:
            now.subtract(Duration(minutes: AppConstants.pendingRefreshDebounceMinutes - 1)),
        username: 'octocat',
        token: 'ghp_test_token_1234567890',
        now: now,
      );

      expect(decision.shouldProceed, isFalse);
      expect(decision.skipReason, RefreshSkipReason.noChanges);
    });

    test('throttles background refresh when cooldown not reached', () {
      final now = DateTime.utc(2026, 1, 1, 10, 0, 0);
      final decision = RefreshPolicy.shouldRefresh(
        isBackground: true,
        isAndroid: true,
        autoUpdateEnabled: true,
        hasPendingRefresh: false,
        lastUpdate:
            now.subtract(Duration(minutes: AppConstants.refreshCooldownMinutes - 1)),
        username: 'octocat',
        token: 'ghp_test_token_1234567890',
        now: now,
      );

      expect(decision.shouldProceed, isFalse);
      expect(decision.skipReason, RefreshSkipReason.throttled);
    });

    test('skips with authError when credentials are missing', () {
      final decision = RefreshPolicy.shouldRefresh(
        isBackground: false,
        isAndroid: true,
        autoUpdateEnabled: true,
        hasPendingRefresh: false,
        username: null,
        token: null,
      );

      expect(decision.shouldProceed, isFalse);
      expect(decision.skipReason, RefreshSkipReason.authError);
    });

    test('proceeds when all conditions are valid', () {
      final now = DateTime.utc(2026, 1, 1, 10, 0, 0);
      final decision = RefreshPolicy.shouldRefresh(
        isBackground: true,
        isAndroid: true,
        autoUpdateEnabled: true,
        hasPendingRefresh: false,
        lastUpdate:
            now.subtract(Duration(minutes: AppConstants.refreshCooldownMinutes + 1)),
        username: 'octocat',
        token: 'ghp_test_token_1234567890',
        now: now,
      );

      expect(decision.shouldProceed, isTrue);
      expect(decision.skipReason, isNull);
    });
  });
}
