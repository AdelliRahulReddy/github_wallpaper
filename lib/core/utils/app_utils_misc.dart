part of 'app_utils.dart';

enum UpdateScheduleMode { autoDaily, interval }

// RENDER UTILS
class RenderUtils {
  static final _rc = <String, ui.Radius>{};
  static const _months = [
    'JANUARY',
    'FEBRUARY',
    'MARCH',
    'APRIL',
    'MAY',
    'JUNE',
    'JULY',
    'AUGUST',
    'SEPTEMBER',
    'OCTOBER',
    'NOVEMBER',
    'DECEMBER'
  ];

  static String headerTextForDate(DateTime d) =>
      '${_months[d.month - 1]} ${d.year}';

  static TextPainter drawText(ui.Canvas canvas, String text, TextStyle style,
      Offset offset, double maxWidth,
      {TextAlign textAlign = TextAlign.left,
      TextDirection textDirection = TextDirection.ltr,
      int? maxLines,
      bool paint = true}) {
    final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textAlign: textAlign,
        textDirection: textDirection,
        maxLines: maxLines)
      ..layout(maxWidth: maxWidth);
    if (paint) {
      double dx = offset.dx;
      if (textAlign == TextAlign.center) dx += (maxWidth - tp.width) / 2;
      if (textAlign == TextAlign.right) dx += maxWidth - tp.width;
      tp.paint(canvas, Offset(dx, offset.dy));
    }
    return tp;
  }

  static Quartiles calculateQuartiles(List<int> counts) {
    final nz = counts.where((c) => c > 0).toList()..sort();
    if (nz.isEmpty) {
      return Quartiles(AppConstants.intensity1, AppConstants.intensity2,
          AppConstants.intensity3);
    }
    int p(double x) => nz[(nz.length * x).ceil().clamp(0, nz.length - 1)];
    final q1 = p(0.25), q2 = p(0.5);
    final t1 = q1 > 0 ? q1 : 1,
        t2 = q2 > t1 ? q2 : t1 + 1,
        t3 = p(0.75) > t2 ? p(0.75) : t2 + 1;
    return Quartiles(t1, t2, t3);
  }

  static int getContributionLevel(int c, {Quartiles? quartiles}) {
    if (c == 0) return 0;
    final b = quartiles ??
        Quartiles(AppConstants.intensity1, AppConstants.intensity2,
            AppConstants.intensity3);
    if (c <= b.q1) return 1;
    if (c <= b.q2) return 2;
    if (c <= b.q3) return 3;
    return 4;
  }

  static ui.Radius getCachedRadius(double r, double s) =>
      _rc.putIfAbsent('${r}_$s', () => Radius.circular(r * s));
  static void clearCaches() => _rc.clear();
}

class AppDateUtils {
  static String formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime? parseDate(String? s) {
    if (s == null) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s);
    return m != null
        ? DateTime.utc(int.parse(m.group(1)!), int.parse(m.group(2)!),
                int.parse(m.group(3)!))
            .toLocal()
        : DateTime.tryParse(s)?.toLocal();
  }
}

class AppColorUtils {
  static Color? parseHexColor(String? hex) {
    if (hex == null) return null;
    final cleaned = hex.trim();
    if (cleaned.isEmpty) return null;
    final normalized = cleaned.startsWith('#') ? cleaned.substring(1) : cleaned;
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return null;
    if (normalized.length == 6) {
      return Color(0xFF000000 | value);
    }
    if (normalized.length == 8) {
      return Color(value);
    }
    return null;
  }
}

class Quartiles {
  final int q1, q2, q3;
  const Quartiles(this.q1, this.q2, this.q3);
}
