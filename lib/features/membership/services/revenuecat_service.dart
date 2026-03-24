import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:github_wallpaper/core/constants/environment_config.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';

class RevenueCatService {
  RevenueCatService._();

  static bool _configured = false;
  static String? _currentAppUserId;

  static bool get isAvailable {
    if (kIsWeb) return false;
    return Platform.isAndroid &&
        AppConfig.revenueCatGooglePublicKey.trim().isNotEmpty;
  }

  static String get entitlementId => AppConfig.revenueCatProEntitlementId;

  static Future<void> initializeForCurrentUser() async {
    if (!isAvailable) return;

    try {
      final appUserId = await _resolveAppUserId();
      if (appUserId == null) return;

      if (!_configured) {
        final configuration =
            PurchasesConfiguration(AppConfig.revenueCatGooglePublicKey)
              ..appUserID = appUserId;
        await Purchases.configure(configuration);
        _configured = true;
        _currentAppUserId = appUserId;
      } else if (_currentAppUserId != appUserId) {
        await Purchases.logIn(appUserId);
        _currentAppUserId = appUserId;
      }

      await _syncSubscriberAttributes();
    } on MissingPluginException {
      AppLog.error('RevenueCat plugin unavailable on this build.', null);
    } on PlatformException catch (error, stack) {
      AppLog.error('RevenueCat init failed: ${error.message}', stack);
    } catch (error, stack) {
      AppLog.error('RevenueCat init failed: $error', stack);
    }
  }

  static Future<void> logOut() async {
    if (!isAvailable || !_configured) return;

    try {
      await Purchases.logOut();
    } on MissingPluginException {
      AppLog.error('RevenueCat plugin unavailable on logout.', null);
    } on PlatformException catch (error, stack) {
      AppLog.error('RevenueCat logout failed: ${error.message}', stack);
    } catch (error, stack) {
      AppLog.error('RevenueCat logout failed: $error', stack);
    } finally {
      _configured = false;
      _currentAppUserId = null;
    }
  }

  static Future<Offerings?> getOfferings() async {
    if (!isAvailable) return null;
    await initializeForCurrentUser();

    try {
      return await Purchases.getOfferings();
    } on MissingPluginException {
      return null;
    } on PlatformException catch (error, stack) {
      AppLog.error('RevenueCat offerings failed: ${error.message}', stack);
      return null;
    } catch (error, stack) {
      AppLog.error('RevenueCat offerings failed: $error', stack);
      return null;
    }
  }

  static Future<CustomerInfo?> getCustomerInfo() async {
    if (!isAvailable) return null;
    await initializeForCurrentUser();

    try {
      return await Purchases.getCustomerInfo();
    } on MissingPluginException {
      return null;
    } on PlatformException catch (error, stack) {
      AppLog.error('RevenueCat customer info failed: ${error.message}', stack);
      return null;
    } catch (error, stack) {
      AppLog.error('RevenueCat customer info failed: $error', stack);
      return null;
    }
  }

  static Future<CustomerInfo> purchasePackage(Package package) async {
    if (!isAvailable) {
      throw StateError(
        'Google Play purchases are not available on this device.',
      );
    }
    await initializeForCurrentUser();

    try {
      final result = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      validateCustomerInfoForProAccess(
        result.customerInfo,
        isRestore: false,
      );
      return result.customerInfo;
    } on PlatformException catch (error) {
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        throw StateError('Purchase was cancelled.');
      }
      if (code == PurchasesErrorCode.paymentPendingError) {
        throw StateError(
            'Payment is pending. Access will unlock after Google Play confirms it.');
      }
      if (code == PurchasesErrorCode.networkError ||
          code == PurchasesErrorCode.offlineConnectionError) {
        throw StateError(
          'A network issue interrupted the purchase. Please try again.',
        );
      }
      if (code == PurchasesErrorCode.invalidReceiptError ||
          code == PurchasesErrorCode.purchaseInvalidError) {
        throw StateError(
          'Google Play could not verify this purchase. Please try again.',
        );
      }
      if (code == PurchasesErrorCode.receiptAlreadyInUseError) {
        throw StateError(
          'This purchase is already linked to another account. Try Restore Purchase on the original account.',
        );
      }
      final message = error.message?.trim();
      throw StateError(
        message?.isNotEmpty == true
            ? message!
            : 'Unable to complete the purchase right now.',
      );
    }
  }

  static Future<CustomerInfo?> restorePurchases() async {
    if (!isAvailable) {
      throw StateError(
        'Google Play restore is only available on Android builds with billing enabled.',
      );
    }
    await initializeForCurrentUser();

    try {
      final customerInfo = await Purchases.restorePurchases();
      validateCustomerInfoForProAccess(
        customerInfo,
        isRestore: true,
      );
      return customerInfo;
    } on PlatformException catch (error) {
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        throw StateError('Restore was cancelled.');
      }
      if (code == PurchasesErrorCode.networkError ||
          code == PurchasesErrorCode.offlineConnectionError) {
        throw StateError(
          'A network issue interrupted restore. Please check your connection and try again.',
        );
      }
      if (code == PurchasesErrorCode.invalidReceiptError ||
          code == PurchasesErrorCode.purchaseInvalidError) {
        throw StateError(
          'Google Play could not verify the purchase receipt. Please try again.',
        );
      }
      if (code == PurchasesErrorCode.receiptAlreadyInUseError) {
        throw StateError(
          'This purchase is already linked to another account. Restore with the original Google Play account.',
        );
      }
      final message = error.message?.trim();
      throw StateError(
        message?.isNotEmpty == true
            ? message!
            : 'Unable to restore purchases right now.',
      );
    }
  }

  static Future<EntitlementInfo?> getActiveProEntitlement({
    CustomerInfo? customerInfo,
  }) async {
    final info = customerInfo ?? await getCustomerInfo();
    return activeProEntitlementFromCustomerInfo(info);
  }

  static Future<String?> getManagementUrl() async {
    final info = await getCustomerInfo();
    final url = info?.managementURL?.trim();
    if (url == null || url.isEmpty) return null;
    return url;
  }

  static Future<String?> _resolveAppUserId() async {
    final storedAppUserId = StorageService.getAppUserId()?.trim();
    if (storedAppUserId != null && storedAppUserId.isNotEmpty) {
      return storedAppUserId;
    }

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid.trim();
    if (user != null && !user.isAnonymous && uid != null && uid.isNotEmpty) {
      await StorageService.setAppUserId(uid);
      return uid;
    }

    if (user != null) {
      try {
        final token = await user.getIdTokenResult();
        final claimEmail =
            token.claims?['github_email']?.toString().trim().toLowerCase() ??
                token.claims?['email']?.toString().trim().toLowerCase();
        if (claimEmail != null && claimEmail.isNotEmpty) {
          return 'email:$claimEmail';
        }
      } catch (_) {}
    }

    final username = StorageService.getUsername()?.trim().toLowerCase();
    if (username != null && username.isNotEmpty) {
      return 'github:$username';
    }

    return null;
  }

  static Future<void> _syncSubscriberAttributes() async {
    final appUserId = StorageService.getAppUserId()?.trim();
    final email = StorageService.getUserEmail()?.trim();
    final displayName = StorageService.getDisplayName()?.trim();
    final username = StorageService.getUsername()?.trim();

    try {
      if (email != null && email.isNotEmpty) {
        await Purchases.setEmail(email);
      }
      if (displayName != null && displayName.isNotEmpty) {
        await Purchases.setDisplayName(displayName);
      }
      final attributes = <String, String>{};
      if (username != null && username.isNotEmpty) {
        attributes['github_username'] = username;
      }
      if (email != null && email.isNotEmpty) {
        attributes['github_email'] = email;
      }
      if (appUserId != null && appUserId.isNotEmpty) {
        attributes['app_user_id'] = appUserId;
      }
      if (attributes.isNotEmpty) {
        await Purchases.setAttributes(attributes);
      }
    } on MissingPluginException {
      AppLog.error(
          'RevenueCat plugin unavailable while syncing attributes.', null);
    } on PlatformException catch (error, stack) {
      AppLog.error(
        'RevenueCat subscriber attribute sync failed: ${error.message}',
        stack,
      );
    } catch (error, stack) {
      AppLog.error(
          'RevenueCat subscriber attribute sync failed: $error', stack);
    }
  }

  static EntitlementInfo? activeProEntitlementFromCustomerInfo(
    CustomerInfo? customerInfo,
  ) {
    final entitlement = customerInfo?.entitlements.active[entitlementId];
    if (entitlement == null || !entitlement.isActive) {
      return null;
    }
    if (entitlement.verification == VerificationResult.failed) {
      AppLog.error(
        'RevenueCat entitlement verification failed for $entitlementId.',
        null,
      );
      return null;
    }
    return entitlement;
  }

  @visibleForTesting
  static void validateCustomerInfoForProAccess(
    CustomerInfo? customerInfo, {
    required bool isRestore,
  }) {
    if (activeProEntitlementFromCustomerInfo(customerInfo) != null) {
      return;
    }

    final attemptedEntitlement = customerInfo?.entitlements.all[entitlementId];
    if (attemptedEntitlement?.verification == VerificationResult.failed) {
      throw StateError(
        'Google Play could not verify this purchase. Please try Restore Purchase or contact support.',
      );
    }

    if (isRestore) {
      throw StateError(
        'No active Pro subscription was found for this Google Play account.',
      );
    }

    throw StateError(
      'Payment completed, but Pro access is not active yet. Please wait a moment and tap Restore Purchase.',
    );
  }
}
