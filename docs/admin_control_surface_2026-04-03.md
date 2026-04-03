# Admin Control Surface

Date: 2026-04-03

## Purpose

This note describes what the standalone web admin currently controls, what it reads, and what was intentionally removed during the 2026-04-03 cleanup.

## What The Admin Dashboard Controls

### Editable App Config

The admin dashboard currently edits one Firestore config document with these live app keys:

- `maintenance_mode`
- `maintenance_message`
- `force_update_enabled`
- `force_update_min_version`
- `force_update_message`
- `smart_quotes_enabled`

These values are read by the Flutter app through the Firestore-backed remote config layer.

### Admin Broadcast Pushes

The admin dashboard can send broadcast notifications to all app users who:

- are signed in
- have a valid app session
- are not anonymous
- have admin broadcasts enabled in settings
- have granted OS notification permission

The broadcast request is sent through Cloud Functions and tracked in Firestore under `admin_notifications`.

### Admin Access Management

The dashboard manages the `admins` collection and can:

- add admin entries
- edit role, enabled state, and notes
- delete admin entries, except the current admin or the last enabled admin

### Read-Only Operational Surfaces

The dashboard also reads and displays:

- user records
- admin broadcast delivery feed
- metrics summary
- crash reports
- telemetry logs

## Cleanup Applied On 2026-04-03

### Removed Stale Or Misleading Items

- Removed stale paywall/billing wording from the Users section.
- Removed unused admin config fields that did not affect the app:
  - `debug_mode_enabled`
  - `onboarding_version`

### Reduced Hardcoded Drift

- Centralized Firestore collection and document names in the admin config file.
- Centralized admin broadcast form limits and placeholders in the admin config file.

## Important Limits

- The admin dashboard is still tied to a specific Firebase project through its web config.
- The Functions base URL is still explicitly configured for the target project.
- Broadcast delivery counts depend on client acknowledgements, so Firestore totals can undercount real OS delivery.

## Related Files

- `admin/index.html`
- `admin/app.js`
- `admin/config.js`
- `functions/index.js`
- `lib/app/services/remote_config_service.dart`

## Recommended Next Steps

1. Keep using this dashboard for operational controls, not product experimentation that lacks app-side readers.
2. If new config keys are added, add the app-side reader and the admin schema together in one change.
3. If a future environment split is needed, move Firebase/admin config to environment-specific deployment inputs instead of editing the checked-in constants manually.
