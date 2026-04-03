# CODEBASE

Current source-of-truth index for the GitWall repository.

This file is intentionally shorter than the older generated inventory. It is optimized for fast orientation by humans and coding agents.

## Current Product State

- App type: Flutter mobile app with Firebase-backed auth/session support and Android wallpaper integrations.
- Pricing state: free-only. No active paywall, membership, or subscription flow in the user experience.
- Current user-facing tabs: `Home`, `Stats`, `Customize`, `Settings`.
- Wallpaper apply path in Customize: lock-screen only.
- Share system: four core story templates plus `Wrapped` as a non-core seasonal asset.
- Quote system: local curated quote catalog with activity-aware selection, quote history, and deterministic fallback behavior.
- Admin tooling: separate web dashboard for app config, admin broadcasts, whitelist management, user visibility, metrics, crash reports, and logs.

## Runtime Flow

1. GitHub OAuth completes through the app and Cloud Functions exchange flow.
2. Firebase custom-token session is restored or created.
3. GitHub contribution data is fetched from the GitHub GraphQL API.
4. Data is cached locally in secure/non-secure storage.
5. The smart quote engine scores the bundled quote catalog against current activity and persists the daily selection locally.
6. Product state is assembled for the UI, wallpaper renderer, widget service, and share surfaces.
7. Background sync, reminders, and notifications run from stored settings.

## Search Index

- Startup and boot: `lib/main.dart`, `lib/app/app_entry.dart`, `lib/app/services/bootstrap_service.dart`
- GitHub auth and identity: `lib/features/auth/services/`, `functions/index.js`
- Sync and repository logic: `lib/features/contributions/repositories/contribution_repository.dart`
- Quote selection and history: `lib/features/contributions/services/daily_quotes.dart`, `lib/features/contributions/models/quote_models.dart`, `lib/features/contributions/data/curated_quote_pool.dart`
- Notifications: `lib/app/services/notification_catalog.dart`, `lib/app/services/notification_service.dart`, `lib/app/services/background_scheduler.dart`
- Wallpaper preview/render/apply: `lib/features/wallpaper/pages/customize_page.dart`, `lib/features/wallpaper/widgets/ui_render.dart`, `lib/features/wallpaper/services/wallpaper_service.dart`, `android/app/src/main/kotlin/com/rahulreddy/githubwallpaper/MainActivity.kt`
- Product-state assembly: `lib/app/product/services/`
- Share cards: `lib/features/contributions/widgets/share_card.dart`, `lib/features/contributions/models/share_template_catalog.dart`, `lib/features/contributions/services/share_service.dart`
- Settings and preferences: `lib/features/settings/pages/`, `lib/features/settings/controllers/`
- Admin dashboard: `admin/index.html`, `admin/app.js`, `admin/config.js`
- Admin backend: `functions/index.js`, `firestore.rules`

## Repository Map

```text
github_wallpaper/
  admin/                  Web admin console for live app controls and broadcasts
  android/                Android host app, Kotlin bridges, resources
  assets/                 Bundled assets, currently centered around the logo
  docs/                   Focused audits and subsystem notes
  functions/              Firebase Cloud Functions backend
  integration_test/       End-to-end smoke coverage
  lib/
    app/                  Startup shell, product-state assembly, app services
    core/                 Constants, theme, storage, errors, utilities
    features/
      auth/               OAuth and identity flows
      contributions/      Dashboard, stats, share flow, quote logic, repository sync
      settings/           Settings UI and preference controllers
      wallpaper/          Customize page, renderers, wallpaper services, widget services
  test/                   Unit and widget tests
  README.md               Human-facing overview
  CODEBASE.md             This index
```

## Important Runtime Rules

### Free Model

- Keep the app free-only unless the user explicitly asks to reintroduce monetization logic.
- Existing tests already assert that subscription and upgrade UI is absent.
- Product copy should describe all features as included.

### Wallpaper Rules

- Customize currently applies only to the lock screen.
- Lock preview and renderer are the primary wallpaper path.
- Lock calendar shows only the active month’s dates; adjacent-month dates are hidden visually.

### Notification Rules

- Notification types currently implemented:
  - auth error
  - sync failure
  - sync success
  - streak reminder
  - streak saved
  - celebrations
  - weekly digest
  - admin broadcast
- Notification copy and channel metadata are centralized in `notification_catalog.dart`.
- Admin broadcast topic subscription depends on:
  - signed-in user
  - valid authenticated app session
  - non-anonymous Firebase user
  - admin broadcast toggle enabled
  - OS notification permission granted

### Admin Dashboard Rules

- App config currently controls:
  - `maintenance_mode`
  - `maintenance_message`
  - `force_update_enabled`
  - `force_update_min_version`
  - `force_update_message`
  - `smart_quotes_enabled`
- Removed stale admin controls:
  - `debug_mode_enabled`
  - `onboarding_version`
- Removed stale billing/paywall wording from the admin UI.

## Core Files By Area

### App Shell

- `lib/main.dart`: Flutter entrypoint.
- `lib/app/app_entry.dart`: initializes providers, bootstrap, maintenance/update gates, widget launch routing, and initial shell selection.
- `lib/app/pages/main_nav_page.dart`: 4-tab logged-in shell.

### Auth

- `lib/features/auth/services/oauth_service.dart`: GitHub OAuth and Firebase session restore.
- `lib/features/auth/services/auth_flow_service.dart`: authenticated app-session setup after sign-in.
- `lib/features/auth/services/identity_service.dart`: internal user identity mapping.
- `functions/index.js`: OAuth exchange endpoint and authenticated admin/app HTTP endpoints.

### Sync And Cached Data

- `lib/features/contributions/repositories/contribution_repository.dart`: GitHub fetch, sync orchestration, post-sync notifications.
- `lib/core/storage/storage_service.dart`: app preferences, cached data, notification flags, wallpaper config, session fields.
- `lib/app/services/background_scheduler.dart`: WorkManager scheduling and reminder checks.

### Wallpaper

- `lib/features/wallpaper/pages/customize_page.dart`: preview, controls, and apply UI.
- `lib/features/wallpaper/widgets/ui_render.dart`: wallpaper renderer for lock/home/internal preview paths.
- `lib/features/wallpaper/services/wallpaper_service.dart`: generate and apply wallpaper file.
- `android/app/src/main/kotlin/com/rahulreddy/githubwallpaper/MainActivity.kt`: Android method-channel bridge for wallpaper apply and notification settings.

### Notifications

- `lib/app/services/notification_catalog.dart`: notification definitions, copy generation, topic rules, local-display rules.
- `lib/app/services/notification_service.dart`: local notification initialization, FCM handling, admin broadcast acks.
- `lib/features/settings/pages/notifications_page.dart`: notification settings UI.

### Share System

- `lib/features/contributions/models/share_template_catalog.dart`: template definitions and ordering.
- `lib/features/contributions/widgets/share_card.dart`: share card rendering.
- `lib/features/contributions/services/share_service.dart`: export/share flow.

### Admin Surface

- `admin/config.js`: Firebase config, Firestore path constants, admin broadcast limits, editable config schema.
- `admin/app.js`: Google sign-in, realtime Firestore subscriptions, admin CRUD, broadcast sender UI.
- `admin/index.html`: admin layout.
- `functions/index.js`: admin broadcast send and ack endpoints.

## Docs Map

- `README.md`: concise overview and setup.
- `docs/quote_system_2026-04-03.md`: current quote architecture, activity tracking, and fallback behavior.
- `docs/notification_audit_2026-04-03.md`: current notification audit and validation plan.
- `docs/admin_control_surface_2026-04-03.md`: current admin dashboard audit and cleanup summary.
- `docs/share_template_system_2026-04-01.md`: share-template design note.
- `docs/codebase_audit_2026-04-01.md`: historical remediation audit; useful for context, not the main source of truth.

## Validation Shortcuts

Use these when touching the main systems:

### Flutter

```bash
dart analyze
flutter test
```

### Notifications

```bash
flutter test test/notification_service_test.dart test/background_scheduler_test.dart test/sync_logic_test.dart
```

### Wallpaper Customize

```bash
flutter test test/customize_preview_overflow_test.dart
```

### Admin / Functions Syntax

```bash
node --check admin/app.js
node --check functions/index.js
```

## Notes For The Next Agent

- Prefer this file for orientation before scanning the whole tree.
- Treat `README.md` as the external overview and this file as the internal index.
- Use the docs folder for subsystem-specific audits.
- Do not assume old generated documentation is still correct; this file is the maintained summary.
