part of 'app_theme.dart';

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
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        elevation: 0,
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
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing12,
        ),
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
      color: colorScheme.surface,
      elevation: 0.5,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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

BoxDecoration _glassCard(BuildContext context,
    {double opacity = 0.1, Color? tint}) {
  final colors = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: (tint ?? colors.surface).withValues(alpha: opacity),
    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
    border: Border.all(color: colors.onSurface.withValues(alpha: 0.08)),
  );
}

List<BoxShadow> _shadow(Color color,
        {double blur = 12.0, double spread = 0.0, double opacity = 0.06}) =>
    [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blur,
        spreadRadius: spread,
        offset: const Offset(0, 4),
      ),
    ];
