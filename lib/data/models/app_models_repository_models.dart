part of 'app_models.dart';

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
