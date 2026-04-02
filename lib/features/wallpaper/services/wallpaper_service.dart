import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';

import 'package:github_wallpaper/app/product/services/product_analytics.dart';
import 'package:github_wallpaper/core/constants/firebase_options.dart';
import 'package:github_wallpaper/core/errors/app_exceptions.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/app/services/refresh_result.dart';
import 'package:github_wallpaper/app/services/telemetry_service.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/features/wallpaper/widgets/ui_render.dart';

String computeStableSignatureHash(String signature) {
  return sha256.convert(utf8.encode(signature)).toString();
}

class WallpaperService {
  static final _l = Lock(), _ul = Lock();
  static const _wallpaperChannel = MethodChannel('github_wallpaper/wallpaper');
  static const _rendererSignatureVersion = MonthHeatmapRenderer.rendererVersion;

  static Future<bool> generateAndSetWallpaper({
    required CachedContributionData data,
    required WallpaperConfig config,
    WallpaperTarget target = WallpaperTarget.lock,
    bool forceApply = false,
    ValueChanged<double>? onProgress,
  }) async {
    return await _l.synchronized(() async {
      final hash = _hash(data, config, target);
      final previousHash = StorageService.getLastWallpaperHash();
      final previousPath = StorageService.getLastWallpaperPath();
      final hasPreviousFile =
          previousPath != null && await File(previousPath).exists();
      final isUnchanged = hash == previousHash && hasPreviousFile;

      if (!forceApply && isUnchanged) {
        AppLog.info('Wallpaper unchanged, skipping update (hash: $hash)');
        return false;
      }

      AppLog.info('Applying wallpaper (force: $forceApply, hash: $hash)');
      onProgress?.call(0.35);
      String wallpaperPath;
      if (isUnchanged) {
        wallpaperPath = previousPath;
      } else {
        final img = await _gen(data, config, target);
        wallpaperPath = await _save(img);
      }

      onProgress?.call(0.8);
      if (Platform.isAndroid) {
        await _setAndroidWallpaper(File(wallpaperPath), target);
        await StorageService.setHasAppliedWallpaper(true);
      }
      await StorageService.setLastWallpaperTarget(target);
      await StorageService.saveWallpaperResult(hash, wallpaperPath);
      await StorageService.recordWallpaperUpdate();
      unawaited(
        ProductAnalytics.track(
          ProductEventName.wallpaperApplied,
          properties: {
            'target': target.name,
            'forceApply': forceApply,
            'reusedImage': isUnchanged,
          },
        ),
      );
      AppLog.info('Wallpaper applied successfully (hash: $hash)');
      onProgress?.call(1.0);
      return true;
    });
  }

  static Future<String> generateWallpaperImage({
    required CachedContributionData data,
    required WallpaperConfig config,
    WallpaperTarget target = WallpaperTarget.lock,
    bool forceGenerate = false,
    ValueChanged<double>? onProgress,
  }) async {
    return await _l.synchronized(() async {
      final hash = _hash(data, config, target);
      final previousHash = StorageService.getLastWallpaperHash();
      final previousPath = StorageService.getLastWallpaperPath();
      final hasPreviousFile =
          previousPath != null && await File(previousPath).exists();
      final isUnchanged = hash == previousHash && hasPreviousFile;

      onProgress?.call(0.35);
      final wallpaperPath = (!forceGenerate && isUnchanged)
          ? previousPath
          : await _save(await _gen(data, config, target));

      await StorageService.setLastWallpaperTarget(target);
      await StorageService.saveWallpaperResult(hash, wallpaperPath);
      onProgress?.call(1.0);
      return wallpaperPath;
    });
  }

  static Future<void> _setAndroidWallpaper(
      File wallpaperFile, WallpaperTarget target) async {
    bool nativeSuccess = false;
    try {
      final result = await _wallpaperChannel.invokeMethod<bool>(
        'setWallpaperFromPath',
        {'path': wallpaperFile.path, 'target': target.name},
      );
      nativeSuccess = result == true;
    } on MissingPluginException {
    } on PlatformException catch (e) {
      AppLog.error('Native wallpaper method failed: ${e.code}', null);
      unawaited(
        TelemetryService.logWallpaperFailure(
          'Native wallpaper method failed: ${e.code}',
        ),
      );
    }

    if (nativeSuccess) return;

    try {
      if (target == WallpaperTarget.both) {
        await WallpaperManagerPlus()
            .setWallpaper(wallpaperFile, WallpaperManagerPlus.homeScreen);
        await WallpaperManagerPlus()
            .setWallpaper(wallpaperFile, WallpaperManagerPlus.lockScreen);
        return;
      }

      await WallpaperManagerPlus()
          .setWallpaper(wallpaperFile, target.toManagerConstant());
    } catch (e) {
      unawaited(TelemetryService.logWallpaperFailure(e));
      throw WallpaperException(
          'Failed to set wallpaper directly and via fallback: $e');
    }
  }

  static Future<bool> openLiveWallpaperPicker() async {
    if (!Platform.isAndroid) return false;
    try {
      final ok = await _wallpaperChannel.invokeMethod<bool>(
        'openLiveWallpaperPicker',
      );
      return ok == true;
    } catch (e, s) {
      AppLog.error(e, s);
      return false;
    }
  }

  static Future<Uint8List> _gen(
      CachedContributionData d, WallpaperConfig c, WallpaperTarget t) async {
    final dm = StorageService.getDimensions();
    final w = dm?['width'] ?? AppConstants.defaultWallpaperWidth,
        h = dm?['height'] ?? AppConstants.defaultWallpaperHeight,
        pr = dm?['pixelRatio'] ?? AppConstants.defaultPixelRatio;

    final ec = DeviceCompatibilityChecker.applyPlacement(base: c, target: t);

    await Future<void>.delayed(Duration.zero);
    return await generateWallpaperTask({
      'data': jsonEncode(d.toJson()),
      'config': jsonEncode(ec.toJson()),
      'target': t.name,
      'width': w,
      'height': h,
      'pixelRatio': pr,
    });
  }

  static Future<String> _save(Uint8List b) async {
    try {
      final d = await getTemporaryDirectory();
      try {
        final dir = Directory(d.path);
        if (await dir.exists()) {
          final files = dir.listSync();
          for (final f in files) {
            if (f is File &&
                f.path.contains('wp_') &&
                f.path.endsWith('.png')) {
              await f.delete();
            }
          }
        }
      } catch (e) {
        AppLog.error('Failed to cleanup old wallpapers: $e');
      }

      return (await File(
                  '${d.path}/wp_${DateTime.now().millisecondsSinceEpoch}.png')
              .writeAsBytes(b))
          .path;
    } catch (e) {
      unawaited(TelemetryService.logWallpaperFailure(e));
      throw WallpaperException('Failed to save wallpaper file: $e');
    }
  }

  static Future<RefreshResult> refreshWallpaper(
      {required Future<RefreshResult> Function({bool force, bool isBackground})
          syncAction,
      bool isBackground = false}) async {
    return await _ul.synchronized(() async {
      if (isBackground) {
        WidgetsFlutterBinding.ensureInitialized();
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        }
        await StorageService.init();
      }
      return syncAction(
        force: !isBackground,
        isBackground: isBackground,
      );
    });
  }

  static String _hash(
      CachedContributionData d, WallpaperConfig c, WallpaperTarget t) {
    final todayKey = AppDateUtils.formatDate(DateTime.now().toUtc());
    final dims = StorageService.getDimensions();
    final safeInsets = StorageService.getSafeInsets();
    final width = dims?['width'] ?? AppConstants.defaultWallpaperWidth;
    final height = dims?['height'] ?? AppConstants.defaultWallpaperHeight;
    final pixelRatio = dims?['pixelRatio'] ?? AppConstants.defaultPixelRatio;
    final daySignature = d.days
        .map((day) => '${day.dateKey}:${day.contributionCount}')
        .join(',');
    final configSignature = jsonEncode(c.toJson());
    final signature =
        '$_rendererSignatureVersion|${d.username.toLowerCase()}|${t.name}|$todayKey|$configSignature|$width|$height|$pixelRatio|${safeInsets.left}|${safeInsets.top}|${safeInsets.right}|${safeInsets.bottom}|$daySignature';
    return computeStableSignatureHash(signature);
  }
}

class DeviceCompatibilityChecker {
  static double reservedTopPx({
    required double screenHeight,
    required EdgeInsets safeInsets,
    required WallpaperTarget target,
  }) {
    final isLockStyle = target != WallpaperTarget.home;
    final contentReserve = isLockStyle
        ? _scaledReserve(
            screenHeight,
            AppConstants.lockTopReserveHeightFraction,
            AppConstants.lockTopReserveMinPx,
            AppConstants.lockTopReserveMaxPx,
          )
        : _scaledReserve(
            screenHeight,
            AppConstants.homeTopReserveHeightFraction,
            AppConstants.homeTopReserveMinPx,
            AppConstants.homeTopReserveMaxPx,
          );
    return safeInsets.top + contentReserve;
  }

  static double reservedBottomPx({
    required double screenHeight,
    required EdgeInsets safeInsets,
    required WallpaperTarget target,
  }) {
    final isLockStyle = target != WallpaperTarget.home;
    final contentReserve = isLockStyle
        ? _scaledReserve(
            screenHeight,
            AppConstants.lockBottomReserveHeightFraction,
            AppConstants.lockBottomReserveMinPx,
            AppConstants.lockBottomReserveMaxPx,
          )
        : _scaledReserve(
            screenHeight,
            AppConstants.homeBottomReserveHeightFraction,
            AppConstants.homeBottomReserveMinPx,
            AppConstants.homeBottomReserveMaxPx,
          );
    return safeInsets.bottom + contentReserve;
  }

  static double _scaledReserve(
    double screenHeight,
    double fraction,
    double minPx,
    double maxPx,
  ) {
    return (screenHeight * fraction).clamp(minPx, maxPx).toDouble();
  }

  static WallpaperConfig applyPlacement(
      {required WallpaperConfig base, required WallpaperTarget target}) {
    final m = StorageService.getDimensions(),
        i = StorageService.getSafeInsets();
    if (m == null) return base;
    final h = m['height']!;
    final extraTop = reservedTopPx(
      screenHeight: h,
      safeInsets: i,
      target: target,
    );
    final extraBottom = reservedBottomPx(
      screenHeight: h,
      safeInsets: i,
      target: target,
    );

    return base.copyWith(
        paddingTop: base.paddingTop + extraTop,
        paddingBottom: base.paddingBottom + extraBottom,
        paddingLeft: base.paddingLeft + i.left + AppConstants.horizontalBuffer,
        paddingRight:
            base.paddingRight + i.right + AppConstants.horizontalBuffer);
  }
}
