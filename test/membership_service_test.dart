import 'package:flutter_test/flutter_test.dart';
import 'package:github_wallpaper/data/models/membership_models.dart';
import 'package:github_wallpaper/shared/services/membership_service.dart';

void main() {
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
}
