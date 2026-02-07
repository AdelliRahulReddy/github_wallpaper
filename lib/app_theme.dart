import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ══════════════════════════════════════════════════════════════════════════
  // CORE PALETTE
  // ══════════════════════════════════════════════════════════════════════════
  static const primaryBlue = Color(0xFF0969DA);
  static const successGreen = Color(0xFF1F883D);
  static const errorRed = Color(0xFFCF222E);
  static const warningOrange = Color(0xFF9A6700);
  static const primaryBrandAccent = Color(0xFF2E5BFF); // Formerly skyDayAccent
  static const accentViolet = Color(0xFF9D50E0);

  // ══════════════════════════════════════════════════════════════════════════
  // NEUTRAL TOKENS (GitHub-inspired)
  // ══════════════════════════════════════════════════════════════════════════
  static const lightBg = Color(0xFFF6F8FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF24292F);
  static const lightBorder = Color(0xFFD0D7DE);

  static const darkBg = Color(0xFF0D1117);
  static const darkSurface = Color(0xFF161B22);
  static const darkText = Color(0xFFC9D1D9);
  static const darkBorder = Color(0xFF30363D);

  // ══════════════════════════════════════════════════════════════════════════
  // SIZING & SPACING
  // ══════════════════════════════════════════════════════════════════════════
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusXXL = 28.0;

  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing60 = 60.0;

  // ══════════════════════════════════════════════════════════════════════════
  // TYPOGRAPHY TOKENS
  // ══════════════════════════════════════════════════════════════════════════
  static const double fontCaption = 11.0;
  static const double fontSmall = 12.0;
  static const double fontBody = 13.0; // Optimized for UI density
  static const double fontBase = 14.0;
  static const double fontMedium = 15.0;
  static const double fontLarge = 16.0;
  static const double fontTitle = 18.0;
  static const double fontHeadline = 24.0;
  static const double fontDisplay = 32.0;

  // Readability Multipliers
  static const double heightTight = 1.1; // Headings
  static const double heightRelaxed = 1.5; // Body text

  // ══════════════════════════════════════════════════════════════════════════
  // SINGLE SOURCE OF TRUTH (Theme Generation)
  // ══════════════════════════════════════════════════════════════════════════

  /// Backward compatible light theme factory
  static ThemeData lightTheme() => create(Brightness.light);

  /// Backward compatible dark theme factory
  static ThemeData darkTheme() => create(Brightness.dark);

  /// Unified Theme Builder
  static ThemeData create(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // 1. Resolve Color Scheme
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? primaryBrandAccent : primaryBlue,
      onPrimary: isDark ? darkBg : lightSurface,
      secondary: successGreen,
      onSecondary: isDark ? darkBg : lightSurface,
      error: errorRed,
      onError: isDark ? darkBg : lightSurface,
      surface: isDark ? darkSurface : lightSurface,
      onSurface: isDark ? darkText : lightText,
      surfaceContainerHighest: isDark ? darkBg : lightBg,
      outline: isDark ? darkBorder : lightBorder,
      outlineVariant: isDark
          ? darkBorder.withValues(alpha: 0.5)
          : lightBorder.withValues(alpha: 0.5),
    );

    // 2. Base Theme Setup
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      scaffoldBackgroundColor: colorScheme.surfaceContainerHighest,
    );

    // 3. Typography Configuration (Plus Jakarta Sans)
    final textTheme =
        GoogleFonts.plusJakartaSansTextTheme(baseTheme.textTheme).copyWith(
      bodyMedium: TextStyle(
        fontSize: fontBase,
        height: heightRelaxed,
        color: colorScheme.onSurface,
      ),
      bodySmall: TextStyle(
        fontSize: fontSmall,
        height: heightRelaxed,
        color: colorScheme.onSurface.withValues(alpha: 0.8),
      ),
      titleLarge: TextStyle(
        fontSize: fontTitle,
        fontWeight: FontWeight.w700,
        height: heightTight,
        color: colorScheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: fontHeadline,
        fontWeight: FontWeight.w800,
        height: heightTight,
        letterSpacing: -0.5,
        color: colorScheme.onSurface,
      ),
    );

    // 4. Component Themes & Extensions
    return baseTheme.copyWith(
      textTheme: textTheme,
      extensions: [AppThemeExt(isLight: !isDark)],

      // AppBar
      appBarTheme: baseTheme.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: colorScheme.surfaceContainerHighest,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ),
      ),

      // Navigation
      navigationBarTheme: baseTheme.navigationBarTheme.copyWith(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: fontSmall,
          ),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 1,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ══════════════════════════════════════════════════════════════════════════

  // Glass card decoration
  static BoxDecoration glassCard({double blur = 0.1, Color? tint}) =>
      BoxDecoration(
        color: (tint ?? lightSurface).withValues(alpha: blur),
        borderRadius: BorderRadius.circular(radiusLarge),
        border: Border.all(color: lightSurface.withValues(alpha: 0.2)),
      );

  // Shadow helper
  static List<BoxShadow> shadow(Color color,
          {double blur = 24.0, double spread = 0.0, double opacity = 0.15}) =>
      [
        BoxShadow(
            color: color.withValues(alpha: opacity),
            blurRadius: blur,
            spreadRadius: spread,
            offset: const Offset(0, 8))
      ];
}

// ══════════════════════════════════════════════════════════════════════════
// THEME EXTENSIONS
// ══════════════════════════════════════════════════════════════════════════

class AppThemeExt extends ThemeExtension<AppThemeExt> {
  final List<Color> heatmapLevels;
  final Color heatmapHighlight;

  AppThemeExt({required bool isLight})
      : heatmapLevels = isLight
            ? [
                const Color(0xFFEBEDF0),
                const Color(0xFF9BE9A8),
                const Color(0xFF40C463),
                const Color(0xFF30A14E),
                const Color(0xFF216E39)
              ]
            : [
                const Color(0xFF161B22),
                const Color(0xFF0E4429),
                const Color(0xFF006D32),
                const Color(0xFF26A641),
                const Color(0xFF39D353)
              ],
        heatmapHighlight = const Color(0xFFFF9500);

  AppThemeExt._raw(
      {required this.heatmapLevels, required this.heatmapHighlight});

  Color get heatmapTodayHighlight => heatmapHighlight;

  @override
  AppThemeExt copyWith({List<Color>? heatmapLevels, Color? heatmapHighlight}) =>
      AppThemeExt._raw(
        heatmapLevels: heatmapLevels ?? this.heatmapLevels,
        heatmapHighlight: heatmapHighlight ?? this.heatmapHighlight,
      );

  @override
  AppThemeExt lerp(ThemeExtension<AppThemeExt>? other, double t) {
    if (other is! AppThemeExt) return this;
    return AppThemeExt._raw(
      heatmapLevels: List.generate(
        heatmapLevels.length,
        (i) => Color.lerp(heatmapLevels[i], other.heatmapLevels[i], t)!,
      ),
      heatmapHighlight:
          Color.lerp(heatmapHighlight, other.heatmapHighlight, t)!,
    );
  }

  static AppThemeExt of(BuildContext c) =>
      Theme.of(c).extension<AppThemeExt>()!;
}

// Context extension
extension ThemeContext on BuildContext {
  AppThemeExt get appTheme => AppThemeExt.of(this);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}

// ══════════════════════════════════════════════════════════════════════════
// REUSABLE COMPONENT WIDGETS
// ══════════════════════════════════════════════════════════════════════════

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const AppCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext c) {
    final s = c.colors;
    final isDark = c.isDark;

    // Adapts transparency and borders for mode clarity
    final card = Container(
      padding: padding ?? const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: isDark
              ? s.outline.withValues(
                  alpha: 0.3) // Higher contrast border for dark mode
              : s.outline.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
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
    final s = c.colors;
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
                const SizedBox(height: AppTheme.spacing8),
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
          const SizedBox(width: AppTheme.spacing12),
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
    final s = c.colors;
    final col = iconColor ?? s.primary;

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: col.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: col.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: col, size: 20),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1.0);
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
                      const SizedBox(height: 2),
                      Text(helper!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                              color: col,
                              fontSize: AppTheme.fontCaption,
                              fontWeight: FontWeight.w700)),
                    ],
                    if (showLabel) ...[
                      const SizedBox(height: 2),
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
    final s = c.colors;
    final col = color ?? s.primary;
    final isDark = c.isDark;

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
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
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                    const SizedBox(height: 4),
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
              padding: const EdgeInsets.all(16),
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
