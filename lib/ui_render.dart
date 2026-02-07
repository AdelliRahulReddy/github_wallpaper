import 'package:flutter/material.dart';
import 'app_models.dart';
import 'app_utils.dart';
import 'app_theme.dart';

class MonthHeatmapRenderer {
  static final _lT = AppThemeExt(isLight: true),
      _dT = AppThemeExt(isLight: false);
  static const _longWeekdayLabels = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat'
  ];
  static const _shortWeekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  static void render(
      {required Canvas canvas,
      required Size size,
      required CachedContributionData data,
      required WallpaperConfig config,
      DateTime? referenceDate,
      DateTime? todayUtc,
      bool showLegend = false}) {
    final tEx = config.isDarkMode ? _dT : _lT;
    final ref = (referenceDate ?? DateTime.now().toUtc()).toUtc();
    final daysNum = DateTime(ref.year, ref.month + 1, 0).day;
    final firstWeekdayOffset = DateTime.utc(ref.year, ref.month, 1).weekday % 7;
    final cells = List.generate(
        daysNum, (i) => _Cell(DateTime.utc(ref.year, ref.month, i + 1), i));

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

    final qTxt = config.customQuote;
    final estimatedQuoteGap = qTxt.isEmpty
        ? 0.0
        : (baseSpacing * 4).clamp(baseSpacing, baseBox * 1.5);
    final estimatedQuoteHeight =
        qTxt.isEmpty ? 0.0 : (config.quoteFontSize * 1.35);
    final baseTotalH = baseHeaderFont +
        (baseSpacing * 3) +
        baseLabelFont +
        (baseSpacing * 2) +
        baseGridH +
        estimatedQuoteGap +
        estimatedQuoteHeight;
    final widthScale = ((avW * 0.95) / baseGridW).clamp(0.1, 10.0).toDouble();
    final heightScale = ((avH * 0.95) / baseTotalH).clamp(0.1, 10.0).toDouble();
    final scale = config.autoFitWidth
        ? (widthScale < heightScale ? widthScale : heightScale)
        : config.scale;

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
    final dayLabels = useLongLabels ? _longWeekdayLabels : _shortWeekdayLabels;
    final lbFontSize = (useLongLabels ? boxSz * 0.28 : boxSz * 0.45)
        .clamp(6.0, 11.0)
        .toDouble();
    final lbH = lbFontSize * 1.2;
    final headerFontSize = (16 * scale).clamp(8.0, 44.0).toDouble();

    // Quote
    final qCol =
        (config.isDarkMode ? AppTheme.lightSurface : AppTheme.lightText)
            .withValues(alpha: config.quoteOpacity);
    final qP = qTxt.isEmpty
        ? null
        : (TextPainter(
            text: TextSpan(
                text: qTxt,
                style: TextStyle(
                    color: qCol,
                    fontSize: config.quoteFontSize * scale,
                    fontStyle: FontStyle.italic)),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            maxLines: 3)
          ..layout(maxWidth: gridW));
    final qH = qP?.height ?? 0.0,
        qGap = qTxt.isEmpty ? 0.0 : (spc * 4).clamp(spc, boxSz * 1.5);

    final legH = showLegend ? (boxSz * 1.5) : 0.0;
    final totH = headerFontSize + headGap + lbH + lbGap + gridH + qGap + qH + legH;
    final yHead = (padT + ((avH - totH) * config.verticalPosition)).clamp(padT,
        size.height - padB - totH < padT ? padT : size.height - padB - totH);
    final yLb = yHead + headerFontSize + headGap;
    final yGrid = yLb + lbH + lbGap;

    // Head
    final hCol = (config.isDarkMode ? AppTheme.lightBg : AppTheme.lightText)
        .withValues(alpha: 0.8);
    if (headerFontSize >= 8) {
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
          color: hCol.withValues(alpha: 0.6),
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
          ..color = tEx.heatmapTodayHighlight;
    final rad = Radius.circular(config.cornerRadius * scale);
    final n = (todayUtc ?? DateTime.now().toUtc()).toUtc();
    final today = DateTime.utc(n.year, n.month, n.day);
    final txtCol =
        (config.isDarkMode ? AppTheme.lightSurface : AppTheme.lightText)
            .withValues(alpha: 0.9);
    final cntSty = TextStyle(
        color: txtCol, fontSize: boxSz * 0.45, fontWeight: FontWeight.bold);

    for (final c in cells) {
      final idx = c.idx + firstWeekdayOffset;
      final cnt = data.getContributionsForDate(c.date);
      final lvl =
          RenderUtils.getContributionLevel(cnt, quartiles: data.quartiles);
      fillP.color = (tEx.heatmapLevels.length > lvl
              ? tEx.heatmapLevels[lvl]
              : tEx.heatmapLevels[0])
          .withValues(alpha: config.opacity);

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

      if (boxSz >= 12.0 && cnt > 0) {
        final tp = TextPainter(
            text: TextSpan(
                text: '$cnt',
                style: cntSty.copyWith(
                    shadows: [Shadow(color: Colors.black26, blurRadius: 2)])),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            maxLines: 1)
          ..layout(maxWidth: boxSz);
        tp.paint(
            canvas,
            Offset(xStart + ((idx % 7) * cellSz) + (boxSz - tp.width) / 2,
                yGrid + ((idx ~/ 7) * cellSz) + (boxSz - tp.height) / 2));
        tp.dispose();
      }
    }

    double nextY = yGrid + gridH + qGap + qH;

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
      RenderUtils.drawText(canvas, "Less", legSty, Offset(currentX, yLegend), 40)
          .dispose();
      currentX += RenderUtils.drawText(
                  canvas, "Less", legSty, Offset(currentX, yLegend), 100,
                  paint: false)
              .width +
          legSpc;

      for (int i = 0; i < 5; i++) {
        fillP.color = (tEx.heatmapLevels.length > i
                ? tEx.heatmapLevels[i]
                : tEx.heatmapLevels[0])
            .withValues(alpha: config.opacity);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(currentX, yLegend, legBoxSz, legBoxSz),
                Radius.circular(rad.x * 0.6)),
            fillP);
        currentX += legBoxSz + legSpc;
      }

      RenderUtils.drawText(canvas, "More", legSty, Offset(currentX, yLegend), 40)
          .dispose();
      nextY = yLegend + legBoxSz;
    }

    // Quote
    if (qP != null) {
      qP.paint(canvas,
          Offset(xStart + (gridW - qP.width) / 2, nextY + (spc * 1.5)));
      qP.dispose();
    }
  }
}

class _Cell {
  final DateTime date;
  final int idx;
  _Cell(this.date, this.idx);
}
