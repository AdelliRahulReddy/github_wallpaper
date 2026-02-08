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
  static const double iconXS = 16.0;
  static const double iconSM = 20.0;
  static const double iconMD = 24.0;
  static const double iconLG = 32.0;

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
  static const double heatmapHeight = 200.0;
  static const double barHeight = 12.0;

  // Readability Multipliers
  static const double heightTight = 1.1; // Headings
  static const double heightRelaxed = 1.5; // Body text

  // ══════════════════════════════════════════════════════════════════════════
  // CONVENIENCE TOKENS (SizedBox, Padding, Radius)
  // ══════════════════════════════════════════════════════════════════════════

  // Spacing (Vertical)
  static const h2 = SizedBox(height: 2.0);
  static const h4 = SizedBox(height: 4.0);
  static const h8 = SizedBox(height: spacing8);
  static const h12 = SizedBox(height: spacing12);
  static const h16 = SizedBox(height: spacing16);
  static const h20 = SizedBox(height: spacing20);
  static const h24 = SizedBox(height: spacing24);
  static const h28 = SizedBox(height: 28.0);
  static const h32 = SizedBox(height: spacing32);
  static const h40 = SizedBox(height: spacing40);
  static const h48 = SizedBox(height: spacing48);
  static const h60 = SizedBox(height: spacing60);
  static const h80 = SizedBox(height: 80.0);
  static const h140 = SizedBox(height: 140.0);
  static const h200 = SizedBox(height: 200.0);

  // Spacing (Horizontal)
  static const w4 = SizedBox(width: 4.0);
  static const w8 = SizedBox(width: spacing8);
  static const w12 = SizedBox(width: spacing12);
  static const w16 = SizedBox(width: spacing16);
  static const w20 = SizedBox(width: spacing20);
  static const w24 = SizedBox(width: spacing24);
  static const w32 = SizedBox(width: spacing32);
  static const w28 = SizedBox(width: 28.0);

  // Padding
  static const pAll4 = EdgeInsets.all(4.0);
  static const pAll8 = EdgeInsets.all(spacing8);
  static const pAll12 = EdgeInsets.all(spacing12);
  static const pAll16 = EdgeInsets.all(spacing16);
  static const pAll20 = EdgeInsets.all(spacing20);
  static const pAll24 = EdgeInsets.all(spacing24);
  static const pAll32 = EdgeInsets.all(spacing32);
  static const pAll40 = EdgeInsets.all(spacing40);

  static const pSymH12 = EdgeInsets.symmetric(horizontal: spacing12);
  static const pSymH16 = EdgeInsets.symmetric(horizontal: spacing16);
  static const pSymH20 = EdgeInsets.symmetric(horizontal: spacing20);
  static const pSymH24 = EdgeInsets.symmetric(horizontal: spacing24);
  static const pSymH32 = EdgeInsets.symmetric(horizontal: spacing32);
  static const pSymH40 = EdgeInsets.symmetric(horizontal: spacing40);

  static const pSymV8 = EdgeInsets.symmetric(vertical: spacing8);
  static const pSymV12 = EdgeInsets.symmetric(vertical: spacing12);
  static const pSymV16 = EdgeInsets.symmetric(vertical: spacing16);
  static const pSymV20 = EdgeInsets.symmetric(vertical: spacing20);
  static const pSymV24 = EdgeInsets.symmetric(vertical: spacing24);
  static const pSymH20V12 = EdgeInsets.symmetric(horizontal: spacing20, vertical: spacing12);

  static const pSymH32V16 = EdgeInsets.symmetric(horizontal: spacing32, vertical: spacing16);
  static const pSymH24V16 = EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing16);
  static const pSymH20V16 = EdgeInsets.symmetric(horizontal: spacing20, vertical: spacing16);

  static const pOnlyB4 = EdgeInsets.only(bottom: 4.0);
  static const pOnlyB8 = EdgeInsets.only(bottom: spacing8);
  static const pOnlyB12 = EdgeInsets.only(bottom: spacing12);
  static const pOnlyB16 = EdgeInsets.only(bottom: spacing16);
  static const pOnlyB20 = EdgeInsets.only(bottom: spacing20);
  static const pOnlyB24 = EdgeInsets.only(bottom: spacing24);
  static const pOnlyB32 = EdgeInsets.only(bottom: spacing32);

  static const pOnlyR4 = EdgeInsets.only(right: 4.0);
  static const pOnlyR12 = EdgeInsets.only(right: spacing12);
  static const pOnlyT8B12 = EdgeInsets.only(top: spacing8, bottom: spacing12);
  static const pOnlyT16 = EdgeInsets.only(top: spacing16);
  static const pZero = EdgeInsets.zero;
  static const pLTRB20_16_20_32 = EdgeInsets.fromLTRB(spacing20, spacing16, spacing20, spacing32);

  // Radius
  static final brSmall = BorderRadius.circular(radiusSmall);
  static final brMedium = BorderRadius.circular(radiusMedium);
  static final brLarge = BorderRadius.circular(radiusLarge);
  static final brXL = BorderRadius.circular(radiusXL);
  static final brXXL = BorderRadius.circular(radiusXXL);
  static final brVertLarge = const BorderRadius.vertical(top: Radius.circular(radiusLarge));
  static final brVertMedium = const BorderRadius.vertical(top: Radius.circular(radiusMedium));
  static final brXS = BorderRadius.circular(radiusSmall / 3);

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
      tertiary: accentViolet,
      onTertiary: Colors.white,
      surfaceTint: isDark ? primaryBrandAccent : primaryBlue,
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

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: spacing16, vertical: spacing20 - 2),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
            borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.45))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
            borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.4), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
            borderSide: BorderSide(color: errorRed.withValues(alpha: 0.2))),
        hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.35)),
        labelStyle: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.45),
            fontWeight: FontWeight.w800,
            fontSize: fontCaption,
            letterSpacing: 1.5),
      ),

      // Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
          elevation: 4,
          shadowColor: colorScheme.primary.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing16),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: fontLarge),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing16),
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? darkSurface : lightSurface,
        contentTextStyle: TextStyle(color: colorScheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
        elevation: 6,
      ),

      // Card
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
            side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.55))),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ══════════════════════════════════════════════════════════════════════════

  // Glass card decoration - Context aware
  static BoxDecoration glassCard(BuildContext context, {double opacity = 0.1, Color? tint}) {
    final colors = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: (tint ?? colors.surface).withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(radiusLarge),
      border: Border.all(color: colors.onSurface.withValues(alpha: 0.08)),
    );
  }

  // Shadow helper
  static List<BoxShadow> shadow(Color color,
          {double blur = 24.0, double spread = 0.0, double opacity = 0.12}) =>
      [
        BoxShadow(
            color: color.withValues(alpha: opacity),
            blurRadius: blur,
            spreadRadius: spread,
            offset: const Offset(0, 6))
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
// COMPONENT WIDGETS
// Moved to ui_render.dart to avoid circular dependency
// ══════════════════════════════════════════════════════════════════════════
