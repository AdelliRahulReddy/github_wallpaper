# Membership System

## Current Model

- Every new user starts on the `free` plan.
- Paid Pro access is controlled only by RevenueCat.
- The live paid offer is a monthly subscription with a 14-day free trial.
- Coupon access is controlled through Firebase and stored as `coupon_pro`.
- Locked Pro features stay visible in the UI and route free users to the paywall.

## Access Sources

### Free

- Default state for all new users.
- Pro features remain visible but locked.
- Tapping a locked Pro feature opens the paywall.

### RevenueCat Subscription

- RevenueCat is the source of truth for paid access.
- If the active `pro` entitlement exists, the app unlocks Pro features.
- The paywall handles purchase, restore, and manage-subscription flows.

### Coupon Access

- Firebase validates coupon codes and marks them as used.
- Successful coupon redemption writes `plan: "coupon_pro"` and `proAccessExpiresAt` to the user document.
- Coupon access unlocks the same Pro features as an active subscription.

## Firestore User Document

```text
/users
  └── {userEmail}
        ├── plan: "free" | "coupon_pro"
        ├── createdAt: timestamp
        ├── proAccessExpiresAt: timestamp?   // coupon access only
        ├── couponCode: string?              // coupon access only
        ├── username: string?
        └── updatedAt: timestamp?
```

Notes:

- Legacy `plan: "pro"` Firestore records are no longer authoritative for paid access.
- Subscription status is resolved from RevenueCat customer info, not Firestore.

## App Behavior

1. Resolve the Firebase user record.
2. Resolve RevenueCat customer info.
3. If RevenueCat has an active `pro` entitlement, unlock Pro.
4. Otherwise, if Firestore has an active `coupon_pro` record, unlock Pro.
5. Otherwise, keep the user on Free.

## UI Rules

- Settings shows:
  - `Upgrade to Pro`
  - `Restore Purchase`
  - `Subscription Details`
  - `Redeem Coupon`
- `Redeem Coupon` stays accessible from root settings navigation.
- The paywall emphasizes:
  - monthly plan
  - 14-day free trial
  - clear pricing and benefit copy

## Firebase Responsibilities

Firebase should only handle:

- user profile data
- coupon validation
- coupon access records

Firebase should not:

- grant paid subscriptions
- cancel paid subscriptions
- act as the authority for store purchases

## Admin Rules

- Admin can manage coupon codes.
- Admin can view user and coupon access records.
- Admin should not directly grant or extend paid Pro access in Firestore.
