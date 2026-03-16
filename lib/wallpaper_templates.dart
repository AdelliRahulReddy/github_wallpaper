import 'package:flutter/material.dart';
import 'app_models.dart';

@immutable
class WallpaperTemplate {
  final String id;
  final String label;
  final String emoji;
  final String description;
  final bool isPro;
  final WallpaperConfig Function(WallpaperConfig base) apply;

  const WallpaperTemplate({
    required this.id,
    required this.label,
    required this.emoji,
    required this.description,
    this.isPro = false,
    required this.apply,
  });
}

class WallpaperTemplates {
  static const List<WallpaperTemplate> all = [
    WallpaperTemplate(
      id: 'minimal_dark',
      label: 'Minimal Dark',
      emoji: '⬛',
      description: 'Clean grid, subtle corners, no quote.',
      isPro: false,
      apply: _minimalDark,
    ),
    WallpaperTemplate(
      id: 'code_centric',
      label: 'Code Centric',
      emoji: '💻',
      description: 'Tight layout, strong contrast, small quote.',
      isPro: true,
      apply: _codeCentric,
    ),
    WallpaperTemplate(
      id: 'large_quote',
      label: 'Large Quote',
      emoji: '📝',
      description: 'Bigger quote, softer grid, centered.',
      isPro: true,
      apply: _largeQuote,
    ),
    WallpaperTemplate(
      id: 'dracula_pop',
      label: 'Dracula Pop',
      emoji: '🧛',
      description: 'High-impact palette with slightly rounded tiles.',
      isPro: true,
      apply: _draculaPop,
    ),
    WallpaperTemplate(
      id: 'monochrome',
      label: 'Monochrome',
      emoji: '⚪',
      description: 'Muted look for a premium minimal aesthetic.',
      isPro: true,
      apply: _monochrome,
    ),
    WallpaperTemplate(
      id: 'neon_night',
      label: 'Neon Night',
      emoji: '⚡',
      description: 'Bright palette with crisp tiles.',
      isPro: true,
      apply: _neonNight,
    ),
  ];

  static WallpaperTemplate fromId(String? id) {
    if (id == null) return all.first;
    return all.firstWhere((t) => t.id == id, orElse: () => all.first);
  }

  static WallpaperConfig _minimalDark(WallpaperConfig base) {
    return base.copyWith(
      autoFitWidth: true,
      opacity: 1.0,
      cornerRadius: 1.5,
      customQuote: '',
      quoteFontSize: 14.0,
      quoteOpacity: 0.9,
      verticalPosition: 0.5,
      horizontalPosition: 0.5,
    );
  }

  static WallpaperConfig _codeCentric(WallpaperConfig base) {
    return base.copyWith(
      autoFitWidth: true,
      opacity: 0.95,
      cornerRadius: 2.0,
      quoteFontSize: 12.0,
      quoteOpacity: 0.85,
      verticalPosition: 0.48,
      horizontalPosition: 0.5,
    );
  }

  static WallpaperConfig _largeQuote(WallpaperConfig base) {
    return base.copyWith(
      autoFitWidth: true,
      opacity: 0.9,
      cornerRadius: 3.0,
      quoteFontSize: 20.0,
      quoteOpacity: 0.95,
      verticalPosition: 0.52,
      horizontalPosition: 0.5,
    );
  }

  static WallpaperConfig _draculaPop(WallpaperConfig base) {
    return base.copyWith(
      autoFitWidth: true,
      opacity: 1.0,
      cornerRadius: 3.5,
      quoteFontSize: 14.0,
      quoteOpacity: 0.9,
      verticalPosition: 0.5,
      horizontalPosition: 0.5,
      themeId: 'dracula',
    );
  }

  static WallpaperConfig _monochrome(WallpaperConfig base) {
    return base.copyWith(
      autoFitWidth: true,
      opacity: 0.85,
      cornerRadius: 2.0,
      quoteFontSize: 14.0,
      quoteOpacity: 0.8,
      verticalPosition: 0.5,
      horizontalPosition: 0.5,
      themeId: 'mono',
    );
  }

  static WallpaperConfig _neonNight(WallpaperConfig base) {
    return base.copyWith(
      autoFitWidth: true,
      opacity: 1.0,
      cornerRadius: 1.0,
      quoteFontSize: 13.0,
      quoteOpacity: 0.9,
      verticalPosition: 0.5,
      horizontalPosition: 0.5,
      themeId: 'neon',
    );
  }
}

