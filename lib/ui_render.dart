import 'package:flutter/material.dart';
import 'app_models.dart';
import 'app_utils.dart';
import 'app_theme.dart';

class MonthHeatmapRenderer {
  static final _lT = AppThemeExt(isLight: true), _dT = AppThemeExt(isLight: false);

  static void render({required Canvas canvas, required Size size, required CachedContributionData data, required WallpaperConfig config, DateTime? referenceDate, DateTime? todayUtc}) {
    final tEx = config.isDarkMode ? _dT : _lT;
    final ref = (referenceDate ?? DateTime.now().toUtc()).toUtc();
    final daysNum = DateTime(ref.year, ref.month + 1, 0).day;
    final cells = List.generate(daysNum, (i) => _Cell(DateTime.utc(ref.year, ref.month, i + 1), i));

    // Bg
    canvas.drawRect(Rect.fromLTWH(0,0,size.width,size.height), Paint()..color = config.isDarkMode ? AppTheme.darkBg : AppTheme.lightBg);

    // Layout
    final padL = config.paddingLeft, padR = config.paddingRight, padT = config.paddingTop, padB = config.paddingBottom;
    final avW = size.width - padL - padR, avH = size.height - padT - padB;
    // Fit scale: (target / baseGrid).clamp(0.1, 10.0) 
    final baseGridW = (7 * 15.0) + (6 * 3.0);
    final scale = config.autoFitWidth ? ((avW * 0.95) / baseGridW).clamp(0.1, 10.0).toDouble() : config.scale;
    final boxSz = 15.0 * scale, spc = 3.0 * scale, cellSz = boxSz + spc;
    final rows = ((daysNum + (DateTime.utc(ref.year, ref.month, 1).weekday % 7)) / 7).ceil();
    final gridW = (7 * cellSz) - spc, gridH = (rows * cellSz) - spc;
    
    // Position
    final xStart = (padL + ((avW - gridW) * config.horizontalPosition)).clamp(padL, size.width - padR - gridW < padL ? padL : size.width - padR - gridW);
    final headGap = (spc * 3).clamp(spc, boxSz), lbH = 12 * scale, lbGap = spc * 2;
    
    // Quote
    final qTxt = config.customQuote;
    final qCol = (config.isDarkMode ? AppTheme.lightSurface : AppTheme.lightText).withValues(alpha: config.quoteOpacity);
    final qP = qTxt.isEmpty ? null : (TextPainter(text: TextSpan(text: qTxt, style: TextStyle(color: qCol, fontSize: config.quoteFontSize * scale, fontStyle: FontStyle.italic)), textAlign: TextAlign.center, textDirection: TextDirection.ltr, maxLines: 3)..layout(maxWidth: gridW));
    final qH = qP?.height ?? 0.0, qGap = qTxt.isEmpty ? 0.0 : (spc * 4).clamp(spc, boxSz * 1.5);

    final totH = lbH * 1.25 + headGap + lbH + lbGap + gridH + qGap + qH; // approx header height
    final yHead = (padT + ((avH - totH) * config.verticalPosition)).clamp(padT, size.height - padB - totH < padT ? padT : size.height - padB - totH);
    final yLb = yHead + (16 * scale) + headGap; // 16*scale approx header font size
    final yGrid = yLb + lbH + lbGap;

    // Head
    final hCol = (config.isDarkMode ? AppTheme.lightBg : AppTheme.lightText).withValues(alpha: 0.8);
    if (16 * scale >= 6) {
      RenderUtils.drawText(canvas, RenderUtils.headerTextForDate(ref), TextStyle(color: hCol, fontSize: 16 * scale, fontWeight: FontWeight.bold), Offset(xStart, yHead), gridW).dispose();
    }

    // Labels
    if (7 * scale >= 4) {
      final lbSty = TextStyle(color: hCol.withValues(alpha: 0.6), fontSize: 7 * scale, fontWeight: FontWeight.w600, letterSpacing: 0.2);
      for (int i = 0; i < 7; i++) {
        RenderUtils.drawText(canvas, ['SUN','MON','TUE','WED','THU','FRI','SAT'][i], lbSty, Offset(xStart + (i * cellSz), yLb), boxSz, textAlign: TextAlign.center).dispose();
      }
    }

    // Cells
    final fillP = Paint()..style = PaintingStyle.fill, bordP = Paint()..style = PaintingStyle.stroke..strokeWidth = (spc/1.5).clamp(1.0, boxSz*0.2)..color = tEx.heatmapTodayHighlight;
    final rad = Radius.circular(config.cornerRadius * scale);
    final n = (todayUtc ?? DateTime.now().toUtc()).toUtc();
    final today = DateTime.utc(n.year, n.month, n.day);
    final txtCol = (config.isDarkMode ? AppTheme.lightSurface : AppTheme.lightText).withValues(alpha: 0.9);
    final cntSty = TextStyle(color: txtCol, fontSize: boxSz * 0.45, fontWeight: FontWeight.w600);

    for (final c in cells) {
      final idx = c.idx + (DateTime.utc(ref.year, ref.month, 1).weekday % 7);
      final cnt = data.getContributionsForDate(c.date);
      final lvl = RenderUtils.getContributionLevel(cnt, quartiles: data.quartiles);
      fillP.color = (tEx.heatmapLevels.length > lvl ? tEx.heatmapLevels[lvl] : tEx.heatmapLevels[0]).withValues(alpha: config.opacity);
      
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(xStart + ((idx % 7) * cellSz), yGrid + ((idx ~/ 7) * cellSz), boxSz, boxSz), rad);
      canvas.drawRRect(r, fillP);
      if (c.date.year == today.year && c.date.month == today.month && c.date.day == today.day) canvas.drawRRect(r, bordP);
      
      if (boxSz >= 12.0 && cnt > 0) {
        final tp = TextPainter(text: TextSpan(text: '$cnt', style: cntSty), textAlign: TextAlign.center, textDirection: TextDirection.ltr, maxLines: 1)..layout(maxWidth: boxSz);
        tp.paint(canvas, Offset(xStart + ((idx % 7) * cellSz) + (boxSz - tp.width)/2, yGrid + ((idx ~/ 7) * cellSz) + (boxSz - tp.height)/2));
        tp.dispose();
      }
    }

    // Quote
    if (qP != null) { qP.paint(canvas, Offset(xStart + (gridW - qP.width)/2, yGrid + gridH + qGap)); qP.dispose(); }
  }
}

class _Cell { final DateTime date; final int idx; _Cell(this.date, this.idx); }
