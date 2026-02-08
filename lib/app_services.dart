import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';
import 'package:synchronized/synchronized.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'app_exceptions.dart';
import 'app_models.dart';
import 'app_utils.dart';
import 'ui_render.dart';
import 'firebase_options.dart';
export 'app_exceptions.dart';

// STORAGE
class StorageService {
  static SharedPreferences? _p;
  static const _kRef = 'pending_wp_refresh';
  static const _ss = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true));

  static Future<void> init() async =>
      _p ??= await SharedPreferences.getInstance();
  static SharedPreferences? get _s => _p;

  // Token
  static Future<void> setToken(String t) async {
    if (t.trim().isEmpty) throw ArgumentError('Empty token');
    if (isValidTokenFormat(t) != null) throw ArgumentError('Invalid token');
    await _ss.write(key: AppConstants.keyToken, value: t.trim());
  }

  static Future<String?> getToken() async {
    try {
      return await _ss.read(key: AppConstants.keyToken);
    } catch (e) {
      if (e.toString().contains('CORRUPTED')) {
        await _ss.delete(key: AppConstants.keyToken);
      }
      return null;
    }
  }

  static Future<void> deleteToken() => _ss.delete(key: AppConstants.keyToken);
  static Future<bool> hasToken() async =>
      (await getToken())?.isNotEmpty ?? false;

  // User
  static Future<void> setUsername(String u) async {
    if (u.trim().isEmpty) throw ArgumentError();
    await (await _init()).setString(AppConstants.keyUsername, u.trim());
  }

  static String? getUsername() => _s?.getString(AppConstants.keyUsername);

  // Cache
  static Future<void> setCachedData(CachedContributionData d) async =>
      (await _init())
          .setString(AppConstants.keyCachedData, jsonEncode(d.toJson()));
  static CachedContributionData? getCachedData() {
    try {
      final j = _s?.getString(AppConstants.keyCachedData);
      return j == null ? null : CachedContributionData.fromJson(jsonDecode(j));
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearCache() async {
    (await _init())
      ..remove(AppConstants.keyCachedData)
      ..remove(AppConstants.keyLastUpdate);
  }

  // Config
  static Future<void> saveWallpaperConfig(WallpaperConfig c) async =>
      (await _init())
          .setString(AppConstants.keyWallpaperConfig, jsonEncode(c.toJson()));
  static WallpaperConfig getWallpaperConfig() {
    try {
      final j = _s?.getString(AppConstants.keyWallpaperConfig);
      return j == null
          ? WallpaperConfig.defaults()
          : WallpaperConfig.fromJson(jsonDecode(j));
    } catch (_) {
      return WallpaperConfig.defaults();
    }
  }

  // Settings
  static Future<void> setAutoUpdate(bool e) async =>
      (await _init()).setBool(AppConstants.keyAutoUpdate, e);
  static bool getAutoUpdate() =>
      _s?.getBool(AppConstants.keyAutoUpdate) ?? true;
  static Future<void> setLastUpdate(DateTime d) async => (await _init())
      .setString(AppConstants.keyLastUpdate, d.toIso8601String());
  static DateTime? getLastUpdate() {
    final s = _s?.getString(AppConstants.keyLastUpdate);
    return s != null ? DateTime.tryParse(s) : null;
  }

  static Future<void> setOnboardingComplete(bool v) async =>
      (await _init()).setBool(AppConstants.keyOnboarding, v);
  static bool isOnboardingComplete() =>
      _s?.getBool(AppConstants.keyOnboarding) ?? false;
  static Future<void> setPendingWallpaperRefresh(bool v) async {
    final p = await _init();
    v ? p.setBool(_kRef, true) : p.remove(_kRef);
  }

  static bool hasPendingWallpaperRefresh() => _s?.getBool(_kRef) ?? false;
  static Future<void> consumePendingWallpaperRefresh() async =>
      (await _init()).remove(_kRef);

  static Future<void> setHasSeenDashboard(bool v) async =>
      (await _init()).setBool(AppConstants.keyHasSeenDashboard, v);
  static bool hasSeenDashboard() =>
      _s?.getBool(AppConstants.keyHasSeenDashboard) ?? false;

  // Dimensions
  static Future<void> saveDeviceModel(String m) async =>
      (await _init()).setString(AppConstants.keyDeviceModel, m.trim());
  static String? getDeviceModel() =>
      _s?.getString(AppConstants.keyDeviceModel)?.trim();
  static Future<void> saveDeviceMetrics(
      {required double width,
      required double height,
      required double pixelRatio,
      required EdgeInsets safeInsets}) async {
    (await _init())
      ..setDouble(AppConstants.keyDimensionWidth, width)
      ..setDouble(AppConstants.keyDimensionHeight, height)
      ..setDouble(AppConstants.keyDimensionPixelRatio, pixelRatio)
      ..setDouble(AppConstants.keySafeInsetTop, safeInsets.top)
      ..setDouble(AppConstants.keySafeInsetBottom, safeInsets.bottom)
      ..setDouble(AppConstants.keySafeInsetLeft, safeInsets.left)
      ..setDouble(AppConstants.keySafeInsetRight, safeInsets.right);
  }

  static EdgeInsets getSafeInsets() {
    final p = _s;
    return EdgeInsets.fromLTRB(
        p?.getDouble(AppConstants.keySafeInsetLeft) ?? 0,
        p?.getDouble(AppConstants.keySafeInsetTop) ?? 0,
        p?.getDouble(AppConstants.keySafeInsetRight) ?? 0,
        p?.getDouble(AppConstants.keySafeInsetBottom) ?? 0);
  }

  static Map<String, double>? getDimensions() {
    final p = _s;
    final w = p?.getDouble(AppConstants.keyDimensionWidth);
    final h = p?.getDouble(AppConstants.keyDimensionHeight);
    final pr = p?.getDouble(AppConstants.keyDimensionPixelRatio);
    if (w == null || h == null || pr == null) return null;
    return {'width': w, 'height': h, 'pixelRatio': pr};
  }

  // Wallpaper
  static Future<void> saveWallpaperResult(String h, String p) async {
    (await _init())
      ..setString(AppConstants.keyWallpaperHash, h)
      ..setString(AppConstants.keyWallpaperPath, p);
  }

  static String? getLastWallpaperHash() =>
      _s?.getString(AppConstants.keyWallpaperHash);
  static String? getLastWallpaperPath() =>
      _s?.getString(AppConstants.keyWallpaperPath);

  static Future<void> logout() async {
    await deleteToken();
    (await _init())
      ..remove(AppConstants.keyUsername)
      ..remove(AppConstants.keyCachedData)
      ..remove(AppConstants.keyWallpaperConfig)
      ..remove(AppConstants.keyLastUpdate)
      ..remove(AppConstants.keyOnboarding)
      ..remove(AppConstants.keyWallpaperHash)
      ..remove(AppConstants.keyWallpaperPath)
      ..remove(_kRef);
  }

  static Future<SharedPreferences> _init() async =>
      _p ??= await SharedPreferences.getInstance();
}

// GITHUB
class GitHubService {
  static final http.Client _c = http.Client();
  static Future<CachedContributionData> getContributions(
      {required String username,
      required String token,
      bool forceRefresh = false}) async {
    // 1. Return cache if valid and not forced
    if (!forceRefresh) {
      final cached = StorageService.getCachedData();
      if (cached != null &&
          !cached.isStale() &&
          cached.username.toLowerCase() == username.toLowerCase()) {
        return cached;
      }
    }

    // 2. Fetch from API
    try {
      final res = await _req(username, token);
      final data = jsonDecode(res.body);
      if (res.statusCode != 200 || data['errors'] != null) {
        if (res.statusCode == 401) throw TokenExpiredException();
        if (res.statusCode == 403) throw AccessDeniedException();
        if (res.statusCode == 429) throw RateLimitException();
        final errors = data['errors'];
        if (errors is List && errors.isNotEmpty) {
          final msg = errors.first['message']?.toString().toLowerCase() ?? '';
          if (msg.contains('rate limit')) throw RateLimitException();
          if (msg.contains('bad credentials') || msg.contains('unauthorized')) {
            throw TokenExpiredException();
          }
        }
        throw GitHubException('API Error: ${res.statusCode}',
            statusCode: res.statusCode, details: res.body);
      }
      if (data['data']?['user'] == null) throw UserNotFoundException();

      final parsed = _parse(data, username);

      // 3. Save to cache
      await StorageService.setCachedData(parsed);
      await StorageService.setLastUpdate(DateTime.now().toUtc());

      return parsed;
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      rethrow;
    }
  }

  static Future<http.Response> _req(String u, String t) async {
    const q =
        r'''query($login:String!,$from:DateTime!,$to:DateTime!){user(login:$login){avatarUrl contributionsCollection(from:$from,to:$to){contributionCalendar{totalContributions weeks{contributionDays{date contributionCount contributionLevel}}} commitContributionsByRepository(maxRepositories:100){repository{nameWithOwner url isPrivate primaryLanguage{name color} languages(first:20,orderBy:{field:SIZE,direction:DESC}){edges{size node{name color}}}} contributions{totalCount}}}}}''';
    final now = DateTime.now().toUtc();
    var a = 0;
    while (true) {
      try {
        final r = await _c
            .post(Uri.parse(AppConstants.apiUrl),
                headers: {
                  'Authorization': 'Bearer $t',
                  'Content-Type': 'application/json'
                },
                body: jsonEncode({
                  'query': q,
                    'variables': {
                    'login': u,
                    'from': now
                        .subtract(
                            Duration(days: AppConstants.githubDataFetchDays))
                        .toIso8601String(),
                    'to': now.toIso8601String()
                  }
                }))
            .timeout(AppConstants.apiTimeout);
        if (r.statusCode >= 500 && ++a < 3) {
          await Future.delayed(Duration(seconds: 1 << a));
          continue;
        }
        return r;
      } catch (e) {
        if (++a < 3) {
          await Future.delayed(Duration(seconds: 1 << a));
          continue;
        }
        rethrow;
      }
    }
  }

  static CachedContributionData _parse(Map<String, dynamic> j, String u) {
    try {
      final user = j['data']['user'];
      final avatarUrl = user['avatarUrl'] as String?;
      final cal = user['contributionsCollection']['contributionCalendar'];
      final days = <ContributionDay>[];
      for (var w in cal['weeks']) {
        for (var d in w['contributionDays']) {
          days.add(ContributionDay.fromJson(d));
        }
      }
      final repos = <RepoContribution>[];
      for (var r in j['data']['user']['contributionsCollection']
          ['commitContributionsByRepository']) {
        if (r['contributions']['totalCount'] > 0 && r['repository'] != null) {
          final repo = r['repository'];
          final langs = (repo['languages']['edges'] as List)
              .map((l) => RepoLanguageSlice(
                  name: l['node']['name'],
                  color: l['node']['color'],
                  size: l['size']))
              .toList();
          repos.add(RepoContribution(
              nameWithOwner: repo['nameWithOwner'],
              url: repo['url'],
              isPrivate: repo['isPrivate'],
              commitCount: r['contributions']['totalCount'],
              primaryLanguageName: repo['primaryLanguage']?['name'],
              primaryLanguageColor: repo['primaryLanguage']?['color'],
              languages: langs));
        }
      }
      repos.sort((a, b) => b.commitCount.compareTo(a.commitCount));
      return CachedContributionData(
          username: u,
          avatarUrl: avatarUrl,
          totalContributions: cal['totalContributions'],
          days: days,
          lastUpdated: DateTime.now().toUtc(),
          repositories: repos);
    } catch (e) {
      throw GitHubException('Parse Error: $e');
    }
  }

  static bool isFormatValid(String t) => isValidTokenFormat(t) == null;

  static Future<bool> validateToken(String t) async {
    if (!isFormatValid(t)) return false;
    try {
      final r = await _c
          .post(Uri.parse(AppConstants.apiUrl),
              headers: {'Authorization': 'Bearer $t'},
              body: jsonEncode({'query': 'query{viewer{login}}'}))
          .timeout(const Duration(seconds: 8));
      return r.statusCode == 200 &&
          jsonDecode(r.body)['data']?['viewer']?['login'] != null;
    } catch (_) {
      return false;
    }
  }

  static void dispose() => _c.close();
}

// WALLPAPER

enum RefreshResult {
  success,
  noChanges,
  networkError,
  authError,
  unknownError,
  throttled;

  bool get isSuccess => index <= 1;
}

class WallpaperService {
  static final _l = Lock(), _ul = Lock();
  static const _wallpaperChannel = MethodChannel('github_wallpaper/wallpaper');

  static RefreshResult _resultForSkipReason(RefreshSkipReason? reason) {
    switch (reason) {
      case RefreshSkipReason.noChanges:
        return RefreshResult.noChanges;
      case RefreshSkipReason.throttled:
        return RefreshResult.throttled;
      case RefreshSkipReason.networkError:
        return RefreshResult.networkError;
      case RefreshSkipReason.authError:
        return RefreshResult.authError;
      case null:
        return RefreshResult.noChanges;
    }
  }

  static Future<bool> generateAndSetWallpaper({
    required CachedContributionData data,
    required WallpaperConfig config,
    WallpaperTarget target = WallpaperTarget.both,
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

      if (!forceApply && isUnchanged) return false;

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
      }
      await StorageService.saveWallpaperResult(hash, wallpaperPath);
      onProgress?.call(1.0);
      return true;
    });
  }

  static Future<void> _setAndroidWallpaper(
      File wallpaperFile, WallpaperTarget target) async {
    try {
      final result = await _wallpaperChannel.invokeMethod<bool>(
        'setWallpaperFromPath',
        {'path': wallpaperFile.path, 'target': target.name},
      );
      if (result == true) return;
      throw Exception('Native wallpaper setting returned false');
    } on MissingPluginException {
      // Fallback to plugin only when channel is unavailable.
    } on PlatformException catch (e) {
      throw Exception('${e.code}: ${e.message}');
    }

    if (target == WallpaperTarget.both) {
      try {
        await WallpaperManagerPlus()
            .setWallpaper(wallpaperFile, WallpaperManagerPlus.bothScreens);
        return;
      } catch (_) {
        await WallpaperManagerPlus()
            .setWallpaper(wallpaperFile, WallpaperManagerPlus.homeScreen);
        await WallpaperManagerPlus()
            .setWallpaper(wallpaperFile, WallpaperManagerPlus.lockScreen);
        return;
      }
    }

    await WallpaperManagerPlus()
        .setWallpaper(wallpaperFile, target.toManagerConstant());
  }

  static Future<Uint8List> _gen(
      CachedContributionData d, WallpaperConfig c, WallpaperTarget t) async {
    final dm = StorageService.getDimensions();
    final w = dm?['width'] ?? AppConstants.defaultWallpaperWidth,
        h = dm?['height'] ?? AppConstants.defaultWallpaperHeight,
        pr = dm?['pixelRatio'] ?? AppConstants.defaultPixelRatio;

    final ec = DeviceCompatibilityChecker.applyPlacement(base: c, target: t);

    // Call directly on main isolate to avoid "UI actions on root isolate" error
    return await generateWallpaperTask({
      'data': jsonEncode(d.toJson()),
      'config': jsonEncode(ec.toJson()),
      'width': w,
      'height': h,
      'pixelRatio': pr,
    });
  }

  static Future<String> _save(Uint8List b) async {
    final d = await getTemporaryDirectory();
    return (await File(
                '${d.path}/wp_${DateTime.now().millisecondsSinceEpoch}.png')
            .writeAsBytes(b))
        .path;
  }

  static Future<RefreshResult> refreshWallpaper(
      {bool isBackground = false}) async {
    return await _ul.synchronized(() async {
      if (isBackground) {
        WidgetsFlutterBinding.ensureInitialized();
        await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform);
        await StorageService.init();
      }
      final dec = RefreshPolicy.shouldRefresh(
          isBackground: isBackground,
          isAndroid: Platform.isAndroid,
          autoUpdateEnabled: StorageService.getAutoUpdate(),
          hasPendingRefresh: StorageService.hasPendingWallpaperRefresh(),
          lastUpdate: StorageService.getLastUpdate(),
          username: StorageService.getUsername(),
          token: await StorageService.getToken());
      if (!dec.shouldProceed) {
        final result = _resultForSkipReason(dec.skipReason);
        if (result == RefreshResult.noChanges) {
          await StorageService.consumePendingWallpaperRefresh();
        }
        return result;
      }
      try {
        final d = await GitHubService.getContributions(
            username: StorageService.getUsername()!,
            token: (await StorageService.getToken())!,
            forceRefresh: true);
        final result = await generateAndSetWallpaper(
                data: d, config: StorageService.getWallpaperConfig())
            ? RefreshResult.success
            : RefreshResult.noChanges;
        if (result.isSuccess) {
          await StorageService.consumePendingWallpaperRefresh();
        }
        return result;
      } on NetworkException {
        return RefreshResult.networkError;
      } on SocketException {
        return RefreshResult.networkError;
      } on TokenExpiredException {
        return RefreshResult.authError;
      } on AccessDeniedException {
        return RefreshResult.authError;
      } on RateLimitException {
        return RefreshResult.throttled;
      } catch (e) {
        return RefreshResult.unknownError;
      }
    });
  }

  // Connectivity check removed in favor of standard http error handling

  static String _hash(
      CachedContributionData d, WallpaperConfig c, WallpaperTarget t) {
    final daySignature = d.days
        .map((day) => '${day.dateKey}:${day.contributionCount}')
        .join(',');
    final configSignature = jsonEncode(c.toJson());
    return '${d.username.toLowerCase()}|${t.name}|$configSignature|$daySignature'
        .hashCode
        .toString();
  }
}

// SETUP & FCM
class DeviceCompatibilityChecker {
  static WallpaperConfig applyPlacement(
      {required WallpaperConfig base, required WallpaperTarget target}) {
    final m = StorageService.getDimensions(),
        i = StorageService.getSafeInsets();
    if (m == null) return base;
    final h = m['height']!;
    final lockClockBuffer = (h * AppConstants.deviceClockBufferHeightFraction)
        .clamp(AppConstants.deviceClockBufferMinPx,
            AppConstants.deviceClockBufferMaxPx)
        .toDouble();

    final double extraTop;
    final double extraBottom;
    switch (target) {
      case WallpaperTarget.lock:
      case WallpaperTarget.both:
        extraTop = i.top + lockClockBuffer;
        extraBottom = i.bottom + lockClockBuffer;
        break;
      case WallpaperTarget.home:
        // Home screen has fewer overlays than lock screen; keep placement tighter.
        extraTop = i.top + (lockClockBuffer * 0.35);
        extraBottom = i.bottom + (lockClockBuffer * 0.2);
        break;
    }

    return base.copyWith(
        paddingTop: base.paddingTop + extraTop,
        paddingBottom: base.paddingBottom + extraBottom,
        paddingLeft: base.paddingLeft + i.left + AppConstants.horizontalBuffer,
        paddingRight:
            base.paddingRight + i.right + AppConstants.horizontalBuffer);
  }
}

@pragma('vm:entry-point')
Future<void> _bgH(RemoteMessage m) async {
  if (m.data['type']?.contains('refresh') == true) {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final msg = RootIsolateToken.instance;
      if (msg != null) {
        BackgroundIsolateBinaryMessenger.ensureInitialized(msg);
      }
    } catch (_) {}

    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await StorageService.init();
    if (StorageService.getAutoUpdate()) {
      await StorageService.setPendingWallpaperRefresh(true);
      if ((await WallpaperService.refreshWallpaper(isBackground: true))
          .isSuccess) {
        await StorageService.consumePendingWallpaperRefresh();
      }
    }
  }
}

class FcmService {
  static Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_bgH);
    // Silent Sync: We only use data messages which don't require visual permission.
    // Subscribe unconditionally to ensure background updates work.
    await FirebaseMessaging.instance
        .subscribeToTopic(AppConstants.fcmTopicDailyUpdates);
    FirebaseMessaging.onMessage.listen((m) {
      if (m.data['type']?.contains('refresh') == true &&
          StorageService.getAutoUpdate()) {
        WallpaperService.refreshWallpaper();
      }
    });
  }
}

class AppConfig {
  static final _l = Lock();
  static String? _sig;
  static Future<void> initializeFromPlatformDispatcher() async {
    try {
      final v = WidgetsBinding.instance.platformDispatcher.views.first;
      await _l.synchronized(() async {
        final mq = MediaQueryData.fromView(v);
        final sig = '${mq.size}|${mq.devicePixelRatio}';
        if (sig != _sig) {
          await StorageService.saveDeviceMetrics(
              width: mq.size.width,
              height: mq.size.height,
              pixelRatio: mq.devicePixelRatio,
              safeInsets: mq.viewPadding);
          _sig = sig;
        }
      });
    } catch (_) {}
  }
}
// BOOTSTRAP
class BootstrapService {
  static Future<bool> boot({
    required Function(double) onProgress,
    required Function(String) onError,
  }) async {
    final startTime = DateTime.now();
    try {
      // 1. Storage
      await StorageService.init().timeout(const Duration(seconds: 10));
      onProgress(0.3);

      // 2. Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 15));
      
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      onProgress(0.6);

      // 3. Firebase Services (App Check, FCM)
      await _initFirebaseServices();
      onProgress(0.8);

      // 4. App Config
      await AppConfig.initializeFromPlatformDispatcher()
          .timeout(const Duration(seconds: 2), onTimeout: () {});

      // 5. Minimum Splash Duration
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < const Duration(seconds: 4)) {
        await Future.delayed(const Duration(seconds: 4) - elapsed);
      }

      onProgress(1.0);
      return true;
    } catch (e, stack) {
      if (Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.recordError(e, stack, fatal: true);
      }
      onError(ErrorHandler.getUserFriendlyMessage(e));
      return false;
    }
  }

  static Future<void> _initFirebaseServices() async {
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode ? AndroidDebugProvider() : AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode ? AppleDebugProvider() : AppleAppAttestProvider(),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      AppLog.error('AppCheck Activation Failed: $e');
    }

    try {
      await FcmService.init().timeout(const Duration(seconds: 5));
    } catch (e) {
      AppLog.error('FCM Init Failed: $e');
    }
  }
}
