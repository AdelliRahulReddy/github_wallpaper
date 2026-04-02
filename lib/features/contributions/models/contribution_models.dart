import 'package:flutter/foundation.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/features/contributions/services/contribution_metrics.dart';

export 'package:github_wallpaper/features/wallpaper/models/wallpaper_config.dart';

String _dateStr(DateTime date) => AppDateUtils.formatDate(date);

DateTime _requiredContributionDate(dynamic raw) {
  final parsed = AppDateUtils.parseDate(raw?.toString());
  if (parsed == null) {
    throw FormatException('Invalid contribution date: $raw');
  }
  return parsed;
}

@immutable
class ContributionDay {
  final DateTime date;
  final int contributionCount;
  final String? contributionLevel;

  const ContributionDay({
    required this.date,
    required this.contributionCount,
    this.contributionLevel,
  });

  factory ContributionDay.fromJson(Map<String, dynamic> json) =>
      ContributionDay(
        date: _requiredContributionDate(json['date']),
        contributionCount: (json['contributionCount'] as num?)?.toInt() ?? 0,
        contributionLevel: json['contributionLevel'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'date': AppDateUtils.formatDate(date),
        'contributionCount': contributionCount,
        'contributionLevel': contributionLevel,
      };

  bool get isActive => contributionCount > 0;

  String get dateKey => _dateStr(date);

  static int _levelValue(String? level) {
    switch (level) {
      case 'FOURTH_QUARTILE':
        return 4;
      case 'THIRD_QUARTILE':
        return 3;
      case 'SECOND_QUARTILE':
        return 2;
      case 'FIRST_QUARTILE':
        return 1;
      default:
        return 0;
    }
  }

  static String? strongestLevel(String? first, String? second) =>
      _levelValue(second) > _levelValue(first) ? second : first;
}

@immutable
class ContributionStats {
  final int currentStreak;
  final int longestStreak;
  final int todayContributions;
  final int activeDaysCount;
  final int peakDayContributions;
  final int totalContributions;
  final String mostActiveWeekday;

  const ContributionStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.todayContributions,
    required this.activeDaysCount,
    required this.peakDayContributions,
    required this.totalContributions,
    required this.mostActiveWeekday,
  });

  factory ContributionStats.fromDays(
    List<ContributionDay> days, {
    DateTime? nowUtc,
  }) {
    final summary = ContributionAnalyzer.analyzeContributions(
      days,
      nowUtc: nowUtc,
      dateOf: (day) => day.date,
      countOf: (day) => day.contributionCount,
    );
    return ContributionStats(
      currentStreak: summary['currentStreak'],
      longestStreak: summary['longestStreak'],
      todayContributions: summary['todayContributions'],
      activeDaysCount: summary['activeDaysCount'],
      peakDayContributions: summary['peakDayContributions'],
      totalContributions: summary['totalContributions'],
      mostActiveWeekday: summary['mostActiveWeekday'],
    );
  }
}

@immutable
class RepoLanguageSlice {
  final String name;
  final String? color;
  final int size;

  const RepoLanguageSlice({
    required this.name,
    this.color,
    required this.size,
  });

  factory RepoLanguageSlice.fromJson(Map<String, dynamic> json) =>
      RepoLanguageSlice(
        name: json['name'] ?? 'Unknown',
        color: json['color'] as String?,
        size: (json['size'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'color': color,
        'size': size,
      };
}

@immutable
class RepoContribution {
  final String nameWithOwner;
  final String? url;
  final bool isPrivate;
  final int commitCount;
  final String? primaryLanguageName;
  final String? primaryLanguageColor;
  final List<RepoLanguageSlice> languages;

  const RepoContribution({
    required this.nameWithOwner,
    this.url,
    required this.isPrivate,
    required this.commitCount,
    this.primaryLanguageName,
    this.primaryLanguageColor,
    required this.languages,
  });

  factory RepoContribution.fromJson(Map<String, dynamic> json) =>
      RepoContribution(
        nameWithOwner: json['nameWithOwner'] ?? 'unknown/unknown',
        url: json['url'] as String?,
        isPrivate: json['isPrivate'] ?? false,
        commitCount: (json['commitCount'] as num?)?.toInt() ?? 0,
        primaryLanguageName: json['primaryLanguageName'] as String?,
        primaryLanguageColor: json['primaryLanguageColor'] as String?,
        languages: (json['languages'] as List? ?? [])
            .map((language) => RepoLanguageSlice.fromJson(language))
            .where((language) => language.name != 'Unknown')
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'nameWithOwner': nameWithOwner,
        'url': url,
        'isPrivate': isPrivate,
        'commitCount': commitCount,
        'primaryLanguageName': primaryLanguageName,
        'primaryLanguageColor': primaryLanguageColor,
        'languages': languages.map((language) => language.toJson()).toList(),
      };
}

@immutable
class LanguageUsage {
  final String name;
  final String? color;
  final double score;
  final double percent;

  const LanguageUsage({
    required this.name,
    this.color,
    required this.score,
    required this.percent,
  });

  factory LanguageUsage.fromJson(Map<String, dynamic> json) => LanguageUsage(
        name: json['name'] ?? 'Unknown',
        color: json['color'] as String?,
        score: (json['score'] as num?)?.toDouble() ?? 0,
        percent: (json['percent'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'color': color,
        'score': score,
        'percent': percent,
      };
}

@immutable
class CachedContributionData {
  final String username;
  final String? avatarUrl;
  final int totalContributions;
  final List<ContributionDay> days;
  final DateTime lastUpdated;
  final ContributionStats stats;
  final Quartiles quartiles;
  final List<RepoContribution> repositories;
  final List<LanguageUsage> topLanguages;
  final Map<String, ContributionDay> _cache;

  CachedContributionData._(
    this.username,
    this.avatarUrl,
    this.totalContributions,
    this.days,
    this.lastUpdated,
    this.stats,
    this.quartiles,
    this.repositories,
    this.topLanguages,
  ) : _cache = {for (final day in days) day.dateKey: day};

  factory CachedContributionData({
    required String username,
    String? avatarUrl,
    required int totalContributions,
    required List<ContributionDay> days,
    required DateTime lastUpdated,
    ContributionStats? stats,
    Quartiles? quartiles,
    List<RepoContribution>? repositories,
    List<LanguageUsage>? topLanguages,
  }) {
    final normalizedDays = _merge(days);
    final normalizedTotal =
        normalizedDays.fold(0, (sum, day) => sum + day.contributionCount);
    final List<RepoContribution> resolvedRepositories =
        List.unmodifiable(repositories ?? const <RepoContribution>[]);
    return CachedContributionData._(
      username.trim(),
      avatarUrl,
      normalizedTotal,
      normalizedDays,
      lastUpdated.toLocal(),
      stats ?? ContributionStats.fromDays(normalizedDays),
      quartiles ??
          RenderUtils.calculateQuartiles(
            normalizedDays.map((day) => day.contributionCount).toList(),
          ),
      resolvedRepositories,
      List.unmodifiable(
        topLanguages ?? calculateTopLanguages(resolvedRepositories),
      ),
    );
  }

  static List<ContributionDay> _merge(List<ContributionDay> rawDays) {
    final merged = <String, ContributionDay>{};
    for (final day in rawDays) {
      final key = day.dateKey;
      final existing = merged[key];
      merged[key] = existing == null
          ? day
          : ContributionDay(
              date: existing.date,
              contributionCount:
                  existing.contributionCount + day.contributionCount,
              contributionLevel: ContributionDay.strongestLevel(
                existing.contributionLevel,
                day.contributionLevel,
              ),
            );
    }
    return merged.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  static List<LanguageUsage> calculateTopLanguages(
    List<RepoContribution> repositories,
  ) {
    final totals = <String, double>{};
    final colors = <String, String?>{};
    for (final repository in repositories) {
      if (repository.commitCount <= 0) continue;
      final totalLanguageSize = repository.languages.fold<int>(
        0,
        (sum, language) => sum + language.size,
      );
      if (totalLanguageSize > 0) {
        for (final language in repository.languages) {
          totals[language.name] = (totals[language.name] ?? 0) +
              (repository.commitCount * language.size / totalLanguageSize);
          colors[language.name] ??= language.color;
        }
      } else if (repository.primaryLanguageName != null) {
        totals[repository.primaryLanguageName!] =
            (totals[repository.primaryLanguageName!] ?? 0) +
                repository.commitCount;
        colors[repository.primaryLanguageName!] ??=
            repository.primaryLanguageColor;
      }
    }

    final totalScore = totals.values.fold(0.0, (sum, score) => sum + score);
    final sortedTotals = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final result = <LanguageUsage>[];
    for (final entry in sortedTotals.take(7)) {
      result.add(
        LanguageUsage(
          name: entry.key,
          color: colors[entry.key],
          score: entry.value,
          percent: totalScore > 0 ? entry.value / totalScore : 0,
        ),
      );
    }

    if (sortedTotals.length > 7) {
      final remaining =
          sortedTotals.skip(7).fold(0.0, (sum, entry) => sum + entry.value);
      if (remaining > 0) {
        result.add(
          LanguageUsage(
            name: 'Other',
            score: remaining,
            percent: totalScore > 0 ? remaining / totalScore : 0,
          ),
        );
      }
    }

    return result;
  }

  factory CachedContributionData.fromJson(Map<String, dynamic> json) =>
      CachedContributionData(
        username: json['username'] ?? '',
        avatarUrl: json['avatarUrl'] as String?,
        totalContributions: (json['totalContributions'] as num?)?.toInt() ?? 0,
        days: (json['days'] as List)
            .map((day) => ContributionDay.fromJson(day))
            .toList(),
        lastUpdated: DateTime.tryParse(json['lastUpdated'] ?? '')?.toLocal() ??
            DateTime.now().toLocal(),
        repositories: (json['repositories'] as List?)
            ?.map((repository) => RepoContribution.fromJson(repository))
            .toList(),
        topLanguages: (json['topLanguages'] as List?)
            ?.map((language) => LanguageUsage.fromJson(language))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'username': username,
        'avatarUrl': avatarUrl,
        'totalContributions': totalContributions,
        'days': days.map((day) => day.toJson()).toList(),
        'lastUpdated': lastUpdated.toIso8601String(),
        'repositories':
            repositories.map((repository) => repository.toJson()).toList(),
        'topLanguages':
            topLanguages.map((language) => language.toJson()).toList(),
      };

  int getContributionsForDate(DateTime date) =>
      _cache[_dateStr(date)]?.contributionCount ?? 0;

  bool isStale([Duration? threshold, DateTime? now]) =>
      (now ?? DateTime.now().toLocal())
          .difference(lastUpdated)
          .compareTo(threshold ?? const Duration(hours: 6)) >
      0;

  int get currentStreak => stats.currentStreak;
  int get longestStreak => stats.longestStreak;
  int get todayCommits => stats.todayContributions;
  int get activeDaysCount => stats.activeDaysCount;
  int get peakDay => stats.peakDayContributions;
  String get mostActiveWeekday => stats.mostActiveWeekday;
  bool get hasContributedToday => stats.todayContributions > 0;
  int get activeRepositoriesCount =>
      repositories.where((repository) => repository.commitCount > 0).length;
  double get averagePerActiveDay =>
      activeDaysCount == 0 ? 0 : totalContributions / activeDaysCount;
}
