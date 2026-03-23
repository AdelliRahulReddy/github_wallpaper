import 'package:flutter/material.dart';
import 'package:github_wallpaper/data/datasources/local/storage_service.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/data/repositories/github_service.dart';
import 'package:github_wallpaper/data/datasources/remote/oauth_service.dart';
import 'package:github_wallpaper/core/app/main_nav_screen.dart';
import 'package:github_wallpaper/shared/services/background_scheduler.dart';
import 'package:github_wallpaper/shared/services/daily_quotes.dart';
import 'package:github_wallpaper/shared/services/membership_service.dart';
import 'package:github_wallpaper/shared/services/notification_service.dart';
import 'package:github_wallpaper/shared/services/revenuecat_service.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  bool _isLoading = false;
  String? _error;
  String _codingLevel = 'Regular coder';
  String _quoteTone = 'Motivational';

  Future<void> _continueWithGitHub() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final session = await OAuthService.signInWithGitHub();
      await StorageService.setToken(session.accessToken);
      await StorageService.setUsername(session.username);
      await StorageService.setUserEmail(session.email);
      await StorageService.setCodingLevel(_codingLevel);
      await StorageService.setQuoteTone(_quoteTone);
      await StorageService.setHasAuthError(false);
      await RevenueCatService.initializeForCurrentUser();
      await MembershipService.refresh(force: true);
      final contributionData = await GitHubService.getContributions(
        username: session.username,
        token: session.accessToken,
        forceRefresh: true,
      );
      await DailyQuoteService.ensureDailyQuote(data: contributionData);
      await StorageService.setOnboardingComplete(true);
      await StorageService.setFirstLoginGreetingPending(true);
      await NotificationService.refreshAdminBroadcastSubscription();
      await BackgroundScheduler.initialize();
      if (StorageService.getAutoUpdate()) {
        await BackgroundScheduler.scheduleUpdates();
      }
      if (BackgroundScheduler.shouldScheduleReminderChecks()) {
        await BackgroundScheduler.scheduleStreakReminders();
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorHandler.getUserFriendlyMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: AppTheme.pSymH24,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.hub_rounded, size: 54, color: cs.primary),
                  AppTheme.h20,
                  Text(
                    'Connect GitHub',
                    textAlign: TextAlign.center,
                    style: t.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  AppTheme.h8,
                  Text(
                    'Sign in with GitHub to sync your contributions and generate wallpaper.',
                    textAlign: TextAlign.center,
                    style: t.bodyLarge?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                  AppTheme.h8,
                  Text(
                    'We will briefly open GitHub and bring you right back.',
                    textAlign: TextAlign.center,
                    style: t.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.58),
                    ),
                  ),
                  AppTheme.h24,
                  DropdownButtonFormField<String>(
                    initialValue: _codingLevel,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Coding level',
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'New to coding', child: Text('New to coding')),
                      DropdownMenuItem(
                          value: 'Beginner', child: Text('Beginner')),
                      DropdownMenuItem(
                          value: 'Regular coder', child: Text('Regular coder')),
                      DropdownMenuItem(
                          value: 'Hardcore developer',
                          child: Text('Hardcore developer')),
                    ],
                    onChanged: _isLoading
                        ? null
                        : (v) => setState(() => _codingLevel = v!),
                  ),
                  AppTheme.h12,
                  DropdownButtonFormField<String>(
                    initialValue: _quoteTone,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Quote style',
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'Friendly', child: Text('Friendly')),
                      DropdownMenuItem(
                          value: 'Motivational', child: Text('Motivational')),
                      DropdownMenuItem(value: 'Roast', child: Text('Roast')),
                    ],
                    onChanged: _isLoading
                        ? null
                        : (v) => setState(() => _quoteTone = v!),
                  ),
                  AppTheme.h24,
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _continueWithGitHub,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login_rounded),
                      label: Text(_isLoading
                          ? 'Signing in...'
                          : 'Continue with GitHub'),
                    ),
                  ),
                  if (_error != null) ...[
                    AppTheme.h16,
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: t.bodyMedium?.copyWith(color: cs.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
