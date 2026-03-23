import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:github_wallpaper/core/errors/app_exceptions.dart';
import 'package:github_wallpaper/data/models/app_models.dart';
import 'package:github_wallpaper/shared/state/app_state.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/data/models/theme_presets.dart';

class MonthHeatmapRenderer {
  static final _lT = AppThemeExt(isLight: true),
      _dT = AppThemeExt(isLight: false);
  static const _shortWeekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static final Map<int, List<_Cell>> _cellsCache = {};

  static void clearCaches() => _cellsCache.clear();
  static void _pruneCache() {
    while (_cellsCache.length > 12) {
      final keys = _cellsCache.keys.toList()..sort();
      _cellsCache.remove(keys.first);
    }
  }

  static void render(
      {required Canvas canvas,
      required Size size,
      required CachedContributionData data,
      required WallpaperConfig config,
      WallpaperTarget target = WallpaperTarget.lock,
      DateTime? referenceDate,
      DateTime? todayUtc,
      bool showLegend = false}) {
    final tEx = config.isDarkMode ? _dT : _lT;
    final isLockFocused = target != WallpaperTarget.home;
    final ref = (referenceDate ?? DateTime.now().toUtc()).toUtc();
    final daysNum = DateTime(ref.year, ref.month + 1, 0).day;
    final firstWeekdayOffset = DateTime.utc(ref.year, ref.month, 1).weekday % 7;
    final monthKey = (ref.year * 100) + ref.month;
    final cells = _cellsCache.putIfAbsent(
        monthKey,
        () => List.generate(daysNum,
            (i) => _Cell(DateTime.utc(ref.year, ref.month, i + 1), i)));
    _pruneCache();

    // Bg
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..color = config.isDarkMode ? AppTheme.darkBg : AppTheme.lightBg);

    // Layout
    final padL = config.paddingLeft,
        padR = config.paddingRight,
        padT = config.paddingTop,
        padB = config.paddingBottom;
    final avW = size.width - padL - padR, avH = size.height - padT - padB;
    final rows = ((daysNum + firstWeekdayOffset) / 7).ceil();

    const baseBox = AppConstants.heatmapBoxSize;
    const baseSpacing = AppConstants.heatmapBoxSpacing;
    const baseHeaderFont = 16.0;
    const baseLabelFont = 8.0;
    final baseCellSize = baseBox + baseSpacing;
    final baseGridW = (7 * baseCellSize) - baseSpacing;
    final baseGridH = (rows * baseCellSize) - baseSpacing;

    final qTxt = config.customQuote.isNotEmpty
        ? config.customQuote
        : (data.totalContributions == 0
            ? 'Your coding journey starts today. Make your first commit to activate GitWall.'
            : '');
    final stats = _buildQuickStats(data, config);
    final showStats = config.showQuickStatsBar && stats.isNotEmpty;

    // Measure Quote First (Fix for Problem 5)
    final qGap = qTxt.isEmpty
        ? 0.0
        : (baseSpacing * 4).clamp(baseSpacing, baseBox * 1.5);
    final qCol =
        (config.isDarkMode ? AppTheme.lightSurface : AppTheme.lightText)
            .withValues(alpha: config.quoteOpacity);
    final baseStatsGap =
        showStats ? (baseSpacing * 2).clamp(baseSpacing, baseBox * 1.0) : 0.0;
    final baseStatsBarH = showStats ? _statsBarHeightBase(stats.length) : 0.0;

    // We need an initial grid width to measure against, but we don't know scale yet.
    // So we iterate:
    // 1. Calculate available width/height
    // 2. Calculate scale based on grid only
    // 3. Measure text with that width
    // 4. Recalculate total height and scale if needed

    final baseTotalHNoQuote = baseHeaderFont +
        (baseSpacing * 3) +
        baseLabelFont +
        (baseSpacing * 2) +
        baseGridH +
        baseStatsGap +
        baseStatsBarH;
    final widthScale = ((avW * 0.95) / baseGridW).clamp(0.1, 10.0).toDouble();

    // Initial scale guess (ignoring quote height for a moment)
    var scale = widthScale;

    // Measure text at this scale
    TextPainter? qP;
    double qH = 0.0;

    if (qTxt.isNotEmpty) {
      final tentativeGridW =
          (7 * (baseBox * scale + baseSpacing * scale)) - (baseSpacing * scale);
      qP = TextPainter(
          text: TextSpan(
              text: qTxt,
              style: TextStyle(
                  color: qCol,
                  fontSize: config.quoteFontSize * scale,
                  fontStyle: FontStyle.italic)),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          maxLines: 3)
        ..layout(maxWidth: tentativeGridW);
      qH = qP.height;
    }

    // Now calculate true height requirement
    final totalHRequired =
        (baseTotalHNoQuote * scale) + (qTxt.isEmpty ? 0 : (qGap + qH));
    final heightScale =
        ((avH * 0.95) / (totalHRequired / scale)).clamp(0.1, 10.0).toDouble();

    if (config.autoFitWidth) {
      // If height is the bottleneck, reduce scale
      if (heightScale < widthScale) {
        scale = heightScale;
        // Remeasure text with new scale if changed significantly
        if (qTxt.isNotEmpty) {
          final finalGridW = (7 * (baseBox * scale + baseSpacing * scale)) -
              (baseSpacing * scale);
          qP = TextPainter(
              text: TextSpan(
                  text: qTxt,
                  style: TextStyle(
                      color: qCol,
                      fontSize: config.quoteFontSize * scale,
                      fontStyle: FontStyle.italic)),
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              maxLines: 3)
            ..layout(maxWidth: finalGridW);
          qH = qP.height;
        }
      }
    } else {
      scale = config.scale;
      // BUG FIX: Re-measure text with manual scale to ensure correct qH
      if (qTxt.isNotEmpty) {
        final finalGridW = (7 * (baseBox * scale + baseSpacing * scale)) -
            (baseSpacing * scale);
        qP = TextPainter(
            text: TextSpan(
                text: qTxt,
                style: TextStyle(
                    color: qCol,
                    fontSize: config.quoteFontSize * scale,
                    fontStyle: FontStyle.italic)),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            maxLines: 3)
          ..layout(maxWidth: finalGridW);
        qH = qP.height;
      }
    }

    final boxSz = baseBox * scale,
        spc = baseSpacing * scale,
        cellSz = boxSz + spc;
    final gridW = (7 * cellSz) - spc, gridH = (rows * cellSz) - spc;

    // Position
    final xStart = (padL + ((avW - gridW) * config.horizontalPosition)).clamp(
        padL,
        size.width - padR - gridW < padL ? padL : size.width - padR - gridW);
    final headGap = (spc * 3).clamp(spc, boxSz), lbGap = spc * 2;
    final useLongLabels = boxSz >= 22.0;
    final dayLabels =
        useLongLabels ? AppConstants.weekdays : _shortWeekdayLabels;
    final lbFontSize = (useLongLabels ? boxSz * 0.28 : boxSz * 0.45)
        .clamp(6.0, 11.0)
        .toDouble();
    final lbH = lbFontSize * 1.2;
    final rawHeaderFontSize = (16 * scale).clamp(8.0, 44.0).toDouble();
    final showHeader = !isLockFocused;
    final headerFontSize = showHeader ? rawHeaderFontSize : 0.0;
    final headerBlockHeight = showHeader
        ? headerFontSize + headGap
        : (boxSz * 1.15).clamp(14.0, 28.0).toDouble();

    // QuotePainter already created above

    final legH = showLegend ? (boxSz * 1.5) : 0.0;
    final statsGap = baseStatsGap * scale;
    final statsBarH = baseStatsBarH * scale;
    final totH = headerBlockHeight +
        lbH +
        lbGap +
        gridH +
        statsGap +
        statsBarH +
        qGap +
        qH +
        legH;
    final yHead = (padT + ((avH - totH) * config.verticalPosition)).clamp(padT,
        size.height - padB - totH < padT ? padT : size.height - padB - totH);
    final yLb = yHead + headerBlockHeight;
    final yGrid = yLb + lbH + lbGap;

    // Head
    final hCol = (config.isDarkMode ? AppTheme.lightBg : AppTheme.lightText)
        .withValues(alpha: showHeader ? 0.8 : 0.6);
    if (showHeader && headerFontSize >= 8) {
      RenderUtils.drawText(
              canvas,
              RenderUtils.headerTextForDate(ref),
              TextStyle(
                  color: hCol,
                  fontSize: headerFontSize,
                  fontWeight: FontWeight.bold),
              Offset(xStart, yHead),
              gridW)
          .dispose();
    }

    // Labels
    if (lbFontSize >= 6) {
      final lbSty = TextStyle(
          color: hCol.withValues(alpha: showHeader ? 0.6 : 0.5),
          fontSize: lbFontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: useLongLabels ? 0.15 : 0.0);
      for (int i = 0; i < 7; i++) {
        RenderUtils.drawText(canvas, dayLabels[i], lbSty,
                Offset(xStart + (i * cellSz), yLb), boxSz,
                textAlign: TextAlign.center)
            .dispose();
      }
    }

    // Cells
    final fillP = Paint()..style = PaintingStyle.fill,
        bordP = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (spc / 1.5).clamp(1.0, boxSz * 0.2)
          ..color = tEx.heatmapHighlight;
    final themeLevels =
        ThemePresets.levelsFor(config.themeId, isDarkMode: config.isDarkMode);
    final rad = Radius.circular(config.cornerRadius * scale);
    final n = (todayUtc ?? DateTime.now().toUtc()).toUtc();
    final today = DateTime.utc(n.year, n.month, n.day);
    final cntBaseSize = boxSz * 0.45;

    final textCache = <int, TextPainter>{};

    for (final c in cells) {
      final idx = c.idx + firstWeekdayOffset;
      final cnt = data.getContributionsForDate(c.date);
      final lvl =
          RenderUtils.getContributionLevel(cnt, quartiles: data.quartiles);
      final cellColor =
          themeLevels.length > lvl ? themeLevels[lvl] : themeLevels[0];
      fillP.color = cellColor.withValues(alpha: config.opacity);

      final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(xStart + ((idx % 7) * cellSz),
              yGrid + ((idx ~/ 7) * cellSz), boxSz, boxSz),
          rad);
      canvas.drawRRect(r, fillP);
      if (c.date.year == today.year &&
          c.date.month == today.month &&
          c.date.day == today.day) {
        canvas.drawRRect(r, bordP);
      }

      final showCount = boxSz >= 12.0 && cnt > 0;
      if (showCount) {
        final lum = cellColor.computeLuminance();
        final isLightCell = lum > 0.55;
        final cacheKey = (cnt << 1) | (isLightCell ? 1 : 0);
        var tp = textCache[cacheKey];
        if (tp == null) {
          final txtCol = isLightCell
              ? Colors.black.withValues(alpha: 0.86)
              : Colors.white.withValues(alpha: 0.92);
          final shCol = isLightCell
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.black.withValues(alpha: 0.28);
          final cntSty = TextStyle(
            color: txtCol,
            fontSize: cntBaseSize,
            fontWeight: FontWeight.w900,
            height: 1.0,
          );
          tp = TextPainter(
              text: TextSpan(
                  text: '$cnt',
                  style: cntSty.copyWith(
                      shadows: [Shadow(color: shCol, blurRadius: 2)])),
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              maxLines: 1)
            ..layout(maxWidth: boxSz);
          textCache[cacheKey] = tp;
        }
        tp.paint(
            canvas,
            Offset(xStart + ((idx % 7) * cellSz) + (boxSz - tp.width) / 2,
                yGrid + ((idx ~/ 7) * cellSz) + (boxSz - tp.height) / 2));
      }
    }

    // Dispose cached painters
    for (final tp in textCache.values) {
      tp.dispose();
    }

    double nextY = yGrid + gridH;

    if (showStats) {
      nextY += statsGap;
      _drawQuickStatsBar(
        canvas: canvas,
        x: xStart,
        y: nextY,
        width: gridW,
        scale: scale,
        config: config,
        data: data,
        items: stats,
      );
      nextY += statsBarH;
    }

    // Legend
    if (showLegend) {
      final yLegend = nextY + (spc * 2);
      final legBoxSz = (boxSz * 0.6).clamp(8.0, 24.0);
      final legSpc = spc * 1.5;
      final legSty = TextStyle(
          color: hCol.withValues(alpha: 0.5),
          fontSize: (legBoxSz * 0.7).clamp(6.0, 12.0),
          fontWeight: FontWeight.w500);

      double currentX = xStart;
      RenderUtils.drawText(
              canvas, "Less", legSty, Offset(currentX, yLegend), 40)
          .dispose();
      currentX += RenderUtils.drawText(
                  canvas, "Less", legSty, Offset(currentX, yLegend), 100,
                  paint: false)
              .width +
          legSpc;

      for (int i = 0; i < 5; i++) {
        final legColor =
            themeLevels.length > i ? themeLevels[i] : themeLevels[0];
        fillP.color = legColor.withValues(alpha: config.opacity);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(currentX, yLegend, legBoxSz, legBoxSz),
                Radius.circular(rad.x * 0.6)),
            fillP);
        currentX += legBoxSz + legSpc;
      }

      RenderUtils.drawText(
              canvas, "More", legSty, Offset(currentX, yLegend), 40)
          .dispose();
      nextY = yLegend + legBoxSz;
    }

    // Quote
    if (qP != null) {
      qP.paint(canvas,
          Offset(xStart + (gridW - qP.width) / 2, nextY + (spc * 1.5) + qGap));
      qP.dispose();
    }
  }

  static List<_QuickStat> _buildQuickStats(
      CachedContributionData data, WallpaperConfig config) {
    final items = <_QuickStat>[];
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
          data.topLanguages.isNotEmpty ? data.topLanguages.first.name : '—';
      items.add(_QuickStat(label: AppStrings.statTopShort, value: top));
    }
    return items;
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
    required CachedContributionData data,
    required List<_QuickStat> items,
  }) {
    if (items.isEmpty) return;
    final pad = 7.0 * scale;
    final r = 12.0 * scale;
    final barH = _statsBarHeightBase(items.length) * scale;
    final bg = Paint()
      ..style = PaintingStyle.fill
      ..color = (config.isDarkMode ? AppTheme.darkBg : AppTheme.lightBg)
          .withValues(alpha: config.isDarkMode ? 0.42 : 0.62);
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (1.0 * scale).clamp(0.8, 2.0)
      ..color = (config.isDarkMode ? Colors.white : Colors.black)
          .withValues(alpha: config.isDarkMode ? 0.12 : 0.10);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, width, barH),
      Radius.circular(r),
    );
    canvas.drawRRect(rect, bg);
    canvas.drawRRect(rect, border);

    final innerW = width - (pad * 2);
    final count = items.length.clamp(1, 6);
    final segW = innerW / count;
    final valueFont =
        ((11.0 * scale) * (count >= 4 ? 0.92 : 1.0)).clamp(9.0, 16.0);
    final labelFont =
        ((8.5 * scale) * (count >= 4 ? 0.90 : 1.0)).clamp(7.0, 12.0);
    final inlineLabelStyle = TextStyle(
      color: (config.isDarkMode ? AppTheme.lightSurface : AppTheme.lightText)
          .withValues(alpha: 0.56),
      fontSize: labelFont,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );
    final valueStyle = TextStyle(
      color: (config.isDarkMode ? AppTheme.lightSurface : AppTheme.lightText)
          .withValues(alpha: 0.92),
      fontSize: valueFont,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.2,
      height: 1.0,
    );

    final maxW = (segW - (6.0 * scale)).clamp(12.0, segW);

    for (int i = 0; i < items.length; i++) {
      final ix = x + pad + (i * segW);
      final textP = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(text: items[i].value, style: valueStyle),
            TextSpan(text: ' ${items[i].label}', style: inlineLabelStyle),
          ],
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: maxW);
      textP.paint(
        canvas,
        Offset(ix + (segW - textP.width) / 2, y + (barH - textP.height) / 2),
      );
      textP.dispose();
    }
  }
}

class _Cell {
  final DateTime date;
  final int idx;
  _Cell(this.date, this.idx);
}

class _QuickStat {
  final String label;
  final String value;
  const _QuickStat({required this.label, required this.value});
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
    final scale = scaleX < scaleY ? scaleX : scaleY;

    canvas.save();
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
