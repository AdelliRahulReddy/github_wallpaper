part of 'app_models.dart';

@immutable
class WallpaperConfig {
  final bool isDarkMode, autoFitWidth;
  final bool showQuickStatsBar,
      statCurrentStreak,
      statLongestStreak,
      statTotalCommits,
      statTopLanguage;
  final double verticalPosition,
      horizontalPosition,
      scale,
      opacity,
      quoteFontSize,
      quoteOpacity,
      cornerRadius;
  final double paddingTop, paddingBottom, paddingLeft, paddingRight;
  final String customQuote;
  final String themeId;
  final String templateId;

  const WallpaperConfig({
    this.isDarkMode = false,
    this.verticalPosition = 0.5,
    this.horizontalPosition = 0.5,
    this.scale = 0.7,
    this.autoFitWidth = true,
    this.opacity = 1.0,
    this.customQuote = '',
    this.quoteFontSize = 14.0,
    this.quoteOpacity = 1.0,
    this.cornerRadius = 2.0,
    this.paddingTop = 0,
    this.paddingBottom = 0,
    this.paddingLeft = 0,
    this.paddingRight = 0,
    this.themeId = ThemePresets.defaultId,
    this.showQuickStatsBar = true,
    this.statCurrentStreak = true,
    this.statLongestStreak = true,
    this.statTotalCommits = true,
    this.statTopLanguage = true,
    this.templateId = 'minimal_dark',
  });

  factory WallpaperConfig.defaults() => const WallpaperConfig();

  factory WallpaperConfig.fromJson(Map<String, dynamic> j) {
    final q = _str(j['customQuote']) ?? '';
    final sanitizedQuote = ValidationUtils.sanitizeQuote(q);
    return WallpaperConfig(
      isDarkMode: j['isDarkMode'] == true,
      verticalPosition: _dbl(j['verticalPosition'], 0.5, 0, 1),
      horizontalPosition: _dbl(j['horizontalPosition'], 0.5, 0, 1),
      scale: _dbl(j['scale'], 0.7, AppConstants.minWallpaperScale,
          AppConstants.maxWallpaperScale),
      autoFitWidth: j['autoFitWidth'] != false,
      opacity: _dbl(j['opacity'], 1.0, 0, 1),
      customQuote: sanitizedQuote.length > AppConstants.quoteMaxLength
          ? sanitizedQuote.substring(0, AppConstants.quoteMaxLength)
          : sanitizedQuote,
      quoteFontSize: _dbl(j['quoteFontSize'], 14, 10, 40),
      quoteOpacity: _dbl(j['quoteOpacity'], 1, 0, 1),
      cornerRadius: _dbl(j['cornerRadius'], 2, 0, 20),
      paddingTop: _dbl(j['paddingTop'], 0, 0, 500),
      paddingBottom: _dbl(j['paddingBottom'], 0, 0, 500),
      paddingLeft: _dbl(j['paddingLeft'], 0, 0, 500),
      paddingRight: _dbl(j['paddingRight'], 0, 0, 500),
      themeId: (j['themeId'] is String && (j['themeId'] as String).isNotEmpty)
          ? j['themeId'] as String
          : ThemePresets.defaultId,
      showQuickStatsBar: j['showQuickStatsBar'] != false,
      statCurrentStreak: j['statCurrentStreak'] != false,
      statLongestStreak: j['statLongestStreak'] != false,
      statTotalCommits: j['statTotalCommits'] != false,
      statTopLanguage: j['statTopLanguage'] != false,
      templateId: (j['templateId'] is String && (j['templateId'] as String).isNotEmpty)
          ? j['templateId'] as String
          : 'minimal_dark',
    );
  }

  Map<String, dynamic> toJson() => {
        'isDarkMode': isDarkMode,
        'verticalPosition': verticalPosition,
        'horizontalPosition': horizontalPosition,
        'scale': scale,
        'autoFitWidth': autoFitWidth,
        'opacity': opacity,
        'customQuote': customQuote,
        'quoteFontSize': quoteFontSize,
        'quoteOpacity': quoteOpacity,
        'cornerRadius': cornerRadius,
        'paddingTop': paddingTop,
        'paddingBottom': paddingBottom,
        'paddingLeft': paddingLeft,
        'paddingRight': paddingRight,
        'themeId': themeId,
        'showQuickStatsBar': showQuickStatsBar,
        'statCurrentStreak': statCurrentStreak,
        'statLongestStreak': statLongestStreak,
        'statTotalCommits': statTotalCommits,
        'statTopLanguage': statTopLanguage,
        'templateId': templateId,
      };

  WallpaperConfig copyWith(
          {bool? isDarkMode,
          double? verticalPosition,
          double? horizontalPosition,
          double? scale,
          bool? autoFitWidth,
           double? opacity,
          String? customQuote,
          double? quoteFontSize,
          double? quoteOpacity,
          double? cornerRadius,
          double? paddingTop,
          double? paddingBottom,
          double? paddingLeft,
          double? paddingRight,
          String? themeId,
          bool? showQuickStatsBar,
          bool? statCurrentStreak,
          bool? statLongestStreak,
          bool? statTotalCommits,
          bool? statTopLanguage,
          String? templateId}) =>
      WallpaperConfig(
        isDarkMode: isDarkMode ?? this.isDarkMode,
        verticalPosition: verticalPosition ?? this.verticalPosition,
        horizontalPosition: horizontalPosition ?? this.horizontalPosition,
        scale: scale ?? this.scale,
        autoFitWidth: autoFitWidth ?? this.autoFitWidth,
        opacity: opacity ?? this.opacity,
        customQuote: customQuote ?? this.customQuote,
        quoteFontSize: quoteFontSize ?? this.quoteFontSize,
        quoteOpacity: quoteOpacity ?? this.quoteOpacity,
        cornerRadius: cornerRadius ?? this.cornerRadius,
        paddingTop: paddingTop ?? this.paddingTop,
        paddingBottom: paddingBottom ?? this.paddingBottom,
        paddingLeft: paddingLeft ?? this.paddingLeft,
        paddingRight: paddingRight ?? this.paddingRight,
        themeId: themeId ?? this.themeId,
        showQuickStatsBar: showQuickStatsBar ?? this.showQuickStatsBar,
        statCurrentStreak: statCurrentStreak ?? this.statCurrentStreak,
        statLongestStreak: statLongestStreak ?? this.statLongestStreak,
        statTotalCommits: statTotalCommits ?? this.statTotalCommits,
        statTopLanguage: statTopLanguage ?? this.statTopLanguage,
        templateId: templateId ?? this.templateId,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WallpaperConfig &&
          isDarkMode == other.isDarkMode &&
          autoFitWidth == other.autoFitWidth &&
          verticalPosition == other.verticalPosition &&
          horizontalPosition == other.horizontalPosition &&
          scale == other.scale &&
          opacity == other.opacity &&
          quoteFontSize == other.quoteFontSize &&
          quoteOpacity == other.quoteOpacity &&
          cornerRadius == other.cornerRadius &&
          paddingTop == other.paddingTop &&
          paddingBottom == other.paddingBottom &&
          paddingLeft == other.paddingLeft &&
          paddingRight == other.paddingRight &&
          themeId == other.themeId &&
          customQuote == other.customQuote &&
          showQuickStatsBar == other.showQuickStatsBar &&
          statCurrentStreak == other.statCurrentStreak &&
          statLongestStreak == other.statLongestStreak &&
          statTotalCommits == other.statTotalCommits &&
          statTopLanguage == other.statTopLanguage &&
          templateId == other.templateId);

  @override
  int get hashCode => Object.hashAll([
        isDarkMode,
        autoFitWidth,
        verticalPosition,
        horizontalPosition,
        scale,
        opacity,
        quoteFontSize,
        quoteOpacity,
        cornerRadius,
        paddingTop,
        paddingBottom,
        paddingLeft,
        paddingRight,
        themeId,
        customQuote,
        showQuickStatsBar,
        statCurrentStreak,
        statLongestStreak,
        statTotalCommits,
        statTopLanguage,
        templateId,
      ]);
}
