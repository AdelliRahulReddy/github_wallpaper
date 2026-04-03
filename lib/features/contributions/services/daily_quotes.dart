import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:github_wallpaper/app/services/remote_config_service.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/features/contributions/data/curated_quote_pool.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/features/contributions/models/quote_models.dart';
import 'package:github_wallpaper/features/contributions/services/contribution_metrics.dart';

class DailyQuoteResult {
  final String quote;
  final bool usedAi;
  final bool usedFallback;
  final bool fromCache;
  final String? quoteId;
  final String? categoryKey;

  const DailyQuoteResult({
    required this.quote,
    this.usedAi = false,
    this.usedFallback = false,
    this.fromCache = false,
    this.quoteId,
    this.categoryKey,
  });
}

class DailyQuoteService {
  static const List<String> _friendly = [
    'Steady progress wins. Pick one meaningful improvement and move it forward today.',
    'You are building real skills line by line. Keep the work honest and focused.',
    'Small, real steps count. Add value to your project today: code, tests, or docs.',
  ];
  static const List<String> _motivational = [
    'Discipline beats mood. Finish one real task today and close the loop.',
    'Consistency compounds. Keep shipping meaningful progress.',
    'Make today undeniable. Improve one thing that matters.',
  ];
  static const List<String> _roast = [
    'Your project is waiting. Stop hovering and make one real improvement.',
    'Today is looking a little empty. Ship something useful, not something noisy.',
    'Excuses do not compile. Progress does.',
  ];

  static String today({CachedContributionData? data}) {
    final dayKey = AppDateUtils.formatDate(DateTime.now().toLocal());
    final cachedState = StorageService.getCachedQuoteState();
    if (cachedState != null &&
        cachedState.dayKey == dayKey &&
        cachedState.quote.trim().isNotEmpty) {
      return cachedState.quote;
    }

    final cachedDay = StorageService.getCachedQuoteDay();
    final cached = StorageService.getCachedQuote();
    if (cachedDay == dayKey && cached != null && cached.trim().isNotEmpty) {
      return cached;
    }

    final resolvedData = data ?? StorageService.getCachedData();
    if (resolvedData != null) {
      final outcome = _buildSelection(
        data: resolvedData,
        forceRegenerate: false,
      );
      return outcome.state.quote;
    }

    return _fallbackQuote(
      tone: StorageService.getQuoteTone(),
      seed: DateTime.now().day,
    );
  }

  static Future<String> ensureDailyQuote({
    required CachedContributionData data,
    bool forceRegenerate = false,
  }) async =>
      (await ensureDailyQuoteResult(
        data: data,
        forceRegenerate: forceRegenerate,
      ))
          .quote;

  static Future<DailyQuoteResult> ensureDailyQuoteResult({
    required CachedContributionData data,
    bool forceRegenerate = false,
  }) async {
    final profile = buildActivityProfile(
      data: data,
      tone: StorageService.getQuoteTone(),
      codingLevel: StorageService.getCodingLevel(),
    );
    final cachedState = StorageService.getCachedQuoteState();

    if (!forceRegenerate &&
        cachedState != null &&
        cachedState.dayKey == profile.dayKey &&
        cachedState.profileFingerprint == profile.fingerprint &&
        cachedState.quote.trim().isNotEmpty) {
      return DailyQuoteResult(
        quote: cachedState.quote,
        fromCache: true,
        quoteId: cachedState.quoteId,
        categoryKey: cachedState.category.key,
      );
    }

    final outcome = _buildSelection(
      data: data,
      forceRegenerate: forceRegenerate,
      previousState: cachedState,
    );
    await StorageService.setQuoteActivitySnapshot(outcome.state.activity);
    await StorageService.setCachedQuoteState(outcome.state);
    if (outcome.state.source == QuoteSelectionSource.catalog) {
      await StorageService.pushQuoteHistory(outcome.state.quoteId);
    }

    return DailyQuoteResult(
      quote: outcome.state.quote,
      usedFallback: outcome.usedFallback,
      quoteId: outcome.state.quoteId,
      categoryKey: outcome.state.category.key,
    );
  }

  @visibleForTesting
  static String normalizeTone(String raw) => QuoteTone.fromLabel(raw).label;

  @visibleForTesting
  static String normalizeCodingLevel(String raw) =>
      QuoteCodingLevel.fromLabel(raw).label;

  @visibleForTesting
  static String streakBucket(int streak) {
    if (streak <= 0) return '0d';
    if (streak <= 3) return '1_3d';
    if (streak <= 7) return '4_7d';
    if (streak <= 14) return '8_14d';
    if (streak <= 30) return '15_30d';
    if (streak <= 60) return '31_60d';
    if (streak <= 100) return '61_100d';
    return '100pd';
  }

  @visibleForTesting
  static String commitsBucket(int commitsToday) {
    if (commitsToday <= 0) return '0c';
    if (commitsToday <= 2) return '1_2c';
    if (commitsToday <= 5) return '3_5c';
    return '6pc';
  }

  @visibleForTesting
  static String weeklyBucket(int weeklyTotal) {
    if (weeklyTotal <= 2) return 'idle';
    if (weeklyTotal <= 8) return 'warming';
    if (weeklyTotal <= 20) return 'steady';
    return 'surging';
  }

  @visibleForTesting
  static String buildProfileKey({
    required int streak,
    required int commitsToday,
    required String tone,
    required String codingLevel,
  }) {
    return [
      streakBucket(streak),
      normalizeTone(tone),
      normalizeCodingLevel(codingLevel),
      commitsBucket(commitsToday),
    ].join('_');
  }

  @visibleForTesting
  static QuoteActivityProfile buildActivityProfile({
    required CachedContributionData data,
    required String tone,
    required String codingLevel,
    DateTime? now,
  }) {
    final localNow = (now ?? DateTime.now()).toLocal();
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final trend7d = ContributionAnalyzer.computeTrend(
      data.days,
      window: 7,
      dateOf: (day) => day.date,
      countOf: (day) => day.contributionCount,
    );
    final activeDaysThisWeek = _countActiveDays(
      data.days,
      start: today.subtract(const Duration(days: 6)),
      end: today,
    );
    final activeDaysThisMonth = _countActiveDays(
      data.days,
      start: today.subtract(const Duration(days: 29)),
      end: today,
    );
    final normalizedTone = normalizeTone(tone);
    final normalizedCodingLevel = normalizeCodingLevel(codingLevel);
    final topRepositoryShare = _topRepositoryShare(data.repositories);

    return QuoteActivityProfile(
      dayKey: AppDateUtils.formatDate(today),
      toneLabel: normalizedTone,
      codingLevelLabel: normalizedCodingLevel,
      profileKey: buildProfileKey(
        streak: data.currentStreak,
        commitsToday: data.todayCommits,
        tone: normalizedTone,
        codingLevel: normalizedCodingLevel,
      ),
      streakBucket: streakBucket(data.currentStreak),
      commitsBucket: commitsBucket(data.todayCommits),
      weeklyBucket: weeklyBucket(trend7d.current),
      categories: _deriveCategories(
        data: data,
        weeklyTotal: trend7d.current,
        activeDaysThisWeek: activeDaysThisWeek,
        weeklyDeltaRatio: trend7d.deltaRatio,
        topRepositoryShare: topRepositoryShare,
        codingLevel: QuoteCodingLevel.fromLabel(normalizedCodingLevel),
      ),
      streak: data.currentStreak,
      commitsToday: data.todayCommits,
      weeklyTotal: trend7d.current,
      activeDaysThisWeek: activeDaysThisWeek,
      activeDaysThisMonth: activeDaysThisMonth,
      weeklyDeltaRatio: trend7d.deltaRatio,
      topRepositoryShare: topRepositoryShare,
    );
  }

  static _SelectionOutcome _buildSelection({
    required CachedContributionData data,
    required bool forceRegenerate,
    QuoteSelectionState? previousState,
  }) {
    final profile = buildActivityProfile(
      data: data,
      tone: StorageService.getQuoteTone(),
      codingLevel: StorageService.getCodingLevel(),
    );
    final smartQuotesEnabled = RemoteConfigService().smartQuotesEnabled;
    final refreshCount = _resolveRefreshCount(
      profile: profile,
      previousState: previousState,
      forceRegenerate: forceRegenerate,
    );

    if (!smartQuotesEnabled) {
      final fallback = _fallbackSelection(profile, refreshCount: refreshCount);
      return _SelectionOutcome(state: fallback, usedFallback: true);
    }

    final tone = QuoteTone.fromLabel(profile.toneLabel);
    final level = QuoteCodingLevel.fromLabel(profile.codingLevelLabel);
    final history = StorageService.getQuoteHistory();
    final blockedIds = <String>{
      if (forceRegenerate && previousState?.dayKey == profile.dayKey)
        previousState!.quoteId,
    };
    final selected = _selectCatalogQuote(
      profile: profile,
      tone: tone,
      level: level,
      history: history,
      previousState: previousState,
      blockedIds: blockedIds,
      refreshCount: refreshCount,
    );

    if (selected != null) {
      return _SelectionOutcome(
        state: QuoteSelectionState(
          dayKey: profile.dayKey,
          quoteId: selected.id,
          quote: selected.text,
          category: _primaryCategoryFor(selected, profile),
          source: QuoteSelectionSource.catalog,
          profileFingerprint: profile.fingerprint,
          refreshCount: refreshCount,
          activity: profile,
        ),
        usedFallback: false,
      );
    }

    final fallback = _fallbackSelection(profile, refreshCount: refreshCount);
    return _SelectionOutcome(state: fallback, usedFallback: true);
  }

  static CuratedQuote? _selectCatalogQuote({
    required QuoteActivityProfile profile,
    required QuoteTone tone,
    required QuoteCodingLevel level,
    required List<String> history,
    required QuoteSelectionState? previousState,
    required Set<String> blockedIds,
    required int refreshCount,
  }) {
    for (final exactLevel in [true, false]) {
      final candidates = <({CuratedQuote quote, double score})>[];
      for (final quote in curatedQuotePool) {
        if (quote.tone != tone) continue;
        if (blockedIds.contains(quote.id)) continue;
        if (!quote.commitBuckets.contains(profile.commitsBucket)) continue;
        if (!quote.streakBuckets.contains(profile.streakBucket)) continue;
        if (exactLevel && !quote.levels.contains(level)) continue;

        final score = _scoreCandidate(
          quote,
          profile: profile,
          level: level,
          history: history,
          previousState: previousState,
          preferVariety: refreshCount > 0,
        );
        candidates.add((quote: quote, score: score));
      }

      if (candidates.isEmpty) continue;
      candidates.sort((a, b) => b.score.compareTo(a.score));
      final topPool = candidates.take(8).map((entry) => entry.quote).toList();
      final selectedIndex = _stableIndex(
        '${profile.fingerprint}|${tone.name}|${level.name}',
        topPool.length,
        refreshCount,
      );
      return topPool[selectedIndex];
    }

    return null;
  }

  static double _scoreCandidate(
    CuratedQuote quote, {
    required QuoteActivityProfile profile,
    required QuoteCodingLevel level,
    required List<String> history,
    required QuoteSelectionState? previousState,
    required bool preferVariety,
  }) {
    var score = 0.0;

    if (quote.levels.contains(level)) {
      score += 24;
    }

    for (var index = 0; index < profile.categories.length; index++) {
      final category = profile.categories[index];
      if (quote.categories.contains(category)) {
        score += (88 - (index * 11)).clamp(18, 88).toDouble();
      }
    }

    if (quote.weeklyBuckets.contains(profile.weeklyBucket)) {
      score += 10;
    }

    final recentIndex = history.indexOf(quote.id);
    if (recentIndex >= 0) {
      score -= max(8, 24 - recentIndex);
    }

    if (previousState?.quoteId == quote.id) {
      score -= preferVariety ? 60 : 18;
    }

    if (previousState != null &&
        quote.categories.contains(previousState.category) &&
        preferVariety) {
      score -= 10;
    }

    score += _stableJitter('${quote.id}|${profile.fingerprint}');
    return score;
  }

  static QuoteCategory _primaryCategoryFor(
    CuratedQuote quote,
    QuoteActivityProfile profile,
  ) {
    for (final category in profile.categories) {
      if (quote.categories.contains(category)) return category;
    }
    return QuoteCategory.generic;
  }

  static QuoteSelectionState _fallbackSelection(
    QuoteActivityProfile profile, {
    required int refreshCount,
  }) {
    final quote = _fallbackQuote(
      tone: profile.toneLabel,
      seed: _stableIndex(profile.fingerprint, 1000, refreshCount),
    );
    return QuoteSelectionState(
      dayKey: profile.dayKey,
      quoteId:
          'fallback_${QuoteTone.fromLabel(profile.toneLabel).name}_$refreshCount',
      quote: quote,
      category: profile.categories.isEmpty
          ? QuoteCategory.generic
          : profile.categories.first,
      source: QuoteSelectionSource.fallback,
      profileFingerprint: profile.fingerprint,
      refreshCount: refreshCount,
      activity: profile,
    );
  }

  @visibleForTesting
  static List<QuoteCategory> deriveCategoriesForTesting({
    required CachedContributionData data,
    required int weeklyTotal,
    required int activeDaysThisWeek,
    required double weeklyDeltaRatio,
    required double topRepositoryShare,
    required String codingLevel,
  }) =>
      _deriveCategories(
        data: data,
        weeklyTotal: weeklyTotal,
        activeDaysThisWeek: activeDaysThisWeek,
        weeklyDeltaRatio: weeklyDeltaRatio,
        topRepositoryShare: topRepositoryShare,
        codingLevel: QuoteCodingLevel.fromLabel(codingLevel),
      );

  static List<QuoteCategory> _deriveCategories({
    required CachedContributionData data,
    required int weeklyTotal,
    required int activeDaysThisWeek,
    required double weeklyDeltaRatio,
    required double topRepositoryShare,
    required QuoteCodingLevel codingLevel,
  }) {
    final categories = <QuoteCategory>[];

    if (milestoneHit(data.currentStreak) != null) {
      categories.add(QuoteCategory.celebrate);
    }

    if (data.todayCommits > 0) {
      categories.add(QuoteCategory.momentum);
    } else if (data.currentStreak > 0) {
      categories.add(QuoteCategory.protect);
    } else {
      categories.add(QuoteCategory.reset);
    }

    if (weeklyDeltaRatio <= -0.25 ||
        (weeklyTotal <= 2 && activeDaysThisWeek <= 1)) {
      categories.add(QuoteCategory.rebound);
    }

    if (topRepositoryShare >= 0.62) {
      categories.add(QuoteCategory.focus);
    }

    if (activeDaysThisWeek >= 5 || data.currentStreak >= 7) {
      categories.add(QuoteCategory.consistency);
    }

    if (weeklyTotal >= 18 ||
        activeDaysThisWeek >= 6 ||
        codingLevel == QuoteCodingLevel.hardcore) {
      categories.add(QuoteCategory.deepWork);
    }

    categories.add(QuoteCategory.generic);

    return categories.toSet().toList(growable: false);
  }

  @visibleForTesting
  static int? milestoneHit(int streak) {
    const milestones = [7, 14, 30, 50, 100, 365];
    return milestones.contains(streak) ? streak : null;
  }

  static int _countActiveDays(
    List<ContributionDay> days, {
    required DateTime start,
    required DateTime end,
  }) {
    var total = 0;
    for (final day in days) {
      final raw = day.date.toLocal();
      final normalized = DateTime(raw.year, raw.month, raw.day);
      if (normalized.isBefore(start) || normalized.isAfter(end)) continue;
      if (day.contributionCount > 0) total += 1;
    }
    return total;
  }

  static double _topRepositoryShare(List<RepoContribution> repositories) {
    if (repositories.isEmpty) return 0;
    final totalCommits = repositories.fold<int>(
      0,
      (sum, repository) => sum + repository.commitCount,
    );
    if (totalCommits <= 0) return 0;
    final topCommits = repositories.first.commitCount;
    return topCommits / totalCommits;
  }

  static int _resolveRefreshCount({
    required QuoteActivityProfile profile,
    required QuoteSelectionState? previousState,
    required bool forceRegenerate,
  }) {
    if (!forceRegenerate) return 0;
    if (previousState == null || previousState.dayKey != profile.dayKey) {
      return 1;
    }
    return previousState.refreshCount + 1;
  }

  static String _fallbackQuote({required String tone, required int seed}) {
    final list = switch (QuoteTone.fromLabel(tone)) {
      QuoteTone.roast => _roast,
      QuoteTone.friendly => _friendly,
      QuoteTone.motivational => _motivational,
    };
    return list[seed.abs() % list.length];
  }

  static double _stableJitter(String seed) =>
      (_stableHash(seed) % 1000).toDouble() / 1000.0;

  static int _stableIndex(String seed, int length, int salt) {
    if (length <= 1) return 0;
    return (_stableHash('$seed|$salt').abs()) % length;
  }

  static int _stableHash(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }
    return hash;
  }
}

class _SelectionOutcome {
  final QuoteSelectionState state;
  final bool usedFallback;

  const _SelectionOutcome({
    required this.state,
    required this.usedFallback,
  });
}
