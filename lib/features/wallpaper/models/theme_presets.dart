// ══════════════════════════════════════════════════════════════════════════
// 🎨 THEME PRESETS - Heatmap Color Palettes
// ══════════════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';

class HeatmapTheme {
  final String id;
  final String label;
  final String emoji;
  final List<Color> levels; // 0=empty, 1..4=activity intensities

  const HeatmapTheme({
    required this.id,
    required this.label,
    required this.emoji,
    required this.levels,
  });
}

class ThemePresets {
  static const String defaultId = 'github';

  static const List<HeatmapTheme> all = [
    HeatmapTheme(
      id: 'github',
      label: 'GitHub',
      emoji: '🟢',
      levels: [
        Color(0xFF161B22), // empty
        Color(0xFF0E4429), // level 1
        Color(0xFF006D32), // level 2
        Color(0xFF26A641), // level 3
        Color(0xFF39D353), // level 4
      ],
    ),
    HeatmapTheme(
      id: 'github_soft',
      label: 'GitHub Soft',
      emoji: '🟩',
      levels: [
        Color(0xFF161B22),
        Color(0xFF144620),
        Color(0xFF1F7A3A),
        Color(0xFF2FBF71),
        Color(0xFF7EE2A8),
      ],
    ),
    HeatmapTheme(
      id: 'mono',
      label: 'Monochrome',
      emoji: '⚪',
      levels: [
        Color(0xFF111316),
        Color(0xFF2B2F36),
        Color(0xFF4B5563),
        Color(0xFF9CA3AF),
        Color(0xFFE5E7EB),
      ],
    ),
    HeatmapTheme(
      id: 'dracula',
      label: 'Dracula',
      emoji: '🧛',
      levels: [
        Color(0xFF282A36),
        Color(0xFF44475A),
        Color(0xFF6272A4),
        Color(0xFFBD93F9),
        Color(0xFFFF79C6),
      ],
    ),
    HeatmapTheme(
      id: 'monokai',
      label: 'Monokai',
      emoji: '🔥',
      levels: [
        Color(0xFF1C1C1C),
        Color(0xFF403929),
        Color(0xFF75715E),
        Color(0xFFF92672),
        Color(0xFFE6DB74),
      ],
    ),
    HeatmapTheme(
      id: 'neon',
      label: 'Neon',
      emoji: '⚡',
      levels: [
        Color(0xFF0A0A0F),
        Color(0xFF0D2952),
        Color(0xFF0057B8),
        Color(0xFF00B4D8),
        Color(0xFF90E0EF),
      ],
    ),
    HeatmapTheme(
      id: 'midnight',
      label: 'Midnight',
      emoji: '🌙',
      levels: [
        Color(0xFF0E0E1A),
        Color(0xFF1A1A3E),
        Color(0xFF2D2D72),
        Color(0xFF6B6BAE),
        Color(0xFFB8B8E0),
      ],
    ),
    HeatmapTheme(
      id: 'sunset',
      label: 'Sunset',
      emoji: '🌅',
      levels: [
        Color(0xFF1A0A00),
        Color(0xFF5C1A00),
        Color(0xFFB33000),
        Color(0xFFFF6B35),
        Color(0xFFFFBF69),
      ],
    ),
    HeatmapTheme(
      id: 'tokyo_night',
      label: 'Tokyo Night',
      emoji: '🌃',
      levels: [
        Color(0xFF0B1020),
        Color(0xFF1A2A4A),
        Color(0xFF2F5D9B),
        Color(0xFF7AA2F7),
        Color(0xFFA9B1D6),
      ],
    ),
  ];

  static HeatmapTheme fromId(String? id) {
    if (id == null) return all.first;
    return all.firstWhere((t) => t.id == id, orElse: () => all.first);
  }

  static List<Color> levelsFor(String? id, {required bool isDarkMode}) {
    final t = fromId(id);
    if (isDarkMode) return t.levels;
    return _toLightLevels(t.levels);
  }

  static List<Color> _toLightLevels(List<Color> base) {
    if (base.length < 5) {
      return const [
        Color(0xFFEBEDF0),
        Color(0xFF9BE9A8),
        Color(0xFF40C463),
        Color(0xFF30A14E),
        Color(0xFF216E39),
      ];
    }
    final res = <Color>[];
    res.add(const Color(0xFFEBEDF0));
    for (var i = 1; i <= 4; i++) {
      final hsl = HSLColor.fromColor(base[i]);
      final lightness = (0.92 - (i * 0.10)).clamp(0.45, 0.92).toDouble();
      final saturation = (hsl.saturation * 0.85).clamp(0.0, 1.0).toDouble();
      res.add(
          hsl.withLightness(lightness).withSaturation(saturation).toColor());
    }
    return res;
  }
}
