// ══════════════════════════════════════════════════════════════════════════
// 🎨 THEME PRESETS - Premium Heatmap Color Palettes
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
        Color(0xFF1A1A1A), // empty
        Color(0xFF0E4429), // level 1
        Color(0xFF006D32), // level 2
        Color(0xFF26A641), // level 3
        Color(0xFF39D353), // level 4
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
  ];

  static HeatmapTheme fromId(String? id) {
    if (id == null) return all.first;
    return all.firstWhere((t) => t.id == id, orElse: () => all.first);
  }
}
