// 📊 DATA MODELS - Optimized
import 'package:flutter/foundation.dart';
import 'app_utils.dart';
import 'app_state.dart';
import 'theme_presets.dart';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';

enum WallpaperTarget {
  home,
  lock,
  both;

  int toManagerConstant() {
    switch (this) {
      case WallpaperTarget.home:
        return WallpaperManagerPlus.homeScreen;
      case WallpaperTarget.lock:
        return WallpaperManagerPlus.lockScreen;
      case WallpaperTarget.both:
        return WallpaperManagerPlus.bothScreens;
    }
  }
}

// Helper to get formatted date string for keys
String _dateStr(DateTime d) => AppDateUtils.formatDate(d);
String? _str(dynamic v) =>
    (v is String && v.trim().isNotEmpty) ? v.trim() : null;
double _dbl(dynamic v, double d, double min, double max) =>
    ((v is num ? v.toDouble() : d).clamp(min, max)).toDouble();

@immutable
class ContributionDay {
  final DateTime date;
  final int contributionCount;
  final String? contributionLevel;
  const ContributionDay(
      {required this.date,
      required this.contributionCount,
      this.contributionLevel});

  factory ContributionDay.fromJson(Map<String, dynamic> j) => ContributionDay(
      date: AppDateUtils.parseDate(j['date']) ?? DateTime.now().toUtc(),
      contributionCount: (j['contributionCount'] as num?)?.toInt() ?? 0,
      contributionLevel: (j['contributionLevel'] as String?));

  Map<String, dynamic> toJson() => {
        'date': AppDateUtils.formatDate(date),
        'contributionCount': contributionCount,
        'contributionLevel': contributionLevel
      };

  bool get isActive => contributionCount > 0;
  String get dateKey => _dateStr(date);

  static int _lvl(String? l) {
    switch (l) {
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

  static String? strongestLevel(String? a, String? b) =>
      _lvl(b) > _lvl(a) ? b : a;
}

@immutable
class ContributionStats {
  final int currentStreak,
      longestStreak,
      todayContributions,
      activeDaysCount,
      peakDayContributions,
      totalContributions;
  final String mostActiveWeekday;
  const ContributionStats(
      {required this.currentStreak,
      required this.longestStreak,
      required this.todayContributions,
      required this.activeDaysCount,
      required this.peakDayContributions,
      required this.totalContributions,
      required this.mostActiveWeekday});

  factory ContributionStats.fromDays(List<ContributionDay> days,
      {DateTime? nowUtc}) {
    final s = ContributionAnalyzer.analyzeContributions(days,
        nowUtc: nowUtc,
        dateOf: (d) => d.date,
        countOf: (d) => d.contributionCount);
    return ContributionStats(
        currentStreak: s['currentStreak'],
        longestStreak: s['longestStreak'],
        todayContributions: s['todayContributions'],
        activeDaysCount: s['activeDaysCount'],
        peakDayContributions: s['peakDayContributions'],
        totalContributions: s['totalContributions'],
        mostActiveWeekday: s['mostActiveWeekday']);
  }
}

@immutable
class RepoLanguageSlice {
  final String name;
  final String? color;
  final int size;
  const RepoLanguageSlice({required this.name, this.color, required this.size});
  factory RepoLanguageSlice.fromJson(Map<String, dynamic> j) =>
      RepoLanguageSlice(
          name: j['name'] ?? 'Unknown',
          color: j['color'],
          size: (j['size'] as num?)?.toInt() ?? 0);
  Map<String, dynamic> toJson() => {'name': name, 'color': color, 'size': size};
}

@immutable
class RepoContribution {
  final String nameWithOwner;
  final String? url;
  final bool isPrivate;
  final int commitCount;
  final String? primaryLanguageName, primaryLanguageColor;
  final List<RepoLanguageSlice> languages;

  const RepoContribution(
      {required this.nameWithOwner,
      this.url,
      required this.isPrivate,
      required this.commitCount,
      this.primaryLanguageName,
      this.primaryLanguageColor,
      required this.languages});

  factory RepoContribution.fromJson(Map<String, dynamic> j) => RepoContribution(
      nameWithOwner: j['nameWithOwner'] ?? 'unknown/unknown',
      url: j['url'],
      isPrivate: j['isPrivate'] ?? false,
      commitCount: (j['commitCount'] as num?)?.toInt() ?? 0,
      primaryLanguageName: j['primaryLanguageName'],
      primaryLanguageColor: j['primaryLanguageColor'],
      languages: (j['languages'] as List? ?? [])
          .map((e) => RepoLanguageSlice.fromJson(e))
          .where((e) => e.name != 'Unknown')
          .toList());

  Map<String, dynamic> toJson() => {
        'nameWithOwner': nameWithOwner,
        'url': url,
        'isPrivate': isPrivate,
        'commitCount': commitCount,
        'primaryLanguageName': primaryLanguageName,
        'primaryLanguageColor': primaryLanguageColor,
        'languages': languages.map((l) => l.toJson()).toList()
      };
}

@immutable
class LanguageUsage {
  final String name;
  final String? color;
  final double score, percent;
  const LanguageUsage(
      {required this.name,
      this.color,
      required this.score,
      required this.percent});
  factory LanguageUsage.fromJson(Map<String, dynamic> j) => LanguageUsage(
      name: j['name'] ?? 'Unknown',
      color: j['color'],
      score: (j['score'] as num?)?.toDouble() ?? 0,
      percent: (j['percent'] as num?)?.toDouble() ?? 0);
  Map<String, dynamic> toJson() =>
      {'name': name, 'color': color, 'score': score, 'percent': percent};
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
      lastUpdated.toUtc(),
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
        lastUpdated: DateTime.tryParse(j['lastUpdated'] ?? '')?.toUtc() ??
            DateTime.now().toUtc(),
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
      (n ?? DateTime.now().toUtc())
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

@immutable
class WallpaperConfig {
  final bool isDarkMode, autoFitWidth;
  final bool showQuickStatsBar,
      statCurrentStreak,
      statLongestStreak,
      statTotalCommits,
      statTopLanguage;
  final double verticalPosition,
      horizontalPosition,
      scale,
      opacity,
      quoteFontSize,
      quoteOpacity,
      cornerRadius;
  final double paddingTop, paddingBottom, paddingLeft, paddingRight;
  final String customQuote;
  final String themeId;
  final String templateId;

  const WallpaperConfig({
    this.isDarkMode = false,
    this.verticalPosition = 0.5,
    this.horizontalPosition = 0.5,
    this.scale = 0.7,
    this.autoFitWidth = true,
    this.opacity = 1.0,
    this.customQuote = '',
    this.quoteFontSize = 14.0,
    this.quoteOpacity = 1.0,
    this.cornerRadius = 2.0,
    this.paddingTop = 0,
    this.paddingBottom = 0,
    this.paddingLeft = 0,
    this.paddingRight = 0,
    this.themeId = ThemePresets.defaultId,
    this.showQuickStatsBar = true,
    this.statCurrentStreak = true,
    this.statLongestStreak = true,
    this.statTotalCommits = true,
    this.statTopLanguage = true,
    this.templateId = 'minimal_dark',
  });

  factory WallpaperConfig.defaults() => const WallpaperConfig();

  factory WallpaperConfig.fromJson(Map<String, dynamic> j) {
    final q = _str(j['customQuote']) ?? '';
    final sanitizedQuote = ValidationUtils.sanitizeQuote(q);
    return WallpaperConfig(
      isDarkMode: j['isDarkMode'] == true,
      verticalPosition: _dbl(j['verticalPosition'], 0.5, 0, 1),
      horizontalPosition: _dbl(j['horizontalPosition'], 0.5, 0, 1),
      scale: _dbl(j['scale'], 0.7, AppConstants.minWallpaperScale,
          AppConstants.maxWallpaperScale),
      autoFitWidth: j['autoFitWidth'] != false,
      opacity: _dbl(j['opacity'], 1.0, 0, 1),
      customQuote: sanitizedQuote.length > AppConstants.quoteMaxLength
          ? sanitizedQuote.substring(0, AppConstants.quoteMaxLength)
          : sanitizedQuote,
      quoteFontSize: _dbl(j['quoteFontSize'], 14, 10, 40),
      quoteOpacity: _dbl(j['quoteOpacity'], 1, 0, 1),
      cornerRadius: _dbl(j['cornerRadius'], 2, 0, 20),
      paddingTop: _dbl(j['paddingTop'], 0, 0, 500),
      paddingBottom: _dbl(j['paddingBottom'], 0, 0, 500),
      paddingLeft: _dbl(j['paddingLeft'], 0, 0, 500),
      paddingRight: _dbl(j['paddingRight'], 0, 0, 500),
      themeId: (j['themeId'] is String && (j['themeId'] as String).isNotEmpty)
          ? j['themeId'] as String
          : ThemePresets.defaultId,
      showQuickStatsBar: j['showQuickStatsBar'] != false,
      statCurrentStreak: j['statCurrentStreak'] != false,
      statLongestStreak: j['statLongestStreak'] != false,
      statTotalCommits: j['statTotalCommits'] != false,
      statTopLanguage: j['statTopLanguage'] != false,
      templateId: (j['templateId'] is String && (j['templateId'] as String).isNotEmpty)
          ? j['templateId'] as String
          : 'minimal_dark',
    );
  }

  Map<String, dynamic> toJson() => {
        'isDarkMode': isDarkMode,
        'verticalPosition': verticalPosition,
        'horizontalPosition': horizontalPosition,
        'scale': scale,
        'autoFitWidth': autoFitWidth,
        'opacity': opacity,
        'customQuote': customQuote,
        'quoteFontSize': quoteFontSize,
        'quoteOpacity': quoteOpacity,
        'cornerRadius': cornerRadius,
        'paddingTop': paddingTop,
        'paddingBottom': paddingBottom,
        'paddingLeft': paddingLeft,
        'paddingRight': paddingRight,
        'themeId': themeId,
        'showQuickStatsBar': showQuickStatsBar,
        'statCurrentStreak': statCurrentStreak,
        'statLongestStreak': statLongestStreak,
        'statTotalCommits': statTotalCommits,
        'statTopLanguage': statTopLanguage,
        'templateId': templateId,
      };

  WallpaperConfig copyWith(
          {bool? isDarkMode,
          double? verticalPosition,
          double? horizontalPosition,
          double? scale,
          bool? autoFitWidth,
           double? opacity,
          String? customQuote,
          double? quoteFontSize,
          double? quoteOpacity,
          double? cornerRadius,
          double? paddingTop,
          double? paddingBottom,
          double? paddingLeft,
          double? paddingRight,
          String? themeId,
          bool? showQuickStatsBar,
          bool? statCurrentStreak,
          bool? statLongestStreak,
          bool? statTotalCommits,
          bool? statTopLanguage,
          String? templateId}) =>
      WallpaperConfig(
        isDarkMode: isDarkMode ?? this.isDarkMode,
        verticalPosition: verticalPosition ?? this.verticalPosition,
        horizontalPosition: horizontalPosition ?? this.horizontalPosition,
        scale: scale ?? this.scale,
        autoFitWidth: autoFitWidth ?? this.autoFitWidth,
        opacity: opacity ?? this.opacity,
        customQuote: customQuote ?? this.customQuote,
        quoteFontSize: quoteFontSize ?? this.quoteFontSize,
        quoteOpacity: quoteOpacity ?? this.quoteOpacity,
        cornerRadius: cornerRadius ?? this.cornerRadius,
        paddingTop: paddingTop ?? this.paddingTop,
        paddingBottom: paddingBottom ?? this.paddingBottom,
        paddingLeft: paddingLeft ?? this.paddingLeft,
        paddingRight: paddingRight ?? this.paddingRight,
        themeId: themeId ?? this.themeId,
        showQuickStatsBar: showQuickStatsBar ?? this.showQuickStatsBar,
        statCurrentStreak: statCurrentStreak ?? this.statCurrentStreak,
        statLongestStreak: statLongestStreak ?? this.statLongestStreak,
        statTotalCommits: statTotalCommits ?? this.statTotalCommits,
        statTopLanguage: statTopLanguage ?? this.statTopLanguage,
        templateId: templateId ?? this.templateId,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WallpaperConfig &&
          isDarkMode == other.isDarkMode &&
          autoFitWidth == other.autoFitWidth &&
          verticalPosition == other.verticalPosition &&
          horizontalPosition == other.horizontalPosition &&
          scale == other.scale &&
          opacity == other.opacity &&
          quoteFontSize == other.quoteFontSize &&
          quoteOpacity == other.quoteOpacity &&
          cornerRadius == other.cornerRadius &&
          paddingTop == other.paddingTop &&
          paddingBottom == other.paddingBottom &&
          paddingLeft == other.paddingLeft &&
          paddingRight == other.paddingRight &&
          themeId == other.themeId &&
          customQuote == other.customQuote &&
          showQuickStatsBar == other.showQuickStatsBar &&
          statCurrentStreak == other.statCurrentStreak &&
          statLongestStreak == other.statLongestStreak &&
          statTotalCommits == other.statTotalCommits &&
          statTopLanguage == other.statTopLanguage &&
          templateId == other.templateId);

  @override
  int get hashCode => Object.hashAll([
        isDarkMode,
        autoFitWidth,
        verticalPosition,
        horizontalPosition,
        scale,
        opacity,
        quoteFontSize,
        quoteOpacity,
        cornerRadius,
        paddingTop,
        paddingBottom,
        paddingLeft,
        paddingRight,
        themeId,
        customQuote,
        showQuickStatsBar,
        statCurrentStreak,
        statLongestStreak,
        statTotalCommits,
        statTopLanguage,
        templateId,
      ]);
}
