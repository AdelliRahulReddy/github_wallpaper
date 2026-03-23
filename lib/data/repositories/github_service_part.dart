part of 'github_service.dart';

CachedContributionData _parseGitHubResponse(
  Map<String, dynamic> payload,
  String username,
) {
  try {
    final user = payload['data']?['user'];
    if (user == null) throw UserNotFoundException();

    final avatarUrl = user['avatarUrl'] as String?;
    final collection = user['contributionsCollection'];
    if (collection == null) {
      throw GitHubException('Incomplete data: contributionsCollection missing');
    }

    final calendar = collection['contributionCalendar'];
    if (calendar == null) {
      throw GitHubException('Incomplete data: contributionCalendar missing');
    }

    final days = <ContributionDay>[];
    final weeks = calendar['weeks'] as List?;
    if (weeks != null) {
      for (final week in weeks) {
        final contributionDays = week['contributionDays'] as List?;
        if (contributionDays == null) continue;
        for (final day in contributionDays) {
          days.add(ContributionDay.fromJson(day));
        }
      }
    }

    final repos = <RepoContribution>[];
    final repoContribs = collection['commitContributionsByRepository'] as List?;
    if (repoContribs != null) {
      for (final repoContribution in repoContribs) {
        final contributionCount =
            repoContribution['contributions']?['totalCount'];
        final repository = repoContribution['repository'];
        if (contributionCount == null || contributionCount <= 0) continue;
        if (repository == null) continue;

        final languages = <RepoLanguageSlice>[];
        final edges = repository['languages']?['edges'] as List?;
        if (edges != null) {
          for (final language in edges) {
            if (language['node'] != null) {
              languages.add(
                RepoLanguageSlice(
                  name: language['node']['name'] ?? 'Unknown',
                  color: language['node']['color'],
                  size: language['size'] ?? 0,
                ),
              );
            }
          }
        }

        repos.add(
          RepoContribution(
            nameWithOwner: repository['nameWithOwner'] ?? 'Unknown',
            url: repository['url'] ?? '',
            isPrivate: repository['isPrivate'] ?? false,
            commitCount: contributionCount,
            primaryLanguageName: repository['primaryLanguage']?['name'],
            primaryLanguageColor: repository['primaryLanguage']?['color'],
            languages: languages,
          ),
        );
      }
    }

    repos.sort((a, b) => b.commitCount.compareTo(a.commitCount));
    return CachedContributionData(
      username: username,
      avatarUrl: avatarUrl,
      totalContributions: calendar['totalContributions'] ?? 0,
      days: days,
      lastUpdated: DateTime.now().toLocal(),
      repositories: repos,
    );
  } catch (e) {
    throw GitHubException('Parse Error: $e');
  }
}

Future<void> _dispatchPostSyncNotifications(CachedContributionData data) async {
  try {
    final now = DateTime.now().toLocal();
    final dayKey = AppDateUtils.formatDate(now);

    if (StorageService.getStreakSavedEnabled() &&
        StorageService.getStreakReminderLastSentDay() == dayKey &&
        data.todayCommits > 0 &&
        StorageService.getStreakSavedLastSentDay() != dayKey) {
      await NotificationService.showStreakSavedNotification(
        currentStreak: data.currentStreak,
      );
      await StorageService.setStreakSavedLastSentDay(dayKey);
    }

    if (StorageService.getCelebrationsEnabled()) {
      final streakMilestones = [7, 14, 30, 50, 100, 365];
      final totalMilestones = [500, 1000, 2500, 5000, 10000];

      final lastStreak = StorageService.getLastCelebratedStreakMilestone();
      final hitStreak = GitHubService._greatestMilestoneAtOrBelow(
        data.currentStreak,
        streakMilestones,
      );
      if (hitStreak > lastStreak) {
        await NotificationService.showCelebrationNotification(
          title: '🔥 $hitStreak‑day streak',
          body: 'Consistency looks good on you.',
        );
        await StorageService.setLastCelebratedStreakMilestone(hitStreak);
      }

      final lastTotal = StorageService.getLastCelebratedTotalMilestone();
      final hitTotal = GitHubService._greatestMilestoneAtOrBelow(
        data.totalContributions,
        totalMilestones,
      );
      if (hitTotal > lastTotal) {
        await NotificationService.showCelebrationNotification(
          title:
              '🚀 ${PresentationFormatter.formatCompactNumber(hitTotal)} contributions',
          body: 'Big numbers. Bigger momentum.',
        );
        await StorageService.setLastCelebratedTotalMilestone(hitTotal);
      }
    }
  } catch (e, s) {
    AppLog.error(e, s);
  }
}

int _greatestMilestoneAtOrBelowValue(int value, List<int> milestones) {
  var best = 0;
  for (final milestone in milestones) {
    if (milestone <= value && milestone > best) {
      best = milestone;
    }
  }
  return best;
}

Future<void> _checkGitHubAuthStatus() async {
  final token = await StorageService.getToken();
  if (token == null) return;

  try {
    final response = await GitHubService._viewerReq(
      token,
      const Duration(seconds: 5),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw TokenExpiredException();
    }
    if (response.statusCode == 200 && StorageService.hasAuthError()) {
      await StorageService.setHasAuthError(false);
    }
  } catch (e) {
    if (e is TokenExpiredException) rethrow;
    AppLog.error(e);
  }
}

void _disposeGitHubClient() => GitHubService._c.close();
