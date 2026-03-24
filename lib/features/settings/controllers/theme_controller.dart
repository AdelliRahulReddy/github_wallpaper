import 'package:flutter/material.dart';

import 'package:github_wallpaper/core/state/safe_change_notifier.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';

class ThemeController extends SafeChangeNotifier {
  ThemeMode _mode = StorageService.getThemeMode();

  ThemeMode get mode => _mode;

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifySafely();
    await StorageService.setThemeMode(mode);
  }

  void refreshFromStorage() {
    _mode = StorageService.getThemeMode();
    notifySafely();
  }
}

