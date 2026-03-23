part of 'app_models.dart';

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
      this.topLanguages)
      : _cache = {for (var d in days) d.dateKey: d};

  factory CachedContributionData(
      {required String username,
      String? avatarUrl,
      required int totalContributions,
      required List<ContributionDay> days,
      required DateTime lastUpdated,
      ContributionStats? stats,
      Quartiles? quartiles,
      List<RepoContribution>? repositories,
      List<LanguageUsage>? topLanguages}) {
    final norm = _merge(days);
    final total = norm.fold(0, (s, d) => s + d.contributionCount);
    return CachedContributionData._(
      username.trim(),
      avatarUrl,
      total,
      norm,
      lastUpdated.toLocal(),
      stats ?? ContributionStats.fromDays(norm),
      quartiles ??
          RenderUtils.calculateQuartiles(
              norm.map((d) => d.contributionCount).toList()),
      List.unmodifiable(repositories ?? []),
      List.unmodifiable(topLanguages ?? calculateTopLanguages(repositories ?? [])),
    );
  }

  static List<ContributionDay> _merge(List<ContributionDay> r) {
    final m = <String, ContributionDay>{};
    for (var d in r) {
      final k = d.dateKey;
      ContributionDay? e = m[k];
      m[k] = e == null
          ? d
          : ContributionDay(
              date: e.date,
              contributionCount: e.contributionCount + d.contributionCount,
              contributionLevel: ContributionDay.strongestLevel(
                  e.contributionLevel, d.contributionLevel));
    }
    return m.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  static List<LanguageUsage> calculateTopLanguages(List<RepoContribution> repos) {
    final t = <String, double>{};
    final c = <String, String?>{};
    for (var r in repos) {
      if (r.commitCount <= 0) continue;
      final sz = r.languages.fold(0, (s, l) => s + l.size);
      if (sz > 0) {
        for (var l in r.languages) {
          t[l.name] = (t[l.name] ?? 0) + (r.commitCount * l.size / sz);
          c[l.name] ??= l.color;
        }
      } else if (r.primaryLanguageName != null) {
        t[r.primaryLanguageName!] =
            (t[r.primaryLanguageName!] ?? 0) + r.commitCount;
        c[r.primaryLanguageName!] ??= r.primaryLanguageColor;
      }
    }
    final tot = t.values.fold(0.0, (a, b) => a + b);
    final s = t.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final res = <LanguageUsage>[];
    for (var e in s.take(7)) {
      res.add(LanguageUsage(
          name: e.key,
          color: c[e.key],
          score: e.value,
          percent: tot > 0 ? e.value / tot : 0));
    }
    if (s.length > 7) {
      final rest = s.skip(7).fold(0.0, (x, e) => x + e.value);
      if (rest > 0) {
        res.add(LanguageUsage(
            name: 'Other',
            color: null,
            score: rest,
            percent: tot > 0 ? rest / tot : 0));
      }
    }
    return res;
  }

  factory CachedContributionData.fromJson(Map<String, dynamic> j) =>
      CachedContributionData(
        username: j['username'] ?? '',
        avatarUrl: j['avatarUrl'],
        totalContributions: (j['totalContributions'] as num?)?.toInt() ?? 0,
        days: (j['days'] as List)
            .map((d) => ContributionDay.fromJson(d))
            .toList(),
        lastUpdated: DateTime.tryParse(j['lastUpdated'] ?? '')?.toLocal() ??
            DateTime.now().toLocal(),
        repositories: (j['repositories'] as List?)
            ?.map((r) => RepoContribution.fromJson(r))
            .toList(),
        topLanguages: (j['topLanguages'] as List?)
            ?.map((l) => LanguageUsage.fromJson(l))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'username': username,
        'avatarUrl': avatarUrl,
        'totalContributions': totalContributions,
        'days': days.map((d) => d.toJson()).toList(),
        'lastUpdated': lastUpdated.toIso8601String(),
        'repositories': repositories.map((r) => r.toJson()).toList(),
        'topLanguages': topLanguages.map((l) => l.toJson()).toList(),
      };

  int getContributionsForDate(DateTime d) =>
      _cache[_dateStr(d)]?.contributionCount ?? 0;
  bool isStale([Duration? t, DateTime? n]) =>
      (n ?? DateTime.now().toLocal())
          .difference(lastUpdated)
          .compareTo(t ?? const Duration(hours: 6)) >
      0;

  // Getters
  int get currentStreak => stats.currentStreak;
  int get longestStreak => stats.longestStreak;
  int get todayCommits => stats.todayContributions;
  int get activeDaysCount => stats.activeDaysCount;
  int get peakDay => stats.peakDayContributions;
  String get mostActiveWeekday => stats.mostActiveWeekday;
  bool get hasContributedToday => stats.todayContributions > 0;
  int get activeRepositoriesCount =>
      repositories.where((r) => r.commitCount > 0).length;
  double get averagePerActiveDay =>
      activeDaysCount == 0 ? 0 : totalContributions / activeDaysCount;
}
