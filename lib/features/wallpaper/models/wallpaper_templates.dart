import 'package:flutter/material.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';

@immutable
class WallpaperTemplate {
  final String id;
  final String label;
  final String emoji;
  final String description;
  final bool seedQuoteIfEmpty;
  final WallpaperConfig Function(WallpaperConfig base) apply;

  const WallpaperTemplate({
    required this.id,
    required this.label,
    required this.emoji,
    required this.description,
    this.seedQuoteIfEmpty = false,
    required this.apply,
  });
}

class WallpaperTemplates {
  static String canonicalId(String? id) => switch (id) {
        'quiet_grid_premium' => 'quiet_grid_home',
        _ => id ?? all.first.id,
      };

  static const List<WallpaperTemplate> all = [
    WallpaperTemplate(
      id: 'minimal_dark',
      label: 'Minimal Dark',
      emoji: '⬛',
      description: 'Sparse grid, subtle corners, no quote.',
      apply: _minimalDark,
    ),
    WallpaperTemplate(
      id: 'code_centric',
      label: 'Code Centric',
      emoji: '💻',
      description: 'Balanced layout with a grid-first focus.',
      seedQuoteIfEmpty: true,
      apply: _codeCentric,
    ),
    WallpaperTemplate(
      id: 'heatmap_hero_lite',
      label: 'Heatmap Hero Lite',
      emoji: '🟩',
      description: 'Poster-style composition with stronger grid emphasis.',
      apply: _heatmapHeroLite,
    ),
    WallpaperTemplate(
      id: 'large_quote',
      label: 'Large Quote',
      emoji: '📝',
      description: 'Quote-forward layout with more breathing room.',
      seedQuoteIfEmpty: true,
      apply: _largeQuote,
    ),
    WallpaperTemplate(
      id: 'dracula_pop',
      label: 'Dracula Pop',
      emoji: '🧛',
      description: 'Power density with a bold stats-led look.',
      apply: _draculaPop,
    ),
    WallpaperTemplate(
      id: 'heatmap_hero',
      label: 'Heatmap Hero',
      emoji: '🔥',
      description: 'Bold lock-screen poster with heatmap priority.',
      apply: _heatmapHero,
    ),
    WallpaperTemplate(
      id: 'streak_poster',
      label: 'Streak Poster',
      emoji: '⚡',
      description: 'Milestone-first composition with stronger proof styling.',
      apply: _streakPoster,
    ),
    WallpaperTemplate(
      id: 'momentum_card',
      label: 'Momentum Card',
      emoji: '📈',
      description: 'Balanced layout with richer insight emphasis.',
      apply: _momentumCard,
    ),
    WallpaperTemplate(
      id: 'quiet_grid_home',
      label: 'Quiet Grid Home',
      emoji: '🌌',
      description: 'Calmer home-screen composition with icon-safe spacing.',
      apply: _quietGridHome,
    ),
    WallpaperTemplate(
      id: 'monochrome',
      label: 'Monochrome',
      emoji: '⚪',
      description: 'Sparse monochrome for a minimal aesthetic.',
      apply: _monochrome,
    ),
    WallpaperTemplate(
      id: 'neon_night',
      label: 'Neon Night',
      emoji: '⚡',
      description: 'Power density with crisp, high-energy contrast.',
      apply: _neonNight,
    ),
  ];

  static WallpaperTemplate fromId(String? id) {
    return all.firstWhere(
      (t) => t.id == canonicalId(id),
      orElse: () => all.first,
    );
  }

  static WallpaperConfig _presetBase(WallpaperConfig current) {
    return WallpaperConfig.defaults().copyWith(
      customQuote: current.customQuote,
      showQuickStatsBar: current.showQuickStatsBar,
      statCurrentStreak: current.statCurrentStreak,
      statLongestStreak: current.statLongestStreak,
      statTotalCommits: current.statTotalCommits,
      statTopLanguage: current.statTopLanguage,
      densityMode: current.densityMode,
      heroFocus: current.heroFocus,
    );
  }

  static WallpaperConfig _minimalDark(WallpaperConfig base) {
    final preset = _presetBase(base);
    return preset.copyWith(
      isDarkMode: true,
      themeId: 'github',
      autoFitWidth: true,
      opacity: 1.0,
      cornerRadius: 1.5,
      customQuote: '',
      quoteFontSize: 14.0,
      quoteOpacity: 0.9,
      verticalPosition: 0.5,
      horizontalPosition: 0.5,
      densityMode: WallpaperDensityMode.sparse,
      heroFocus: WallpaperHeroFocus.grid,
    );
  }

  static WallpaperConfig _codeCentric(WallpaperConfig base) {
    final preset = _presetBase(base);
    return preset.copyWith(
      isDarkMode: true,
      themeId: 'tokyo_night',
      autoFitWidth: true,
      opacity: 0.95,
      cornerRadius: 2.0,
      quoteFontSize: 12.0,
      quoteOpacity: 0.85,
      verticalPosition: 0.48,
      horizontalPosition: 0.5,
      densityMode: WallpaperDensityMode.normal,
      heroFocus: WallpaperHeroFocus.grid,
    );
  }

  static WallpaperConfig _heatmapHeroLite(WallpaperConfig base) {
    final preset = _presetBase(base);
    return preset.copyWith(
      isDarkMode: true,
      themeId: 'midnight',
      autoFitWidth: true,
      opacity: 1.0,
      cornerRadius: 2.5,
      customQuote: '',
      quoteFontSize: 13.0,
      quoteOpacity: 0.82,
      verticalPosition: 0.58,
      horizontalPosition: 0.5,
      densityMode: WallpaperDensityMode.normal,
      heroFocus: WallpaperHeroFocus.grid,
      statTopLanguage: false,
    );
  }

  static WallpaperConfig _largeQuote(WallpaperConfig base) {
    final preset = _presetBase(base);
    return preset.copyWith(
      isDarkMode: false,
      themeId: 'github_soft',
      autoFitWidth: true,
      opacity: 0.9,
      cornerRadius: 3.0,
      quoteFontSize: 20.0,
      quoteOpacity: 0.95,
      verticalPosition: 0.52,
      horizontalPosition: 0.5,
      densityMode: WallpaperDensityMode.power,
      heroFocus: WallpaperHeroFocus.quote,
    );
  }

  static WallpaperConfig _draculaPop(WallpaperConfig base) {
    final preset = _presetBase(base);
    return preset.copyWith(
      isDarkMode: true,
      autoFitWidth: true,
      opacity: 1.0,
      cornerRadius: 3.5,
      quoteFontSize: 14.0,
      quoteOpacity: 0.9,
      verticalPosition: 0.5,
      horizontalPosition: 0.5,
      themeId: 'dracula',
      densityMode: WallpaperDensityMode.power,
      heroFocus: WallpaperHeroFocus.stats,
    );
  }

  static WallpaperConfig _heatmapHero(WallpaperConfig base) {
    final preset = _presetBase(base);
    return preset.copyWith(
      isDarkMode: true,
      autoFitWidth: true,
      opacity: 1.0,
      cornerRadius: 3.0,
      quoteFontSize: 13.0,
      quoteOpacity: 0.84,
      verticalPosition: 0.56,
      horizontalPosition: 0.5,
      themeId: 'tokyo_night',
      densityMode: WallpaperDensityMode.normal,
      heroFocus: WallpaperHeroFocus.grid,
      statTopLanguage: false,
    );
  }

  static WallpaperConfig _streakPoster(WallpaperConfig base) {
    final preset = _presetBase(base);
    return preset.copyWith(
      isDarkMode: true,
      autoFitWidth: true,
      opacity: 1.0,
      cornerRadius: 3.5,
      quoteFontSize: 12.5,
      quoteOpacity: 0.78,
      verticalPosition: 0.57,
      horizontalPosition: 0.5,
      themeId: 'dracula',
      densityMode: WallpaperDensityMode.power,
      heroFocus: WallpaperHeroFocus.stats,
      statTopLanguage: false,
    );
  }

  static WallpaperConfig _momentumCard(WallpaperConfig base) {
    final preset = _presetBase(base);
    return preset.copyWith(
      isDarkMode: true,
      autoFitWidth: true,
      opacity: 0.98,
      cornerRadius: 2.5,
      quoteFontSize: 13.5,
      quoteOpacity: 0.84,
      verticalPosition: 0.54,
      horizontalPosition: 0.5,
      themeId: 'github_soft',
      densityMode: WallpaperDensityMode.normal,
      heroFocus: WallpaperHeroFocus.stats,
    );
  }

  static WallpaperConfig _quietGridHome(WallpaperConfig base) {
    final preset = _presetBase(base);
    return preset.copyWith(
      isDarkMode: true,
      autoFitWidth: true,
      opacity: 0.94,
      cornerRadius: 2.0,
      quoteFontSize: 12.0,
      quoteOpacity: 0.74,
      verticalPosition: 0.44,
      horizontalPosition: 0.46,
      themeId: 'mono',
      densityMode: WallpaperDensityMode.sparse,
      heroFocus: WallpaperHeroFocus.grid,
      statTopLanguage: false,
    );
  }

  static WallpaperConfig _monochrome(WallpaperConfig base) {
    final preset = _presetBase(base);
    return preset.copyWith(
      isDarkMode: true,
      autoFitWidth: true,
      opacity: 0.85,
      cornerRadius: 2.0,
      quoteFontSize: 14.0,
      quoteOpacity: 0.8,
      verticalPosition: 0.5,
      horizontalPosition: 0.5,
      themeId: 'mono',
      densityMode: WallpaperDensityMode.sparse,
      heroFocus: WallpaperHeroFocus.grid,
    );
  }

  static WallpaperConfig _neonNight(WallpaperConfig base) {
    final preset = _presetBase(base);
    return preset.copyWith(
      isDarkMode: true,
      autoFitWidth: true,
      opacity: 1.0,
      cornerRadius: 1.0,
      quoteFontSize: 13.0,
      quoteOpacity: 0.9,
      verticalPosition: 0.5,
      horizontalPosition: 0.5,
      themeId: 'neon',
      densityMode: WallpaperDensityMode.power,
      heroFocus: WallpaperHeroFocus.stats,
    );
  }
}
