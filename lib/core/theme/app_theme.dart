import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'app_theme_factory.dart';
part 'app_theme_extensions.dart';

class AppTheme {
  // ══════════════════════════════════════════════════════════════════════════
  // CORE PALETTE
  // ══════════════════════════════════════════════════════════════════════════
  static const primaryBlue = Color(0xFF0969DA);
  static const successGreen = Color(0xFF1F883D);
  static const errorRed = Color(0xFFCF222E);
  static const warningOrange = Color(0xFF9A6700);
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

  static const double spacing6 = 6.0;
  static const double spacing8 = 8.0;
  static const double spacing10 = 10.0;
  static const double spacing12 = 12.0;
  static const double spacing14 = 14.0;
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
  static const double homeAppBarBaseHeight = spacing8 * 8;
  static const double homeAvatarSize = spacing8 * 5;
  static const double borderWidthHairline = 1.0;

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
  // CONVENIENCE TOKENS (SizedBox, Padding, Radius, Animation)
  // ══════════════════════════════════════════════════════════════════════════

  // Durations
  static const durationFast = Duration(milliseconds: 150);
  static const durationNormal = Duration(milliseconds: 250);
  static const durationSlow = Duration(milliseconds: 350);

  // Spacing (Vertical)
  static const h2 = SizedBox(height: 2.0);
  static const h4 = SizedBox(height: 4.0);
  static const h6 = SizedBox(height: 6.0);
  static const h8 = SizedBox(height: spacing8);
  static const h10 = SizedBox(height: spacing10);
  static const h12 = SizedBox(height: spacing12);
  static const h14 = SizedBox(height: spacing14);
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
  static const w6 = SizedBox(width: 6.0);
  static const w8 = SizedBox(width: spacing8);
  static const w10 = SizedBox(width: spacing10);
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
  static const pSymH20V12 =
      EdgeInsets.symmetric(horizontal: spacing20, vertical: spacing12);

  static const pSymH32V16 =
      EdgeInsets.symmetric(horizontal: spacing32, vertical: spacing16);
  static const pSymH24V16 =
      EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing16);
  static const pSymH20V16 =
      EdgeInsets.symmetric(horizontal: spacing20, vertical: spacing16);

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
  static const pLTRB20_16_20_32 =
      EdgeInsets.fromLTRB(spacing20, spacing16, spacing20, spacing32);

  // Smart Device Padding
  static EdgeInsets pagePadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w > 600) return const EdgeInsets.all(spacing40);
    if (w > 400) return const EdgeInsets.all(spacing24);
    return const EdgeInsets.all(spacing20);
  }

  static EdgeInsets pagePaddingTop(BuildContext context) =>
      pagePadding(context).copyWith(bottom: 0);

  // Radius (Consolidated)
  static final brSmall = BorderRadius.circular(radiusSmall);
  static final brMedium = BorderRadius.circular(radiusMedium);
  static final brLarge = BorderRadius.circular(radiusLarge);
  static final brXL = BorderRadius.circular(radiusXL);
  static final brXXL = BorderRadius.circular(radiusXXL);
  static final brXS = BorderRadius.circular(radiusSmall / 3);
  static final brVertLarge =
      const BorderRadius.vertical(top: Radius.circular(radiusLarge));
  static final brVertMedium =
      const BorderRadius.vertical(top: Radius.circular(radiusMedium));

  // ══════════════════════════════════════════════════════════════════════════
  // SINGLE SOURCE OF TRUTH (Theme Generation)
  // ══════════════════════════════════════════════════════════════════════════

  /// Backward compatible light theme factory
  static ThemeData lightTheme() => create(Brightness.light);

  /// Backward compatible dark theme factory
  static ThemeData darkTheme() => create(Brightness.dark);

  /// Unified Theme Builder
  static ThemeData create(Brightness brightness) => _createTheme(brightness);

  // ??????????????????????????????????????????????????????????????????????????
  // HELPER METHODS
  // ??????????????????????????????????????????????????????????????????????????

  static BoxDecoration glassCard(BuildContext context,
          {double opacity = 0.1, Color? tint}) =>
      _glassCard(context, opacity: opacity, tint: tint);

  static List<BoxShadow> shadow(Color color,
          {double blur = 12.0, double spread = 0.0, double opacity = 0.06}) =>
      _shadow(color, blur: blur, spread: spread, opacity: opacity);
}
