import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/shared/services/background_scheduler.dart';
import 'package:github_wallpaper/shared/services/refresh_result.dart';

void main() {
  group('BackgroundScheduler Logic Tests', () {
    test('shouldMarkTaskSuccessful returns correct values for RefreshResult', () {
      expect(BackgroundScheduler.shouldMarkTaskSuccessful(RefreshResult.success), isTrue);
      expect(BackgroundScheduler.shouldMarkTaskSuccessful(RefreshResult.noChanges), isTrue);
      expect(BackgroundScheduler.shouldMarkTaskSuccessful(RefreshResult.authError), isTrue); // Don't retry auth errors as they need user action
      expect(BackgroundScheduler.shouldMarkTaskSuccessful(RefreshResult.throttled), isTrue); // Throttled should wait for next cycle
      
      expect(BackgroundScheduler.shouldMarkTaskSuccessful(RefreshResult.networkError), isFalse); // Retry on network error
      expect(BackgroundScheduler.shouldMarkTaskSuccessful(RefreshResult.unknownError), isFalse); // Retry on unknown error
    });
  });
}
