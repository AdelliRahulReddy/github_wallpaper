part of 'app_theme.dart';

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

  // AppThemeExt contains heatmapLevels and heatmapHighlight

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
        sectionCardPadding: EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
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
      ThemeExtension<SettingsThemeTokens>? other, double t) {
    if (other is! SettingsThemeTokens) return this;
    return SettingsThemeTokens._raw(
      screenPadding:
          EdgeInsets.lerp(screenPadding, other.screenPadding, t) ?? screenPadding,
      sectionCardPadding:
          EdgeInsets.lerp(sectionCardPadding, other.sectionCardPadding, t) ??
              sectionCardPadding,
      sectionHeaderPadding:
          EdgeInsets.lerp(sectionHeaderPadding, other.sectionHeaderPadding, t) ??
              sectionHeaderPadding,
      sectionTitleOpacity:
          sectionTitleOpacity + (other.sectionTitleOpacity - sectionTitleOpacity) * t,
      subtitleOpacity: subtitleOpacity + (other.subtitleOpacity - subtitleOpacity) * t,
      chevronOpacity: chevronOpacity + (other.chevronOpacity - chevronOpacity) * t,
      chipBackgroundOpacity: chipBackgroundOpacity +
          (other.chipBackgroundOpacity - chipBackgroundOpacity) * t,
      dividerIndent: dividerIndent + (other.dividerIndent - dividerIndent) * t,
      leadingIconSize:
          leadingIconSize + (other.leadingIconSize - leadingIconSize) * t,
      profileAvatarSize:
          profileAvatarSize + (other.profileAvatarSize - profileAvatarSize) * t,
    );
  }

  static SettingsThemeTokens of(BuildContext c) =>
      Theme.of(c).extension<SettingsThemeTokens>()!;
}

// Context extension
extension ThemeContext on BuildContext {
  AppThemeExt get appTheme => AppThemeExt.of(this);
  SettingsThemeTokens get settingsTokens => SettingsThemeTokens.of(this);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}

// ══════════════════════════════════════════════════════════════════════════
// COMPONENT WIDGETS
// Moved to ui_render.dart to avoid circular dependency
// ══════════════════════════════════════════════════════════════════════════
