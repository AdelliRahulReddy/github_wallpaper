import 'package:flutter/foundation.dart';

enum MembershipPlan {
  couponPro('coupon_pro'),
  pro('pro'),
  free('free');

  const MembershipPlan(this.value);
  final String value;

  static MembershipPlan fromValue(String? raw) {
    return MembershipPlan.values.firstWhere(
      (plan) => plan.value == raw,
      orElse: () => MembershipPlan.free,
    );
  }
}

@immutable
class MembershipInfo {
  final MembershipPlan plan;
  final DateTime? createdAt;
  final DateTime? proAccessExpiresAt;
  final DateTime? paidAt;
  final int? paidAmount;
  final String? couponCode;
  final DateTime? lastValidatedAt;
  final bool fromCache;

  const MembershipInfo({
    required this.plan,
    this.createdAt,
    this.proAccessExpiresAt,
    this.paidAt,
    this.paidAmount,
    this.couponCode,
    this.lastValidatedAt,
    this.fromCache = false,
  });

  factory MembershipInfo.free({
    DateTime? lastValidatedAt,
    bool fromCache = false,
  }) {
    return MembershipInfo(
      plan: MembershipPlan.free,
      lastValidatedAt: lastValidatedAt?.toLocal(),
      fromCache: fromCache,
    );
  }

  factory MembershipInfo.fromCacheJson(Map<String, dynamic> json) {
    return MembershipInfo(
      plan: MembershipPlan.fromValue(json['plan']?.toString()),
      createdAt: _parseStoredDateTime(json['createdAt']),
      proAccessExpiresAt: _parseStoredDateTime(json['proAccessExpiresAt']),
      paidAt: _parseStoredDateTime(json['paidAt']),
      paidAmount: (json['paidAmount'] as num?)?.toInt(),
      couponCode: _cleanString(json['couponCode']),
      lastValidatedAt: _parseStoredDateTime(json['lastValidatedAt']),
      fromCache: json['fromCache'] == true,
    );
  }

  Map<String, dynamic> toCacheJson() => {
        'plan': plan.value,
        'createdAt': createdAt?.toIso8601String(),
        'proAccessExpiresAt': proAccessExpiresAt?.toIso8601String(),
        'paidAt': paidAt?.toIso8601String(),
        'paidAmount': paidAmount,
        'couponCode': couponCode,
        'lastValidatedAt': lastValidatedAt?.toIso8601String(),
        'fromCache': fromCache,
      };

  MembershipInfo copyWith({
    MembershipPlan? plan,
    DateTime? createdAt,
    bool clearCreatedAt = false,
    DateTime? proAccessExpiresAt,
    bool clearProAccessExpiresAt = false,
    DateTime? paidAt,
    bool clearPaidAt = false,
    int? paidAmount,
    bool clearPaidAmount = false,
    String? couponCode,
    bool clearCouponCode = false,
    DateTime? lastValidatedAt,
    bool clearLastValidatedAt = false,
    bool? fromCache,
  }) {
    return MembershipInfo(
      plan: plan ?? this.plan,
      createdAt: clearCreatedAt ? null : (createdAt ?? this.createdAt),
      proAccessExpiresAt: clearProAccessExpiresAt
          ? null
          : (proAccessExpiresAt ?? this.proAccessExpiresAt),
      paidAt: clearPaidAt ? null : (paidAt ?? this.paidAt),
      paidAmount: clearPaidAmount ? null : (paidAmount ?? this.paidAmount),
      couponCode: clearCouponCode ? null : (couponCode ?? this.couponCode),
      lastValidatedAt: clearLastValidatedAt
          ? null
          : (lastValidatedAt ?? this.lastValidatedAt),
      fromCache: fromCache ?? this.fromCache,
    );
  }

  bool get hasProAccess =>
      plan == MembershipPlan.pro || plan == MembershipPlan.couponPro;

  bool get isSubscriptionAccess => plan == MembershipPlan.pro;

  bool get isCouponAccess =>
      plan == MembershipPlan.couponPro && proAccessExpiresAt != null;

  MembershipInfo markCached(bool value) => copyWith(fromCache: value);

  static DateTime? _parseStoredDateTime(dynamic raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  static String? _cleanString(dynamic raw) {
    final value = raw?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }
}
