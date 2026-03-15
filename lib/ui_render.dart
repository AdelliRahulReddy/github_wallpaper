import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_exceptions.dart';
import 'app_models.dart';
import 'app_utils.dart';
import 'app_theme.dart';
import 'theme_presets.dart';

class MonthHeatmapRenderer {
  static final _lT = AppThemeExt(isLight: true),
      _dT = AppThemeExt(isLight: false);
  static const _shortWeekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static final Map<int, List<_Cell>> _cellsCache = {};

  static void clearCaches() => _cellsCache.clear();
  static void _pruneCache() {
    if (_cellsCache.length > 12) {
      final keys = _cellsCache.keys.toList()..sort();
      _cellsCache.remove(keys.first);
    }
  }

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
    final monthKey = (ref.year * 100) + ref.month;
    final cells = _cellsCache.putIfAbsent(
        monthKey,
        () => List.generate(
            daysNum, (i) => _Cell(DateTime.utc(ref.year, ref.month, i + 1), i)));
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

    final qTxt = config.customQuote;
    
    // Measure Quote First (Fix for Problem 5)
    final qGap = qTxt.isEmpty ? 0.0 : (baseSpacing * 4).clamp(baseSpacing, baseBox * 1.5);
    final qCol = (config.isDarkMode ? AppTheme.lightSurface : AppTheme.lightText)
            .withValues(alpha: config.quoteOpacity);
    
    // We need an initial grid width to measure against, but we don't know scale yet.
    // So we iterate: 
    // 1. Calculate available width/height
    // 2. Calculate scale based on grid only
    // 3. Measure text with that width
    // 4. Recalculate total height and scale if needed
    
    final baseTotalHNoQuote = baseHeaderFont + (baseSpacing * 3) + baseLabelFont + (baseSpacing * 2) + baseGridH;
    final widthScale = ((avW * 0.95) / baseGridW).clamp(0.1, 10.0).toDouble();
    
    // Initial scale guess (ignoring quote height for a moment)
    var scale = widthScale;
    
    // Measure text at this scale
    TextPainter? qP;
    double qH = 0.0;
    
    if (qTxt.isNotEmpty) {
      final tentativeGridW = (7 * (baseBox * scale + baseSpacing * scale)) - (baseSpacing * scale);
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
    final totalHRequired = (baseTotalHNoQuote * scale) + (qTxt.isEmpty ? 0 : (qGap + qH));
    final heightScale = ((avH * 0.95) / (totalHRequired / scale)).clamp(0.1, 10.0).toDouble();
    
    if (config.autoFitWidth) {
       // If height is the bottleneck, reduce scale
       if (heightScale < widthScale) {
          scale = heightScale;
          // Remeasure text with new scale if changed significantly
          if (qTxt.isNotEmpty) {
             final finalGridW = (7 * (baseBox * scale + baseSpacing * scale)) - (baseSpacing * scale);
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
          final finalGridW = (7 * (baseBox * scale + baseSpacing * scale)) - (baseSpacing * scale);
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
    final dayLabels = useLongLabels ? AppConstants.weekdays : _shortWeekdayLabels;
    final lbFontSize = (useLongLabels ? boxSz * 0.28 : boxSz * 0.45)
        .clamp(6.0, 11.0)
        .toDouble();
    final lbH = lbFontSize * 1.2;
    final headerFontSize = (16 * scale).clamp(8.0, 44.0).toDouble();

    // QuotePainter already created above

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
          ..color = tEx.heatmapHighlight;
    final rad = Radius.circular(config.cornerRadius * scale);
    final n = (todayUtc ?? DateTime.now().toUtc()).toUtc();
    final today = DateTime.utc(n.year, n.month, n.day);
    final txtCol =
        (config.isDarkMode ? AppTheme.lightSurface : AppTheme.lightText)
            .withValues(alpha: 0.9);
    final cntSty = TextStyle(
        color: txtCol, fontSize: boxSz * 0.45, fontWeight: FontWeight.bold);

    final textCache = <int, TextPainter>{};

    for (final c in cells) {
      final idx = c.idx + firstWeekdayOffset;
      final cnt = data.getContributionsForDate(c.date);
      final lvl =
          RenderUtils.getContributionLevel(cnt, quartiles: data.quartiles);
      final themeLevels = ThemePresets.fromId(config.themeId).levels;
      fillP.color = (themeLevels.length > lvl ? themeLevels[lvl] : themeLevels[0])
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
        var tp = textCache[cnt];
        if (tp == null) {
          tp = TextPainter(
              text: TextSpan(
                  text: '$cnt',
                  style: cntSty.copyWith(
                      shadows: [Shadow(color: Colors.black26, blurRadius: 2)])),
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              maxLines: 1)
            ..layout(maxWidth: boxSz);
          textCache[cnt] = tp;
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

// ══════════════════════════════════════════════════════════════════════════
// REUSABLE COMPONENT WIDGETS (Moved from AppTheme)
// ══════════════════════════════════════════════════════════════════════════

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const AppCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext c) {
    final theme = Theme.of(c);
    final cardTheme = theme.cardTheme;

    final card = Container(
      padding: padding ?? AppTheme.pAll20,
      decoration: BoxDecoration(
        color: cardTheme.color,
        borderRadius: (cardTheme.shape as RoundedRectangleBorder).borderRadius,
        border: Border.fromBorderSide((cardTheme.shape as RoundedRectangleBorder).side),
        boxShadow: onTap != null ? AppTheme.shadow(theme.colorScheme.shadow) : null,
      ),
      child: child,
    );
    return onTap == null ? card : GestureDetector(onTap: onTap, child: card);
  }
}

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const AppSectionHeader(
      {super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext c) {
    final s = Theme.of(c).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.plusJakartaSans(
                      color: s.onSurface,
                      fontSize: AppTheme.fontTitle,
                      fontWeight: FontWeight.w700,
                      height: AppTheme.heightTight)),
              if (subtitle != null) ...[
                AppTheme.h8,
                Text(subtitle!,
                    style: GoogleFonts.plusJakartaSans(
                        color: s.onSurface.withValues(alpha: 0.7),
                        fontSize: AppTheme.fontBody,
                        fontWeight: FontWeight.w500,
                        height: AppTheme.heightRelaxed)),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          AppTheme.w12,
          trailing!
        ],
      ],
    );
  }
}

class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? helper;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const MetricTile(
      {super.key,
      required this.label,
      required this.value,
      this.helper,
      required this.icon,
      this.iconColor,
      this.onTap});

  @override
  Widget build(BuildContext c) {
    final s = Theme.of(c).colorScheme;
    final col = iconColor ?? s.primary;
    final textScale = MediaQuery.textScalerOf(c).scale(1.0);

    return AppCard(
      padding: AppTheme.pAll12,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: col.withValues(alpha: 0.12),
              borderRadius: AppTheme.brMedium,
              border: Border.all(color: col.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: col, size: AppTheme.iconSM),
          ),
          AppTheme.w12,
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact =
                    constraints.maxHeight < 88 || textScale > 1.15;
                final isVeryTight = constraints.maxHeight < 72;
                final showHelper = helper != null && !isCompact;
                final showLabel = !isVeryTight;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                            color: s.onSurface,
                            fontSize: AppTheme.fontHeadline,
                            fontWeight: FontWeight.w800,
                            height: AppTheme.heightTight)),
                    if (showHelper) ...[
                      AppTheme.h4,
                      Text(helper!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                              color: col,
                              fontSize: AppTheme.fontCaption,
                              fontWeight: FontWeight.w700)),
                    ],
                    if (showLabel) ...[
                      AppTheme.h4,
                      Text(label,
                          maxLines: isCompact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                              color: s.onSurface.withValues(alpha: 0.7),
                              fontSize: AppTheme.fontBody,
                              fontWeight: FontWeight.w600)),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HeroMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const HeroMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext c) {
    final s = Theme.of(c).colorScheme;
    final col = color ?? s.primary;
    final isDark = Theme.of(c).brightness == Brightness.dark;

    return AppCard(
      padding: AppTheme.pZero,
      onTap: onTap,
      child: Container(
        padding: AppTheme.pAll24,
        decoration: BoxDecoration(
          borderRadius: AppTheme.brLarge,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              col.withValues(alpha: isDark ? 0.15 : 0.05),
              col.withValues(alpha: isDark ? 0.05 : 0.01),
            ],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      color: col.withValues(alpha: 0.8),
                      fontSize: AppTheme.fontCaption,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  AppTheme.h8,
                  Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      color: s.onSurface,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  if (subtitle != null) ...[
                    AppTheme.h4,
                    Text(
                      subtitle!,
                      style: GoogleFonts.plusJakartaSans(
                        color: s.onSurface.withValues(alpha: 0.6),
                        fontSize: AppTheme.fontBody,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: AppTheme.pAll16,
              decoration: BoxDecoration(
                color: col.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: col.withValues(alpha: 0.1)),
              ),
              child: Icon(icon, color: col, size: 32),
            ),
          ],
        ),
      ),
    );
  }
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
  final w = args['width'] as double,
      h = args['height'] as double,
      pr = args['pixelRatio'] as double;

  final r = ui.PictureRecorder();
  final canvas = ui.Canvas(r, ui.Rect.fromLTWH(0, 0, w * pr, h * pr));
  canvas.scale(pr);

  MonthHeatmapRenderer.render(
      canvas: canvas, size: ui.Size(w, h), data: d, config: c);

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
