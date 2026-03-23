import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';

class RemoteConfigService extends ChangeNotifier {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  final FirebaseFirestore _db =
      FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');
  final Completer<void> _initCompleter = Completer<void>();

  Map<String, dynamic> _appConfig = _defaultAppConfig;

  StreamSubscription? _appConfigSub;

  bool _isInitialized = false;

  static const Map<String, dynamic> _defaultAppConfig = {
    'maintenance_mode': false,
    'maintenance_message': "We'll be back soon",
    'force_update_enabled': false,
    'force_update_min_version': '1.0.0',
    'force_update_message': 'Please update GitWall',
    'ai_quotes_enabled': true,
    'ai_quotes_quota_exceeded': false,
    'debug_mode_enabled': false,
    'onboarding_version': 1,
    'coupon_access_duration_days': 180,
  };

  Future<void> init() async {
    if (_isInitialized) return;

    _appConfigSub =
        _db.collection('config').doc('app_config').snapshots().listen((snap) {
      if (snap.exists) {
        _appConfig = snap.data() ?? _defaultAppConfig;
        notifyListeners();
      }
      _checkInit();
    }, onError: (e) => _handleError('app_config', e));

    Timer(const Duration(seconds: 3), () {
      if (!_initCompleter.isCompleted) {
        if (kDebugMode) {
          AppLog.info(
              'RemoteConfigService: Initial fetch timed out, using defaults');
        }
        _initCompleter.complete();
      }
    });

    await _initCompleter.future;
    _isInitialized = true;
  }

  void _checkInit() {
    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
  }

  void _handleError(String doc, dynamic e) {
    if (kDebugMode) {
      AppLog.error('RemoteConfigService: Error listening to $doc: $e');
    }
    _checkInit();
  }

  dynamic getAppValue(String key) {
    return _appConfig[key] ?? _defaultAppConfig[key];
  }

  bool get aiQuotesEnabled =>
      getAppValue('ai_quotes_enabled') &&
      !getAppValue('ai_quotes_quota_exceeded');

  bool get maintenanceMode => getAppValue('maintenance_mode');
  String get maintenanceMessage => getAppValue('maintenance_message');
  bool get forceUpdateEnabled => getAppValue('force_update_enabled');
  String get forceUpdateMinVersion => getAppValue('force_update_min_version');
  String get forceUpdateMessage => getAppValue('force_update_message');
  bool get debugModeEnabled => getAppValue('debug_mode_enabled');
  int get onboardingVersion => getAppValue('onboarding_version');
  int get couponAccessDurationDays =>
      (getAppValue('coupon_access_duration_days') as num?)?.toInt() ?? 180;

  @override
  void dispose() {
    _appConfigSub?.cancel();
    super.dispose();
  }
}
