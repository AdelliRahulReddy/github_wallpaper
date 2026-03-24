import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/app/services/remote_config_service.dart';
import 'package:github_wallpaper/features/membership/services/membership_entitlements.dart';
import 'package:github_wallpaper/features/contributions/services/contribution_metrics.dart';

import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/core/constants/environment_config.dart'
    as app_config;

class DailyQuoteResult {
  final String quote;
  final bool usedAi;
  final bool usedFallback;
  final bool fromCache;

  const DailyQuoteResult({
    required this.quote,
    this.usedAi = false,
    this.usedFallback = false,
    this.fromCache = false,
  });
}

class DailyQuoteService {
  static const List<String> _friendly = [
    'Steady progress wins. Pick one meaningful improvement and move it forward today.',
    'You are building real skills line by line. Keep the work honest and focused.',
    'Small, real steps count. Add value to your project today—code, tests, or docs.',
  ];
  static const List<String> _motivational = [
    'Discipline beats mood. Finish one real task today and close the loop.',
    'Consistency compounds. Keep shipping meaningful progress.',
    'Make today undeniable: improve one thing that matters.',
  ];
  static const List<String> _roast = [
    'Your project is waiting. Stop hovering and make one real improvement.',
    'Today is looking a little empty. Ship something useful, not something noisy.',
    'Excuses do not compile. Progress does.',
  ];

  static String today() {
    final dayKey = AppDateUtils.formatDate(DateTime.now().toLocal());
    final cachedDay = StorageService.getCachedAiQuoteDay();
    final cached = StorageService.getCachedAiQuote();
    if (cachedDay == dayKey && cached != null && cached.trim().isNotEmpty) {
      return cached;
    }
    final fallback = _fallbackQuote(
      tone: StorageService.getQuoteTone(),
      seed: DateTime.now().day,
    );
    return fallback;
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
    final dayKey = AppDateUtils.formatDate(DateTime.now().toLocal());
    final cachedDay = StorageService.getCachedAiQuoteDay();
    final cached = StorageService.getCachedAiQuote();
    if (!forceRegenerate &&
        cachedDay == dayKey &&
        cached != null &&
        cached.trim().isNotEmpty) {
      return DailyQuoteResult(quote: cached, fromCache: true);
    }

    final tone = normalizeTone(StorageService.getQuoteTone());
    final hasProAccess = MembershipEntitlements.hasProAccess;

    if (forceRegenerate && hasProAccess) {
      final generated = await _generateRegeneratedQuote(
        data: data,
        tone: tone,
        codingLevel: normalizeCodingLevel(StorageService.getCodingLevel()),
      );
      if (generated != null && generated.trim().isNotEmpty) {
        await StorageService.setCachedAiQuote(quote: generated, dayKey: dayKey);
        return DailyQuoteResult(quote: generated, usedAi: true);
      }
    }

    if (!MembershipEntitlements.canUseAiQuotes) {
      final quote = _fallbackQuote(tone: tone, seed: data.todayCommits);
      await StorageService.setCachedAiQuote(quote: quote, dayKey: dayKey);
      return DailyQuoteResult(
        quote: quote,
        usedFallback: true,
      );
    }

    final pooledQuote = await _fetchPooledQuote(data);
    final quote =
        pooledQuote ?? _fallbackQuote(tone: tone, seed: data.todayCommits);
    await StorageService.setCachedAiQuote(quote: quote, dayKey: dayKey);
    return DailyQuoteResult(
      quote: quote,
      usedFallback: pooledQuote == null,
    );
  }

  @visibleForTesting
  static String normalizeTone(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.contains('friendly')) return 'Friendly';
    if (lower.contains('roast')) return 'Roast';
    return 'Motivational';
  }

  @visibleForTesting
  static String normalizeCodingLevel(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.contains('hardcore')) return 'Hardcore';
    if (lower.contains('beginner')) return 'Beginner';
    if (lower.contains('new')) return 'New';
    return 'Regular';
  }

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

  static Future<String?> _fetchPooledQuote(CachedContributionData data) async {
    final remoteConfig = RemoteConfigService();
    if (!remoteConfig.aiQuotesEnabled) {
      AppLog.info('AI quotes disabled in Remote Config. Using fallback quote.');
      return null;
    }

    final db = _dbOrNull;
    if (db == null) {
      AppLog.info('Firestore unavailable for pooled quotes. Using fallback.');
      return null;
    }

    try {
      final docId = AppDateUtils.formatDate(DateTime.now().toLocal());
      final profileKey = buildProfileKey(
        streak: data.currentStreak,
        commitsToday: data.todayCommits,
        tone: StorageService.getQuoteTone(),
        codingLevel: StorageService.getCodingLevel(),
      );
      final snapshot = await db.collection('daily_quotes').doc(docId).get();
      final value = snapshot.data()?[profileKey];
      final quote = value?.toString().trim();
      if (quote == null || quote.isEmpty) {
        AppLog.info('No pooled quote found for key: $profileKey');
        return null;
      }
      return quote;
    } catch (e, s) {
      AppLog.error(e, s);
      return null;
    }
  }

  static Future<String?> _generateRegeneratedQuote({
    required CachedContributionData data,
    required String tone,
    required String codingLevel,
  }) async {
    try {
      final remoteConfig = RemoteConfigService();
      if (!remoteConfig.aiQuotesEnabled) {
        AppLog.info(
            'AI quotes disabled in Remote Config. Using pooled/fallback quotes.');
        return null;
      }

      final key = app_config.AppConfig.geminiApiKey.trim();
      if (key.isEmpty) {
        AppLog.info('Gemini API key is empty. Using pooled/fallback quotes.');
        return null;
      }

      final trend7d = ContributionAnalyzer.computeTrend(
        data.days,
        window: 7,
        dateOf: (d) => d.date,
        countOf: (d) => d.contributionCount,
      );
      final model =
          GenerativeModel(model: 'gemini-3.1-flash-lite-preview', apiKey: key);
      final weeklyDeltaPct = (trend7d.deltaRatio * 100).toStringAsFixed(0);
      final prompt = '''
You are an AI coach for a developer's progress dashboard.
Write a short 1-2 sentence message that is contextual, calm, and actionable.

User context:
- Coding level: $codingLevel
- Tone: $tone
- Current streak: ${data.currentStreak} days
- Commits today: ${data.todayCommits}
- This week: ${trend7d.current} commits ($weeklyDeltaPct% vs last week)

Rules:
- Do NOT write generic inspirational quotes.
- Do NOT tell them to "just commit" or game stats.
- Encourage meaningful work: features, fixes, tests, docs, reviews.
- If commits today > 0, acknowledge they're safe today and suggest a next meaningful step.
- If commits today == 0, suggest one small, real task to make progress today (no streak obsession).
- If tone is "roast", be funny and slightly insulting, but never malicious.
- Return ONLY the message text. No quotes, no markdown, no emojis.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
      return null;
    } catch (e, s) {
      AppLog.error(e, s);
      return null;
    }
  }

  static String _fallbackQuote({required String tone, required int seed}) {
    final lower = normalizeTone(tone).toLowerCase();
    final list = lower.contains('roast')
        ? _roast
        : lower.contains('friendly')
            ? _friendly
            : _motivational;
    return list[Random(seed).nextInt(list.length)];
  }

  static FirebaseFirestore? get _dbOrNull {
    if (Firebase.apps.isEmpty) {
      return null;
    }

    try {
      return FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'default',
      );
    } catch (e, s) {
      AppLog.error('DailyQuoteService Firestore unavailable: $e', s);
      return null;
    }
  }
}

