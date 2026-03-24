import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:github_wallpaper/core/constants/environment_config.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/features/membership/models/membership_models.dart';
import 'package:github_wallpaper/features/membership/services/revenuecat_service.dart';

class MembershipService {
  MembershipService._();

  static FirebaseFirestore? get _dbOrNull {
    if (Firebase.apps.isEmpty) {
      return null;
    }
    return FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'default',
    );
  }

  static Future<MembershipInfo> refresh({
    bool force = false,
    CustomerInfo? revenueCatCustomerInfo,
  }) async {
    final cached = StorageService.getCachedMembershipInfo();
    final now = DateTime.now().toLocal();

    if (!force && !shouldRevalidate(cached, now: now)) {
      return cached!;
    }

    final email = await _membershipEmail();
    if (email == null) {
      final fallback = await _buildFallbackMembership(
        cached: cached,
        now: now,
        revenueCatCustomerInfo: revenueCatCustomerInfo,
      );
      await StorageService.setCachedMembershipInfo(fallback);
      return fallback;
    }

    final db = _dbOrNull;
    if (db == null) {
      final fallback = await _buildFallbackMembership(
        cached: cached,
        now: now,
        revenueCatCustomerInfo: revenueCatCustomerInfo,
      );
      await StorageService.setCachedMembershipInfo(fallback);
      return fallback;
    }

    try {
      final docRef = db.collection('users').doc(email);
      final snapshot = await docRef.get();
      final existing = snapshot.exists
          ? _membershipFromFirestore(
              snapshot.data() ?? const <String, dynamic>{})
          : null;

      MembershipInfo resolved;
      if (existing == null) {
        resolved = buildInitialMembership(now: now);
        await docRef
            .set(
              _firestorePayload(
                resolved,
                username: StorageService.getUsername(),
                email: email,
              ),
              SetOptions(merge: true),
            )
            .catchError((_) {});
      } else {
        resolved = resolveMembership(
          info: existing,
          now: now,
        );
      }

      resolved = await _mergeRevenueCatEntitlements(
        resolved,
        revenueCatCustomerInfo: revenueCatCustomerInfo,
      );

      final withValidation = resolved.copyWith(
        lastValidatedAt: now,
        fromCache: false,
      );
      await StorageService.setCachedMembershipInfo(withValidation);
      return withValidation;
    } catch (e, s) {
      AppLog.error('Membership refresh failed: $e', s);
      final fallback = await _buildFallbackMembership(
        cached: cached,
        now: now,
        revenueCatCustomerInfo: revenueCatCustomerInfo,
      );
      await StorageService.setCachedMembershipInfo(fallback);
      return fallback;
    }
  }

  static Future<MembershipInfo> redeemCouponCode(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.isEmpty) {
      throw ArgumentError('Coupon code is required');
    }

    if (Firebase.apps.isEmpty) {
      throw StateError(
        'A signed-in app session is required to redeem a coupon.',
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      throw StateError(
        'A signed-in app session is required to redeem a coupon.',
      );
    }

    final idToken = await user.getIdToken();
    final resolvedEmail = await _membershipEmail(forceRefreshIdToken: true);
    if (resolvedEmail != null && resolvedEmail.isNotEmpty) {
      await StorageService.setUserEmail(resolvedEmail);
    }

    final response = await http.post(
      Uri.parse(AppConfig.couponRedeemUrl),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'code': normalizedCode}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final backendMessage = _extractBackendMessage(response.body);
      throw StateError(backendMessage ?? AppStrings.membershipCouponInvalid);
    }

    return refresh(force: true);
  }

  static bool shouldRevalidate(MembershipInfo? cached, {DateTime? now}) {
    if (cached == null) return true;

    final current = (now ?? DateTime.now()).toLocal();
    final lastValidatedAt =
        cached.lastValidatedAt ?? StorageService.getMembershipLastValidatedAt();
    if (lastValidatedAt == null) return true;

    return !_isSameLocalDay(lastValidatedAt, current);
  }

  @visibleForTesting
  static MembershipInfo buildInitialMembership({
    required DateTime now,
  }) {
    return MembershipInfo(
      plan: MembershipPlan.free,
      createdAt: now.toLocal(),
    );
  }

  @visibleForTesting
  static MembershipInfo resolveMembership({
    required MembershipInfo info,
    required DateTime now,
  }) {
    var resolved = info.copyWith(fromCache: false);

    if (resolved.plan == MembershipPlan.couponPro &&
        resolved.proAccessExpiresAt != null) {
      final expiry = resolved.proAccessExpiresAt!;
      final currentDay = DateTime(now.year, now.month, now.day);
      final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
      if (!currentDay.isBefore(expiryDay)) {
        resolved = resolved.copyWith(
          plan: MembershipPlan.free,
          clearProAccessExpiresAt: true,
          clearCouponCode: true,
          clearPaidAt: true,
          clearPaidAmount: true,
        );
      }
    }

    return resolved;
  }

  static MembershipInfo _membershipFromFirestore(
    Map<String, dynamic> data,
  ) {
    final rawPlan = _cleanString(data['plan']);
    final plan = _planFromFirestore(rawPlan);
    if (rawPlan == MembershipPlan.pro.value) {
      AppLog.info(
        'Ignoring Firestore pro plan for ${data['email'] ?? 'unknown user'} and waiting for RevenueCat verification.',
      );
    }

    return MembershipInfo(
      plan: plan,
      createdAt: _parseFirestoreDate(data['createdAt']),
      proAccessExpiresAt: _parseFirestoreDate(data['proAccessExpiresAt']),
      paidAt: _parseFirestoreDate(data['paidAt']),
      paidAmount: (data['paidAmount'] as num?)?.toInt(),
      couponCode: _cleanString(data['couponCode']),
    );
  }

  static Map<String, dynamic> _firestorePayload(
    MembershipInfo info, {
    required String? username,
    required String email,
  }) {
    final appUserId = StorageService.getAppUserId();
    final payload = <String, dynamic>{
      'email': email,
      'username': username?.trim(),
      'plan': info.plan.value,
      'createdAt': _timestampFromDate(info.createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (appUserId != null && appUserId.isNotEmpty) {
      payload['appUserId'] = appUserId;
    }

    final proAccessExpiresAt = _timestampFromDate(info.proAccessExpiresAt);
    if (proAccessExpiresAt != null) {
      payload['proAccessExpiresAt'] = proAccessExpiresAt;
    }

    final paidAt = _timestampFromDate(info.paidAt);
    if (paidAt != null) {
      payload['paidAt'] = paidAt;
    }

    if (info.paidAmount != null) {
      payload['paidAmount'] = info.paidAmount;
    }

    if (info.couponCode != null && info.couponCode!.trim().isNotEmpty) {
      payload['couponCode'] = info.couponCode;
    }

    return payload;
  }

  static Future<String?> _membershipEmail({
    bool forceRefreshIdToken = false,
  }) async {
    final stored = StorageService.getUserEmail()?.trim().toLowerCase();
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }

    if (Firebase.apps.isEmpty) {
      return null;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await StorageService.syncAuthenticatedAppUserId(user: user);
    }
    final directEmail = user?.email?.trim().toLowerCase();
    if (directEmail != null && directEmail.isNotEmpty) {
      await StorageService.setUserEmail(directEmail);
      return directEmail;
    }

    if (user != null) {
      try {
        final token = await user.getIdTokenResult(forceRefreshIdToken);
        final claimEmail =
            token.claims?['github_email']?.toString().trim().toLowerCase() ??
                token.claims?['email']?.toString().trim().toLowerCase();
        if (claimEmail != null && claimEmail.isNotEmpty) {
          await StorageService.setUserEmail(claimEmail);
          return claimEmail;
        }
      } catch (_) {}
    }

    return null;
  }

  static Timestamp? _timestampFromDate(DateTime? value) {
    return value == null ? null : Timestamp.fromDate(value.toUtc());
  }

  static DateTime? _parseFirestoreDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate().toLocal();
    if (raw is DateTime) return raw.toLocal();
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  static String? _cleanString(dynamic raw) {
    final value = raw?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  static MembershipPlan _planFromFirestore(String? rawPlan) {
    if (rawPlan == MembershipPlan.couponPro.value) {
      return MembershipPlan.couponPro;
    }
    return MembershipPlan.free;
  }

  static bool _isSameLocalDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String? _extractBackendMessage(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {}

    return null;
  }

  @visibleForTesting
  static MembershipInfo mergeRevenueCatCustomerInfo({
    required MembershipInfo info,
    required CustomerInfo? customerInfo,
  }) {
    final entitlement =
        RevenueCatService.activeProEntitlementFromCustomerInfo(customerInfo);
    if (entitlement == null) {
      return info;
    }

    return info.copyWith(
      plan: MembershipPlan.pro,
      paidAt: _parseRevenueCatDate(entitlement.latestPurchaseDate),
      proAccessExpiresAt: _parseRevenueCatDate(entitlement.expirationDate),
      clearCouponCode: true,
    );
  }

  static Future<MembershipInfo> _mergeRevenueCatEntitlements(
    MembershipInfo info, {
    CustomerInfo? revenueCatCustomerInfo,
  }) async {
    try {
      var customerInfo = revenueCatCustomerInfo;
      if (customerInfo == null) {
        await RevenueCatService.initializeForCurrentUser();
        customerInfo = await RevenueCatService.getCustomerInfo();
      }
      return mergeRevenueCatCustomerInfo(
        info: info,
        customerInfo: customerInfo,
      );
    } catch (e, s) {
      AppLog.error('RevenueCat membership merge failed: $e', s);
      return info;
    }
  }

  static DateTime? _parseRevenueCatDate(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  static Future<MembershipInfo> _buildFallbackMembership({
    required MembershipInfo? cached,
    required DateTime now,
    CustomerInfo? revenueCatCustomerInfo,
  }) async {
    final base = (cached ?? MembershipInfo.free()).copyWith(
      lastValidatedAt: now,
      fromCache: cached != null,
    );
    final resolved = await _mergeRevenueCatEntitlements(
      base,
      revenueCatCustomerInfo: revenueCatCustomerInfo,
    );
    return resolved.copyWith(
      lastValidatedAt: now,
      fromCache: cached != null,
    );
  }
}
