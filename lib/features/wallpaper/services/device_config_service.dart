import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';

class DeviceConfigService {
  static final _lock = Lock();
  static String? _signature;

  static Future<void> initializeFromPlatformDispatcher() async {
    try {
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      await _lock.synchronized(() async {
        final media = MediaQueryData.fromView(view);
        final signature = '${media.size}|${media.devicePixelRatio}';
        if (signature != _signature) {
          await StorageService.saveDeviceMetrics(
            width: media.size.width,
            height: media.size.height,
            pixelRatio: media.devicePixelRatio,
            safeInsets: media.viewPadding,
          );
          _signature = signature;
        }
      });
    } catch (e, s) {
      AppLog.error(e, s);
    }
  }
}

