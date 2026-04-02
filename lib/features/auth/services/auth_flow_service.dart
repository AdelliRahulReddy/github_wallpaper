import 'dart:async';

import 'package:github_wallpaper/app/services/background_scheduler.dart';
import 'package:github_wallpaper/app/services/notification_service.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/features/auth/services/identity_service.dart';
import 'package:github_wallpaper/features/auth/services/oauth_service.dart';
import 'package:github_wallpaper/features/wallpaper/services/widget_service.dart';

class AuthFlowResult {
  final OAuthSession session;

  const AuthFlowResult({
    required this.session,
  });
}

class AuthFlowService {
  static Future<AuthFlowResult> connectGitHub({
    bool onboardingFlow = false,
  }) async {
    final session = await OAuthService.signInWithGitHub();
    await Future.wait([
      StorageService.setToken(session.accessToken),
      StorageService.setUsername(session.username),
      StorageService.setUserEmail(session.email),
      StorageService.setGitHubProviderId(session.githubProviderId),
      StorageService.setHasAuthError(false),
    ]);
    await IdentityService.applyAuthenticatedSession(session);

    if (onboardingFlow) {
      await Future.wait([
        StorageService.setOnboardingComplete(true),
        StorageService.setFirstLoginGreetingPending(true),
        StorageService.setHasSeenDashboard(false),
        StorageService.setPostLoginSetupComplete(false),
      ]);
    }

    unawaited(NotificationService.initPushMessaging());
    await Future.wait([
      NotificationService.refreshAdminBroadcastSubscription(),
      BackgroundScheduler.initialize(),
    ]);
    if (StorageService.getAutoUpdate()) {
      await BackgroundScheduler.scheduleUpdates();
    }
    if (BackgroundScheduler.shouldScheduleReminderChecks()) {
      await BackgroundScheduler.scheduleStreakReminders();
    }
    unawaited(WidgetService.refreshFromCache());

    return AuthFlowResult(
      session: session,
    );
  }
}
