import 'package:flutter/foundation.dart';

enum QuoteTone {
  friendly,
  motivational,
  roast;

  static QuoteTone fromLabel(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.contains('friendly')) return QuoteTone.friendly;
    if (lower.contains('roast')) return QuoteTone.roast;
    return QuoteTone.motivational;
  }

  String get label => switch (this) {
        QuoteTone.friendly => 'Friendly',
        QuoteTone.motivational => 'Motivational',
        QuoteTone.roast => 'Roast',
      };
}

enum QuoteCodingLevel {
  newcomer,
  beginner,
  regular,
  hardcore;

  static QuoteCodingLevel fromLabel(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.contains('hardcore')) return QuoteCodingLevel.hardcore;
    if (lower.contains('beginner')) return QuoteCodingLevel.beginner;
    if (lower.contains('new')) return QuoteCodingLevel.newcomer;
    return QuoteCodingLevel.regular;
  }

  String get label => switch (this) {
        QuoteCodingLevel.newcomer => 'New',
        QuoteCodingLevel.beginner => 'Beginner',
        QuoteCodingLevel.regular => 'Regular',
        QuoteCodingLevel.hardcore => 'Hardcore',
      };
}

enum QuoteCategory {
  reset,
  protect,
  rebound,
  momentum,
  celebrate,
  focus,
  consistency,
  deepWork,
  generic;

  String get key => switch (this) {
        QuoteCategory.reset => 'reset',
        QuoteCategory.protect => 'protect',
        QuoteCategory.rebound => 'rebound',
        QuoteCategory.momentum => 'momentum',
        QuoteCategory.celebrate => 'celebrate',
        QuoteCategory.focus => 'focus',
        QuoteCategory.consistency => 'consistency',
        QuoteCategory.deepWork => 'deep_work',
        QuoteCategory.generic => 'generic',
      };

  static QuoteCategory fromKey(String raw) {
    final normalized = raw.trim().toLowerCase();
    return QuoteCategory.values.firstWhere(
      (value) => value.key == normalized,
      orElse: () => QuoteCategory.generic,
    );
  }
}

enum QuoteSelectionSource {
  catalog,
  fallback;

  String get key => switch (this) {
        QuoteSelectionSource.catalog => 'catalog',
        QuoteSelectionSource.fallback => 'fallback',
      };

  static QuoteSelectionSource fromKey(String raw) {
    final normalized = raw.trim().toLowerCase();
    return QuoteSelectionSource.values.firstWhere(
      (value) => value.key == normalized,
      orElse: () => QuoteSelectionSource.fallback,
    );
  }
}

@immutable
class CuratedQuote {
  final String id;
  final String text;
  final QuoteTone tone;
  final Set<QuoteCodingLevel> levels;
  final Set<QuoteCategory> categories;
  final Set<String> streakBuckets;
  final Set<String> commitBuckets;
  final Set<String> weeklyBuckets;

  const CuratedQuote({
    required this.id,
    required this.text,
    required this.tone,
    required this.levels,
    required this.categories,
    required this.streakBuckets,
    required this.commitBuckets,
    required this.weeklyBuckets,
  });
}

@immutable
class QuoteActivityProfile {
  final String dayKey;
  final String toneLabel;
  final String codingLevelLabel;
  final String profileKey;
  final String streakBucket;
  final String commitsBucket;
  final String weeklyBucket;
  final List<QuoteCategory> categories;
  final int streak;
  final int commitsToday;
  final int weeklyTotal;
  final int activeDaysThisWeek;
  final int activeDaysThisMonth;
  final double weeklyDeltaRatio;
  final double topRepositoryShare;

  const QuoteActivityProfile({
    required this.dayKey,
    required this.toneLabel,
    required this.codingLevelLabel,
    required this.profileKey,
    required this.streakBucket,
    required this.commitsBucket,
    required this.weeklyBucket,
    required this.categories,
    required this.streak,
    required this.commitsToday,
    required this.weeklyTotal,
    required this.activeDaysThisWeek,
    required this.activeDaysThisMonth,
    required this.weeklyDeltaRatio,
    required this.topRepositoryShare,
  });

  String get fingerprint => [
        dayKey,
        profileKey,
        weeklyBucket,
        categories.map((value) => value.key).join(','),
        weeklyTotal,
        activeDaysThisWeek,
        activeDaysThisMonth,
        weeklyDeltaRatio.toStringAsFixed(2),
        topRepositoryShare.toStringAsFixed(2),
      ].join('|');

  Map<String, dynamic> toJson() => {
        'dayKey': dayKey,
        'toneLabel': toneLabel,
        'codingLevelLabel': codingLevelLabel,
        'profileKey': profileKey,
        'streakBucket': streakBucket,
        'commitsBucket': commitsBucket,
        'weeklyBucket': weeklyBucket,
        'categories': categories.map((value) => value.key).toList(),
        'streak': streak,
        'commitsToday': commitsToday,
        'weeklyTotal': weeklyTotal,
        'activeDaysThisWeek': activeDaysThisWeek,
        'activeDaysThisMonth': activeDaysThisMonth,
        'weeklyDeltaRatio': weeklyDeltaRatio,
        'topRepositoryShare': topRepositoryShare,
      };

  factory QuoteActivityProfile.fromJson(Map<String, dynamic> json) =>
      QuoteActivityProfile(
        dayKey: '${json['dayKey'] ?? ''}',
        toneLabel: '${json['toneLabel'] ?? 'Motivational'}',
        codingLevelLabel: '${json['codingLevelLabel'] ?? 'Regular'}',
        profileKey: '${json['profileKey'] ?? ''}',
        streakBucket: '${json['streakBucket'] ?? '0d'}',
        commitsBucket: '${json['commitsBucket'] ?? '0c'}',
        weeklyBucket: '${json['weeklyBucket'] ?? 'idle'}',
        categories: ((json['categories'] as List?) ?? const [])
            .map((value) => QuoteCategory.fromKey('$value'))
            .toList(growable: false),
        streak: (json['streak'] as num?)?.toInt() ?? 0,
        commitsToday: (json['commitsToday'] as num?)?.toInt() ?? 0,
        weeklyTotal: (json['weeklyTotal'] as num?)?.toInt() ?? 0,
        activeDaysThisWeek: (json['activeDaysThisWeek'] as num?)?.toInt() ?? 0,
        activeDaysThisMonth:
            (json['activeDaysThisMonth'] as num?)?.toInt() ?? 0,
        weeklyDeltaRatio: (json['weeklyDeltaRatio'] as num?)?.toDouble() ?? 0.0,
        topRepositoryShare:
            (json['topRepositoryShare'] as num?)?.toDouble() ?? 0.0,
      );
}

@immutable
class QuoteSelectionState {
  final String dayKey;
  final String quoteId;
  final String quote;
  final QuoteCategory category;
  final QuoteSelectionSource source;
  final String profileFingerprint;
  final int refreshCount;
  final QuoteActivityProfile activity;

  const QuoteSelectionState({
    required this.dayKey,
    required this.quoteId,
    required this.quote,
    required this.category,
    required this.source,
    required this.profileFingerprint,
    required this.refreshCount,
    required this.activity,
  });

  Map<String, dynamic> toJson() => {
        'dayKey': dayKey,
        'quoteId': quoteId,
        'quote': quote,
        'category': category.key,
        'source': source.key,
        'profileFingerprint': profileFingerprint,
        'refreshCount': refreshCount,
        'activity': activity.toJson(),
      };

  factory QuoteSelectionState.fromJson(Map<String, dynamic> json) =>
      QuoteSelectionState(
        dayKey: '${json['dayKey'] ?? ''}',
        quoteId: '${json['quoteId'] ?? ''}',
        quote: '${json['quote'] ?? ''}',
        category: QuoteCategory.fromKey('${json['category'] ?? 'generic'}'),
        source: QuoteSelectionSource.fromKey('${json['source'] ?? 'fallback'}'),
        profileFingerprint: '${json['profileFingerprint'] ?? ''}',
        refreshCount: (json['refreshCount'] as num?)?.toInt() ?? 0,
        activity: QuoteActivityProfile.fromJson(
          (json['activity'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{},
        ),
      );
}
