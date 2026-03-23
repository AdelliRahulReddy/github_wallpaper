# RevenueCat Handover

Date: 2026-03-23
Repo: `c:\Users\adell\Desktop\github_wallpaper`
Context: Flutter app with Firebase auth/membership system. User requested RevenueCat integration using Google Play Billing with public key `goog_uOrOeEbviaYqcfNwfGcyRGQvxiU`.

## What Was Completed

### Dependency
- `purchases_flutter` was already added to `pubspec.yaml`
- Current version in repo: `^8.11.0`

### Config
- Added RevenueCat app config constants in:
  - `lib/core/constants/environment_config.dart`
- Added:
  - `AppConfig.revenueCatGooglePublicKey`
  - `AppConfig.revenueCatProEntitlementId`

### New Service
- Added new file:
  - `lib/shared/services/revenuecat_service.dart`
- Service currently includes:
  - Android-only availability guard
  - SDK configure/login flow
  - user identity resolution from stored email / Firebase / GitHub username
  - subscriber attribute sync
  - `getOfferings()`
  - `getCustomerInfo()`
  - `getActiveProEntitlement()`
  - `purchasePackage()`
  - `restorePurchases()`
  - `getManagementUrl()`
  - `logOut()`

### App Wiring
- Bootstrap now initializes RevenueCat before membership refresh:
  - `lib/shared/services/bootstrap_service.dart`
- GitHub sign-in setup now initializes RevenueCat:
  - `lib/features/auth/screens/setup_screen.dart`
- GitHub reconnect flow now initializes RevenueCat:
  - `lib/features/settings/screens/settings_screen.dart`
- Logout now logs out RevenueCat too:
  - `lib/features/settings/screens/settings_screen.dart`

### Membership Merge
- `MembershipService.refresh()` now tries to merge an active RevenueCat entitlement into app membership state:
  - `lib/shared/services/membership_service.dart`
- Current behavior:
  - if RevenueCat entitlement `pro` is active, returned membership becomes `MembershipPlan.pro`
  - expiration comes from RevenueCat entitlement expiration date
  - existing founder/coupon/free logic remains intact when no active entitlement exists

### Access Page UI Work
- `lib/features/settings/screens/membership_access_page.dart` was partially upgraded to:
  - load current offering/customer entitlement
  - show Google Play plans section
  - purchase plan from RevenueCat
  - restore purchases through RevenueCat
  - show Google Play manage-subscription action for store-managed subscriptions
  - replace some “planned” messaging with live Google Play messaging

### Copy Updates
- Updated some user-facing copy:
  - `lib/core/app/main_nav_screen.dart`
  - `lib/shared/services/notification_service.dart`
  - `lib/features/wallpaper/screens/customize/customize_screen.dart`

## Current Blocker

There is a compile error in:
- `lib/features/settings/screens/membership_access_page.dart`

Error:
- `_PackageCard` is calling `_billingPeriodLabel(package)`
- but `_billingPeriodLabel` exists only inside `_MembershipAccessPageState`
- so analyzer/tests fail with:
  - `The method '_billingPeriodLabel' isn't defined for the type '_PackageCard'`

## Exact Fix Needed First

Choose one of these:

1. Preferred:
- add a new `billingPeriodLabel` string parameter to `_PackageCard`
- compute it in `_MembershipAccessPageState` with `_billingPeriodLabel(package)`
- pass it into `_PackageCard`
- render that string instead of calling `_billingPeriodLabel()` from inside `_PackageCard`

2. Alternative:
- move `_billingPeriodLabel` out to a top-level helper function so both the state class and `_PackageCard` can use it

This should clear the analyzer/test failure immediately.

## Verification Status Before Stop

### Ran
- `dart analyze ...`
- `flutter test test/environment_config_test.dart test/membership_service_test.dart test/free_experience_test.dart test/customize_quote_membership_test.dart test/daily_quotes_test.dart test/membership_entitlements_test.dart`

### Result
- failed only because of the `_billingPeriodLabel` compile error in `membership_access_page.dart`

## Files Touched In This RevenueCat Pass

- `pubspec.yaml`
- `lib/core/constants/environment_config.dart`
- `lib/shared/services/revenuecat_service.dart`
- `lib/shared/services/bootstrap_service.dart`
- `lib/features/auth/screens/setup_screen.dart`
- `lib/features/settings/screens/settings_screen.dart`
- `lib/shared/services/membership_service.dart`
- `lib/features/settings/screens/membership_access_page.dart`
- `lib/core/app/main_nav_screen.dart`
- `lib/shared/services/notification_service.dart`
- `lib/features/wallpaper/screens/customize/customize_screen.dart`

## Important Product Decisions Already Reflected

- Founder claim remains separate from paid billing
- Founder access duration is still 3 months
- Coupon access remains 6 months
- Paid plans should come from Google Play via RevenueCat
- Restore membership should use RevenueCat restore, not just cached app state
- Store-managed subscriptions should not show destructive “Use Free plan” as the main cancellation path
- Instead, purchased plans should open Google Play subscription management

## Things Still Pending After Fixing Compile Error

### Must Do
- make `membership_access_page.dart` compile again
- rerun analyzer/tests
- test purchase/restore flow on Android device

### Likely Follow-up Cleanup
- improve package card labeling if RevenueCat offerings are not configured yet
- confirm RevenueCat entitlement ID really is `pro` in dashboard
- confirm package identifiers/offering setup in RevenueCat dashboard
- check whether `MembershipService.refresh()` should store more purchase metadata

### Nice To Have
- update docs to mention RevenueCat / Google Play Billing
- consider webhook or server-side sync later if admin needs paid membership visibility in Firestore

## Recommended Next Commands

After fixing the compile issue:

```cmd
dart analyze lib/core/constants/environment_config.dart lib/shared/services/revenuecat_service.dart lib/shared/services/membership_service.dart lib/shared/services/bootstrap_service.dart lib/features/auth/screens/setup_screen.dart lib/features/settings/screens/settings_screen.dart lib/features/settings/screens/membership_access_page.dart lib/core/app/main_nav_screen.dart lib/shared/services/notification_service.dart lib/features/wallpaper/screens/customize/customize_screen.dart
```

```cmd
flutter test test/environment_config_test.dart test/membership_service_test.dart test/free_experience_test.dart test/customize_quote_membership_test.dart test/daily_quotes_test.dart test/membership_entitlements_test.dart
```

Then device test:

1. Login with GitHub
2. Open Settings > Membership & Access
3. Confirm Google Play plans section renders
4. Confirm restore works without crash
5. Confirm founder claim / coupon still work
6. Confirm purchased Pro updates UI and Customize locked items unlock

## External Reference Used

Official RevenueCat docs were checked during this pass:
- https://www.revenuecat.com/docs/getting-started/installation/flutter
- https://www.revenuecat.com/docs/getting-started/displaying-products

The implementation was aligned to the installed local SDK API in:
- `C:\Users\adell\AppData\Local\Pub\Cache\hosted\pub.dev\purchases_flutter-8.11.0`
