import 'package:github_wallpaper/data/datasources/local/storage_service.dart';
import 'package:github_wallpaper/data/models/membership_models.dart';
import 'package:github_wallpaper/shared/state/app_state.dart';

class MembershipState extends SafeChangeNotifier {
  MembershipInfo? _info = StorageService.getCachedMembershipInfo();

  MembershipInfo? get info => _info;
  bool get hasProAccess => _info?.hasProAccess ?? false;

  void refreshFromStorage() {
    _info = StorageService.getCachedMembershipInfo();
    notifySafely();
  }

  void setMembershipInfo(MembershipInfo info) {
    _info = info;
    notifySafely();
  }

  void clear() {
    _info = null;
    notifySafely();
  }
}
