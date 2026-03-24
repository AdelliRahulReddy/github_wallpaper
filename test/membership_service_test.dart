import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/features/membership/models/membership_models.dart';
import 'package:github_wallpaper/features/membership/services/membership_service.dart';
import 'package:github_wallpaper/features/membership/services/revenuecat_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

CustomerInfo _buildCustomerInfo({
  EntitlementInfo? entitlement,
  String? managementUrl,
}) {
  final allEntitlements = <String, EntitlementInfo>{};
  final activeEntitlements = <String, EntitlementInfo>{};
  if (entitlement != null) {
    allEntitlements[RevenueCatService.entitlementId] = entitlement;
    if (entitlement.isActive) {
      activeEntitlements[RevenueCatService.entitlementId] = entitlement;
    }
  }

  return CustomerInfo(
    EntitlementInfos(
      allEntitlements,
      activeEntitlements,
      verification:
          entitlement?.verification ?? VerificationResult.notRequested,
    ),
    entitlement == null
        ? const {}
        : {'gitwall_pro_monthly': entitlement.latestPurchaseDate},
    entitlement?.isActive == true ? ['gitwall_pro_monthly'] : const [],
    entitlement == null ? const [] : ['gitwall_pro_monthly'],
    const <StoreTransaction>[],
    '2026-01-01T00:00:00Z',
    'app-user-123',
    entitlement?.expirationDate == null
        ? const {}
        : {'gitwall_pro_monthly': entitlement!.expirationDate},
    '2026-03-24T00:00:00Z',
    latestExpirationDate: entitlement?.expirationDate,
    managementURL: managementUrl,
  );
}

EntitlementInfo _buildProEntitlement({
  bool isActive = true,
  VerificationResult verification = VerificationResult.verified,
  PeriodType periodType = PeriodType.normal,
  String? expirationDate = '2026-04-24T00:00:00Z',
}) {
  return EntitlementInfo(
    RevenueCatService.entitlementId,
    isActive,
    isActive,
    '2026-03-24T00:00:00Z',
    '2026-03-24T00:00:00Z',
    'gitwall_pro_monthly',
    false,
    store: Store.playStore,
    periodType: periodType,
    expirationDate: expirationDate,
    verification: verification,
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    await StorageService.clearCachedMembershipInfo();
  });

  group('MembershipService.buildInitialMembership', () {
    test('creates free membership for new users', () {
      final info = MembershipService.buildInitialMembership(
        now: DateTime(2026, 12, 15, 10),
      );

      expect(info.plan, MembershipPlan.free);
      expect(info.hasProAccess, isFalse);
      expect(info.proAccessExpiresAt, isNull);
    });
  });

  group('MembershipService.resolveMembership', () {
    test('keeps coupon pro active before expiry', () {
      final info = MembershipInfo(
        plan: MembershipPlan.couponPro,
        createdAt: DateTime(2026, 10, 1),
        proAccessExpiresAt: DateTime(2027, 3, 30),
        couponCode: 'TEST180',
      );

      final resolved = MembershipService.resolveMembership(
        info: info,
        now: DateTime(2027, 3, 1),
      );

      expect(resolved.plan, MembershipPlan.couponPro);
      expect(resolved.hasProAccess, isTrue);
      expect(resolved.couponCode, 'TEST180');
    });

    test('expires coupon pro on expiry day back to free', () {
      final info = MembershipInfo(
        plan: MembershipPlan.couponPro,
        createdAt: DateTime(2026, 9, 1),
        proAccessExpiresAt: DateTime(2027, 2, 28, 23, 59),
        couponCode: 'TEST180',
      );

      final resolved = MembershipService.resolveMembership(
        info: info,
        now: DateTime(2027, 2, 28, 9),
      );

      expect(resolved.plan, MembershipPlan.free);
      expect(resolved.hasProAccess, isFalse);
      expect(resolved.couponCode, isNull);
      expect(resolved.proAccessExpiresAt, isNull);
    });

    test('preserves paid pro membership without expiry downgrade', () {
      final info = MembershipInfo(
        plan: MembershipPlan.pro,
        createdAt: DateTime(2026, 9, 1),
        paidAt: DateTime(2027, 1, 15),
        paidAmount: 199,
      );

      final resolved = MembershipService.resolveMembership(
        info: info,
        now: DateTime(2028, 1, 1),
      );

      expect(resolved.plan, MembershipPlan.pro);
      expect(resolved.hasProAccess, isTrue);
      expect(resolved.paidAmount, 199);
    });
  });

  group('MembershipService.shouldRevalidate', () {
    test('revalidates when there is no cached membership', () {
      expect(MembershipService.shouldRevalidate(null), isTrue);
    });

    test('skips revalidation on the same local day', () {
      final info = MembershipInfo.free(
        lastValidatedAt: DateTime(2026, 3, 23, 8),
      );

      final shouldRevalidate = MembershipService.shouldRevalidate(
        info,
        now: DateTime(2026, 3, 23, 21),
      );

      expect(shouldRevalidate, isFalse);
    });

    test('revalidates on the next local day', () {
      final info = MembershipInfo.free(
        lastValidatedAt: DateTime(2026, 3, 23, 23, 59),
      );

      final shouldRevalidate = MembershipService.shouldRevalidate(
        info,
        now: DateTime(2026, 3, 24, 0, 1),
      );

      expect(shouldRevalidate, isTrue);
    });
  });

  group('RevenueCat membership merging', () {
    test('purchase customer info unlocks pro immediately', () async {
      final customerInfo = _buildCustomerInfo(
        entitlement: _buildProEntitlement(),
      );

      final info = await MembershipService.refresh(
        force: true,
        revenueCatCustomerInfo: customerInfo,
      );

      expect(info.plan, MembershipPlan.pro);
      expect(info.hasProAccess, isTrue);
      expect(StorageService.getCachedMembershipInfo()?.hasProAccess, isTrue);
    });

    test('failed RevenueCat verification does not unlock pro', () async {
      final customerInfo = _buildCustomerInfo(
        entitlement: _buildProEntitlement(
          verification: VerificationResult.failed,
        ),
      );

      final info = await MembershipService.refresh(
        force: true,
        revenueCatCustomerInfo: customerInfo,
      );

      expect(info.plan, MembershipPlan.free);
      expect(info.hasProAccess, isFalse);
    });

    test('restore validation rejects accounts without an active pro purchase',
        () {
      final customerInfo = _buildCustomerInfo();

      expect(
        () => RevenueCatService.validateCustomerInfoForProAccess(
          customerInfo,
          isRestore: true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('purchase validation rejects invalid receipts', () {
      final customerInfo = _buildCustomerInfo(
        entitlement: _buildProEntitlement(
          verification: VerificationResult.failed,
        ),
      );

      expect(
        () => RevenueCatService.validateCustomerInfoForProAccess(
          customerInfo,
          isRestore: false,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
