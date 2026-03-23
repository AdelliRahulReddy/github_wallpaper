import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';

double _srgbToLinear(double c) {
  if (c <= 0.04045) return c / 12.92;
  return math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

double _relativeLuminance(Color c) {
  final r = _srgbToLinear(c.r);
  final g = _srgbToLinear(c.g);
  final b = _srgbToLinear(c.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contrastRatio(Color fg, Color bg) {
  final l1 = _relativeLuminance(fg) + 0.05;
  final l2 = _relativeLuminance(bg) + 0.05;
  final light = l1 > l2 ? l1 : l2;
  final dark = l1 > l2 ? l2 : l1;
  return light / dark;
}

void _expectAaLargeOrNormal(Color fg, Color bg, {double min = 4.5}) {
  expect(_contrastRatio(fg, bg) >= min, true);
}

void main() {
  test('Light theme contrast meets AA for core pairs', () {
    final theme = AppTheme.lightTheme();
    final cs = theme.colorScheme;
    _expectAaLargeOrNormal(cs.onSurface, cs.surface);
    _expectAaLargeOrNormal(cs.onPrimary, cs.primary);
    _expectAaLargeOrNormal(cs.onError, cs.error);
    _expectAaLargeOrNormal(cs.onInverseSurface, cs.inverseSurface);
  });

  test('Dark theme contrast meets AA for core pairs', () {
    final theme = AppTheme.darkTheme();
    final cs = theme.colorScheme;
    _expectAaLargeOrNormal(cs.onSurface, cs.surface);
    _expectAaLargeOrNormal(cs.onPrimary, cs.primary);
    _expectAaLargeOrNormal(cs.onError, cs.error);
    _expectAaLargeOrNormal(cs.onInverseSurface, cs.inverseSurface);
  });
}
