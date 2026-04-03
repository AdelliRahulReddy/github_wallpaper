import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:github_wallpaper/core/errors/app_exceptions.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/features/contributions/services/contribution_metrics.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/features/wallpaper/models/theme_presets.dart';
import 'package:github_wallpaper/features/wallpaper/models/wallpaper_templates.dart';

class WallpaperCalendarCell {
  const WallpaperCalendarCell({
    required this.date,
    required this.contributionCount,
    required this.isToday,
    required this.isInFocusMonth,
    required this.startsNewMonth,
    required this.weekdayLabel,
    required this.shortMonthLabel,
    required this.accessibilityLabel,
  });

  final DateTime date;
  final int contributionCount;
  final bool isToday;
  final bool isInFocusMonth;
  final bool startsNewMonth;
  final String weekdayLabel;
  final String shortMonthLabel;
  final String accessibilityLabel;
}

class MonthHeatmapRenderer {
  static final _lT = AppThemeExt(isLight: true),
      _dT = AppThemeExt(isLight: false);
  static const rendererVersion = '2026-04-03-lock-month-only-v3';
  static void clearCaches() => RenderUtils.clearCaches();

  static double _focusScaleMultiplier(WallpaperHeroFocus focus) =>
      switch (focus) {
        WallpaperHeroFocus.auto => 1.0,
        WallpaperHeroFocus.grid => 1.0,
        WallpaperHeroFocus.quote => 0.92,
        WallpaperHeroFocus.stats => 0.96,
      };

  static double _statsBarMultiplier(
    WallpaperDensityMode densityMode,
    WallpaperHeroFocus focus,
  ) {
    final density = densityMode.statOpacityMultiplier;
    final focusBoost = switch (focus) {
      WallpaperHeroFocus.auto => 1.0,
      WallpaperHeroFocus.grid => 0.98,
      WallpaperHeroFocus.quote => 0.92,
      WallpaperHeroFocus.stats => 1.10,
    };
    return density * focusBoost;
  }

  static double _quoteFontMultiplier(
    WallpaperDensityMode densityMode,
    WallpaperHeroFocus focus,
  ) {
    final density = densityMode.quoteMultiplier;
    final focusBoost = switch (focus) {
      WallpaperHeroFocus.auto => 1.0,
      WallpaperHeroFocus.grid => 0.95,
      WallpaperHeroFocus.quote => 1.22,
      WallpaperHeroFocus.stats => 0.98,
    };
    return density * focusBoost;
  }

  static const _weekdayLabels = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN'
  ];
  static const _weekdayCompactLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _weekdayAccessibilityLabels = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _monthLabels = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  static const _monthAccessibilityLabels = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static DateTime _normalizeUtcDay(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  static DateTime _startOfCalendarWeek(DateTime dateUtc) {
    final normalized = _normalizeUtcDay(dateUtc);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  static DateTime _endOfCalendarWeek(DateTime dateUtc) =>
      _startOfCalendarWeek(dateUtc).add(const Duration(days: 6));

  static DateTime _startOfMonth(DateTime dateUtc) =>
      DateTime.utc(dateUtc.year, dateUtc.month, 1);

  static DateTime _endOfMonth(DateTime dateUtc) =>
      DateTime.utc(dateUtc.year, dateUtc.month + 1, 0);

  static _CalendarWindow _calendarWindowFor(
    DateTime todayUtc,
    WallpaperTarget target,
  ) {
    if (target == WallpaperTarget.home) {
      const dayCount = 35;
      final endOfRange = _endOfCalendarWeek(todayUtc);
      final startOfRange =
          endOfRange.subtract(const Duration(days: dayCount - 1));
      return _CalendarWindow(
        focusMonthStart: _startOfMonth(todayUtc),
        focusMonthEnd: _endOfMonth(todayUtc),
        dates: List<DateTime>.generate(
          dayCount,
          (index) => _normalizeUtcDay(startOfRange.add(Duration(days: index))),
          growable: false,
        ),
      );
    }

    final monthStart = _startOfMonth(todayUtc);
    final monthEnd = _endOfMonth(todayUtc);
    final calendarStart = _startOfCalendarWeek(monthStart);
    final calendarEnd = _endOfCalendarWeek(monthEnd);
    final dayCount = calendarEnd.difference(calendarStart).inDays + 1;
    return _CalendarWindow(
      focusMonthStart: monthStart,
      focusMonthEnd: monthEnd,
      dates: List<DateTime>.generate(
        dayCount,
        (index) => _normalizeUtcDay(calendarStart.add(Duration(days: index))),
        growable: false,
      ),
    );
  }

  static String _weekdayLabelFor(
    DateTime dateUtc,
    WallpaperTarget target,
  ) =>
      target == WallpaperTarget.home
          ? _weekdayLabels[dateUtc.weekday - 1]
          : _weekdayCompactLabels[dateUtc.weekday - 1];

  static String _weekdayAccessibilityLabelFor(DateTime dateUtc) =>
      _weekdayAccessibilityLabels[dateUtc.weekday - 1];

  static String _shortMonthLabelFor(DateTime dateUtc) =>
      _monthLabels[dateUtc.month - 1];

  static String _monthAccessibilityLabelFor(DateTime dateUtc) =>
      _monthAccessibilityLabels[dateUtc.month - 1];

  static String _longDateLabel(DateTime dateUtc) =>
      '${_monthAccessibilityLabelFor(dateUtc)} ${dateUtc.day}, ${dateUtc.year}';

  static String _monthYearAccessibilityLabel(DateTime dateUtc) =>
      '${_monthAccessibilityLabelFor(dateUtc)} ${dateUtc.year}';

  static _MonthActivitySummary _buildMonthActivitySummary(
    CachedContributionData data,
    DateTime todayUtc,
  ) {
    final monthStart = _startOfMonth(todayUtc);
    final monthEnd = _endOfMonth(todayUtc);
    final monthDays = data.days
        .where((day) =>
            day.date.year == monthStart.year &&
            day.date.month == monthStart.month)
        .toList(growable: false);
    final monthStats = ContributionStats.fromDays(
      monthDays,
      nowUtc: todayUtc,
    );
    return _MonthActivitySummary(
      monthStart: monthStart,
      monthEnd: monthEnd,
      stats: monthStats,
    );
  }

  static List<WallpaperCalendarCell> buildCalendarCells({
    required CachedContributionData data,
    required DateTime todayUtc,
    required WallpaperTarget target,
  }) {
    final today = _normalizeUtcDay(todayUtc);
    final calendarWindow = _calendarWindowFor(today, target);
    final dates = calendarWindow.dates;
    return List<WallpaperCalendarCell>.generate(dates.length, (index) {
      final date = dates[index];
      final count = data.getContributionsForDate(date);
      final previous = index == 0 ? null : dates[index - 1];
      final startsNewMonth = previous == null ||
          previous.month != date.month ||
          previous.year != date.year;
      final isInFocusMonth = date.year == calendarWindow.focusMonthStart.year &&
          date.month == calendarWindow.focusMonthStart.month;
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      final contributionLabel =
          count == 1 ? '1 contribution' : '$count contributions';
      final accessibility = isToday
          ? 'Today, ${_weekdayAccessibilityLabelFor(date)}, ${_longDateLabel(date)}, $contributionLabel'
          : '${_weekdayAccessibilityLabelFor(date)}, ${_longDateLabel(date)}, $contributionLabel';
      return WallpaperCalendarCell(
        date: date,
        contributionCount: count,
        isToday: isToday,
        isInFocusMonth: isInFocusMonth,
        startsNewMonth: startsNewMonth,
        weekdayLabel: _weekdayLabelFor(date, target),
        shortMonthLabel: _shortMonthLabelFor(date),
        accessibilityLabel: accessibility,
      );
    }, growable: false);
  }

  static String buildCalendarAccessibilityLabel({
    required CachedContributionData data,
    required DateTime todayUtc,
    required WallpaperTarget target,
  }) {
    final cells = buildCalendarCells(
      data: data,
      todayUtc: todayUtc,
      target: target,
    );
    if (cells.isEmpty) {
      return 'No contribution dates available.';
    }

    final today = _normalizeUtcDay(todayUtc);
    final calendarWindow = _calendarWindowFor(today, target);
    final first = cells.first.date;
    final last = cells.last.date;
    final todayCell = cells.firstWhere(
      (cell) => cell.isToday,
      orElse: () => cells.last,
    );
    if (target != WallpaperTarget.home) {
      return '${_monthYearAccessibilityLabel(calendarWindow.focusMonthStart)} calendar '
          'from ${_longDateLabel(calendarWindow.focusMonthStart)} to ${_longDateLabel(calendarWindow.focusMonthEnd)}. '
          'Today is ${todayCell.accessibilityLabel}.';
    }
    return 'Rolling activity calendar from ${_longDateLabel(first)} to ${_longDateLabel(last)}. '
        'Today is ${todayCell.accessibilityLabel}.';
  }

  static void _drawAtmosphere({
    required Canvas canvas,
    required Size size,
    required WallpaperTarget target,
    required WallpaperConfig config,
    required List<Color> themeLevels,
  }) {
    final base = config.isDarkMode ? AppTheme.darkBg : AppTheme.lightBg;
    final primary = themeLevels[themeLevels.length - 1];
    final secondary = themeLevels[themeLevels.length > 2 ? 2 : 1];
    final ambient = themeLevels[themeLevels.length > 1 ? 1 : 0];
    final glowAlpha = target == WallpaperTarget.home ? 0.14 : 0.20;
    final baseRect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawRect(
      baseRect,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          Offset(size.width, size.height),
          [
            base,
            Color.lerp(base, ambient, config.isDarkMode ? 0.10 : 0.06)!,
            Color.lerp(base, primary, config.isDarkMode ? 0.14 : 0.08)!,
          ],
          const [0.0, 0.55, 1.0],
        ),
    );

    if (target != WallpaperTarget.home) {
      void drawBeam({
        required Offset center,
        required double width,
        required double height,
        required double rotation,
        required Color start,
        required Color end,
      }) {
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(rotation);
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: width,
          height: height,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect,
            Radius.circular(height * 0.5),
          ),
          Paint()
            ..shader = ui.Gradient.linear(
              rect.topCenter,
              rect.bottomCenter,
              [
                start,
                end,
              ],
            ),
        );
        canvas.restore();
      }

      drawBeam(
        center: Offset(size.width * 0.80, size.height * 0.20),
        width: size.width * 0.72,
        height: size.height * 0.16,
        rotation: -0.48,
        start: primary.withValues(alpha: glowAlpha * 0.22),
        end: Colors.transparent,
      );
      drawBeam(
        center: Offset(size.width * 0.24, size.height * 0.78),
        width: size.width * 0.52,
        height: size.height * 0.12,
        rotation: -0.44,
        start: secondary.withValues(alpha: glowAlpha * 0.14),
        end: Colors.transparent,
      );
    }

    final heroGlowCenter = target == WallpaperTarget.home
        ? Offset(size.width * 0.34, size.height * 0.46)
        : Offset(size.width * 0.5, size.height * 0.56);
    final quoteGlowCenter = target == WallpaperTarget.home
        ? Offset(size.width * 0.82, size.height * 0.24)
        : Offset(size.width * 0.18, size.height * 0.22);

    canvas.drawCircle(
      heroGlowCenter,
      size.width * (target == WallpaperTarget.home ? 0.42 : 0.48),
      Paint()
        ..shader = ui.Gradient.radial(
          heroGlowCenter,
          size.width * (target == WallpaperTarget.home ? 0.42 : 0.48),
          [
            primary.withValues(
                alpha: target == WallpaperTarget.home
                    ? glowAlpha
                    : glowAlpha * 0.72),
            secondary.withValues(alpha: glowAlpha * 0.42),
            Colors.transparent,
          ],
          const [0.0, 0.42, 1.0],
        ),
    );

    canvas.drawCircle(
      quoteGlowCenter,
      size.width * 0.30,
      Paint()
        ..shader = ui.Gradient.radial(
          quoteGlowCenter,
          size.width * 0.30,
          [
            secondary.withValues(alpha: glowAlpha * 0.55),
            Colors.transparent,
          ],
        ),
    );

    canvas.drawRect(
      baseRect,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          Offset(0, size.height),
          [
            Colors.black.withValues(
                alpha: target == WallpaperTarget.home ? 0.08 : 0.14),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.18),
          ],
          const [0.0, 0.45, 1.0],
        ),
    );
  }

  static String _trimChipLabel(String value, {int maxChars = 16}) {
    final normalized = value.trim();
    if (normalized.length <= maxChars) return normalized;
    return '${normalized.substring(0, maxChars - 3)}...';
  }

  static String _shortRepoLabel(String value) {
    final slash = value.lastIndexOf('/');
    final repo = slash >= 0 ? value.substring(slash + 1) : value;
    return _trimChipLabel(repo, maxChars: 15);
  }

  static List<_IdentityItem> _buildIdentityItems(
    CachedContributionData data,
    WallpaperConfig config,
    WallpaperTarget target,
  ) {
    final usernameMaxChars = target == WallpaperTarget.home ? 14 : 14;
    final items = <_IdentityItem>[
      _IdentityItem(
        label: '@${_trimChipLabel(data.username, maxChars: usernameMaxChars)}',
      ),
    ];
    final topLanguage =
        data.topLanguages.isNotEmpty ? data.topLanguages.first : null;
    final topRepo = data.repositories
        .where((repository) => repository.commitCount > 0)
        .toList()
      ..sort((a, b) => b.commitCount.compareTo(a.commitCount));

    if (config.densityMode == WallpaperDensityMode.sparse &&
        target == WallpaperTarget.home) {
      return items;
    }

    if (target != WallpaperTarget.home &&
        (config.heroFocus == WallpaperHeroFocus.grid ||
            config.densityMode != WallpaperDensityMode.power)) {
      return items;
    }

    if (target != WallpaperTarget.home &&
        config.densityMode == WallpaperDensityMode.power &&
        topRepo.isNotEmpty) {
      final repository = topRepo.first;
      items.add(
        _IdentityItem(
          label: _shortRepoLabel(repository.nameWithOwner),
          accent: AppColorUtils.parseHexColor(
            repository.primaryLanguageColor,
          ),
        ),
      );
      return items;
    }

    if (topLanguage != null) {
      items.add(
        _IdentityItem(
          label: _trimChipLabel(topLanguage.name, maxChars: 14),
          accent: AppColorUtils.parseHexColor(topLanguage.color),
        ),
      );
    }

    return items;
  }

  static String _resolvedQuote(
    CachedContributionData data,
    WallpaperConfig config,
    WallpaperTarget target,
  ) {
    final custom = config.customQuote.trim();
    if (custom.isNotEmpty) return custom;
    final templateId = WallpaperTemplates.canonicalId(config.templateId);

    final wantsQuote = config.heroFocus == WallpaperHeroFocus.quote ||
        templateId == 'large_quote';
    if (!wantsQuote) return '';

    if (data.totalContributions == 0) {
      return 'Your coding journey starts today. One commit lights up the wall.';
    }
    if (data.currentStreak >= 30) {
      return 'Quiet consistency turns into unmistakable proof.';
    }
    if (data.currentStreak >= 7) {
      return 'Consistency compounds faster than motivation.';
    }
    if (data.peakDay >= 10) {
      return 'Ship quietly. Let the graph speak.';
    }
    return target == WallpaperTarget.home
        ? 'One small commit is enough to move the graph.'
        : 'One small commit is still momentum.';
  }

  static _PosterHeadline _buildHeadline({
    required CachedContributionData data,
    required WallpaperConfig config,
    required WallpaperTarget target,
    required DateTime todayUtc,
    required _CalendarWindow calendarWindow,
  }) {
    final templateId = WallpaperTemplates.canonicalId(config.templateId);
    final trend = ContributionAnalyzer.computeTrend(
      data.days,
      window: 7,
      dateOf: (day) => day.date,
      countOf: (day) => day.contributionCount,
    );
    final signedTrend = trend.previous <= 0 && trend.current > 0
        ? 'Momentum unlocked'
        : '${trend.deltaRatio >= 0 ? '+' : ''}${(trend.deltaRatio * 100).round()}% this week';
    final displayDates = calendarWindow.dates;

    switch (templateId) {
      case 'streak_poster':
        return _PosterHeadline(
          eyebrow:
              target == WallpaperTarget.home ? 'HOME PROFILE' : 'STREAK POSTER',
          title: data.currentStreak > 0
              ? '${data.currentStreak} day streak'
              : 'Start a fresh streak',
          subtitle: data.currentStreak > 0
              ? 'One more commit keeps the run alive.'
              : 'A single commit turns the wall back on.',
        );
      case 'momentum_card':
        return _PosterHeadline(
          eyebrow: '7 DAY MOMENTUM',
          title: signedTrend,
          subtitle: trend.current > 0 || trend.previous > 0
              ? '${trend.current} contributions in the current window.'
              : 'A clean canvas for the next sprint.',
        );
      case 'dracula_pop':
      case 'neon_night':
        return _PosterHeadline(
          eyebrow: 'PEAK OUTPUT',
          title: data.peakDay > 0
              ? '${data.peakDay} commits'
              : 'Build the first spike',
          subtitle: data.peakDay > 0
              ? 'Your strongest day in the current snapshot.'
              : 'The first deep work session can define the poster.',
        );
      case 'large_quote':
        return _PosterHeadline(
          eyebrow: target == WallpaperTarget.home
              ? 'CALM HOME PROFILE'
              : 'QUOTE HERO',
        );
      case 'heatmap_hero':
      case 'heatmap_hero_lite':
        return _PosterHeadline(
          eyebrow:
              target == WallpaperTarget.home ? 'CALM ACTIVITY' : 'HEATMAP HERO',
          subtitle: target == WallpaperTarget.home
              ? 'Cleaner spacing with room for icons and widgets.'
              : 'Last ${displayDates.length} days, tuned for quicker scanning.',
        );
      case 'quiet_grid_home':
      case 'quiet_grid_premium':
        return const _PosterHeadline(
          eyebrow: 'ICON SAFE HOME',
          subtitle: 'Balanced for app icons and glanceable widgets.',
        );
      default:
        if (config.heroFocus == WallpaperHeroFocus.stats) {
          return _PosterHeadline(
            eyebrow: target == WallpaperTarget.home
                ? 'HOME PROFILE'
                : 'MOMENTUM SNAPSHOT',
            title: data.currentStreak > 0
                ? '${data.currentStreak} day run'
                : 'Momentum starts now',
            subtitle: data.currentStreak > 0
                ? '${PresentationFormatter.formatCompactNumber(data.totalContributions)} total contributions.'
                : 'The next commit sets the pace.',
          );
        }
        return _PosterHeadline(
          eyebrow: target == WallpaperTarget.home
              ? 'HOME PROFILE'
              : 'ROLLING HEATMAP',
          subtitle: target == WallpaperTarget.home
              ? 'Calm composition with more icon-safe breathing room.'
              : 'Last ${displayDates.length} days of GitHub activity.',
        );
    }
  }

  static TextPainter _layoutText(
    String text,
    TextStyle style,
    double maxWidth, {
    TextAlign textAlign = TextAlign.left,
    int? maxLines,
  }) {
    return TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: maxLines == null ? null : '...',
    )..layout(maxWidth: maxWidth);
  }

  static void _drawPosterPanel({
    required Canvas canvas,
    required Rect rect,
    required double radius,
    required WallpaperConfig config,
    required bool isDarkMode,
    required bool isHome,
    required bool isFullWidth,
    required Color accent,
  }) {
    final surfaceOpacity =
        (0.28 + (config.opacity * 0.72)).clamp(0.28, 1.0).toDouble();
    final resolvedRadius =
        math.max(8.0, radius + (config.cornerRadius * (isHome ? 1.0 : 1.3)));
    final shadowPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(resolvedRadius)),
      );
    if (!isFullWidth) {
      canvas.drawShadow(
        shadowPath,
        Colors.black.withValues(alpha: isHome ? 0.20 : 0.26),
        isHome ? 28 : 36,
        false,
      );
    }

    final baseColor = isDarkMode
        ? const Color(0xFF0F1511).withValues(
            alpha:
                (isFullWidth ? 0.58 : (isHome ? 0.66 : 0.76)) * surfaceOpacity,
          )
        : Colors.white.withValues(
            alpha:
                (isFullWidth ? 0.86 : (isHome ? 0.88 : 0.94)) * surfaceOpacity,
          );
    final secondaryColor = isDarkMode
        ? const Color(0xFF0B100C).withValues(
            alpha:
                (isFullWidth ? 0.68 : (isHome ? 0.72 : 0.82)) * surfaceOpacity,
          )
        : const Color(0xFFF6F8FA).withValues(alpha: 0.96 * surfaceOpacity);

    final panelRRect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(resolvedRadius),
    );
    canvas.drawRRect(
      panelRRect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          [
            baseColor,
            secondaryColor,
            accent.withValues(
              alpha: (isHome ? 0.08 : (isFullWidth ? 0.07 : 0.12)) *
                  surfaceOpacity,
            ),
          ],
          const [0.0, 0.68, 1.0],
        ),
    );
    if (!isFullWidth) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.deflate(10),
          Radius.circular(math.max(2.0, resolvedRadius - 10)),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = Colors.white.withValues(
            alpha: (isDarkMode ? 0.08 : 0.14) * surfaceOpacity,
          ),
      );
    }
    canvas.drawRRect(
      panelRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHome ? 1.2 : 1.4
        ..color = accent.withValues(
          alpha: (isFullWidth ? 0.14 : (isHome ? 0.16 : 0.22)) * surfaceOpacity,
        ),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rect.left + 2,
          rect.top + 2,
          rect.width - 4,
          rect.height * 0.42,
        ),
        Radius.circular(math.max(4.0, resolvedRadius - 2)),
      ),
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          Offset(rect.left, rect.top + rect.height * 0.42),
          [
            Colors.white.withValues(
              alpha: (isDarkMode ? 0.06 : 0.20) * surfaceOpacity,
            ),
            Colors.transparent,
          ],
        ),
    );

    final accentBarRect = Rect.fromLTWH(
      rect.left + 18,
      rect.top + 18,
      rect.width * (isFullWidth ? 0.08 : (isHome ? 0.12 : 0.14)),
      isHome ? 4 : 5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(accentBarRect, const Radius.circular(999)),
      Paint()..color = accent.withValues(alpha: 0.80),
    );
    if (!isHome) {
      final glowRect = Rect.fromLTWH(
        rect.left + (rect.width * 0.58),
        rect.top + (rect.height * 0.08),
        rect.width * 0.42,
        rect.height * 0.34,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          glowRect,
          Radius.circular(radius * 0.7),
        ),
        Paint()
          ..shader = ui.Gradient.radial(
            glowRect.center,
            glowRect.longestSide * 0.7,
            [
              accent.withValues(alpha: isDarkMode ? 0.12 : 0.08),
              Colors.transparent,
            ],
          ),
      );
    }
  }

  static double _drawIdentityChips({
    required Canvas canvas,
    required double x,
    required double y,
    required double maxWidth,
    required double scale,
    required bool isDarkMode,
    required List<_IdentityItem> items,
  }) {
    if (items.isEmpty) return 0.0;

    final textColor = (isDarkMode ? AppTheme.lightSurface : AppTheme.lightText)
        .withValues(alpha: 0.92);
    final neutralBg = (isDarkMode ? Colors.white : Colors.black)
        .withValues(alpha: isDarkMode ? 0.06 : 0.05);
    final neutralBorder = (isDarkMode ? Colors.white : Colors.black)
        .withValues(alpha: isDarkMode ? 0.12 : 0.10);
    final gap = 8.0 * scale;
    final chipHeight = 28.0 * scale;
    final horizontalPad = 11.0 * scale;

    var currentX = x;
    var usedHeight = 0.0;

    for (final item in items.take(2)) {
      final accent = item.accent;
      final painter = _layoutText(
        item.label,
        TextStyle(
          color: textColor,
          fontSize: (11.0 * scale).clamp(8.0, 18.0),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        (maxWidth - (horizontalPad * 2)).clamp(24.0, maxWidth),
        maxLines: 1,
      );
      final chipWidth =
          (painter.width + (horizontalPad * 2)).clamp(0.0, maxWidth).toDouble();
      if (currentX + chipWidth > x + maxWidth && currentX > x) {
        painter.dispose();
        break;
      }

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(currentX, y, chipWidth, chipHeight),
        Radius.circular(chipHeight / 2),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = accent == null
              ? neutralBg
              : accent.withValues(alpha: isDarkMode ? 0.14 : 0.10),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (1.0 * scale).clamp(0.8, 1.6)
          ..color = accent == null
              ? neutralBorder
              : accent.withValues(alpha: isDarkMode ? 0.24 : 0.18),
      );
      painter.paint(
        canvas,
        Offset(
          currentX + horizontalPad,
          y + (chipHeight - painter.height) / 2,
        ),
      );
      usedHeight = chipHeight;
      currentX += chipWidth + gap;
      painter.dispose();
    }

    return usedHeight;
  }

  static TextPainter _iconPainter(
    IconData icon,
    double size,
    Color color,
  ) {
    return TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          inherit: false,
          color: color,
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
  }

  static String _resolvedLockPosterQuote(
    CachedContributionData data,
    WallpaperConfig config,
  ) {
    final direct = _resolvedQuote(data, config, WallpaperTarget.lock);
    if (direct.isNotEmpty) return direct;
    if (data.totalContributions <= 0) {
      return 'Start small. Make the first square count.';
    }
    if (data.currentStreak >= 30) {
      return 'Consistency leaves the strongest signature.';
    }
    if (data.currentStreak >= 7) {
      return 'The streak is proof that you kept showing up.';
    }
    if (data.todayCommits > 0) {
      return 'Today already moved the wall forward.';
    }
    if (data.peakDay >= 10) {
      return 'Your strongest days earn their place on the lock screen.';
    }
    return 'Quiet work still deserves a premium frame.';
  }

  static void _renderLockSnapshotCard({
    required Canvas canvas,
    required Size size,
    required CachedContributionData data,
    required WallpaperConfig config,
    required List<Color> themeLevels,
    required _CalendarWindow calendarWindow,
    required List<WallpaperCalendarCell> calendarCells,
    required int rows,
  }) {
    double fitWithin(double value, double minValue, double maxValue) {
      final resolvedMax = math.max(0.0, maxValue);
      if (resolvedMax <= minValue) return resolvedMax;
      return value.clamp(minValue, resolvedMax).toDouble();
    }

    final accent = themeLevels[themeLevels.length - 1];
    final secondary = themeLevels[themeLevels.length > 2 ? 2 : 1];
    final surfaceOpacity =
        (0.28 + (config.opacity * 0.72)).clamp(0.28, 1.0).toDouble();
    final padLeft = config.paddingLeft;
    final padRight = config.paddingRight;
    final padTop = config.paddingTop;
    final padBottom = config.paddingBottom;
    final availableWidth = size.width - padLeft - padRight;
    final availableHeight = size.height - padTop - padBottom;
    final textColor =
        config.isDarkMode ? AppTheme.lightSurface : AppTheme.lightText;
    final templateId = WallpaperTemplates.canonicalId(config.templateId);
    final showQuoteBand = config.customQuote.trim().isNotEmpty ||
        config.heroFocus == WallpaperHeroFocus.quote ||
        templateId == 'large_quote';
    final monthSummary =
        _buildMonthActivitySummary(data, calendarWindow.focusMonthStart);
    final focusMonthStart = calendarWindow.focusMonthStart;
    final monthTitle =
        _monthAccessibilityLabelFor(focusMonthStart).toUpperCase();
    final yearLabel = '${calendarWindow.focusMonthStart.year}';
    final identityLabel = data.username.trim().isEmpty
        ? 'GitWall'
        : _trimChipLabel(data.username);
    final syncLabel =
        'Updated ${PresentationFormatter.formatTimeAgoCompact(data.lastUpdated)}';
    final quote = _resolvedLockPosterQuote(data, config);
    final stats = _buildQuickStats(
      data,
      config,
      WallpaperTarget.lock,
      calendarWindow.focusMonthStart,
    );

    var scale = config.autoFitWidth
        ? (availableWidth / 390.0).clamp(0.88, 1.18).toDouble()
        : config.scale.clamp(0.55, 1.85).toDouble();
    double posterWidth = 0.0;
    double posterHeight = 0.0;
    double panelPadH = 0.0;
    double panelPadV = 0.0;
    double sectionGap = 0.0;
    double lockBadgeHeight = 0.0;
    double topMetaGap = 0.0;
    double weekdayHeaderHeight = 0.0;
    double cellGap = 0.0;
    double heatmapStagePad = 0.0;
    double boxSize = 0.0;
    double gridWidth = 0.0;
    double gridHeight = 0.0;
    double heatmapStageHeight = 0.0;
    double statsHeight = 0.0;
    double heatmapLabelHeight = 0.0;
    double quoteBandHeight = 0.0;
    double quoteBandPadH = 0.0;
    TextPainter? lockBadgePainter;
    TextPainter? heatmapHeadingPainter;
    TextPainter? heatmapSublinePainter;
    TextPainter? monthPainter;
    TextPainter? yearPainter;
    TextPainter? metaPainter;
    TextPainter? quotePainter;
    TextPainter? quoteMarkPainter;

    void disposePainters() {
      lockBadgePainter?.dispose();
      heatmapHeadingPainter?.dispose();
      heatmapSublinePainter?.dispose();
      monthPainter?.dispose();
      yearPainter?.dispose();
      metaPainter?.dispose();
      quotePainter?.dispose();
      quoteMarkPainter?.dispose();
      lockBadgePainter = null;
      heatmapHeadingPainter = null;
      heatmapSublinePainter = null;
      monthPainter = null;
      yearPainter = null;
      metaPainter = null;
      quotePainter = null;
      quoteMarkPainter = null;
    }

    for (int pass = 0; pass < 4; pass++) {
      disposePainters();
      posterWidth = fitWithin(availableWidth * 0.97, 356.0, availableWidth);
      panelPadH = 22.0 * scale;
      panelPadV = 24.0 * scale;
      sectionGap = 10.0 * scale;
      lockBadgeHeight = (24.0 * scale).clamp(20.0, 32.0).toDouble();
      topMetaGap = 8.0 * scale;
      weekdayHeaderHeight = (10.0 * scale).clamp(8.0, 15.0).toDouble();
      cellGap = (4.5 * scale).clamp(3.0, 7.0).toDouble();
      heatmapStagePad = 14.0 * scale;
      quoteBandPadH = 16.0 * scale;

      final contentWidth = posterWidth - (panelPadH * 2);
      final heatmapInnerWidth = contentWidth - (heatmapStagePad * 2);

      lockBadgePainter = _layoutText(
        'MONTHLY SNAPSHOT',
        TextStyle(
          color: textColor.withValues(alpha: 0.86),
          fontSize: (10.0 * scale).clamp(8.0, 15.0),
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
        contentWidth * 0.42,
        maxLines: 1,
      );
      monthPainter = _layoutText(
        monthTitle,
        TextStyle(
          color: textColor,
          fontSize: (36.0 * scale).clamp(24.0, 56.0),
          fontWeight: FontWeight.w900,
          height: 0.96,
          letterSpacing: 1.5,
        ),
        contentWidth * 0.76,
        maxLines: 1,
      );
      yearPainter = _layoutText(
        yearLabel,
        TextStyle(
          color: Color.lerp(textColor, accent, 0.55)!.withValues(alpha: 0.88),
          fontSize: (12.0 * scale).clamp(9.0, 18.0),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
        contentWidth * 0.22,
        textAlign: TextAlign.right,
        maxLines: 1,
      );
      metaPainter = _layoutText(
        '@$identityLabel  •  $syncLabel',
        TextStyle(
          color: textColor.withValues(alpha: 0.68),
          fontSize: (10.5 * scale).clamp(8.5, 15.0),
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        contentWidth,
        maxLines: 1,
      );
      statsHeight = config.showQuickStatsBar && stats.isNotEmpty
          ? (_statsBarHeightBase(stats.length) * scale * 1.12)
              .clamp(28.0, 68.0)
              .toDouble()
          : 0.0;
      boxSize = ((heatmapInnerWidth - (6 * cellGap)) / 7)
          .clamp(20.0, 46.0)
          .toDouble();
      gridWidth = (7 * (boxSize + cellGap)) - cellGap;
      gridHeight = (rows * (boxSize + cellGap)) - cellGap;
      heatmapHeadingPainter = _layoutText(
        '$monthTitle ACTIVITY',
        TextStyle(
          color: textColor.withValues(alpha: 0.84),
          fontSize: (10.5 * scale).clamp(8.0, 15.0),
          fontWeight: FontWeight.w900,
          letterSpacing: 0.7,
        ),
        contentWidth * 0.56,
        maxLines: 1,
      );
      heatmapSublinePainter = _layoutText(
        '${monthSummary.stats.totalContributions} commits this month',
        TextStyle(
          color: textColor.withValues(alpha: 0.58),
          fontSize: (9.5 * scale).clamp(7.5, 13.0),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        contentWidth * 0.38,
        textAlign: TextAlign.right,
        maxLines: 1,
      );
      heatmapLabelHeight = math.max(
        heatmapHeadingPainter!.height,
        heatmapSublinePainter!.height,
      );
      heatmapStageHeight = (heatmapStagePad * 2) +
          heatmapLabelHeight +
          (12.0 * scale) +
          weekdayHeaderHeight +
          (10.0 * scale) +
          gridHeight;
      if (showQuoteBand) {
        quotePainter = _layoutText(
          quote,
          TextStyle(
            color: textColor.withValues(
              alpha: (config.quoteOpacity * 0.92).clamp(0.0, 1.0),
            ),
            fontSize: ((config.quoteFontSize * scale) *
                    _quoteFontMultiplier(
                      config.densityMode,
                      WallpaperHeroFocus.quote,
                    ))
                .clamp(11.0, 22.0),
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
            height: 1.22,
            letterSpacing: -0.08,
          ),
          fitWithin(contentWidth - (quoteBandPadH * 2), 60.0, contentWidth),
          textAlign: TextAlign.left,
          maxLines: 2,
        );
        quoteMarkPainter = _layoutText(
          '“',
          TextStyle(
            color: accent.withValues(alpha: config.isDarkMode ? 0.18 : 0.12),
            fontSize: (36.0 * scale).clamp(24.0, 54.0),
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
          contentWidth,
          textAlign: TextAlign.left,
          maxLines: 1,
        );
        quoteBandHeight = math.max(
          (60.0 * scale).clamp(52.0, 88.0),
          quotePainter!.height + (24.0 * scale),
        );
      } else {
        quotePainter = null;
        quoteMarkPainter = null;
        quoteBandHeight = 0.0;
      }

      posterHeight = (panelPadV * 2) +
          lockBadgeHeight +
          topMetaGap +
          monthPainter!.height +
          (8.0 * scale) +
          metaPainter!.height +
          sectionGap +
          statsHeight +
          (statsHeight > 0 ? sectionGap : 0.0) +
          heatmapStageHeight +
          (showQuoteBand ? sectionGap + quoteBandHeight : 0.0);

      final maxAllowedHeight = availableHeight * 0.90;
      if (posterHeight <= maxAllowedHeight || pass == 3) {
        break;
      }
      scale *= (maxAllowedHeight / posterHeight).clamp(0.82, 0.96);
    }

    final maxPosterX = math.max(padLeft, size.width - padRight - posterWidth);
    final posterX =
        (padLeft + ((availableWidth - posterWidth) * config.horizontalPosition))
            .clamp(padLeft, maxPosterX);
    final maxPosterY = math.max(padTop, size.height - padBottom - posterHeight);
    final posterY =
        (padTop + ((availableHeight - posterHeight) * config.verticalPosition))
            .clamp(
      padTop,
      maxPosterY,
    );
    final posterRect =
        Rect.fromLTWH(posterX, posterY, posterWidth, posterHeight);

    _drawPosterPanel(
      canvas: canvas,
      rect: posterRect,
      radius: (16.0 * scale) + (config.cornerRadius * scale * 2.6),
      config: config,
      isDarkMode: config.isDarkMode,
      isHome: false,
      isFullWidth: false,
      accent: accent,
    );

    final contentX = posterRect.left + panelPadH;
    final contentWidth = posterRect.width - (panelPadH * 2);
    var currentY = posterRect.top + panelPadV;

    final lockBadgeWidth = fitWithin(
      lockBadgePainter!.width + (36.0 * scale),
      90.0,
      contentWidth * 0.5,
    );
    final badgeRect = Rect.fromLTWH(
      contentX,
      currentY,
      lockBadgeWidth,
      lockBadgeHeight,
    );
    final badgeRRect = RRect.fromRectAndRadius(
      badgeRect,
      Radius.circular(lockBadgeHeight / 2),
    );
    canvas.drawRRect(
      badgeRRect,
      Paint()
        ..shader = ui.Gradient.linear(
          badgeRect.topLeft,
          badgeRect.bottomRight,
          [
            accent.withValues(alpha: config.isDarkMode ? 0.16 : 0.12),
            secondary.withValues(alpha: config.isDarkMode ? 0.12 : 0.08),
          ],
        ),
    );
    canvas.drawRRect(
      badgeRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1.2 * scale).clamp(0.9, 1.8)
        ..color = accent.withValues(alpha: config.isDarkMode ? 0.26 : 0.18),
    );
    final badgeIcon = _iconPainter(
      Icons.lock_outline_rounded,
      (13.0 * scale).clamp(11.0, 18.0).toDouble(),
      accent.withValues(alpha: 0.96),
    );
    badgeIcon.paint(
      canvas,
      Offset(
        badgeRect.left + (14.0 * scale),
        badgeRect.top + (badgeRect.height - badgeIcon.height) / 2,
      ),
    );
    lockBadgePainter!.paint(
      canvas,
      Offset(
        badgeRect.left + (14.0 * scale) + badgeIcon.width + (8.0 * scale),
        badgeRect.top + (badgeRect.height - lockBadgePainter!.height) / 2,
      ),
    );
    badgeIcon.dispose();
    currentY += lockBadgeHeight + topMetaGap;

    monthPainter!.paint(canvas, Offset(contentX, currentY));
    yearPainter!.paint(
      canvas,
      Offset(
        contentX + contentWidth - yearPainter!.width,
        currentY + (monthPainter!.height * 0.22),
      ),
    );
    currentY += monthPainter!.height + (8.0 * scale);

    metaPainter!.paint(canvas, Offset(contentX, currentY));
    currentY += metaPainter!.height + (10.0 * scale);

    canvas.drawLine(
      Offset(contentX, currentY),
      Offset(contentX + (contentWidth * 0.18), currentY),
      Paint()
        ..strokeWidth = (2.0 * scale).clamp(1.2, 3.0)
        ..strokeCap = StrokeCap.round
        ..color = accent.withValues(alpha: 0.9),
    );
    currentY += 4.0 * scale;

    if (config.showQuickStatsBar && stats.isNotEmpty) {
      _drawQuickStatsBar(
        canvas: canvas,
        x: contentX,
        y: currentY,
        width: contentWidth,
        scale: scale,
        config: config.copyWith(heroFocus: WallpaperHeroFocus.stats),
        items: stats,
        accent: accent,
      );
      currentY += statsHeight + sectionGap;
    }

    final heatmapRect =
        Rect.fromLTWH(contentX, currentY, contentWidth, heatmapStageHeight);
    final heatmapRadius = (28.0 * scale) + (config.cornerRadius * scale * 0.85);
    final heatmapRRect = RRect.fromRectAndRadius(
      heatmapRect,
      Radius.circular(heatmapRadius),
    );
    canvas.drawRRect(
      heatmapRRect,
      Paint()
        ..shader = ui.Gradient.linear(
          heatmapRect.topLeft,
          heatmapRect.bottomRight,
          [
            config.isDarkMode
                ? const Color(0xFF0E1419)
                    .withValues(alpha: 0.92 * surfaceOpacity)
                : Colors.white.withValues(alpha: 0.86 * surfaceOpacity),
            config.isDarkMode
                ? const Color(0xFF131C22)
                    .withValues(alpha: 0.96 * surfaceOpacity)
                : const Color(0xFFF5F7FB)
                    .withValues(alpha: 0.92 * surfaceOpacity),
            accent.withValues(
              alpha: (config.isDarkMode ? 0.09 : 0.05) * surfaceOpacity,
            ),
          ],
          const [0.0, 0.72, 1.0],
        ),
    );
    canvas.drawRRect(
      heatmapRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1.2 * scale).clamp(0.9, 1.8)
        ..color = accent.withValues(
          alpha: (config.isDarkMode ? 0.14 : 0.10) * surfaceOpacity,
        ),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          heatmapRect.left + 1,
          heatmapRect.top + 1,
          heatmapRect.width - 2,
          heatmapRect.height * 0.34,
        ),
        Radius.circular(math.max(4.0, heatmapRadius - (2.0 * scale))),
      ),
      Paint()
        ..shader = ui.Gradient.linear(
          heatmapRect.topLeft,
          Offset(heatmapRect.left, heatmapRect.top + heatmapRect.height * 0.34),
          [
            Colors.white.withValues(
              alpha: (config.isDarkMode ? 0.08 : 0.22) * surfaceOpacity,
            ),
            Colors.transparent,
          ],
        ),
    );

    heatmapHeadingPainter!.paint(
      canvas,
      Offset(
        heatmapRect.left + heatmapStagePad,
        heatmapRect.top + heatmapStagePad,
      ),
    );
    heatmapSublinePainter!.paint(
      canvas,
      Offset(
        heatmapRect.right - heatmapStagePad - heatmapSublinePainter!.width,
        heatmapRect.top + heatmapStagePad,
      ),
    );

    final gridStartX = heatmapRect.left + ((heatmapRect.width - gridWidth) / 2);
    var gridStartY =
        heatmapRect.top + heatmapStagePad + heatmapLabelHeight + (12.0 * scale);
    final weekdayStyle = TextStyle(
      color: textColor.withValues(alpha: 0.56),
      fontSize: weekdayHeaderHeight.clamp(8.0, 16.0),
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
    );
    final weekdayCache = <String, TextPainter>{};
    for (int column = 0; column < 7; column++) {
      final label = _weekdayLabels[column];
      final painter = weekdayCache.putIfAbsent(
        label,
        () => _layoutText(
          label,
          weekdayStyle,
          boxSize * 1.2,
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      );
      final left = gridStartX + (column * (boxSize + cellGap));
      painter.paint(
        canvas,
        Offset(left + (boxSize - painter.width) / 2, gridStartY),
      );
    }
    gridStartY += weekdayHeaderHeight + (10.0 * scale);

    final emptyCellColor =
        config.isDarkMode ? const Color(0xFF2A333C) : const Color(0xFFF0F3F6);
    final overflowCellColor =
        config.isDarkMode ? const Color(0xFF1A2026) : const Color(0xFFF8FAFC);
    final outlineColor = (config.isDarkMode ? Colors.white : Colors.black)
        .withValues(alpha: config.isDarkMode ? 0.14 : 0.10);
    final cellRadiusValue = ((2.5 + (config.cornerRadius * 1.7)) * scale).clamp(
      2.0,
      boxSize * 0.42,
    );
    final cellRadius = Radius.circular(cellRadiusValue.toDouble());
    final cellPaint = Paint()..style = PaintingStyle.fill;
    final cellBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (1.1 * scale).clamp(0.9, 1.6)
      ..color = outlineColor;
    final todayBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (2.0 * scale).clamp(1.2, 2.2)
      ..color = AppTheme.warningOrange;
    final dateTextCache = <int, TextPainter>{};
    final countTextCache = <int, TextPainter>{};
    final monthTextCache = <String, TextPainter>{};

    for (int index = 0; index < calendarCells.length; index++) {
      final cell = calendarCells[index];
      final left = gridStartX + ((index % 7) * (boxSize + cellGap));
      final top = gridStartY + ((index ~/ 7) * (boxSize + cellGap));
      final rect = Rect.fromLTWH(left, top, boxSize, boxSize);
      final rrect = RRect.fromRectAndRadius(rect, cellRadius);
      final isOverflowCell = !cell.isInFocusMonth;
      if (isOverflowCell) {
        cellPaint.color = overflowCellColor.withValues(
          alpha: (config.isDarkMode ? 0.22 : 0.45) * config.opacity,
        );
      } else if (cell.contributionCount <= 0) {
        cellPaint.color = emptyCellColor.withValues(
          alpha: (config.isDarkMode ? 0.65 : 0.88) * config.opacity,
        );
      } else {
        final level = RenderUtils.getContributionLevel(
          cell.contributionCount,
          quartiles: data.quartiles,
        );
        final color = themeLevels[level.clamp(0, themeLevels.length - 1)];
        cellPaint.color = Color.lerp(
          color,
          config.isDarkMode ? Colors.white : Colors.black,
          config.isDarkMode ? 0.04 : 0.02,
        )!
            .withValues(
          alpha: (0.24 + (config.opacity * 0.75)).clamp(0.24, 0.99),
        );
      }
      canvas.drawRRect(rrect, cellPaint);
      canvas.drawRRect(rrect, cellBorder);
      if (cell.isToday) {
        canvas.drawRRect(rrect, todayBorder);
      }

      if (isOverflowCell) {
        continue;
      }

      final displayColor = cellPaint.color;
      final isLightCell = displayColor.computeLuminance() > 0.56;
      final primaryTextColor = isLightCell
          ? Colors.black.withValues(alpha: 0.88)
          : Colors.white.withValues(alpha: 0.94);
      final secondaryTextColor = isLightCell
          ? Colors.black.withValues(alpha: 0.68)
          : Colors.white.withValues(alpha: 0.76);
      final dateColor = !cell.isInFocusMonth
          ? primaryTextColor.withValues(alpha: 0.42)
          : cell.contributionCount > 0
              ? primaryTextColor
              : primaryTextColor.withValues(alpha: 0.76);
      final dateFontSize = (boxSize * 0.29).clamp(10.0, 24.0);
      final dateCacheKey = (cell.date.day << 3) |
          (isLightCell ? 4 : 0) |
          (cell.isInFocusMonth ? 2 : 0) |
          (cell.contributionCount > 0 ? 1 : 0);
      final datePainter = dateTextCache.putIfAbsent(
        dateCacheKey,
        () => _layoutText(
          '${cell.date.day}',
          TextStyle(
            color: dateColor,
            fontSize: dateFontSize,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
          boxSize * 0.54,
          maxLines: 1,
        ),
      );
      final showMonthLabel =
          cell.isInFocusMonth && cell.startsNewMonth && boxSize >= 31.0;

      if (showMonthLabel) {
        final monthPainter = monthTextCache.putIfAbsent(
          '${cell.shortMonthLabel}-${isLightCell ? 1 : 0}-${cell.isInFocusMonth ? 1 : 0}',
          () => _layoutText(
            cell.shortMonthLabel,
            TextStyle(
              color: secondaryTextColor.withValues(
                alpha: cell.isInFocusMonth ? 0.72 : 0.48,
              ),
              fontSize: (boxSize * 0.12).clamp(7.0, 11.0),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
            boxSize * 0.42,
            maxLines: 1,
          ),
        );
        monthPainter.paint(
          canvas,
          Offset(
            left + boxSize - monthPainter.width - (boxSize * 0.10),
            top + (boxSize * 0.12),
          ),
        );
      }

      datePainter.paint(
        canvas,
        Offset(
          left + (boxSize * 0.14),
          top + (boxSize * 0.12),
        ),
      );

      if (cell.contributionCount > 0 && cell.isInFocusMonth) {
        if (boxSize >= 29.0) {
          final countCacheKey =
              (cell.contributionCount << 1) | (isLightCell ? 1 : 0);
          final countPainter = countTextCache.putIfAbsent(
            countCacheKey,
            () => _layoutText(
              '${cell.contributionCount}',
              TextStyle(
                color: secondaryTextColor,
                fontSize: (boxSize * 0.17).clamp(8.0, 14.0),
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
              boxSize * 0.44,
              maxLines: 1,
            ),
          );
          countPainter.paint(
            canvas,
            Offset(
              left + boxSize - countPainter.width - (boxSize * 0.12),
              top + boxSize - countPainter.height - (boxSize * 0.12),
            ),
          );
        } else {
          canvas.drawCircle(
            Offset(
              left + boxSize - (boxSize * 0.18),
              top + boxSize - (boxSize * 0.18),
            ),
            (boxSize * 0.06).clamp(1.8, 3.8),
            Paint()..color = secondaryTextColor,
          );
        }
      }
    }

    for (final painter in weekdayCache.values) {
      painter.dispose();
    }
    for (final painter in dateTextCache.values) {
      painter.dispose();
    }
    for (final painter in countTextCache.values) {
      painter.dispose();
    }
    for (final painter in monthTextCache.values) {
      painter.dispose();
    }

    if (showQuoteBand && quotePainter != null && quoteMarkPainter != null) {
      final resolvedQuotePainter = quotePainter!;
      final resolvedQuoteMarkPainter = quoteMarkPainter!;
      currentY += heatmapStageHeight + sectionGap;
      final quoteRect = Rect.fromLTWH(
        contentX,
        currentY,
        contentWidth,
        quoteBandHeight,
      );
      final quoteRadius = (22.0 * scale) + (config.cornerRadius * scale * 0.75);
      final quoteRRect = RRect.fromRectAndRadius(
        quoteRect,
        Radius.circular(quoteRadius),
      );
      canvas.drawRRect(
        quoteRRect,
        Paint()
          ..shader = ui.Gradient.linear(
            quoteRect.topLeft,
            quoteRect.bottomRight,
            [
              accent.withValues(
                alpha: (config.isDarkMode ? 0.08 : 0.05) * surfaceOpacity,
              ),
              config.isDarkMode
                  ? const Color(0xFF11171B)
                      .withValues(alpha: 0.84 * surfaceOpacity)
                  : Colors.white.withValues(alpha: 0.76 * surfaceOpacity),
            ],
            const [0.0, 1.0],
          ),
      );
      canvas.drawRRect(
        quoteRRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (1.0 * scale).clamp(0.9, 1.5)
          ..color = accent.withValues(
            alpha: (config.isDarkMode ? 0.10 : 0.08) * surfaceOpacity,
          ),
      );
      resolvedQuotePainter.paint(
        canvas,
        Offset(
          quoteRect.left + quoteBandPadH,
          quoteRect.top + (quoteRect.height - resolvedQuotePainter.height) / 2,
        ),
      );
      resolvedQuoteMarkPainter.paint(
        canvas,
        Offset(
          quoteRect.left + quoteBandPadH - (2.0 * scale),
          quoteRect.top + (10.0 * scale),
        ),
      );
    }

    disposePainters();
  }

  static void render({
    required Canvas canvas,
    required Size size,
    required CachedContributionData data,
    required WallpaperConfig config,
    WallpaperTarget target = WallpaperTarget.lock,
    DateTime? referenceDate,
    DateTime? todayUtc,
    bool showLegend = false,
  }) {
    final themeExt = config.isDarkMode ? _dT : _lT;
    final themeLevels =
        ThemePresets.levelsFor(config.themeId, isDarkMode: config.isDarkMode);
    final now = (todayUtc ?? referenceDate ?? DateTime.now().toUtc()).toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final calendarWindow = _calendarWindowFor(today, target);
    final displayDates = calendarWindow.dates;
    final calendarCells = buildCalendarCells(
      data: data,
      todayUtc: today,
      target: target,
    );
    final rows = (displayDates.length / 7).ceil();
    final isHome = target == WallpaperTarget.home;
    final accent = themeLevels[themeLevels.length - 1];

    _drawAtmosphere(
      canvas: canvas,
      size: size,
      target: target,
      config: config,
      themeLevels: themeLevels,
    );

    if (!isHome) {
      _renderLockSnapshotCard(
        canvas: canvas,
        size: size,
        data: data,
        config: config,
        themeLevels: themeLevels,
        calendarWindow: calendarWindow,
        calendarCells: calendarCells,
        rows: rows,
      );
      return;
    }

    final isFullWidthLockLayout = !isHome;
    final templateId = WallpaperTemplates.canonicalId(config.templateId);
    final isQuoteHero = config.heroFocus == WallpaperHeroFocus.quote ||
        templateId == 'large_quote';
    final isGridFirstLayout =
        config.heroFocus == WallpaperHeroFocus.grid && !isQuoteHero;
    final isMinimalLockPoster = isFullWidthLockLayout && isGridFirstLayout;
    final identityBeforeGrid = isFullWidthLockLayout;
    final statsBeforeGrid = isFullWidthLockLayout;

    final padLeft = config.paddingLeft;
    final padRight = config.paddingRight;
    final padTop = config.paddingTop;
    final padBottom = config.paddingBottom;
    final availableWidth = size.width - padLeft - padRight;
    final availableHeight = size.height - padTop - padBottom;

    final stats = _buildQuickStats(data, config, target, today);
    final identityItems = _buildIdentityItems(data, config, target);
    final quote = _resolvedQuote(data, config, target);
    final headline = _buildHeadline(
      data: data,
      config: config,
      target: target,
      todayUtc: today,
      calendarWindow: calendarWindow,
    );

    const baseBoxSize = AppConstants.heatmapBoxSize;
    const baseSpacing = AppConstants.heatmapBoxSpacing;
    final baseGridWidth = (7 * (baseBoxSize + baseSpacing)) - baseSpacing;
    final desiredGridWidth = (availableWidth *
            (isHome ? 0.58 : 0.82) *
            config.densityMode.scaleMultiplier *
            _focusScaleMultiplier(config.heroFocus))
        .clamp(220.0, isHome ? 420.0 : availableWidth - 32)
        .toDouble();
    var scale = config.autoFitWidth
        ? (desiredGridWidth / baseGridWidth).clamp(0.72, 2.2).toDouble()
        : config.scale.clamp(0.55, 2.8).toDouble();

    TextPainter? eyebrowPainter;
    TextPainter? titlePainter;
    TextPainter? subtitlePainter;
    TextPainter? quotePainter;
    double boxSize = 0.0;
    double spacing = 0.0;
    double gridWidth = 0.0;
    double gridHeight = 0.0;
    double panelPadH = 0.0;
    double panelPadV = 0.0;
    double panelWidth = 0.0;
    double panelHeight = 0.0;
    double statsHeight = 0.0;
    double identityHeight = 0.0;
    double weekdayHeaderHeight = 0.0;
    double legendHeight = showLegend ? 16.0 : 0.0;

    void disposeTextPainters() {
      eyebrowPainter?.dispose();
      titlePainter?.dispose();
      subtitlePainter?.dispose();
      quotePainter?.dispose();
      eyebrowPainter = null;
      titlePainter = null;
      subtitlePainter = null;
      quotePainter = null;
    }

    for (int pass = 0; pass < 3; pass++) {
      disposeTextPainters();
      boxSize = baseBoxSize * scale;
      spacing = baseSpacing * scale;
      gridWidth = (7 * (boxSize + spacing)) - spacing;
      gridHeight = (rows * (boxSize + spacing)) - spacing;
      panelPadH = (isMinimalLockPoster ? 20.0 : 18.0) * scale;
      panelPadV = (isMinimalLockPoster ? 24.0 : (isHome ? 18.0 : 20.0)) * scale;
      if (isFullWidthLockLayout) {
        panelWidth = availableWidth;
        gridWidth = panelWidth - (panelPadH * 2);
        boxSize = ((gridWidth - (6 * spacing)) / 7).clamp(18.0, 220.0);
        gridWidth = (7 * (boxSize + spacing)) - spacing;
        gridHeight = (rows * (boxSize + spacing)) - spacing;
      }
      weekdayHeaderHeight =
          (isHome ? 11.0 * scale : 13.0 * scale).clamp(10.0, 22.0).toDouble();
      final contentWidth =
          isFullWidthLockLayout ? availableWidth - (panelPadH * 2) : gridWidth;
      final textColor =
          config.isDarkMode ? AppTheme.lightSurface : AppTheme.lightText;
      final eyebrowColor =
          Color.lerp(textColor, accent, 0.60)!.withValues(alpha: 0.88);
      final subtitleColor = textColor.withValues(alpha: 0.66);
      final quoteColor = textColor.withValues(
          alpha: (config.quoteOpacity * 0.94).clamp(0.0, 1.0));

      if (headline.eyebrow.isNotEmpty) {
        eyebrowPainter = _layoutText(
          headline.eyebrow,
          TextStyle(
            color: eyebrowColor,
            fontSize: (10.0 * scale).clamp(8.0, 16.0),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
          ),
          contentWidth,
          maxLines: 1,
        );
      }
      if ((headline.title ?? '').isNotEmpty) {
        titlePainter = _layoutText(
          headline.title!,
          TextStyle(
            color: textColor.withValues(alpha: 0.97),
            fontSize: ((isHome ? 20.0 : 28.0) * scale)
                .clamp(isHome ? 14.0 : 16.0, isHome ? 30.0 : 42.0),
            fontWeight: FontWeight.w900,
            height: 1.0,
            letterSpacing: -0.6,
          ),
          contentWidth,
          maxLines: 2,
        );
      }
      if ((headline.subtitle ?? '').isNotEmpty) {
        subtitlePainter = _layoutText(
          headline.subtitle!,
          TextStyle(
            color: subtitleColor,
            fontSize: (10.5 * scale).clamp(8.0, 16.0),
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
          contentWidth,
          maxLines: 2,
        );
      }
      if (quote.isNotEmpty) {
        quotePainter = _layoutText(
          quote,
          TextStyle(
            color: quoteColor,
            fontSize: (config.quoteFontSize *
                    scale *
                    _quoteFontMultiplier(config.densityMode, config.heroFocus))
                .clamp(10.0, isQuoteHero ? 34.0 : 24.0),
            fontWeight: isQuoteHero ? FontWeight.w700 : FontWeight.w600,
            fontStyle: isQuoteHero ? FontStyle.normal : FontStyle.italic,
            height: isQuoteHero ? 1.18 : 1.26,
            letterSpacing: isQuoteHero ? -0.2 : 0.0,
          ),
          contentWidth * (isQuoteHero ? 0.98 : 0.92),
          textAlign: TextAlign.center,
          maxLines: isQuoteHero ? (isHome ? 3 : 4) : (isHome ? 2 : 3),
        );
      }

      identityHeight = identityItems.isEmpty ? 0.0 : 28.0 * scale;
      statsHeight = config.showQuickStatsBar && stats.isNotEmpty
          ? (_statsBarHeightBase(stats.length) *
                  scale *
                  _statsBarMultiplier(config.densityMode, config.heroFocus))
              .clamp(24.0, 72.0)
          : 0.0;
      legendHeight = showLegend ? 14.0 * scale : 0.0;

      final sectionGap = (isMinimalLockPoster ? 10.0 : 12.0) * scale;
      final largeGap = (isMinimalLockPoster ? 18.0 : 16.0) * scale;
      double contentHeight = 0.0;

      if (eyebrowPainter != null) contentHeight += eyebrowPainter!.height;
      if (titlePainter != null) {
        if (contentHeight > 0) contentHeight += 6.0 * scale;
        contentHeight += titlePainter!.height;
      }
      if (subtitlePainter != null) {
        if (contentHeight > 0) contentHeight += 8.0 * scale;
        contentHeight += subtitlePainter!.height;
      }
      if (quotePainter != null && isQuoteHero) {
        if (contentHeight > 0) contentHeight += largeGap;
        contentHeight += quotePainter!.height;
      }
      if (identityHeight > 0 && identityBeforeGrid) {
        if (contentHeight > 0) contentHeight += sectionGap;
        contentHeight += identityHeight;
      }
      if (statsHeight > 0 && statsBeforeGrid) {
        if (contentHeight > 0) contentHeight += sectionGap;
        contentHeight += statsHeight;
      }
      if (contentHeight > 0) contentHeight += largeGap;
      contentHeight += weekdayHeaderHeight + (6.0 * scale) + gridHeight;
      if (quotePainter != null && !isQuoteHero) {
        contentHeight += sectionGap + quotePainter!.height;
      }
      if (identityHeight > 0 && !identityBeforeGrid) {
        contentHeight += sectionGap + identityHeight;
      }
      if (statsHeight > 0 && !statsBeforeGrid) {
        contentHeight += sectionGap + statsHeight;
      }
      if (legendHeight > 0) {
        contentHeight += sectionGap + legendHeight;
      }

      panelWidth =
          isFullWidthLockLayout ? availableWidth : gridWidth + (panelPadH * 2);
      panelHeight = contentHeight + (panelPadV * 2);

      final maxAllowedHeight = availableHeight *
          (isHome ? 0.64 : (isMinimalLockPoster ? 0.76 : 0.70));
      if (panelHeight <= maxAllowedHeight || pass == 2) break;
      scale *= (maxAllowedHeight / panelHeight).clamp(0.7, 0.98);
    }

    final xAlignment = isHome
        ? (0.08 + (config.horizontalPosition * 0.24)).clamp(0.04, 0.32)
        : 0.0;
    final yAlignment = isHome
        ? (0.18 + ((config.verticalPosition - 0.5) * 0.14)).clamp(0.10, 0.28)
        : (0.34 + ((config.verticalPosition - 0.5) * 0.20)).clamp(0.20, 0.54);

    final panelX = isFullWidthLockLayout
        ? padLeft
        : (padLeft + ((availableWidth - panelWidth) * xAlignment)).clamp(
            padLeft,
            size.width - padRight - panelWidth < padLeft
                ? padLeft
                : size.width - padRight - panelWidth,
          );
    final panelY =
        (padTop + ((availableHeight - panelHeight) * yAlignment)).clamp(
      padTop,
      size.height - padBottom - panelHeight < padTop
          ? padTop
          : size.height - padBottom - panelHeight,
    );
    final panelRect = Rect.fromLTWH(panelX, panelY, panelWidth, panelHeight);
    _drawPosterPanel(
      canvas: canvas,
      rect: panelRect,
      radius: (isHome ? 28.0 : 32.0) * scale,
      config: config,
      isDarkMode: config.isDarkMode,
      isHome: isHome,
      isFullWidth: isFullWidthLockLayout,
      accent: accent,
    );

    final contentX = panelX + panelPadH;
    var currentY = panelY + panelPadV;
    final contentWidth = panelWidth - (panelPadH * 2);

    if (eyebrowPainter != null) {
      eyebrowPainter!.paint(canvas, Offset(contentX, currentY));
      currentY += eyebrowPainter!.height;
    }
    if (titlePainter != null) {
      if (eyebrowPainter != null) currentY += 6.0 * scale;
      titlePainter!.paint(canvas, Offset(contentX, currentY));
      currentY += titlePainter!.height;
    }
    if (subtitlePainter != null) {
      if (eyebrowPainter != null || titlePainter != null) {
        currentY += 8.0 * scale;
      }
      subtitlePainter!.paint(canvas, Offset(contentX, currentY));
      currentY += subtitlePainter!.height;
    }
    if (quotePainter != null && isQuoteHero) {
      currentY += 16.0 * scale;
      quotePainter!.paint(
        canvas,
        Offset(contentX + (contentWidth - quotePainter!.width) / 2, currentY),
      );
      currentY += quotePainter!.height;
    }

    if (identityItems.isNotEmpty && identityBeforeGrid) {
      currentY += 12.0 * scale;
      currentY += _drawIdentityChips(
        canvas: canvas,
        x: contentX,
        y: currentY,
        maxWidth: contentWidth,
        scale: scale,
        isDarkMode: config.isDarkMode,
        items: identityItems,
      );
    }

    if (config.showQuickStatsBar && stats.isNotEmpty && statsBeforeGrid) {
      currentY += 12.0 * scale;
      _drawQuickStatsBar(
        canvas: canvas,
        x: contentX,
        y: currentY,
        width: contentWidth,
        scale: scale,
        config: config,
        items: stats,
        accent: accent,
      );
      currentY += statsHeight;
    }

    currentY += 16.0 * scale;
    final gridY = currentY;
    final weekdayStyle = TextStyle(
      color: (config.isDarkMode ? AppTheme.lightSurface : AppTheme.lightText)
          .withValues(alpha: 0.56),
      fontSize: weekdayHeaderHeight.clamp(10.0, 20.0),
      fontWeight: FontWeight.w800,
      letterSpacing: 0.7,
    );
    final weekdayCache = <String, TextPainter>{};
    for (int column = 0; column < 7; column++) {
      final label = calendarCells[column].weekdayLabel;
      final painter = weekdayCache.putIfAbsent(
        label,
        () => _layoutText(label, weekdayStyle, boxSize,
            textAlign: TextAlign.center, maxLines: 1),
      );
      final left = contentX + (column * (boxSize + spacing));
      painter.paint(
        canvas,
        Offset(
          left + (boxSize - painter.width) / 2,
          gridY,
        ),
      );
    }

    final calendarGridY = gridY + weekdayHeaderHeight + (6.0 * scale);
    final gridAlpha = (config.opacity *
            (isQuoteHero ? (isHome ? 0.68 : 0.76) : (isHome ? 0.94 : 1.0)))
        .clamp(0.35, 1.0)
        .toDouble();
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final todayBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (spacing / 1.5).clamp(1.0, boxSize * 0.18)
      ..color = themeExt.heatmapHighlight;
    final cellRadius = Radius.circular(
      config.cornerRadius * scale + (isHome ? 1.0 : 2.0),
    );
    final dateTextCache = <int, TextPainter>{};
    final countTextCache = <int, TextPainter>{};
    final monthTextCache = <String, TextPainter>{};
    final emptyCellColor = (config.isDarkMode ? Colors.white : Colors.black)
        .withValues(alpha: config.isDarkMode ? 0.08 : 0.06);
    final overflowCellColor = (config.isDarkMode ? Colors.white : Colors.black)
        .withValues(alpha: config.isDarkMode ? 0.04 : 0.035);

    for (int index = 0; index < calendarCells.length; index++) {
      final cell = calendarCells[index];
      final level = RenderUtils.getContributionLevel(
        cell.contributionCount,
        quartiles: data.quartiles,
      );
      final color =
          themeLevels.length > level ? themeLevels[level] : themeLevels[0];
      final isOverflowCell = !cell.isInFocusMonth && !isHome;
      final displayColor = isOverflowCell
          ? overflowCellColor
          : cell.contributionCount <= 0
              ? (isHome ? color.withValues(alpha: gridAlpha) : emptyCellColor)
              : color.withValues(alpha: gridAlpha);
      fillPaint.color = displayColor;

      final left = contentX + ((index % 7) * (boxSize + spacing));
      final top = calendarGridY + ((index ~/ 7) * (boxSize + spacing));
      final cellRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, boxSize, boxSize),
        cellRadius,
      );
      canvas.drawRRect(cellRect, fillPaint);

      if (cell.isToday) {
        canvas.drawRRect(cellRect, todayBorderPaint);
      }

      final luminance = displayColor.computeLuminance();
      final isLightCell = luminance > 0.55;
      final primaryTextColor = isLightCell
          ? Colors.black.withValues(alpha: 0.86)
          : Colors.white.withValues(alpha: 0.92);
      final secondaryTextColor = isLightCell
          ? Colors.black.withValues(alpha: 0.66)
          : Colors.white.withValues(alpha: 0.72);
      final quietDateColor = cell.contributionCount == 0
          ? primaryTextColor.withValues(alpha: isGridFirstLayout ? 0.62 : 0.70)
          : primaryTextColor;

      final dateFontSize =
          (boxSize * (isGridFirstLayout ? 0.27 : 0.24)).clamp(9.0, 26.0);
      final dateCacheKey = (cell.date.day << 3) |
          (isLightCell ? 4 : 0) |
          (cell.contributionCount > 0 ? 2 : 0) |
          (isGridFirstLayout ? 1 : 0);
      final datePainter = dateTextCache.putIfAbsent(
        dateCacheKey,
        () => _layoutText(
          '${cell.date.day}',
          TextStyle(
            color: quietDateColor,
            fontSize: dateFontSize,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
          boxSize * 0.5,
          maxLines: 1,
        ),
      );
      final showMonthLabel =
          cell.startsNewMonth && boxSize >= (isGridFirstLayout ? 38.0 : 30.0);

      if (showMonthLabel) {
        final label = cell.shortMonthLabel;
        final monthPainter = monthTextCache.putIfAbsent(
          '$label-${isLightCell ? 1 : 0}',
          () => _layoutText(
            label,
            TextStyle(
              color: secondaryTextColor.withValues(
                  alpha: isGridFirstLayout ? 0.78 : 0.72),
              fontSize: (boxSize * (isGridFirstLayout ? 0.11 : 0.12))
                  .clamp(7.0, 12.0),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
            boxSize * 0.42,
            maxLines: 1,
          ),
        );
        if (isGridFirstLayout) {
          monthPainter.paint(
            canvas,
            Offset(
              left + (boxSize - monthPainter.width) / 2,
              top + (boxSize * 0.10),
            ),
          );
        } else {
          monthPainter.paint(
            canvas,
            Offset(
              left + boxSize - monthPainter.width - (boxSize * 0.10),
              top + (boxSize * 0.12),
            ),
          );
        }
      }

      if (isGridFirstLayout) {
        datePainter.paint(
          canvas,
          Offset(
            left + (boxSize - datePainter.width) / 2,
            top +
                ((boxSize - datePainter.height) / 2) +
                (showMonthLabel ? boxSize * 0.08 : 0),
          ),
        );
      } else {
        datePainter.paint(
          canvas,
          Offset(
            left + (boxSize * 0.14),
            top + (boxSize * 0.12),
          ),
        );
      }

      if (cell.contributionCount > 0 &&
          !isQuoteHero &&
          !isGridFirstLayout &&
          !isOverflowCell) {
        if (boxSize >= 30) {
          final countCacheKey =
              (cell.contributionCount << 1) | (isLightCell ? 1 : 0);
          final countPainter = countTextCache.putIfAbsent(
            countCacheKey,
            () => _layoutText(
              '${cell.contributionCount}',
              TextStyle(
                color: secondaryTextColor,
                fontSize: (boxSize * 0.18).clamp(8.0, 16.0),
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
              boxSize * 0.4,
              maxLines: 1,
            ),
          );
          countPainter.paint(
            canvas,
            Offset(
              left + boxSize - countPainter.width - (boxSize * 0.12),
              top + boxSize - countPainter.height - (boxSize * 0.12),
            ),
          );
        } else {
          canvas.drawCircle(
            Offset(
              left + boxSize - (boxSize * 0.18),
              top + boxSize - (boxSize * 0.18),
            ),
            (boxSize * 0.06).clamp(1.8, 4.5),
            Paint()..color = secondaryTextColor,
          );
        }
      }
    }

    for (final painter in dateTextCache.values) {
      painter.dispose();
    }
    for (final painter in countTextCache.values) {
      painter.dispose();
    }
    for (final painter in monthTextCache.values) {
      painter.dispose();
    }
    for (final painter in weekdayCache.values) {
      painter.dispose();
    }

    currentY = calendarGridY + gridHeight;

    if (quotePainter != null && !isQuoteHero) {
      currentY += 12.0 * scale;
      quotePainter!.paint(
        canvas,
        Offset(contentX + (contentWidth - quotePainter!.width) / 2, currentY),
      );
      currentY += quotePainter!.height;
    }

    if (identityItems.isNotEmpty && !identityBeforeGrid) {
      currentY += 12.0 * scale;
      currentY += _drawIdentityChips(
        canvas: canvas,
        x: contentX,
        y: currentY,
        maxWidth: contentWidth,
        scale: scale,
        isDarkMode: config.isDarkMode,
        items: identityItems,
      );
    }

    if (config.showQuickStatsBar && stats.isNotEmpty && !statsBeforeGrid) {
      currentY += 12.0 * scale;
      _drawQuickStatsBar(
        canvas: canvas,
        x: contentX,
        y: currentY,
        width: contentWidth,
        scale: scale,
        config: config,
        items: stats,
        accent: accent,
      );
      currentY += statsHeight;
    }

    if (showLegend) {
      currentY += 12.0 * scale;
      final legendTextStyle = TextStyle(
        color: (config.isDarkMode ? AppTheme.lightSurface : AppTheme.lightText)
            .withValues(alpha: 0.56),
        fontSize: (8.5 * scale).clamp(7.0, 12.0),
        fontWeight: FontWeight.w700,
      );
      final legendBox = (boxSize * 0.55).clamp(8.0, 18.0);
      final legendGap = 6.0 * scale;
      var legendX = contentX;
      final lessPainter =
          _layoutText('Low', legendTextStyle, contentWidth, maxLines: 1);
      lessPainter.paint(canvas, Offset(legendX, currentY));
      legendX += lessPainter.width + legendGap;
      lessPainter.dispose();
      for (int i = 0; i < 5; i++) {
        final color = themeLevels.length > i ? themeLevels[i] : themeLevels[0];
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(legendX, currentY, legendBox, legendBox),
            Radius.circular(legendBox * 0.3),
          ),
          Paint()..color = color.withValues(alpha: config.opacity),
        );
        legendX += legendBox + legendGap;
      }
      final morePainter =
          _layoutText('High', legendTextStyle, contentWidth, maxLines: 1);
      morePainter.paint(canvas, Offset(legendX, currentY));
      morePainter.dispose();
    }

    disposeTextPainters();
  }

  static List<_QuickStat> _buildQuickStats(
    CachedContributionData data,
    WallpaperConfig config,
    WallpaperTarget target,
    DateTime todayUtc,
  ) {
    final items = <_QuickStat>[];
    var limit = target == WallpaperTarget.home
        ? config.densityMode.quickStatLimit.clamp(1, 2)
        : config.densityMode.quickStatLimit;
    if (target != WallpaperTarget.home &&
        config.heroFocus == WallpaperHeroFocus.grid) {
      limit = limit.clamp(1, 2);
    }
    if (config.statCurrentStreak) {
      items.add(_QuickStat(
          label: AppStrings.statCurrentShort, value: '${data.currentStreak}d'));
    }
    if (config.statLongestStreak) {
      items.add(_QuickStat(
          label: AppStrings.statBestShort, value: '${data.longestStreak}d'));
    }
    if (config.statTotalCommits) {
      items.add(_QuickStat(
          label: AppStrings.statTotalShort,
          value: PresentationFormatter.formatCompactNumber(
              data.totalContributions)));
    }
    if (config.statTopLanguage) {
      final top =
          data.topLanguages.isNotEmpty ? data.topLanguages.first.name : '-';
      items.add(_QuickStat(label: AppStrings.statTopShort, value: top));
    }
    return items.take(limit).toList(growable: false);
  }

  static double _statsBarHeightBase(int count) {
    if (count <= 0) return 0.0;
    const padV = 6.0;
    const valueFont = 11.0;
    final itemH = (valueFont * 1.20) + 2.0;
    return (padV * 2) + itemH;
  }

  static void _drawQuickStatsBar({
    required Canvas canvas,
    required double x,
    required double y,
    required double width,
    required double scale,
    required WallpaperConfig config,
    required List<_QuickStat> items,
    required Color accent,
  }) {
    if (items.isEmpty) return;
    final barHeight = (_statsBarHeightBase(items.length) *
            scale *
            _statsBarMultiplier(config.densityMode, config.heroFocus))
        .clamp(24.0, 72.0)
        .toDouble();
    final surfaceOpacity =
        (0.30 + (config.opacity * 0.70)).clamp(0.30, 1.0).toDouble();
    final radius = (14.0 * scale) + (config.cornerRadius * 0.85);
    final base = config.isDarkMode ? const Color(0xFF0A0F0B) : Colors.white;
    final border = accent.withValues(alpha: config.isDarkMode ? 0.24 : 0.18);
    final bgRect = Rect.fromLTWH(x, y, width, barHeight);
    final barRRect = RRect.fromRectAndRadius(
      bgRect,
      Radius.circular(radius),
    );
    canvas.drawRRect(
      barRRect,
      Paint()
        ..shader = ui.Gradient.linear(
          bgRect.topLeft,
          bgRect.topRight,
          [
            base.withValues(
              alpha: (config.isDarkMode ? 0.62 : 0.84) * surfaceOpacity,
            ),
            base.withValues(
              alpha: (config.isDarkMode ? 0.52 : 0.76) * surfaceOpacity,
            ),
            accent.withValues(
              alpha: (config.isDarkMode ? 0.12 : 0.08) * surfaceOpacity,
            ),
          ],
          const [0.0, 0.7, 1.0],
        ),
    );
    canvas.drawRRect(
      barRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1.0 * scale).clamp(0.8, 1.8)
        ..color = border.withValues(alpha: surfaceOpacity),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 1, y + 1, width - 2, barHeight * 0.46),
        Radius.circular(math.max(2.0, radius - 1)),
      ),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(x, y),
          Offset(x, y + barHeight * 0.46),
          [
            Colors.white.withValues(
              alpha: (config.isDarkMode ? 0.08 : 0.16) * surfaceOpacity,
            ),
            Colors.transparent,
          ],
        ),
    );

    final innerPad = 10.0 * scale;
    final segmentCount = items.length.clamp(1, 4);
    final segmentWidth = (width - (innerPad * 2)) / segmentCount;
    final valueStyle = TextStyle(
      color: (config.isDarkMode ? AppTheme.lightSurface : AppTheme.lightText)
          .withValues(alpha: 0.94),
      fontSize:
          ((11.0 * scale) * (segmentCount >= 3 ? 0.95 : 1.0)).clamp(8.0, 18.0),
      fontWeight: FontWeight.w900,
      letterSpacing: -0.2,
      height: 1.0,
    );
    final labelStyle = TextStyle(
      color: (config.isDarkMode ? AppTheme.lightSurface : AppTheme.lightText)
          .withValues(alpha: 0.58),
      fontSize:
          ((8.5 * scale) * (segmentCount >= 3 ? 0.94 : 1.0)).clamp(7.0, 13.0),
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      height: 1.0,
    );

    for (int index = 0; index < items.length; index++) {
      final segmentX = x + innerPad + (index * segmentWidth);
      if (index > 0) {
        canvas.drawLine(
          Offset(segmentX, y + (barHeight * 0.22)),
          Offset(segmentX, y + (barHeight * 0.78)),
          Paint()
            ..strokeWidth = (1.0 * scale).clamp(0.8, 1.5)
            ..color = border.withValues(
              alpha: (config.isDarkMode ? 0.24 : 0.18) * 0.65,
            ),
        );
      }
      final textP = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(text: items[index].value, style: valueStyle),
            TextSpan(text: ' ${items[index].label}', style: labelStyle),
          ],
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      )..layout(
          maxWidth: (segmentWidth - (6.0 * scale)).clamp(16.0, segmentWidth));
      textP.paint(
        canvas,
        Offset(
          segmentX + (segmentWidth - textP.width) / 2,
          y + (barHeight - textP.height) / 2,
        ),
      );
      textP.dispose();
    }
  }
}

class _CalendarWindow {
  final DateTime focusMonthStart;
  final DateTime focusMonthEnd;
  final List<DateTime> dates;

  const _CalendarWindow({
    required this.focusMonthStart,
    required this.focusMonthEnd,
    required this.dates,
  });
}

class _MonthActivitySummary {
  final DateTime monthStart;
  final DateTime monthEnd;
  final ContributionStats stats;

  const _MonthActivitySummary({
    required this.monthStart,
    required this.monthEnd,
    required this.stats,
  });
}

class _QuickStat {
  final String label;
  final String value;
  const _QuickStat({required this.label, required this.value});
}

class _IdentityItem {
  final String label;
  final Color? accent;

  const _IdentityItem({required this.label, this.accent});
}

class _PosterHeadline {
  final String eyebrow;
  final String? title;
  final String? subtitle;

  const _PosterHeadline({
    required this.eyebrow,
    this.title,
    this.subtitle,
  });
}

class WallpaperPreviewPainter extends CustomPainter {
  final CachedContributionData data;
  final double wallpaperWidth;
  final double wallpaperHeight;
  final WallpaperTarget target;
  final WallpaperConfig config;

  WallpaperPreviewPainter({
    required this.data,
    required this.wallpaperWidth,
    required this.wallpaperHeight,
    required this.target,
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Background
    final paint = Paint()
      ..color = config.isDarkMode ? AppTheme.darkBg : AppTheme.lightBg
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint);

    // 2. Scale context to match wallpaper resolution
    final scaleX = size.width / wallpaperWidth;
    final scaleY = size.height / wallpaperHeight;
    final scale = math.min(scaleX, scaleY);
    final dx = (size.width - (wallpaperWidth * scale)) / 2;
    final dy = (size.height - (wallpaperHeight * scale)) / 2;

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(dx, dy);
    canvas.scale(scale);

    // 3. Render Heatmap
    MonthHeatmapRenderer.render(
      canvas: canvas,
      size: Size(wallpaperWidth, wallpaperHeight),
      data: data,
      config: config,
      target: target,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WallpaperPreviewPainter old) {
    return old.config != config || old.data != data || old.target != target;
  }
}

// ══════════════════════════════════════════════════════════════════════════
// WALLPAPER GENERATION TASK (Moved from AppServices)
// ══════════════════════════════════════════════════════════════════════════

@pragma('vm:entry-point')
Future<Uint8List> generateWallpaperTask(Map<String, dynamic> args) async {
  final d = CachedContributionData.fromJson(jsonDecode(args['data']));
  final c = WallpaperConfig.fromJson(jsonDecode(args['config']));
  final targetName = args['target'] as String?;
  final target = WallpaperTarget.values.firstWhere(
    (value) => value.name == targetName,
    orElse: () => WallpaperTarget.lock,
  );
  final w = args['width'] as double,
      h = args['height'] as double,
      pr = args['pixelRatio'] as double;

  final r = ui.PictureRecorder();
  final canvas = ui.Canvas(r, ui.Rect.fromLTWH(0, 0, w * pr, h * pr));
  canvas.scale(pr);

  MonthHeatmapRenderer.render(
      canvas: canvas, size: ui.Size(w, h), data: d, config: c, target: target);

  final p = r.endRecording();
  final img = await p.toImage((w * pr).round(), (h * pr).round());
  try {
    final b = await img.toByteData(format: ui.ImageByteFormat.png);
    if (b == null) {
      throw WallpaperException('Failed to encode wallpaper image.');
    }
    return b.buffer.asUint8List();
  } finally {
    img.dispose();
    p.dispose();
  }
}
