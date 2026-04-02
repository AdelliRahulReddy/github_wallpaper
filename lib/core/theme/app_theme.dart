import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  static BoxDecoration surfaceDecoration(
    BuildContext context, {
    AppSurfaceTone tone = AppSurfaceTone.standard,
    Color? accent,
  }) =>
      _surfaceDecoration(context, tone: tone, accent: accent);

  static ButtonStyle outlinedActionStyle(
    BuildContext context, {
    bool compact = false,
  }) =>
      _outlinedActionStyle(context, compact: compact);

  static ButtonStyle ghostActionStyle(
    BuildContext context, {
    Color? color,
    bool compact = false,
  }) =>
      _ghostActionStyle(context, color: color, compact: compact);

  static ButtonStyle primaryActionStyle(
    BuildContext context, {
    bool compact = false,
  }) =>
      _primaryActionStyle(context, compact: compact);
}

ThemeData _createTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  const neoGreen = Color(0xFF39D353);
  final baseScheme =
      ColorScheme.fromSeed(seedColor: neoGreen, brightness: brightness);
  final colorScheme = isDark
      ? baseScheme.copyWith(
          primary: neoGreen,
          onPrimary: const Color(0xFF06120A),
          secondary: const Color(0xFF9B5CFF),
          tertiary: const Color(0xFFFFB020),
          surface: const Color(0xFF0B0F0C),
          surfaceContainerLowest: const Color(0xFF070B08),
          surfaceContainerLow: const Color(0xFF0B100C),
          surfaceContainer: const Color(0xFF0F1511),
          surfaceContainerHigh: const Color(0xFF121A15),
          surfaceContainerHighest: const Color(0xFF162019),
          outline: const Color(0xFF2A3A31),
          outlineVariant: const Color(0xFF1F2B23),
          onSurface: const Color(0xFFEAF4ED),
          onSurfaceVariant: const Color(0xFFA9B7AE),
          shadow: const Color(0xFF000000),
        )
      : baseScheme.copyWith(
          primary: neoGreen,
          onPrimary: const Color(0xFF06120A),
          secondary: const Color(0xFF6D28D9),
          tertiary: const Color(0xFFB45309),
          outlineVariant: const Color(0xFFE3E7E4),
        );

  final baseTheme = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
  );

  final scaffoldBg = colorScheme.surfaceContainerLowest;
  final dividerColor = colorScheme.outlineVariant;

  final textTheme = baseTheme.textTheme.copyWith(
    titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
      fontSize: 25,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: -0.2,
    ),
    titleMedium: baseTheme.textTheme.titleMedium?.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: -0.1,
    ),
    titleSmall: baseTheme.textTheme.titleSmall?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: 0.0,
    ),
    bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.4,
      letterSpacing: 0.0,
    ),
    bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.4,
      letterSpacing: 0.0,
    ),
    bodySmall: baseTheme.textTheme.bodySmall?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.35,
      letterSpacing: 0.0,
    ),
    labelSmall: baseTheme.textTheme.labelSmall?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0.2,
    ),
  );

  return baseTheme.copyWith(
    scaffoldBackgroundColor: scaffoldBg,
    dividerColor: dividerColor,
    cardColor: colorScheme.surface,
    textTheme: textTheme,
    iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
    extensions: [
      AppThemeExt(isLight: !isDark),
      AppSurfaceTokens.standard(),
      SettingsThemeTokens.standard(),
    ],
    appBarTheme: baseTheme.appBarTheme.copyWith(
      backgroundColor: scaffoldBg,
      surfaceTintColor: scaffoldBg,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: scaffoldBg,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: scaffoldBg,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    ),
    navigationBarTheme: baseTheme.navigationBarTheme.copyWith(
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.secondaryContainer,
      labelTextStyle: WidgetStateProperty.all(textTheme.labelSmall),
    ),
    dividerTheme: DividerThemeData(
      color: dividerColor,
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: BorderSide(color: dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      labelStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        fontSize: 13,
        letterSpacing: 0.2,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        elevation: 0,
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing12,
        ),
        textStyle: textTheme.titleSmall,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        elevation: 0,
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing12,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing12,
        ),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: isDark ? 0.38 : 0.32),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        textStyle: textTheme.titleSmall,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.onSurfaceVariant,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        textStyle: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    chipTheme: baseTheme.chipTheme.copyWith(
      backgroundColor: colorScheme.surfaceContainerHigh,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      labelStyle: textTheme.labelSmall?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing10,
        vertical: 0,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbIcon: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Icon(Icons.check_rounded, size: 14);
        }
        return const Icon(Icons.close_rounded, size: 14);
      }),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surface,
      modalBackgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      elevation: 1,
    ),
    cardTheme: CardThemeData(
      color: isDark ? colorScheme.surfaceContainerLow : colorScheme.surface,
      elevation: 0,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: isDark ? 0.24 : 0.14),
        ),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      minLeadingWidth: AppTheme.iconMD,
      titleTextStyle: textTheme.bodyMedium,
      iconColor: colorScheme.primary,
    ),
  );
}

BoxDecoration _glassCard(
  BuildContext context, {
  double opacity = 0.1,
  Color? tint,
}) {
  final colors = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: (tint ?? colors.surface).withValues(alpha: opacity),
    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
    border: Border.all(color: colors.onSurface.withValues(alpha: 0.08)),
  );
}

List<BoxShadow> _shadow(
  Color color, {
  double blur = 12.0,
  double spread = 0.0,
  double opacity = 0.06,
}) =>
    [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blur,
        spreadRadius: spread,
        offset: const Offset(0, 4),
      ),
    ];

enum AppSurfaceTone {
  standard,
  muted,
  emphasized,
  glass,
  poster,
}

BoxDecoration _surfaceDecoration(
  BuildContext context, {
  AppSurfaceTone tone = AppSurfaceTone.standard,
  Color? accent,
}) {
  final colors = Theme.of(context).colorScheme;
  final tokens = AppSurfaceTokens.of(context);
  final accentColor = accent ?? colors.primary;
  final color = switch (tone) {
    AppSurfaceTone.standard => colors.surface,
    AppSurfaceTone.muted => colors.surfaceContainerLow,
    AppSurfaceTone.emphasized =>
      colors.surfaceContainerHigh.withValues(alpha: 0.92),
    AppSurfaceTone.glass =>
      colors.surface.withValues(alpha: tokens.glassFillOpacity),
    AppSurfaceTone.poster => colors.surfaceContainerHighest.withValues(
        alpha: 0.96,
      ),
  };
  final borderColor = switch (tone) {
    AppSurfaceTone.poster => accentColor.withValues(
        alpha: tokens.accentStrokeOpacity,
      ),
    AppSurfaceTone.emphasized => colors.outline.withValues(
        alpha: tokens.strongStrokeOpacity,
      ),
    AppSurfaceTone.glass => colors.outline.withValues(
        alpha: tokens.standardStrokeOpacity,
      ),
    AppSurfaceTone.standard ||
    AppSurfaceTone.muted =>
      colors.outline.withValues(alpha: tokens.subtleStrokeOpacity),
  };
  final radius = switch (tone) {
    AppSurfaceTone.poster => tokens.posterRadius,
    AppSurfaceTone.standard ||
    AppSurfaceTone.muted ||
    AppSurfaceTone.emphasized ||
    AppSurfaceTone.glass =>
      tokens.panelRadius,
  };

  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor),
    boxShadow: [
      BoxShadow(
        color: colors.shadow.withValues(alpha: tokens.shadowOpacity),
        blurRadius: tone == AppSurfaceTone.poster ? 28 : 18,
        spreadRadius: tone == AppSurfaceTone.poster ? -6 : -8,
        offset: Offset(0, tone == AppSurfaceTone.poster ? 18 : 10),
      ),
    ],
    gradient: tone == AppSurfaceTone.poster
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withValues(alpha: 0.98),
              accentColor.withValues(alpha: 0.06),
            ],
          )
        : null,
  );
}

ButtonStyle _primaryActionStyle(
  BuildContext context, {
  bool compact = false,
}) {
  final theme = Theme.of(context);
  return theme.filledButtonTheme.style!.copyWith(
    minimumSize: WidgetStatePropertyAll(
      Size.fromHeight(compact ? 40 : 48),
    ),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(
        horizontal: compact ? AppTheme.spacing12 : AppTheme.spacing16,
        vertical: compact ? AppTheme.spacing10 : AppTheme.spacing12,
      ),
    ),
  );
}

ButtonStyle _outlinedActionStyle(
  BuildContext context, {
  bool compact = false,
}) {
  final theme = Theme.of(context);
  return theme.outlinedButtonTheme.style!.copyWith(
    minimumSize: WidgetStatePropertyAll(
      Size.fromHeight(compact ? 40 : 48),
    ),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(
        horizontal: compact ? AppTheme.spacing12 : AppTheme.spacing16,
        vertical: compact ? AppTheme.spacing10 : AppTheme.spacing12,
      ),
    ),
  );
}

ButtonStyle _ghostActionStyle(
  BuildContext context, {
  Color? color,
  bool compact = false,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  return theme.textButtonTheme.style!.copyWith(
    foregroundColor: WidgetStatePropertyAll(color ?? scheme.onSurfaceVariant),
    minimumSize: WidgetStatePropertyAll(
      Size(0, compact ? 36 : 40),
    ),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(
        horizontal: compact ? AppTheme.spacing10 : AppTheme.spacing12,
        vertical: compact ? AppTheme.spacing8 : AppTheme.spacing10,
      ),
    ),
  );
}

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
                const Color(0xFF216E39),
              ]
            : [
                const Color(0xFF161B22),
                const Color(0xFF0E4429),
                const Color(0xFF006D32),
                const Color(0xFF26A641),
                const Color(0xFF39D353),
              ],
        heatmapHighlight = const Color(0xFFFF9500);

  AppThemeExt._raw({
    required this.heatmapLevels,
    required this.heatmapHighlight,
  });

  @override
  AppThemeExt copyWith({
    List<Color>? heatmapLevels,
    Color? heatmapHighlight,
  }) =>
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
        (index) => Color.lerp(
          heatmapLevels[index],
          other.heatmapLevels[index],
          t,
        )!,
      ),
      heatmapHighlight:
          Color.lerp(heatmapHighlight, other.heatmapHighlight, t)!,
    );
  }

  static AppThemeExt of(BuildContext context) =>
      Theme.of(context).extension<AppThemeExt>()!;
}

class AppSurfaceTokens extends ThemeExtension<AppSurfaceTokens> {
  final double contentMaxWidth;
  final double panelRadius;
  final double posterRadius;
  final double subtleStrokeOpacity;
  final double standardStrokeOpacity;
  final double strongStrokeOpacity;
  final double accentStrokeOpacity;
  final double shadowOpacity;
  final double glassFillOpacity;
  final EdgeInsets panelPadding;
  final EdgeInsets heroPadding;
  final double sectionGap;
  final double compactGap;
  final double buttonHeight;

  const AppSurfaceTokens._raw({
    required this.contentMaxWidth,
    required this.panelRadius,
    required this.posterRadius,
    required this.subtleStrokeOpacity,
    required this.standardStrokeOpacity,
    required this.strongStrokeOpacity,
    required this.accentStrokeOpacity,
    required this.shadowOpacity,
    required this.glassFillOpacity,
    required this.panelPadding,
    required this.heroPadding,
    required this.sectionGap,
    required this.compactGap,
    required this.buttonHeight,
  });

  factory AppSurfaceTokens.standard() => const AppSurfaceTokens._raw(
        contentMaxWidth: 1120,
        panelRadius: AppTheme.radiusLarge,
        posterRadius: AppTheme.radiusXL,
        subtleStrokeOpacity: 0.12,
        standardStrokeOpacity: 0.18,
        strongStrokeOpacity: 0.26,
        accentStrokeOpacity: 0.20,
        shadowOpacity: 0.08,
        glassFillOpacity: 0.74,
        panelPadding: EdgeInsets.all(AppTheme.spacing20),
        heroPadding: EdgeInsets.all(AppTheme.spacing24),
        sectionGap: AppTheme.spacing16,
        compactGap: AppTheme.spacing12,
        buttonHeight: 48,
      );

  EdgeInsets pagePaddingFor(double width) {
    if (width >= 1100) {
      return const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing32,
        vertical: AppTheme.spacing20,
      );
    }
    if (width >= 700) {
      return const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing24,
        vertical: AppTheme.spacing20,
      );
    }
    return const EdgeInsets.symmetric(
      horizontal: AppTheme.spacing16,
      vertical: AppTheme.spacing16,
    );
  }

  @override
  AppSurfaceTokens copyWith({
    double? contentMaxWidth,
    double? panelRadius,
    double? posterRadius,
    double? subtleStrokeOpacity,
    double? standardStrokeOpacity,
    double? strongStrokeOpacity,
    double? accentStrokeOpacity,
    double? shadowOpacity,
    double? glassFillOpacity,
    EdgeInsets? panelPadding,
    EdgeInsets? heroPadding,
    double? sectionGap,
    double? compactGap,
    double? buttonHeight,
  }) =>
      AppSurfaceTokens._raw(
        contentMaxWidth: contentMaxWidth ?? this.contentMaxWidth,
        panelRadius: panelRadius ?? this.panelRadius,
        posterRadius: posterRadius ?? this.posterRadius,
        subtleStrokeOpacity: subtleStrokeOpacity ?? this.subtleStrokeOpacity,
        standardStrokeOpacity:
            standardStrokeOpacity ?? this.standardStrokeOpacity,
        strongStrokeOpacity: strongStrokeOpacity ?? this.strongStrokeOpacity,
        accentStrokeOpacity: accentStrokeOpacity ?? this.accentStrokeOpacity,
        shadowOpacity: shadowOpacity ?? this.shadowOpacity,
        glassFillOpacity: glassFillOpacity ?? this.glassFillOpacity,
        panelPadding: panelPadding ?? this.panelPadding,
        heroPadding: heroPadding ?? this.heroPadding,
        sectionGap: sectionGap ?? this.sectionGap,
        compactGap: compactGap ?? this.compactGap,
        buttonHeight: buttonHeight ?? this.buttonHeight,
      );

  @override
  AppSurfaceTokens lerp(ThemeExtension<AppSurfaceTokens>? other, double t) {
    if (other is! AppSurfaceTokens) return this;
    return AppSurfaceTokens._raw(
      contentMaxWidth:
          contentMaxWidth + (other.contentMaxWidth - contentMaxWidth) * t,
      panelRadius: panelRadius + (other.panelRadius - panelRadius) * t,
      posterRadius: posterRadius + (other.posterRadius - posterRadius) * t,
      subtleStrokeOpacity: subtleStrokeOpacity +
          (other.subtleStrokeOpacity - subtleStrokeOpacity) * t,
      standardStrokeOpacity: standardStrokeOpacity +
          (other.standardStrokeOpacity - standardStrokeOpacity) * t,
      strongStrokeOpacity: strongStrokeOpacity +
          (other.strongStrokeOpacity - strongStrokeOpacity) * t,
      accentStrokeOpacity: accentStrokeOpacity +
          (other.accentStrokeOpacity - accentStrokeOpacity) * t,
      shadowOpacity: shadowOpacity + (other.shadowOpacity - shadowOpacity) * t,
      glassFillOpacity:
          glassFillOpacity + (other.glassFillOpacity - glassFillOpacity) * t,
      panelPadding:
          EdgeInsets.lerp(panelPadding, other.panelPadding, t) ?? panelPadding,
      heroPadding:
          EdgeInsets.lerp(heroPadding, other.heroPadding, t) ?? heroPadding,
      sectionGap: sectionGap + (other.sectionGap - sectionGap) * t,
      compactGap: compactGap + (other.compactGap - compactGap) * t,
      buttonHeight: buttonHeight + (other.buttonHeight - buttonHeight) * t,
    );
  }

  static AppSurfaceTokens of(BuildContext context) =>
      Theme.of(context).extension<AppSurfaceTokens>()!;
}

class SettingsThemeTokens extends ThemeExtension<SettingsThemeTokens> {
  final EdgeInsets screenPadding;
  final EdgeInsets sectionCardPadding;
  final EdgeInsets sectionHeaderPadding;
  final double sectionTitleOpacity;
  final double subtitleOpacity;
  final double chevronOpacity;
  final double chipBackgroundOpacity;
  final double dividerIndent;
  final double leadingIconSize;
  final double profileAvatarSize;

  const SettingsThemeTokens._raw({
    required this.screenPadding,
    required this.sectionCardPadding,
    required this.sectionHeaderPadding,
    required this.sectionTitleOpacity,
    required this.subtitleOpacity,
    required this.chevronOpacity,
    required this.chipBackgroundOpacity,
    required this.dividerIndent,
    required this.leadingIconSize,
    required this.profileAvatarSize,
  });

  factory SettingsThemeTokens.standard() => const SettingsThemeTokens._raw(
        screenPadding: EdgeInsets.symmetric(vertical: AppTheme.spacing16),
        sectionCardPadding:
            EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
        sectionHeaderPadding: EdgeInsets.only(
          left: AppTheme.spacing16,
          top: AppTheme.spacing20,
          bottom: 6,
        ),
        sectionTitleOpacity: 0.55,
        subtitleOpacity: 0.55,
        chevronOpacity: 0.35,
        chipBackgroundOpacity: 0.12,
        dividerIndent: 56,
        leadingIconSize: AppTheme.iconMD,
        profileAvatarSize: 40,
      );

  @override
  SettingsThemeTokens copyWith({
    EdgeInsets? screenPadding,
    EdgeInsets? sectionCardPadding,
    EdgeInsets? sectionHeaderPadding,
    double? sectionTitleOpacity,
    double? subtitleOpacity,
    double? chevronOpacity,
    double? chipBackgroundOpacity,
    double? dividerIndent,
    double? leadingIconSize,
    double? profileAvatarSize,
  }) =>
      SettingsThemeTokens._raw(
        screenPadding: screenPadding ?? this.screenPadding,
        sectionCardPadding: sectionCardPadding ?? this.sectionCardPadding,
        sectionHeaderPadding: sectionHeaderPadding ?? this.sectionHeaderPadding,
        sectionTitleOpacity: sectionTitleOpacity ?? this.sectionTitleOpacity,
        subtitleOpacity: subtitleOpacity ?? this.subtitleOpacity,
        chevronOpacity: chevronOpacity ?? this.chevronOpacity,
        chipBackgroundOpacity:
            chipBackgroundOpacity ?? this.chipBackgroundOpacity,
        dividerIndent: dividerIndent ?? this.dividerIndent,
        leadingIconSize: leadingIconSize ?? this.leadingIconSize,
        profileAvatarSize: profileAvatarSize ?? this.profileAvatarSize,
      );

  @override
  SettingsThemeTokens lerp(
    ThemeExtension<SettingsThemeTokens>? other,
    double t,
  ) {
    if (other is! SettingsThemeTokens) return this;
    return SettingsThemeTokens._raw(
      screenPadding: EdgeInsets.lerp(screenPadding, other.screenPadding, t) ??
          screenPadding,
      sectionCardPadding:
          EdgeInsets.lerp(sectionCardPadding, other.sectionCardPadding, t) ??
              sectionCardPadding,
      sectionHeaderPadding: EdgeInsets.lerp(
              sectionHeaderPadding, other.sectionHeaderPadding, t) ??
          sectionHeaderPadding,
      sectionTitleOpacity: sectionTitleOpacity +
          (other.sectionTitleOpacity - sectionTitleOpacity) * t,
      subtitleOpacity:
          subtitleOpacity + (other.subtitleOpacity - subtitleOpacity) * t,
      chevronOpacity:
          chevronOpacity + (other.chevronOpacity - chevronOpacity) * t,
      chipBackgroundOpacity: chipBackgroundOpacity +
          (other.chipBackgroundOpacity - chipBackgroundOpacity) * t,
      dividerIndent: dividerIndent + (other.dividerIndent - dividerIndent) * t,
      leadingIconSize:
          leadingIconSize + (other.leadingIconSize - leadingIconSize) * t,
      profileAvatarSize:
          profileAvatarSize + (other.profileAvatarSize - profileAvatarSize) * t,
    );
  }

  static SettingsThemeTokens of(BuildContext context) =>
      Theme.of(context).extension<SettingsThemeTokens>()!;
}

extension ThemeContext on BuildContext {
  AppThemeExt get appTheme => AppThemeExt.of(this);
  AppSurfaceTokens get surfaceTokens => AppSurfaceTokens.of(this);
  SettingsThemeTokens get settingsTokens => SettingsThemeTokens.of(this);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}
