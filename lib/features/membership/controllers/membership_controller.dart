import 'dart:async';

import 'package:github_wallpaper/core/state/safe_change_notifier.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/features/membership/models/membership_models.dart';

class MembershipController extends SafeChangeNotifier {
  MembershipInfo? _info = StorageService.getCachedMembershipInfo();

  MembershipInfo? get info => _info;
  bool get hasProAccess => _info?.hasProAccess ?? false;

  void refreshFromStorage() {
    _info = StorageService.getCachedMembershipInfo();
    notifySafely();
  }

  void setMembershipInfo(MembershipInfo info) {
    _info = info;
    unawaited(StorageService.setCachedMembershipInfo(info));
    notifySafely();
  }

  void clear() {
    _info = null;
    notifySafely();
  }
}
