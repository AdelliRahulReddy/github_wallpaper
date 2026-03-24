import 'package:flutter/foundation.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/features/wallpaper/models/theme_presets.dart';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';

String? _cleanString(dynamic value) =>
    (value is String && value.trim().isNotEmpty) ? value.trim() : null;

double _clampedDouble(dynamic value, double fallback, double min, double max) =>
    ((value is num ? value.toDouble() : fallback).clamp(min, max)).toDouble();

enum WallpaperTarget {
  home,
  lock,
  both;

  int toManagerConstant() {
    switch (this) {
      case WallpaperTarget.home:
        return WallpaperManagerPlus.homeScreen;
      case WallpaperTarget.lock:
        return WallpaperManagerPlus.lockScreen;
      case WallpaperTarget.both:
        return WallpaperManagerPlus.bothScreens;
    }
  }
}

@immutable
class WallpaperConfig {
  final bool isDarkMode;
  final bool autoFitWidth;
  final bool showQuickStatsBar;
  final bool statCurrentStreak;
  final bool statLongestStreak;
  final bool statTotalCommits;
  final bool statTopLanguage;
  final double verticalPosition;
  final double horizontalPosition;
  final double scale;
  final double opacity;
  final double quoteFontSize;
  final double quoteOpacity;
  final double cornerRadius;
  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;
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

  factory WallpaperConfig.fromJson(Map<String, dynamic> json) {
    final quote = _cleanString(json['customQuote']) ?? '';
    final sanitizedQuote = ValidationUtils.sanitizeQuote(quote);
    return WallpaperConfig(
      isDarkMode: json['isDarkMode'] == true,
      verticalPosition: _clampedDouble(json['verticalPosition'], 0.5, 0, 1),
      horizontalPosition:
          _clampedDouble(json['horizontalPosition'], 0.5, 0, 1),
      scale: _clampedDouble(
        json['scale'],
        0.7,
        AppConstants.minWallpaperScale,
        AppConstants.maxWallpaperScale,
      ),
      autoFitWidth: json['autoFitWidth'] != false,
      opacity: _clampedDouble(json['opacity'], 1.0, 0, 1),
      customQuote: sanitizedQuote.length > AppConstants.quoteMaxLength
          ? sanitizedQuote.substring(0, AppConstants.quoteMaxLength)
          : sanitizedQuote,
      quoteFontSize: _clampedDouble(json['quoteFontSize'], 14, 10, 40),
      quoteOpacity: _clampedDouble(json['quoteOpacity'], 1, 0, 1),
      cornerRadius: _clampedDouble(json['cornerRadius'], 2, 0, 20),
      paddingTop: _clampedDouble(json['paddingTop'], 0, 0, 500),
      paddingBottom: _clampedDouble(json['paddingBottom'], 0, 0, 500),
      paddingLeft: _clampedDouble(json['paddingLeft'], 0, 0, 500),
      paddingRight: _clampedDouble(json['paddingRight'], 0, 0, 500),
      themeId: (json['themeId'] is String &&
              (json['themeId'] as String).isNotEmpty)
          ? json['themeId'] as String
          : ThemePresets.defaultId,
      showQuickStatsBar: json['showQuickStatsBar'] != false,
      statCurrentStreak: json['statCurrentStreak'] != false,
      statLongestStreak: json['statLongestStreak'] != false,
      statTotalCommits: json['statTotalCommits'] != false,
      statTopLanguage: json['statTopLanguage'] != false,
      templateId: (json['templateId'] is String &&
              (json['templateId'] as String).isNotEmpty)
          ? json['templateId'] as String
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

  WallpaperConfig copyWith({
    bool? isDarkMode,
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
    String? templateId,
  }) =>
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
