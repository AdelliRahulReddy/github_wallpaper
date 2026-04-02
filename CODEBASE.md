# CODEBASE

Single-source technical reference for the GitWall repository. This document replaces the deleted `docs/` markdown set and is the repository-level architecture, history, and maintenance guide.

## Searchable Index

- `Bootstrap and startup`: `lib/main.dart`, `lib/app/app_entry.dart`, `lib/app/services/bootstrap_service.dart`
- `OAuth and identity`: `lib/features/auth/services/oauth_service.dart`, `lib/features/auth/services/auth_flow_service.dart`, `lib/features/auth/services/identity_service.dart`, `functions/index.js`, `firestore.rules`
- `GitHub sync and caching`: `lib/features/contributions/repositories/contribution_repository.dart`, `lib/core/storage/storage_service.dart`, `lib/app/product/services/sync_engine.dart`
- `Wallpaper rendering and apply`: `lib/features/wallpaper/widgets/ui_render.dart`, `lib/features/wallpaper/services/wallpaper_service.dart`, `android/app/src/main/kotlin/com/rahulreddy/githubwallpaper/MainActivity.kt`
- `Notifications and broadcasts`: `lib/app/services/notification_service.dart`, `functions/index.js`, `admin/app.js`
- `Settings and preferences`: `lib/features/settings/pages/settings_page.dart`, `lib/features/settings/controllers/settings_controller.dart`, `lib/features/settings/controllers/theme_controller.dart`
- `Analytics surfaces`: `lib/app/product/services/insight_engine.dart`, `lib/app/product/services/surface_builders.dart`, `lib/features/contributions/pages/stats_page.dart`
- `Android build`: `android/build.gradle.kts`, `android/settings.gradle.kts`, `android/gradle.properties`, `android/app/build.gradle.kts`
- `Tests`: `test/`, `integration_test/exploratory_user_journeys_test.dart`

## Current Snapshot

- App type: Flutter application backed by Firebase, GitHub OAuth, GitHub GraphQL, Cloud Functions, and Android wallpaper/widget integrations.
- Monetization status: current worktree is free-model only; RevenueCat/paywall runtime code has been removed.
- Primary runtime data flow: GitHub OAuth -> Cloud Function exchange -> Firebase custom-token session -> GitHub GraphQL sync -> local cache -> product snapshot -> UI surfaces -> wallpaper/widget output.
- Major generated/vendor areas intentionally summarized rather than expanded file-by-file: `.dart_tool/`, `build/`, `coverage/`, `android/.gradle/`, `android/.kotlin/`, `functions/node_modules/`, `ios/Flutter/ephemeral/`, `macos/Flutter/ephemeral/`.

## Application History

- `2026-01-23`: initial Flutter multi-platform scaffold (`5eba447`).
- `2026-01-26`: navigation and Android configuration unification (`bec2437`).
- `2026-02-03`: onboarding, preview rendering, and month heatmap refactor (`bace288`).
- `2026-02-07` to `2026-02-13`: app icon/splash/Play Store/theme polish (`5c60fce`, `4028aba`, `2f4e903`).
- `2026-03-15` to `2026-03-16`: widget/live-wallpaper support and overflow fixes (`8871c2d`, `324abfb`).
- `2026-03-22`: OAuth/environment config and startup reliability work.
- `2026-03-23`: admin/backend consolidation and broad staging.
- `2026-03-24`: architecture consolidation introduced the product snapshot/foundation layer (`f16a0c3`).
- `2026-04-01 current worktree`: free-model cleanup and documentation consolidation.

## Repository Structure

```text
github_wallpaper/
  .github/                CI workflow(s), currently a secret scan.
  .codex/                 Local Codex skill/tooling data; not product runtime.
  admin/                  Standalone web admin console for realtime config and operations.
  android/                Android app module, manifests, Kotlin bridges, and resources.
  assets/                 Bundled Flutter assets (`logo.png`).
  functions/              Firebase Cloud Functions backend and npm lockfiles.
  integration_test/       End-to-end smoke scenarios.
  ios/                    iOS host app shell and Xcode project.
  lib/                    Main Flutter application source.
  linux/                  Linux desktop shell.
  macos/                  macOS desktop shell.
  test/                   Unit and widget tests.
  web/                    Flutter web host files and install manifest.
  windows/                Windows desktop shell.
  README.md               Short human-facing overview.
  CODEBASE.md             Complete architectural reference.
```

## Pubspec Reference

- Package name: `github_wallpaper`
- Version: `1.0.0+4`
- Dart SDK constraint: `^3.5.0`
- Flutter SDK constraint: `>=3.24.0`
- Asset declaration: the entire `assets/` directory is bundled; the meaningful runtime asset is `assets/logo.png`.
- Build-time tool sections in `pubspec.yaml`: `flutter_launcher_icons` and `flutter_native_splash`, both driven from `assets/logo.png` with background `#0D1117`.

### Runtime Dependencies

| Package | Constraint | Why it exists |
| --- | --- | --- |
| `flutter` | `sdk: flutter` | Runtime dependency. |
| `http` | `^1.2.2` | GitHub GraphQL and backend HTTP transport. |
| `shared_preferences` | `^2.3.3           # User preferences & settings` | Non-sensitive local flags and settings. |
| `flutter_secure_storage` | `^9.2.2       # 🔐 Encrypted token storage` | Encrypted token and sensitive-cache storage. |
| `path_provider` | `^2.1.5                # Local file paths` | Temporary wallpaper image output. |
| `wallpaper_manager_plus` | `^2.0.3       # Set wallpaper (lock/home/both)` | Wallpaper apply fallback on Android. |
| `intl` | `^0.19.0                        # Date & number formatting` | Formatting helpers. |
| `url_launcher` | `^6.3.1                 # Open external links` | External links. |
| `package_info_plus` | `^8.1.2            # App version info` | Version/package lookup. |
| `synchronized` | `^3.1.0+1               # ✨ NEW - Thread-safe lock operations` | Locking around storage and wallpaper operations. |
| `crypto` | `^3.0.6                      # Stable hashing (e.g., SHA-256)` | SHA-256 hashing for wallpaper signatures. |
| `workmanager` | `^0.9.0                 # 🔔 Background task scheduling (upgraded for Flutter compatibility)` | Background scheduling. |
| `flutter_local_notifications` | `^17.1.2 # Local notifications for background alerts` | Local reminders and sync notifications. |
| `share_plus` | `^10.1.4                 # Share exported images` | Share-sheet integration. |
| `home_widget` | `^0.7.0                 # Home screen widgets (Android/iOS)` | Native home-screen widget bridge. |
| `provider` | `^6.1.2                    # State management (ChangeNotifier)` | ChangeNotifier wiring. |
| `flutter_appauth` | `^12.0.0            # GitHub OAuth (PKCE)` | GitHub OAuth PKCE flow. |
| `google_generative_ai` | `^0.4.6        # Gemini AI integration` | Gemini client. |
| `smooth_page_indicator` | `^1.2.0+3      # Page dots for onboarding` | Onboarding dots. |
| `fl_chart` | `^0.68.0` | Stats charts. |
| `cupertino_icons` | `^1.0.8` | Runtime dependency. |
| `firebase_core` | `^4.5.0` | Firebase bootstrap. |
| `cloud_firestore` | `^6.1.3` | Firestore access. |
| `firebase_auth` | `^6.2.0` | Custom-token sessions. |
| `firebase_crashlytics` | `^5.0.8` | Crash logging. |
| `firebase_messaging` | `^16.1.2` | Push notifications. |
| `device_info_plus` | `^10.1.0` | Device metrics. |
| `sensors_plus` | `^5.0.1` | Device sensor hooks. |
| `flutter_native_splash` | `^2.4.2        # Native splash screen` | Build-time splash generator. |

### Dev Dependencies

| Package | Constraint | Why it exists |
| --- | --- | --- |
| `flutter_test` | `` | Test framework. |
| `integration_test` | `` | Integration test harness. |
| `flutter_lints` | `^5.0.0` | Lint rules. |
| `flutter_launcher_icons` | `^0.14.3` | Build-time icon generator. |

## Root and Configuration File Inventory

### `README.md`
- Purpose: Short human-facing project overview that should link into CODEBASE.md for deep technical detail.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-23 f1d0a3c` with summary "fix: Clean up membership paywall page and resolve README merge conflict"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `pubspec.yaml`
- Purpose: Canonical Flutter package manifest defining SDK constraints, dependencies, assets, and build-time generators.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `pubspec.lock`
- Purpose: Repository file for pubspec.lock.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `analysis_options.yaml`
- Purpose: Repository file for analysis options.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-23 7c85939` with summary "Bulk update: Staging local changes across codebase."; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `.metadata`
- Purpose: Repository file for .metadata.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `.gitignore`
- Purpose: Repository file for .gitignore.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-23 7c85939` with summary "Bulk update: Staging local changes across codebase."; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `firebase.json`
- Purpose: Firebase CLI configuration for Functions, Firestore rules, Storage rules, and emulator ports.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-23 7c85939` with summary "Bulk update: Staging local changes across codebase."; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `firestore.rules`
- Purpose: Authoritative Firestore access-control policy for custom sessions, canonical user IDs, and admin-only collections.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-23 7c85939` with summary "Bulk update: Staging local changes across codebase."; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `storage.rules`
- Purpose: Repository file for storage.rules.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-02-09 3798821` with summary "feat: final polish, critical fixes, and documentation updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `.flutter-plugins-dependencies`
- Purpose: Repository file for .flutter plugins dependencies.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `untracked/current-worktree -` with summary "No committed history for this path."; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `privacy_policy.html`
- Purpose: Repository file for privacy policytml.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-02-14 3cd16e0` with summary "docs: update privacy policy for play store review and final prep"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `LICENSE`
- Purpose: Repository file for LICENSE.
- Key APIs/classes: `Copyright`, `files`
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-02-07 5c60fce` with summary "Complete changes"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `.github/workflows/secret-scan.yml`
- Purpose: Repository file for secret scan.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-02-09 3798821` with summary "feat: final polish, critical fixes, and documentation updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

## Admin and Backend

### `admin/index.html`
- Purpose: Web admin asset for indextml.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-23 7c85939` with summary "Bulk update: Staging local changes across codebase."; current worktree status `M`.
- Safe modification note: Safe to iterate independently if Firestore schemas and backend endpoints remain stable.

### `admin/styles.css`
- Purpose: Web admin asset for styles.css.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-23 7c85939` with summary "Bulk update: Staging local changes across codebase."; current worktree status `M`.
- Safe modification note: Safe to iterate independently if Firestore schemas and backend endpoints remain stable.

### `admin/config.js`
- Purpose: Web admin asset for config.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-23 7c85939` with summary "Bulk update: Staging local changes across codebase."; current worktree status `M`.
- Safe modification note: Safe to iterate independently if Firestore schemas and backend endpoints remain stable.

### `admin/app.js`
- Purpose: Web admin asset for app.
- Key APIs/classes: `bootstrapAuth`, `resetLiveState`, `startGoogleSignIn`, `handleSignOut`, `loadDashboard`, `assertAdmin`, `subscribeDoc`, `subscribeMetrics`, `subscribeAdmins`, `subscribeUsers`, `subscribeBroadcasts`, `subscribeIncidentFeeds`
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-23 7c85939` with summary "Bulk update: Staging local changes across codebase."; current worktree status `M`.
- Safe modification note: Safe to iterate independently if Firestore schemas and backend endpoints remain stable.

### `functions/.gitignore`
- Purpose: Backend package file for .gitignore.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-26 bec2437` with summary "feat: unify navigation structure and fix onboarding navigation bug"; current worktree status `tracked`.
- Safe modification note: Coordinate with client endpoints, admin UI, and Firestore rules.

### `functions/package.json`
- Purpose: Backend package file for packageon.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-23 7c85939` with summary "Bulk update: Staging local changes across codebase."; current worktree status `tracked`.
- Safe modification note: Coordinate with client endpoints, admin UI, and Firestore rules.

### `functions/package-lock.json`
- Purpose: Backend package file for package lockon.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-02-15 1ed3850` with summary "Production polish: centralized strings, build fixes, and added verification tests"; current worktree status `tracked`.
- Safe modification note: Coordinate with client endpoints, admin UI, and Firestore rules.

### `functions/index.js`
- Purpose: Single-file backend entrypoint exporting HTTPS and scheduled functions for OAuth exchange, admin broadcasts, telemetry, and daily quotes.
- Key APIs/classes: `exchangeAuthorizationCode`, `fetchGitHubJson`, `buildGitHubSession`, `authenticateAdminRequest`, `authenticateAppRequest`, `resolveAppEmail`, `resolveCanonicalAppSession`, `resolveCanonicalUserIdentity`, `buildCanonicalUserPayload`, `collectLegacyIds`, `extractCanonicalLinkedUserId`, `assertAuthorizedAdminEmail`
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-23 7c85939` with summary "Bulk update: Staging local changes across codebase."; current worktree status `M`.
- Safe modification note: Coordinate with client endpoints, admin UI, and Firestore rules.

## lib/ Architecture

- `lib/main.dart` is intentionally trivial; almost all runtime boot logic lives in `lib/app/app_entry.dart`.
- Layering direction: `core` and `app/product` provide primitives and pure state, `features/*/models` define contracts, `features/*/services` orchestrate behavior, and `features/*/pages` plus `widgets` render UI.
- The most sensitive seams are session bootstrap, sync state, storage serialization, wallpaper rendering, and Android native method channels.
- The architectural center of gravity moved on `2026-03-24` to the `app/product/` snapshot + surface-builder model.

### Detailed lib/ File Reference

### `lib/app/app_entry.dart`
- Purpose: Primary Flutter bootstrap, provider wiring, startup gate, maintenance/update handling, and widget deep-link entry.
- Key APIs/classes: `MyApp`, `_MyAppState`, `AppInitializer`, `_AppInitializerState`, `AppLifecycleObserver`, `_AdminStateScreen`, `_BootstrapBlankScreen`, `_recordErrorIfConsented`, `_recordFlutterErrorIfConsented`, `main`
- External dependencies: `dart:async`, `dart:ui`, `firebase_core`, `firebase_crashlytics`, `firebase_messaging`, `flutter`, `home_widget`, `package_info_plus`, `provider`
- Relationships: Depends on `lib/app/pages/main_nav_page.dart`, `lib/app/product/services/product_analytics.dart`, `lib/app/services/background_scheduler.dart`, `lib/app/services/bootstrap_service.dart`, `lib/app/services/notification_service.dart`, `lib/app/services/remote_config_service.dart`, `lib/app/services/telemetry_service.dart`, `lib/core/constants/environment_config.dart`, `lib/core/constants/firebase_options.dart`, `lib/core/storage/storage_service.dart`, `lib/core/theme/app_theme.dart`, `lib/core/utils/app_utils.dart`, `lib/features/auth/pages/onboarding_page.dart`, `lib/features/contributions/repositories/contribution_repository.dart`, `lib/features/settings/controllers/settings_controller.dart`, `lib/features/settings/controllers/theme_controller.dart`, `lib/features/wallpaper/services/wallpaper_service.dart`, `lib/features/wallpaper/services/widget_service.dart`; referenced by `integration_test/exploratory_user_journeys_test.dart`, `lib/main.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/app/pages/main_nav_page.dart`
- Purpose: Application shell page for main nav page.
- Key APIs/classes: `MainNavPage`, `_MainNavPageState`, `_MainNavPageStateSurface`
- External dependencies: `dart:async`, `dart:io`, `flutter`
- Relationships: Depends on `lib/app/services/refresh_result.dart`, `lib/core/errors/app_exceptions.dart`, `lib/core/storage/storage_service.dart`, `lib/core/theme/app_theme.dart`, `lib/core/utils/app_utils.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/contributions/pages/home_page.dart`, `lib/features/contributions/pages/stats_page.dart`, `lib/features/contributions/repositories/contribution_repository.dart`, `lib/features/contributions/services/achievement_service.dart`, `lib/features/settings/pages/settings_page.dart`, `lib/features/wallpaper/pages/customize_page.dart`, `lib/features/wallpaper/services/device_config_service.dart`, `lib/features/wallpaper/services/wallpaper_service.dart`; referenced by `lib/app/app_entry.dart`, `lib/features/auth/pages/onboarding_page.dart`, `lib/features/settings/pages/settings_page.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/app/product/models/product_models.dart`
- Purpose: Product-layer model for product models.
- Key APIs/classes: `ClockTime`, `RawSnapshot`, `InsightSnapshot`, `PreferenceState`, `EntitledFeature`, `EntitlementState`, `SyncStatus`, `SyncFailureType`, `SyncMode`, `SyncState`, `ProductSnapshot`
- External dependencies: `flutter`
- Relationships: Depends on `lib/core/utils/app_utils.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/contributions/services/contribution_metrics.dart`; referenced by `lib/app/product/services/entitlement_engine.dart`, `lib/app/product/services/insight_engine.dart`, `lib/app/product/services/product_state_factory.dart`, `lib/app/product/services/surface_builders.dart`, `lib/app/product/services/sync_engine.dart`, `test/entitlement_engine_test.dart`, `test/product_foundation_test.dart`.
- Modification history: last committed touch `untracked/current-worktree -` with summary "No committed history for this path."; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/app/product/services/entitlement_engine.dart`
- Purpose: Product-layer service for entitlement engine.
- Key APIs/classes: `EntitlementEngine`
- External dependencies: None or standard tool syntax
- Relationships: Depends on `lib/app/product/models/product_models.dart`, `lib/features/wallpaper/models/theme_presets.dart`, `lib/features/wallpaper/models/wallpaper_templates.dart`; referenced by `lib/app/product/services/product_state_factory.dart`, `test/entitlement_engine_test.dart`, `test/product_foundation_test.dart`.
- Modification history: last committed touch `untracked/current-worktree -` with summary "No committed history for this path."; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/app/product/services/insight_engine.dart`
- Purpose: Product-layer service for insight engine.
- Key APIs/classes: `InsightEngine`
- External dependencies: None or standard tool syntax
- Relationships: Depends on `lib/app/product/models/product_models.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/contributions/services/contribution_metrics.dart`; referenced by `lib/app/product/services/product_state_factory.dart`, `test/product_foundation_test.dart`.
- Modification history: last committed touch `untracked/current-worktree -` with summary "No committed history for this path."; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/app/product/services/product_analytics.dart`
- Purpose: Product-layer service for product analytics.
- Key APIs/classes: `ProductEventName`, `ProductEvent`, `ProductAnalytics`
- External dependencies: `dart:collection`, `dart:convert`, `flutter`
- Relationships: Depends on `lib/core/utils/app_utils.dart`; referenced by `lib/app/app_entry.dart`, `lib/features/wallpaper/services/wallpaper_service.dart`.
- Modification history: last committed touch `untracked/current-worktree -` with summary "No committed history for this path."; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/app/product/services/product_copy.dart`
- Purpose: Product-layer service for product copy.
- Key APIs/classes: `ProductStateLanguage`
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `untracked/current-worktree -` with summary "No committed history for this path."; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/app/product/services/product_state_factory.dart`
- Purpose: Product-layer service for product state factory.
- Key APIs/classes: `ProductStateFactory`
- External dependencies: None or standard tool syntax
- Relationships: Depends on `lib/app/product/models/product_models.dart`, `lib/app/product/services/entitlement_engine.dart`, `lib/app/product/services/insight_engine.dart`, `lib/app/product/services/sync_engine.dart`, `lib/core/storage/storage_service.dart`, `lib/features/contributions/models/contribution_models.dart`; referenced by `lib/features/wallpaper/services/widget_service.dart`.
- Modification history: last committed touch `untracked/current-worktree -` with summary "No committed history for this path."; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/app/product/services/surface_builders.dart`
- Purpose: Product-layer service for surface builders.
- Key APIs/classes: `HomeSurfaceModel`, `StatsSurfaceModel`, `WallpaperSurfaceModel`, `ShareSurfaceModel`, `WidgetSurfaceModel`, `SettingsHealthSurfaceModel`, `HomeBuilder`, `StatsBuilder`, `WallpaperBuilder`, `ShareBuilder`, `WidgetBuilder`, `SettingsHealthBuilder`
- External dependencies: `flutter`
- Relationships: Depends on `lib/app/product/models/product_models.dart`, `lib/core/storage/storage_service.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/contributions/services/contribution_metrics.dart`; referenced by `lib/features/wallpaper/services/widget_service.dart`, `test/product_foundation_test.dart`.
- Modification history: last committed touch `untracked/current-worktree -` with summary "No committed history for this path."; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/app/product/services/sync_engine.dart`
- Purpose: Product-layer service for sync engine.
- Key APIs/classes: `SyncEngine`
- External dependencies: None or standard tool syntax
- Relationships: Depends on `lib/app/product/models/product_models.dart`, `lib/app/services/refresh_result.dart`, `lib/core/utils/app_utils.dart`, `lib/features/contributions/models/contribution_models.dart`; referenced by `lib/app/product/services/product_state_factory.dart`, `test/product_foundation_test.dart`.
- Modification history: last committed touch `untracked/current-worktree -` with summary "No committed history for this path."; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/app/services/background_scheduler.dart`
- Purpose: Application infrastructure service for background scheduler.
- Key APIs/classes: `BackgroundScheduler`, `_resultForSkipReason`, `_shouldPersistDailyKey`, `_hasFreshReminderData`, `_runReminderChecks`, `_runBackgroundWallpaperUpdate`, `callbackDispatcher`
- External dependencies: `dart:io`, `firebase_core`, `flutter`, `workmanager`
- Relationships: Depends on `lib/app/services/notification_service.dart`, `lib/app/services/refresh_result.dart`, `lib/app/services/telemetry_service.dart`, `lib/core/constants/firebase_options.dart`, `lib/core/storage/storage_service.dart`, `lib/core/utils/app_utils.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/contributions/repositories/contribution_repository.dart`; referenced by `lib/app/app_entry.dart`, `lib/features/auth/services/auth_flow_service.dart`, `lib/features/settings/controllers/settings_controller.dart`, `lib/features/settings/pages/notifications_page.dart`, `lib/features/settings/pages/settings_page.dart`, `lib/features/settings/pages/wallpaper_sync_page.dart`, `lib/features/wallpaper/pages/customize_page.dart`, `test/background_scheduler_test.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/app/services/bootstrap_service.dart`
- Purpose: Application infrastructure service for bootstrap service.
- Key APIs/classes: `BootstrapService`
- External dependencies: `dart:async`, `firebase_auth`, `firebase_core`, `firebase_crashlytics`, `flutter`
- Relationships: Depends on `lib/app/services/notification_service.dart`, `lib/app/services/remote_config_service.dart`, `lib/core/constants/firebase_options.dart`, `lib/core/errors/app_exceptions.dart`, `lib/core/storage/storage_service.dart`, `lib/core/utils/app_utils.dart`, `lib/features/auth/services/identity_service.dart`, `lib/features/auth/services/oauth_service.dart`, `lib/features/contributions/services/daily_quotes.dart`, `lib/features/wallpaper/services/device_config_service.dart`; referenced by `lib/app/app_entry.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/app/services/notification_service.dart`
- Purpose: Application infrastructure service for notification service.
- Key APIs/classes: `NotificationService`, `firebaseMessagingBackgroundHandler`
- External dependencies: `dart:convert`, `dart:io`, `firebase_auth`, `firebase_core`, `firebase_messaging`, `flutter`, `flutter_local_notifications`, `http`, `package_info_plus`, `url_launcher`
- Relationships: Depends on `lib/core/constants/environment_config.dart`, `lib/core/constants/firebase_options.dart`, `lib/core/storage/storage_service.dart`, `lib/core/utils/app_utils.dart`, `lib/features/auth/services/identity_service.dart`; referenced by `lib/app/app_entry.dart`, `lib/app/services/background_scheduler.dart`, `lib/app/services/bootstrap_service.dart`, `lib/features/auth/services/auth_flow_service.dart`, `lib/features/contributions/repositories/contribution_repository.dart`, `lib/features/settings/controllers/settings_controller.dart`, `lib/features/settings/pages/notifications_page.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/app/services/refresh_result.dart`
- Purpose: Application infrastructure service for refresh result.
- Key APIs/classes: `RefreshResult`
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by `lib/app/pages/main_nav_page.dart`, `lib/app/product/services/sync_engine.dart`, `lib/app/services/background_scheduler.dart`, `lib/features/contributions/repositories/contribution_repository.dart`, `lib/features/wallpaper/services/wallpaper_service.dart`, `test/background_scheduler_test.dart`, `test/product_foundation_test.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/app/services/remote_config_service.dart`
- Purpose: Application infrastructure service for remote config service.
- Key APIs/classes: `RemoteConfigService`
- External dependencies: `cloud_firestore`, `dart:async`, `firebase_core`, `flutter`
- Relationships: Depends on `lib/core/utils/app_utils.dart`; referenced by `lib/app/app_entry.dart`, `lib/app/services/bootstrap_service.dart`, `lib/features/contributions/services/daily_quotes.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/app/services/telemetry_service.dart`
- Purpose: Application infrastructure service for telemetry service.
- Key APIs/classes: `TelemetryService`
- External dependencies: `dart:convert`, `dart:io`, `firebase_auth`, `flutter`, `http`, `package_info_plus`
- Relationships: Depends on `lib/core/constants/environment_config.dart`, `lib/core/storage/storage_service.dart`, `lib/core/utils/app_utils.dart`, `lib/features/auth/services/identity_service.dart`; referenced by `lib/app/app_entry.dart`, `lib/app/services/background_scheduler.dart`, `lib/features/contributions/repositories/contribution_repository.dart`, `lib/features/wallpaper/services/wallpaper_service.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/core/constants/environment_config.dart`
- Purpose: Core shared module for environment config.
- Key APIs/classes: `AppConfig`
- External dependencies: None or standard tool syntax
- Relationships: Depends on `lib/core/errors/app_exceptions.dart`; referenced by `lib/app/app_entry.dart`, `lib/app/services/notification_service.dart`, `lib/app/services/telemetry_service.dart`, `lib/features/auth/services/oauth_service.dart`, `lib/features/contributions/services/daily_quotes.dart`, `lib/features/settings/pages/settings_page.dart`, `test/environment_config_test.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/core/constants/firebase_options.dart`
- Purpose: Core shared module for firebase options.
- Key APIs/classes: `DefaultFirebaseOptions`
- External dependencies: `firebase_core`, `flutter`
- Relationships: Depends on no internal source imports; referenced by `lib/app/app_entry.dart`, `lib/app/services/background_scheduler.dart`, `lib/app/services/bootstrap_service.dart`, `lib/app/services/notification_service.dart`, `lib/features/wallpaper/services/wallpaper_service.dart`.
- Modification history: last committed touch `2026-03-23 7c85939` with summary "Bulk update: Staging local changes across codebase."; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/core/errors/app_exceptions.dart`
- Purpose: Core shared module for app exceptions.
- Key APIs/classes: `GitHubException`, `NetworkException`, `UserNotFoundException`, `RateLimitException`, `TokenExpiredException`, `AccessDeniedException`, `StorageException`, `WallpaperException`, `ContextInitException`
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by `lib/app/pages/main_nav_page.dart`, `lib/app/services/bootstrap_service.dart`, `lib/core/constants/environment_config.dart`, `lib/core/utils/app_utils.dart`, `lib/features/auth/services/oauth_service.dart`, `lib/features/contributions/repositories/contribution_repository.dart`, `lib/features/wallpaper/services/wallpaper_service.dart`, `lib/features/wallpaper/widgets/ui_render.dart`.
- Modification history: last committed touch `2026-03-23 7c85939` with summary "Bulk update: Staging local changes across codebase."; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/core/state/safe_change_notifier.dart`
- Purpose: Core shared module for safe change notifier.
- Key APIs/classes: `SafeChangeNotifier`
- External dependencies: `flutter`
- Relationships: Depends on no internal source imports; referenced by `lib/features/settings/controllers/settings_controller.dart`, `lib/features/settings/controllers/theme_controller.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/core/storage/storage_service.dart`
- Purpose: Central persistence layer over shared_preferences and flutter_secure_storage.
- Key APIs/classes: `StorageService`
- External dependencies: `dart:async`, `dart:convert`, `dart:io`, `firebase_auth`, `firebase_core`, `flutter`, `flutter_secure_storage`, `shared_preferences`, `synchronized`
- Relationships: Depends on `lib/core/utils/app_utils.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/wallpaper/models/theme_presets.dart`, `lib/features/wallpaper/models/wallpaper_templates.dart`, `lib/features/wallpaper/widgets/ui_render.dart`; referenced by `integration_test/exploratory_user_journeys_test.dart`, `lib/app/app_entry.dart`, `lib/app/pages/main_nav_page.dart`, `lib/app/product/services/product_state_factory.dart`, `lib/app/product/services/surface_builders.dart`, `lib/app/services/background_scheduler.dart`, `lib/app/services/bootstrap_service.dart`, `lib/app/services/notification_service.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Preserve stored key compatibility and serialized data contracts.

### `lib/core/theme/app_theme.dart`
- Purpose: Core shared module for app theme.
- Key APIs/classes: `AppTheme`, `AppSurfaceTone`, `AppThemeExt`, `AppSurfaceTokens`, `SettingsThemeTokens`, `ThemeContext`, `_createTheme`, `_glassCard`, `_shadow`, `_surfaceDecoration`, `_primaryActionStyle`, `_outlinedActionStyle`
- External dependencies: `flutter`
- Relationships: Depends on no internal source imports; referenced by `lib/app/app_entry.dart`, `lib/app/pages/main_nav_page.dart`, `lib/core/ui/app_components.dart`, `lib/core/utils/app_utils.dart`, `lib/features/auth/pages/onboarding_page.dart`, `lib/features/auth/widgets/onboarding_content.dart`, `lib/features/contributions/pages/home_page.dart`, `lib/features/contributions/pages/stats_page.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/core/ui/app_components.dart`
- Purpose: Core shared module for app components.
- Key APIs/classes: `AppPageContent`, `AppSurface`, `AppPill`, `AppCard`, `AppSectionHeader`, `MetricTile`, `HeroMetricCard`
- External dependencies: `flutter`
- Relationships: Depends on `lib/core/theme/app_theme.dart`; referenced by `lib/features/contributions/pages/home_page.dart`, `lib/features/contributions/pages/stats_page.dart`, `lib/features/contributions/widgets/stats_sections.dart`, `lib/features/settings/pages/notifications_page.dart`, `lib/features/settings/widgets/settings_widgets.dart`, `lib/features/wallpaper/pages/customize_page.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/core/utils/app_utils.dart`
- Purpose: Core shared module for app utils.
- Key APIs/classes: `SensitiveDataSanitizer`, `ErrorHandler`, `AppLog`, `Debouncer`, `ValidationUtils`, `AppStrings`, `AppConstants`, `RefreshSkipReason`, `RefreshDecision`, `RefreshPolicy`, `UpdateScheduleMode`, `RenderUtils`
- External dependencies: `dart:async`, `dart:io`, `dart:ui`, `firebase_crashlytics`, `flutter`, `flutter_appauth`
- Relationships: Depends on `lib/core/errors/app_exceptions.dart`, `lib/core/theme/app_theme.dart`; referenced by `lib/app/app_entry.dart`, `lib/app/pages/main_nav_page.dart`, `lib/app/product/models/product_models.dart`, `lib/app/product/services/product_analytics.dart`, `lib/app/product/services/sync_engine.dart`, `lib/app/services/background_scheduler.dart`, `lib/app/services/bootstrap_service.dart`, `lib/app/services/notification_service.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/features/auth/pages/onboarding_page.dart`
- Purpose: Auth module file for onboarding page.
- Key APIs/classes: `GitHubConnectPage`, `OnboardingPage`, `_GitHubConnectPageState`, `_SingleActionBar`, `_OnboardingBackdrop`, `_BackdropGlow`, `_BackdropPainter`
- External dependencies: `dart:async`, `dart:ui`, `flutter`
- Relationships: Depends on `lib/app/pages/main_nav_page.dart`, `lib/core/theme/app_theme.dart`, `lib/core/utils/app_utils.dart`, `lib/features/auth/services/auth_flow_service.dart`, `lib/features/auth/services/oauth_service.dart`, `lib/features/auth/widgets/onboarding_content.dart`; referenced by `lib/app/app_entry.dart`, `lib/features/settings/pages/settings_page.dart`, `test/onboarding_overflow_test.dart`, `test/onboarding_setup_layout_test.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Keep backend/session/OAuth assumptions aligned across client, Firestore rules, and Cloud Functions.

### `lib/features/auth/services/auth_flow_service.dart`
- Purpose: Auth module file for auth flow service.
- Key APIs/classes: `AuthFlowResult`, `AuthFlowService`
- External dependencies: `dart:async`
- Relationships: Depends on `lib/app/services/background_scheduler.dart`, `lib/app/services/notification_service.dart`, `lib/core/storage/storage_service.dart`, `lib/features/auth/services/identity_service.dart`, `lib/features/auth/services/oauth_service.dart`, `lib/features/wallpaper/services/widget_service.dart`; referenced by `lib/features/auth/pages/onboarding_page.dart`, `lib/features/settings/pages/settings_page.dart`.
- Modification history: last committed touch `untracked/current-worktree -` with summary "No committed history for this path."; current worktree status `??`.
- Safe modification note: Keep backend/session/OAuth assumptions aligned across client, Firestore rules, and Cloud Functions.

### `lib/features/auth/services/identity_service.dart`
- Purpose: Auth module file for identity service.
- Key APIs/classes: `IdentityService`
- External dependencies: `cloud_firestore`, `dart:async`, `firebase_auth`, `firebase_core`, `synchronized`
- Relationships: Depends on `lib/core/storage/storage_service.dart`, `lib/core/utils/app_utils.dart`, `lib/features/auth/services/oauth_service.dart`; referenced by `lib/app/services/bootstrap_service.dart`, `lib/app/services/notification_service.dart`, `lib/app/services/telemetry_service.dart`, `lib/features/auth/services/auth_flow_service.dart`.
- Modification history: last committed touch `untracked/current-worktree -` with summary "No committed history for this path."; current worktree status `??`.
- Safe modification note: Keep backend/session/OAuth assumptions aligned across client, Firestore rules, and Cloud Functions.

### `lib/features/auth/services/oauth_service.dart`
- Purpose: GitHub PKCE OAuth client plus backend exchange/session creation logic.
- Key APIs/classes: `OAuthSession`, `OAuthService`
- External dependencies: `dart:async`, `dart:convert`, `dart:io`, `firebase_auth`, `flutter`, `flutter_appauth`, `http`
- Relationships: Depends on `lib/core/constants/environment_config.dart`, `lib/core/errors/app_exceptions.dart`; referenced by `lib/app/services/bootstrap_service.dart`, `lib/features/auth/pages/onboarding_page.dart`, `lib/features/auth/services/auth_flow_service.dart`, `lib/features/auth/services/identity_service.dart`, `test/oauth_service_test.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Keep backend/session/OAuth assumptions aligned across client, Firestore rules, and Cloud Functions.

### `lib/features/auth/widgets/onboarding_content.dart`
- Purpose: Auth module file for onboarding content.
- Key APIs/classes: `GitHubConnectContent`, `_GitHubConnectContentState`, `_HeroIllustrationPanel`, `_AmbientGlow`, `_HeroCornerChip`, `_HeroCopyBlock`, `_GitHubSnapshotCard`, `_WallpaperPreviewDevice`, `_MiniWallpaperPreview`, `_PhoneNotificationCard`, `_PhoneStatusRow`, `_PhoneStatusPill`
- External dependencies: `dart:math`, `dart:ui`, `flutter`
- Relationships: Depends on `lib/core/theme/app_theme.dart`; referenced by `lib/features/auth/pages/onboarding_page.dart`, `test/onboarding_preparing_state_test.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Keep backend/session/OAuth assumptions aligned across client, Firestore rules, and Cloud Functions.

### `lib/features/contributions/models/contribution_models.dart`
- Purpose: Contributions module file for contribution models.
- Key APIs/classes: `ContributionDay`, `ContributionStats`, `RepoLanguageSlice`, `RepoContribution`, `LanguageUsage`, `CachedContributionData`, `_dateStr`, `_requiredContributionDate`
- External dependencies: `flutter`
- Relationships: Depends on `lib/core/utils/app_utils.dart`, `lib/features/contributions/services/contribution_metrics.dart`, `lib/features/wallpaper/models/wallpaper_config.dart`; referenced by `integration_test/exploratory_user_journeys_test.dart`, `lib/app/pages/main_nav_page.dart`, `lib/app/product/models/product_models.dart`, `lib/app/product/services/insight_engine.dart`, `lib/app/product/services/product_state_factory.dart`, `lib/app/product/services/surface_builders.dart`, `lib/app/product/services/sync_engine.dart`, `lib/app/services/background_scheduler.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/features/contributions/pages/home_page.dart`
- Purpose: Contributions module file for home page.
- Key APIs/classes: `HomePage`, `_HomePageState`, `_HomePageStateView`, `_HomeRecentActivityFeedCard`, `_HomeTodayHeroCard`, `_HomeWeeklyGoalCard`, `_HomeCurrentStreakCard`, `_HomeJourneySnapshotCard`, `_SnapshotMetric`, `_HomeWeekStripSection`, `_HomeQuoteCard`, `_WeekDayCell`
- External dependencies: `dart:async`, `flutter`, `intl`
- Relationships: Depends on `lib/core/storage/storage_service.dart`, `lib/core/theme/app_theme.dart`, `lib/core/ui/app_components.dart`, `lib/core/utils/app_utils.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/contributions/services/achievement_service.dart`, `lib/features/contributions/services/contribution_metrics.dart`, `lib/features/contributions/services/daily_quotes.dart`, `lib/features/contributions/services/share_service.dart`, `lib/features/settings/pages/settings_page.dart`; referenced by `lib/app/pages/main_nav_page.dart`, `test/home_greeting_test.dart`, `test/home_profile_layout_overflow_test.dart`, `test/home_setup_prompt_test.dart`, `test/home_share_sheet_test.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/features/contributions/pages/stats_page.dart`
- Purpose: Contributions module file for stats page.
- Key APIs/classes: `StatsPage`, `_StatsPageState`, `_StatsPageStateView`, `_StatsHeaderSummary`, `_StatsCurrentYearOnlyNoticeCard`
- External dependencies: `flutter`, `intl`
- Relationships: Depends on `lib/core/theme/app_theme.dart`, `lib/core/ui/app_components.dart`, `lib/core/utils/app_utils.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/contributions/widgets/stats_sections.dart`; referenced by `lib/app/pages/main_nav_page.dart`, `test/free_experience_test.dart`, `test/home_profile_layout_overflow_test.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/features/contributions/pages/wrapped_page.dart`
- Purpose: Contributions module file for wrapped page.
- Key APIs/classes: `WrappedPage`, `_WrappedPageState`, `_WrappedPageStateView`, `_WrappedSlide`, `_RecapSlide`, `_RecapStat`, `_BigNumber`, `_MiniStatCard`, `_RepoCard`, `_LanguageCard`, `_EmptyState`
- External dependencies: `flutter`, `smooth_page_indicator`
- Relationships: Depends on `lib/core/theme/app_theme.dart`, `lib/core/utils/app_utils.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/contributions/services/contribution_metrics.dart`, `lib/features/contributions/services/share_service.dart`, `lib/features/contributions/widgets/share_card.dart`; referenced by `lib/features/contributions/widgets/stats_sections.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/features/contributions/repositories/contribution_repository.dart`
- Purpose: GitHub GraphQL fetch, parse, cache, sync, and post-sync side-effect coordinator.
- Key APIs/classes: `ContributionRepository`, `_parseGitHubResponse`, `_dispatchPostSyncNotifications`, `_greatestMilestoneAtOrBelowValue`, `_checkGitHubAuthStatus`, `_disposeGitHubClient`
- External dependencies: `dart:async`, `dart:convert`, `dart:io`, `http`
- Relationships: Depends on `lib/app/services/notification_service.dart`, `lib/app/services/refresh_result.dart`, `lib/app/services/telemetry_service.dart`, `lib/core/errors/app_exceptions.dart`, `lib/core/storage/storage_service.dart`, `lib/core/utils/app_utils.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/contributions/services/contribution_metrics.dart`, `lib/features/contributions/services/daily_quotes.dart`, `lib/features/wallpaper/services/wallpaper_service.dart`, `lib/features/wallpaper/services/widget_service.dart`; referenced by `lib/app/app_entry.dart`, `lib/app/pages/main_nav_page.dart`, `lib/app/services/background_scheduler.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Validate sync, offline, auth-failure, and throttling behavior after edits.

### `lib/features/contributions/services/achievement_service.dart`
- Purpose: Contributions module file for achievement service.
- Key APIs/classes: `AchievementService`, `HomeAchievement`
- External dependencies: `flutter`
- Relationships: Depends on `lib/core/storage/storage_service.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/contributions/services/contribution_metrics.dart`; referenced by `lib/app/pages/main_nav_page.dart`, `lib/features/contributions/pages/home_page.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/features/contributions/services/contribution_metrics.dart`
- Purpose: Contributions module file for contribution metrics.
- Key APIs/classes: `PresentationFormatter`, `TrendSummary`, `ContributionAnalyzer`, `CacheValidator`
- External dependencies: None or standard tool syntax
- Relationships: Depends on `lib/core/utils/app_utils.dart`; referenced by `lib/app/product/models/product_models.dart`, `lib/app/product/services/insight_engine.dart`, `lib/app/product/services/surface_builders.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/contributions/pages/home_page.dart`, `lib/features/contributions/pages/wrapped_page.dart`, `lib/features/contributions/repositories/contribution_repository.dart`, `lib/features/contributions/services/achievement_service.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/features/contributions/services/daily_quotes.dart`
- Purpose: Contributions module file for daily quotes.
- Key APIs/classes: `DailyQuoteResult`, `DailyQuoteService`
- External dependencies: `cloud_firestore`, `dart:math`, `firebase_core`, `flutter`, `google_generative_ai`
- Relationships: Depends on `lib/app/services/remote_config_service.dart`, `lib/core/constants/environment_config.dart`, `lib/core/storage/storage_service.dart`, `lib/core/utils/app_utils.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/contributions/services/contribution_metrics.dart`; referenced by `lib/app/services/bootstrap_service.dart`, `lib/features/contributions/pages/home_page.dart`, `lib/features/contributions/repositories/contribution_repository.dart`, `lib/features/wallpaper/pages/customize_page.dart`, `test/daily_quotes_test.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/features/contributions/services/share_service.dart`
- Purpose: Story-only share chooser, fixed preview stage, sticky export CTA, and capture flow for the four core share templates plus Wrapped.
- Key APIs/classes: `ShareService`, `_ShareChooserSheet`, `_ShareChooserSheetState`
- External dependencies: `dart:io`, `dart:typed_data`, `dart:ui`, `flutter`, `path_provider`, `share_plus`
- Relationships: Depends on `lib/core/theme/app_theme.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/contributions/services/contribution_metrics.dart`, `lib/features/contributions/widgets/share_card.dart`; referenced by `lib/features/contributions/pages/home_page.dart`, `lib/features/contributions/pages/wrapped_page.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/features/contributions/widgets/share_card.dart`
- Purpose: Story-format share template renderer and export frame for Daily Flex, Repo Focus, Streak Milestone, Monthly Snapshot, and Wrapped, with shared heatmap-first card composition.
- Key APIs/classes: `ShareCardFamily`, `ShareExportFormat`, `ShareCardFamilyX`, `ShareExportFormatX`, `ShareCard`, `_HeroRow`, `_MiniMetric`, `_MetricGroup`, `_ShareCardHeader`, `_BrandChip`, `WrappedShareCard`
- External dependencies: `flutter`, `intl`
- Relationships: Depends on `lib/core/storage/storage_service.dart`, `lib/core/theme/app_theme.dart`, `lib/core/utils/app_utils.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/contributions/services/contribution_metrics.dart`, `lib/features/wallpaper/models/theme_presets.dart`; referenced by `lib/features/contributions/pages/wrapped_page.dart`, `lib/features/contributions/services/share_service.dart`, `test/share_card_layout_test.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/features/contributions/widgets/stats_sections.dart`
- Purpose: Contributions module file for stats sections.
- Key APIs/classes: `StatsAtAGlanceGrid`, `_AtAGlanceTile`, `StatsYearHeatmapCard`, `_StatsHeatCell`, `StatsWeeklyBreakdownCard`, `StatsStreakHistoryCard`, `StatsMostActiveDaysCard`, `StatsTopLanguagesCard`, `_LangRow`, `StatsTopReposCard`, `StatsYearWrappedCtaCard`, `_TeaserStat`
- External dependencies: `dart:math`, `fl_chart`, `flutter`, `intl`
- Relationships: Depends on `lib/core/theme/app_theme.dart`, `lib/core/ui/app_components.dart`, `lib/core/utils/app_utils.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/contributions/pages/wrapped_page.dart`; referenced by `lib/features/contributions/pages/stats_page.dart`, `test/stats_sections_overflow_test.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/features/settings/controllers/settings_controller.dart`
- Purpose: Settings module file for settings controller.
- Key APIs/classes: `SettingsController`
- External dependencies: `dart:async`, `flutter`
- Relationships: Depends on `lib/app/services/background_scheduler.dart`, `lib/app/services/notification_service.dart`, `lib/core/state/safe_change_notifier.dart`, `lib/core/storage/storage_service.dart`; referenced by `lib/app/app_entry.dart`, `lib/features/settings/pages/notifications_page.dart`, `lib/features/settings/pages/settings_page.dart`, `test/free_experience_test.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/features/settings/controllers/theme_controller.dart`
- Purpose: Settings module file for theme controller.
- Key APIs/classes: `ThemeController`
- External dependencies: `flutter`
- Relationships: Depends on `lib/core/state/safe_change_notifier.dart`, `lib/core/storage/storage_service.dart`; referenced by `lib/app/app_entry.dart`, `lib/features/settings/pages/settings_page.dart`, `test/free_experience_test.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/features/settings/pages/notifications_page.dart`
- Purpose: Settings module file for notifications page.
- Key APIs/classes: `NotificationsPage`, `_NotificationsPageState`
- External dependencies: `firebase_messaging`, `flutter`, `provider`
- Relationships: Depends on `lib/app/services/background_scheduler.dart`, `lib/app/services/notification_service.dart`, `lib/core/storage/storage_service.dart`, `lib/core/theme/app_theme.dart`, `lib/core/ui/app_components.dart`, `lib/core/utils/app_utils.dart`, `lib/features/settings/controllers/settings_controller.dart`, `lib/features/settings/widgets/settings_widgets.dart`; referenced by `lib/features/settings/pages/settings_page.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/features/settings/pages/profile_page.dart`
- Purpose: Settings module file for profile page.
- Key APIs/classes: `ProfileCard`, `ProfilePage`, `_ProfilePageState`, `_EditDisplayNamePage`, `_EditDisplayNamePageState`
- External dependencies: `flutter`
- Relationships: Depends on `lib/core/storage/storage_service.dart`, `lib/core/theme/app_theme.dart`, `lib/core/utils/app_utils.dart`, `lib/features/settings/widgets/settings_widgets.dart`; referenced by `lib/features/settings/pages/settings_page.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/features/settings/pages/settings_page.dart`
- Purpose: Main settings hub for profile, notifications, sync preferences, support, and session actions.
- Key APIs/classes: `SettingsPage`, `_SettingsPageState`
- External dependencies: `dart:async`, `flutter`, `package_info_plus`, `provider`, `share_plus`, `url_launcher`
- Relationships: Depends on `lib/app/pages/main_nav_page.dart`, `lib/app/services/background_scheduler.dart`, `lib/core/constants/environment_config.dart`, `lib/core/storage/storage_service.dart`, `lib/core/theme/app_theme.dart`, `lib/core/utils/app_utils.dart`, `lib/features/auth/pages/onboarding_page.dart`, `lib/features/auth/services/auth_flow_service.dart`, `lib/features/settings/controllers/settings_controller.dart`, `lib/features/settings/controllers/theme_controller.dart`, `lib/features/settings/pages/notifications_page.dart`, `lib/features/settings/pages/profile_page.dart`, `lib/features/settings/pages/support_page.dart`, `lib/features/settings/pages/wallpaper_sync_page.dart`, `lib/features/settings/widgets/settings_widgets.dart`, `lib/features/wallpaper/services/widget_service.dart`; referenced by `lib/app/pages/main_nav_page.dart`, `lib/features/contributions/pages/home_page.dart`, `test/free_experience_test.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/features/settings/pages/support_page.dart`
- Purpose: Settings module file for support page.
- Key APIs/classes: `SupportPage`
- External dependencies: `flutter`, `url_launcher`
- Relationships: Depends on `lib/core/theme/app_theme.dart`, `lib/core/utils/app_utils.dart`, `lib/features/settings/widgets/settings_widgets.dart`; referenced by `lib/features/settings/pages/settings_page.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/features/settings/pages/wallpaper_sync_page.dart`
- Purpose: Settings module file for wallpaper sync page.
- Key APIs/classes: `WallpaperSyncPage`, `_WallpaperSyncPageState`
- External dependencies: `flutter`
- Relationships: Depends on `lib/app/services/background_scheduler.dart`, `lib/core/storage/storage_service.dart`, `lib/core/theme/app_theme.dart`, `lib/core/utils/app_utils.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/contributions/services/contribution_metrics.dart`, `lib/features/settings/widgets/settings_widgets.dart`; referenced by `lib/features/settings/pages/settings_page.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/features/settings/widgets/settings_widgets.dart`
- Purpose: Settings module file for settings widgets.
- Key APIs/classes: `SettingsSection`, `SettingsCard`, `StatusChip`, `SettingsTile`
- External dependencies: `flutter`
- Relationships: Depends on `lib/core/theme/app_theme.dart`, `lib/core/ui/app_components.dart`; referenced by `lib/features/settings/pages/notifications_page.dart`, `lib/features/settings/pages/profile_page.dart`, `lib/features/settings/pages/settings_page.dart`, `lib/features/settings/pages/support_page.dart`, `lib/features/settings/pages/wallpaper_sync_page.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `lib/features/wallpaper/models/theme_presets.dart`
- Purpose: Wallpaper module file for theme presets.
- Key APIs/classes: `HeatmapTheme`, `ThemePresets`
- External dependencies: `flutter`
- Relationships: Depends on no internal source imports; referenced by `lib/app/product/services/entitlement_engine.dart`, `lib/core/storage/storage_service.dart`, `lib/features/contributions/widgets/share_card.dart`, `lib/features/wallpaper/models/wallpaper_config.dart`, `lib/features/wallpaper/pages/customize_page.dart`, `lib/features/wallpaper/widgets/ui_render.dart`, `test/entitlement_engine_test.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Re-test rendering and native apply flows after changes.

### `lib/features/wallpaper/models/wallpaper_config.dart`
- Purpose: Wallpaper module file for wallpaper config.
- Key APIs/classes: `WallpaperDensityMode`, `WallpaperHeroFocus`, `WallpaperTarget`, `WallpaperConfig`, `_cleanString`, `_clampedDouble`
- External dependencies: `flutter`, `wallpaper_manager_plus`
- Relationships: Depends on `lib/core/utils/app_utils.dart`, `lib/features/wallpaper/models/theme_presets.dart`; referenced by `lib/features/contributions/models/contribution_models.dart`, `test/entitlement_engine_test.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Re-test rendering and native apply flows after changes.

### `lib/features/wallpaper/models/wallpaper_templates.dart`
- Purpose: Wallpaper module file for wallpaper templates.
- Key APIs/classes: `WallpaperTemplate`, `WallpaperTemplates`
- External dependencies: `flutter`
- Relationships: Depends on `lib/features/contributions/models/contribution_models.dart`; referenced by `lib/app/product/services/entitlement_engine.dart`, `lib/core/storage/storage_service.dart`, `lib/features/wallpaper/pages/customize_page.dart`, `lib/features/wallpaper/widgets/ui_render.dart`, `test/entitlement_engine_test.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Re-test rendering and native apply flows after changes.

### `lib/features/wallpaper/pages/customize_page.dart`
- Purpose: Wallpaper module file for customize page.
- Key APIs/classes: `CustomizePage`, `_CustomizePageState`, `_CustomizePageStateView`, `_CustomizePageStatePreview`, `_CustomizePageStateTemplates`, `_CustomizePageStateThemes`, `_CustomizePageStateThemeGallery`, `_CustomizePageStateControls`, `_CustomizePageStateControlSections`, `_CustomizePageStateControlHelpers`, `_CustomizePageStateGuides`, `_WallpaperAppliedCelebration`
- External dependencies: `dart:async`, `flutter`, `smooth_page_indicator`
- Relationships: Depends on `lib/app/services/background_scheduler.dart`, `lib/core/storage/storage_service.dart`, `lib/core/theme/app_theme.dart`, `lib/core/ui/app_components.dart`, `lib/core/utils/app_utils.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/contributions/services/daily_quotes.dart`, `lib/features/wallpaper/models/theme_presets.dart`, `lib/features/wallpaper/models/wallpaper_templates.dart`, `lib/features/wallpaper/services/device_config_service.dart`, `lib/features/wallpaper/services/wallpaper_service.dart`, `lib/features/wallpaper/widgets/ui_render.dart`; referenced by `lib/app/pages/main_nav_page.dart`, `test/customize_preview_overflow_test.dart`, `test/customize_quote_access_test.dart`, `test/free_experience_test.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Re-test rendering and native apply flows after changes.

### `lib/features/wallpaper/services/device_config_service.dart`
- Purpose: Wallpaper module file for device config service.
- Key APIs/classes: `DeviceConfigService`
- External dependencies: `flutter`, `synchronized`
- Relationships: Depends on `lib/core/storage/storage_service.dart`, `lib/core/utils/app_utils.dart`; referenced by `lib/app/pages/main_nav_page.dart`, `lib/app/services/bootstrap_service.dart`, `lib/features/wallpaper/pages/customize_page.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Re-test rendering and native apply flows after changes.

### `lib/features/wallpaper/services/wallpaper_service.dart`
- Purpose: Wallpaper generation, hashing, file output, native apply bridge, and refresh orchestration.
- Key APIs/classes: `WallpaperService`, `DeviceCompatibilityChecker`, `computeStableSignatureHash`
- External dependencies: `crypto`, `dart:async`, `dart:convert`, `dart:io`, `firebase_core`, `flutter`, `path_provider`, `synchronized`, `wallpaper_manager_plus`
- Relationships: Depends on `lib/app/product/services/product_analytics.dart`, `lib/app/services/refresh_result.dart`, `lib/app/services/telemetry_service.dart`, `lib/core/constants/firebase_options.dart`, `lib/core/errors/app_exceptions.dart`, `lib/core/storage/storage_service.dart`, `lib/core/utils/app_utils.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/wallpaper/widgets/ui_render.dart`; referenced by `lib/app/app_entry.dart`, `lib/app/pages/main_nav_page.dart`, `lib/features/contributions/repositories/contribution_repository.dart`, `lib/features/wallpaper/pages/customize_page.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Re-test rendering and native apply flows after changes.

### `lib/features/wallpaper/services/widget_service.dart`
- Purpose: Wallpaper module file for widget service.
- Key APIs/classes: `WidgetService`
- External dependencies: `home_widget`
- Relationships: Depends on `lib/app/product/services/product_state_factory.dart`, `lib/app/product/services/surface_builders.dart`, `lib/core/storage/storage_service.dart`, `lib/core/utils/app_utils.dart`, `lib/features/contributions/models/contribution_models.dart`; referenced by `lib/app/app_entry.dart`, `lib/features/auth/services/auth_flow_service.dart`, `lib/features/contributions/repositories/contribution_repository.dart`, `lib/features/settings/pages/settings_page.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Re-test rendering and native apply flows after changes.

### `lib/features/wallpaper/widgets/ui_render.dart`
- Purpose: Core wallpaper/preview renderer and image generation entrypoint.
- Key APIs/classes: `WallpaperCalendarCell`, `MonthHeatmapRenderer`, `_QuickStat`, `_IdentityItem`, `_PosterHeadline`, `WallpaperPreviewPainter`
- External dependencies: `dart:convert`, `dart:ui`, `flutter`
- Relationships: Depends on `lib/core/errors/app_exceptions.dart`, `lib/core/theme/app_theme.dart`, `lib/core/utils/app_utils.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/contributions/services/contribution_metrics.dart`, `lib/features/wallpaper/models/theme_presets.dart`, `lib/features/wallpaper/models/wallpaper_templates.dart`; referenced by `lib/core/storage/storage_service.dart`, `lib/features/wallpaper/pages/customize_page.dart`, `lib/features/wallpaper/services/wallpaper_service.dart`, `test/customize_preview_overflow_test.dart`.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Re-test rendering and native apply flows after changes.

### `lib/main.dart`
- Purpose: Repository file for main.
- Key APIs/classes: `main`
- External dependencies: None or standard tool syntax
- Relationships: Depends on `lib/app/app_entry.dart`; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

## Android Build and Native Runtime

- Build DSL: Kotlin DSL (`*.gradle.kts`), not Groovy.
- `android/app/build.gradle.kts` currently sets `compileSdk = 36`, `targetSdk = 36`, `minSdk = 24`, Java/Kotlin target `17`, and enables desugaring.
- There are no flavor dimensions and no product flavors configured today.
- Release builds enable shrinking/minification and require release-signing config when release tasks run.
- OAuth redirect handling is wired through the manifest placeholder scheme `gitwall`.

### `android/build.gradle.kts`
- Purpose: Android build or native runtime file for build.gradle.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Validate at least a build or on-device smoke check after changes.

### `android/settings.gradle.kts`
- Purpose: Android plugin-management file that loads Flutter tooling and pins plugin versions.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-26 bec2437` with summary "feat: unify navigation structure and fix onboarding navigation bug"; current worktree status `tracked`.
- Safe modification note: Validate at least a build or on-device smoke check after changes.

### `android/gradle.properties`
- Purpose: Android build or native runtime file for gradleperties.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-26 bec2437` with summary "feat: unify navigation structure and fix onboarding navigation bug"; current worktree status `tracked`.
- Safe modification note: Validate at least a build or on-device smoke check after changes.

### `android/gradle/wrapper/gradle-wrapper.properties`
- Purpose: Android build or native runtime file for gradle wrapperperties.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-25 940dd10` with summary "updated v"; current worktree status `tracked`.
- Safe modification note: Validate at least a build or on-device smoke check after changes.

### `android/app/build.gradle.kts`
- Purpose: Android app-module build definition with SDK levels, signing, release shrinking, and desugaring.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-23 7c85939` with summary "Bulk update: Staging local changes across codebase."; current worktree status `tracked`.
- Safe modification note: Validate at least a build or on-device smoke check after changes.

### `android/app/proguard-rules.pro`
- Purpose: Android build or native runtime file for proguard rules.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-23 7c85939` with summary "Bulk update: Staging local changes across codebase."; current worktree status `tracked`.
- Safe modification note: Validate at least a build or on-device smoke check after changes.

### `android/app/google-services.json`
- Purpose: Android build or native runtime file for google serviceson.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-23 7c85939` with summary "Bulk update: Staging local changes across codebase."; current worktree status `tracked`.
- Safe modification note: Validate at least a build or on-device smoke check after changes.

### `android/key.properties.example`
- Purpose: Android build or native runtime file for keyperties.example.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-02-03 bace288` with summary "feat: Enhance Onboarding, Unified Preview & Month Heatmap Refactor"; current worktree status `tracked`.
- Safe modification note: Validate at least a build or on-device smoke check after changes.

### `android/key.properties`
- Purpose: Android build or native runtime file for keyperties.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `untracked/current-worktree -` with summary "No committed history for this path."; current worktree status `tracked`.
- Safe modification note: Validate at least a build or on-device smoke check after changes.

### `android/local.properties`
- Purpose: Android build or native runtime file for localperties.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `untracked/current-worktree -` with summary "No committed history for this path."; current worktree status `tracked`.
- Safe modification note: Validate at least a build or on-device smoke check after changes.

### `android/app/src/main/AndroidManifest.xml`
- Purpose: Primary Android manifest for permissions, OAuth redirect, widget, and live wallpaper registration.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-23 7c85939` with summary "Bulk update: Staging local changes across codebase."; current worktree status `tracked`.
- Safe modification note: Validate at least a build or on-device smoke check after changes.

### `android/app/src/debug/AndroidManifest.xml`
- Purpose: Android build or native runtime file for AndroidManifest.xml.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Validate at least a build or on-device smoke check after changes.

### `android/app/src/profile/AndroidManifest.xml`
- Purpose: Android build or native runtime file for AndroidManifest.xml.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Validate at least a build or on-device smoke check after changes.

### `android/app/src/main/kotlin/com/rahulreddy/githubwallpaper/MainActivity.kt`
- Purpose: Android MethodChannel bridge for wallpaper apply and notification settings intents.
- Key APIs/classes: `MainActivity`
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-23 7c85939` with summary "Bulk update: Staging local changes across codebase."; current worktree status `tracked`.
- Safe modification note: Validate at least a build or on-device smoke check after changes.

### `android/app/src/main/kotlin/com/rahulreddy/githubwallpaper/GitWallWidgetProvider.kt`
- Purpose: Android build or native runtime file for GitWallWidgetProvider.
- Key APIs/classes: `GitWallWidgetProvider`
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `tracked`.
- Safe modification note: Validate at least a build or on-device smoke check after changes.

### `android/app/src/main/kotlin/com/rahulreddy/githubwallpaper/GitWallLiveWallpaperService.kt`
- Purpose: Android build or native runtime file for GitWallLiveWallpaperService.
- Key APIs/classes: `GitWallLiveWallpaperService`
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-16 324abfb` with summary "chore: update and fix overflow errors"; current worktree status `tracked`.
- Safe modification note: Validate at least a build or on-device smoke check after changes.

### Android resource groups

- `android/app/src/main/res/drawable*`: splash backgrounds, widget background, and notification art.
- `android/app/src/main/res/layout/gitwall_widget.xml`: native home-widget layout.
- `android/app/src/main/res/mipmap*`: launcher icon raster outputs.
- `android/app/src/main/res/values*`: colors, strings, and launch/normal theme definitions.
- `android/app/src/main/res/xml/*`: widget metadata, live wallpaper descriptor, and network security policy.

## Apple, Web, and Desktop Shells

- iOS and macOS remain close to default Flutter shells, with product-specific changes mainly in OAuth URL schemes and plugin registration.
- Web is a thin host shell around the Flutter build.
- Linux and Windows folders are standard Flutter desktop runners with no GitWall-specific business logic.

### `ios/Runner/AppDelegate.swift`
- Purpose: Platform shell/build file for AppDelegate.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `ios/Runner/Info.plist`
- Purpose: Platform shell/build file for Info.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-23 7c85939` with summary "Bulk update: Staging local changes across codebase."; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `ios/Runner.xcodeproj/project.pbxproj`
- Purpose: Platform shell/build file for project.pbxproj.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-23 7c85939` with summary "Bulk update: Staging local changes across codebase."; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `ios/Flutter/Debug.xcconfig`
- Purpose: Platform shell/build file for Debug.xcconfig.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `ios/Flutter/Release.xcconfig`
- Purpose: Platform shell/build file for Release.xcconfig.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `ios/Flutter/Generated.xcconfig`
- Purpose: Platform shell/build file for Generated.xcconfig.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `untracked/current-worktree -` with summary "No committed history for this path."; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `macos/Runner/AppDelegate.swift`
- Purpose: Platform shell/build file for AppDelegate.
- Key APIs/classes: `AppDelegate`
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `macos/Runner/MainFlutterWindow.swift`
- Purpose: Platform shell/build file for MainFlutterWindow.
- Key APIs/classes: `MainFlutterWindow`
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `macos/Runner/Info.plist`
- Purpose: Platform shell/build file for Info.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `macos/Runner/Configs/AppInfo.xcconfig`
- Purpose: Platform shell/build file for AppInfo.xcconfig.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `macos/Runner/Configs/Debug.xcconfig`
- Purpose: Platform shell/build file for Debug.xcconfig.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `macos/Runner/Configs/Release.xcconfig`
- Purpose: Platform shell/build file for Release.xcconfig.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `macos/Runner/Configs/Warnings.xcconfig`
- Purpose: Platform shell/build file for Warnings.xcconfig.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `macos/Flutter/GeneratedPluginRegistrant.swift`
- Purpose: Platform shell/build file for GeneratedPluginRegistrant.
- Key APIs/classes: `RegisterGeneratedPlugins`
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-23 7c85939` with summary "Bulk update: Staging local changes across codebase."; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `macos/Runner.xcodeproj/project.pbxproj`
- Purpose: Platform shell/build file for project.pbxproj.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `web/index.html`
- Purpose: Platform shell/build file for indextml.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-02-13 2f4e903` with summary "Finalizing all pending changes and security settings"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `web/manifest.json`
- Purpose: Platform shell/build file for manifeston.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-02-08 0f88ea7` with summary "chore: finalize theme consistency and refactor codebase dashboard elements"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `linux/CMakeLists.txt`
- Purpose: Platform shell/build file for CMakeLists.txt.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `linux/flutter/CMakeLists.txt`
- Purpose: Platform shell/build file for CMakeLists.txt.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `linux/runner/CMakeLists.txt`
- Purpose: Platform shell/build file for CMakeLists.txt.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `linux/runner/main.cc`
- Purpose: Platform shell/build file for main.
- Key APIs/classes: `main`
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `linux/runner/my_application.cc`
- Purpose: Platform shell/build file for my application.
- Key APIs/classes: `first_frame_cb`, `my_application_activate`, `my_application_local_command_line`, `my_application_startup`, `my_application_shutdown`, `my_application_dispose`, `my_application_class_init`, `my_application_init`
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `linux/runner/my_application.h`
- Purpose: Platform shell/build file for my application.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `windows/CMakeLists.txt`
- Purpose: Platform shell/build file for CMakeLists.txt.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `windows/flutter/CMakeLists.txt`
- Purpose: Platform shell/build file for CMakeLists.txt.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `windows/runner/CMakeLists.txt`
- Purpose: Platform shell/build file for CMakeLists.txt.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `windows/runner/main.cpp`
- Purpose: Platform shell/build file for main.
- Key APIs/classes: `wWinMain`
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `windows/runner/flutter_window.cpp`
- Purpose: Platform shell/build file for flutter window.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `windows/runner/flutter_window.h`
- Purpose: Platform shell/build file for flutter window.
- Key APIs/classes: `FlutterWindow`
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `windows/runner/utils.cpp`
- Purpose: Platform shell/build file for utils.
- Key APIs/classes: `CreateAndAttachConsole`
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `windows/runner/utils.h`
- Purpose: Platform shell/build file for utils.
- Key APIs/classes: `CreateAndAttachConsole`
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `windows/runner/win32_window.cpp`
- Purpose: Platform shell/build file for win32 window.
- Key APIs/classes: `WindowClassRegistrar`, `Scale`, `EnableFullDpiSupportIfAvailable`
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `windows/runner/win32_window.h`
- Purpose: Platform shell/build file for win32 window.
- Key APIs/classes: `Win32Window`
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

### `windows/runner/Runner.rc`
- Purpose: Platform shell/build file for Runner.rc.
- Key APIs/classes: None or non-code configuration
- External dependencies: None or standard tool syntax
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-01-23 5eba447` with summary "Initial commit: GitHub Wallpaper App with auto-updates"; current worktree status `tracked`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

## Tests

- `test/` mixes unit and widget tests, with heavy emphasis on responsive layout regressions and free-access behavior.
- The `app/product/` foundation is covered by `test/product_foundation_test.dart` and `test/entitlement_engine_test.dart`.
- Legacy membership/paywall tests have been replaced by free-experience assertions in the current worktree.

### `test/app_strings_test.dart`
- Purpose: Test coverage for app strings test.
- Key APIs/classes: `main`
- External dependencies: `flutter_test`
- Relationships: Depends on `lib/core/utils/app_utils.dart`; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-23 7c85939` with summary "Bulk update: Staging local changes across codebase."; current worktree status `M`.
- Safe modification note: Update tests with behavior changes instead of after them.

### `test/background_scheduler_test.dart`
- Purpose: Test coverage for background scheduler test.
- Key APIs/classes: `main`
- External dependencies: `flutter_test`
- Relationships: Depends on `lib/app/services/background_scheduler.dart`, `lib/app/services/refresh_result.dart`; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Update tests with behavior changes instead of after them.

### `test/customize_preview_overflow_test.dart`
- Purpose: Test coverage for customize preview overflow test.
- Key APIs/classes: `main`
- External dependencies: `dart:convert`, `flutter`, `flutter_test`, `shared_preferences`
- Relationships: Depends on `lib/core/storage/storage_service.dart`, `lib/core/theme/app_theme.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/wallpaper/pages/customize_page.dart`, `lib/features/wallpaper/widgets/ui_render.dart`; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Update tests with behavior changes instead of after them.

### `test/customize_quote_access_test.dart`
- Purpose: Test coverage for customize quote access test.
- Key APIs/classes: `main`
- External dependencies: `flutter`, `flutter_test`, `shared_preferences`
- Relationships: Depends on `lib/core/storage/storage_service.dart`, `lib/core/theme/app_theme.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/wallpaper/pages/customize_page.dart`; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `untracked/current-worktree -` with summary "No committed history for this path."; current worktree status `??`.
- Safe modification note: Update tests with behavior changes instead of after them.

### `test/daily_quotes_test.dart`
- Purpose: Test coverage for daily quotes test.
- Key APIs/classes: `main`
- External dependencies: `flutter_test`
- Relationships: Depends on `lib/features/contributions/services/daily_quotes.dart`; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Update tests with behavior changes instead of after them.

### `test/entitlement_engine_test.dart`
- Purpose: Test coverage for entitlement engine test.
- Key APIs/classes: `main`
- External dependencies: `flutter_test`, `shared_preferences`
- Relationships: Depends on `lib/app/product/models/product_models.dart`, `lib/app/product/services/entitlement_engine.dart`, `lib/core/storage/storage_service.dart`, `lib/features/wallpaper/models/theme_presets.dart`, `lib/features/wallpaper/models/wallpaper_config.dart`, `lib/features/wallpaper/models/wallpaper_templates.dart`; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `untracked/current-worktree -` with summary "No committed history for this path."; current worktree status `??`.
- Safe modification note: Update tests with behavior changes instead of after them.

### `test/environment_config_test.dart`
- Purpose: Test coverage for environment config test.
- Key APIs/classes: `main`
- External dependencies: `flutter_test`
- Relationships: Depends on `lib/core/constants/environment_config.dart`, `lib/core/errors/app_exceptions.dart`; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Update tests with behavior changes instead of after them.

### `test/error_handler_safe_snackbar_test.dart`
- Purpose: Test coverage for error handler safe snackbar test.
- Key APIs/classes: `main`
- External dependencies: `flutter`, `flutter_test`
- Relationships: Depends on `lib/core/utils/app_utils.dart`; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-23 7c85939` with summary "Bulk update: Staging local changes across codebase."; current worktree status `M`.
- Safe modification note: Update tests with behavior changes instead of after them.

### `test/free_experience_test.dart`
- Purpose: Test coverage for free experience test.
- Key APIs/classes: `main`
- External dependencies: `flutter`, `flutter_test`, `provider`, `shared_preferences`
- Relationships: Depends on `lib/core/storage/storage_service.dart`, `lib/core/theme/app_theme.dart`, `lib/core/utils/app_utils.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/contributions/pages/stats_page.dart`, `lib/features/settings/controllers/settings_controller.dart`, `lib/features/settings/controllers/theme_controller.dart`, `lib/features/settings/pages/settings_page.dart`, `lib/features/wallpaper/pages/customize_page.dart`; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Update tests with behavior changes instead of after them.

### `test/home_greeting_test.dart`
- Purpose: Test coverage for home greeting test.
- Key APIs/classes: `main`
- External dependencies: `flutter`, `flutter_test`, `shared_preferences`
- Relationships: Depends on `lib/core/storage/storage_service.dart`, `lib/core/theme/app_theme.dart`, `lib/core/utils/app_utils.dart`, `lib/features/contributions/pages/home_page.dart`; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Update tests with behavior changes instead of after them.

### `test/home_profile_layout_overflow_test.dart`
- Purpose: Test coverage for home profile layout overflow test.
- Key APIs/classes: `main`
- External dependencies: `flutter`, `flutter_test`, `shared_preferences`
- Relationships: Depends on `lib/core/storage/storage_service.dart`, `lib/core/theme/app_theme.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/contributions/pages/home_page.dart`, `lib/features/contributions/pages/stats_page.dart`; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Update tests with behavior changes instead of after them.

### `test/home_setup_prompt_test.dart`
- Purpose: Test coverage for home setup prompt test.
- Key APIs/classes: `main`
- External dependencies: `flutter`, `flutter_test`, `shared_preferences`
- Relationships: Depends on `lib/core/storage/storage_service.dart`, `lib/core/theme/app_theme.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/contributions/pages/home_page.dart`; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `untracked/current-worktree -` with summary "No committed history for this path."; current worktree status `??`.
- Safe modification note: Update tests with behavior changes instead of after them.

### `test/home_share_sheet_test.dart`
- Purpose: Test coverage for home share sheet test.
- Key APIs/classes: `main`
- External dependencies: `flutter`, `flutter_test`, `shared_preferences`
- Relationships: Depends on `lib/core/storage/storage_service.dart`, `lib/core/theme/app_theme.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/contributions/pages/home_page.dart`; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `untracked/current-worktree -` with summary "No committed history for this path."; current worktree status `??`.
- Safe modification note: Update tests with behavior changes instead of after them.

### `test/oauth_redirect_config_test.dart`
- Purpose: Test coverage for oauth redirect config test.
- Key APIs/classes: `main`
- External dependencies: `dart:io`, `flutter_test`
- Relationships: Depends on no internal source imports; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-23 7c85939` with summary "Bulk update: Staging local changes across codebase."; current worktree status `tracked`.
- Safe modification note: Update tests with behavior changes instead of after them.

### `test/oauth_service_test.dart`
- Purpose: Test coverage for oauth service test.
- Key APIs/classes: `main`
- External dependencies: `flutter_test`, `http`
- Relationships: Depends on `lib/core/errors/app_exceptions.dart`, `lib/features/auth/services/oauth_service.dart`; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Update tests with behavior changes instead of after them.

### `test/onboarding_overflow_test.dart`
- Purpose: Test coverage for onboarding overflow test.
- Key APIs/classes: `main`
- External dependencies: `flutter`, `flutter_test`
- Relationships: Depends on `lib/core/theme/app_theme.dart`, `lib/features/auth/pages/onboarding_page.dart`; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Update tests with behavior changes instead of after them.

### `test/onboarding_preparing_state_test.dart`
- Purpose: Test coverage for onboarding preparing state test.
- Key APIs/classes: `main`
- External dependencies: `flutter`, `flutter_test`
- Relationships: Depends on `lib/core/theme/app_theme.dart`, `lib/features/auth/widgets/onboarding_content.dart`; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `untracked/current-worktree -` with summary "No committed history for this path."; current worktree status `??`.
- Safe modification note: Update tests with behavior changes instead of after them.

### `test/onboarding_setup_layout_test.dart`
- Purpose: Test coverage for onboarding setup layout test.
- Key APIs/classes: `_pumpAtSize`, `main`
- External dependencies: `flutter`, `flutter_test`
- Relationships: Depends on `lib/core/theme/app_theme.dart`, `lib/features/auth/pages/onboarding_page.dart`; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Update tests with behavior changes instead of after them.

### `test/product_foundation_test.dart`
- Purpose: Test coverage for product foundation test.
- Key APIs/classes: `main`
- External dependencies: `flutter_test`
- Relationships: Depends on `lib/app/product/models/product_models.dart`, `lib/app/product/services/entitlement_engine.dart`, `lib/app/product/services/insight_engine.dart`, `lib/app/product/services/surface_builders.dart`, `lib/app/product/services/sync_engine.dart`, `lib/app/services/refresh_result.dart`, `lib/core/utils/app_utils.dart`, `lib/features/contributions/models/contribution_models.dart`; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `untracked/current-worktree -` with summary "No committed history for this path."; current worktree status `??`.
- Safe modification note: Update tests with behavior changes instead of after them.

### `test/share_card_layout_test.dart`
- Purpose: Test coverage for share card layout test.
- Key APIs/classes: `main`
- External dependencies: `flutter`, `flutter_test`, `shared_preferences`
- Relationships: Depends on `lib/core/storage/storage_service.dart`, `lib/core/theme/app_theme.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/contributions/services/contribution_metrics.dart`, `lib/features/contributions/widgets/share_card.dart`; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Update tests with behavior changes instead of after them.

### `test/stats_sections_overflow_test.dart`
- Purpose: Test coverage for stats sections overflow test.
- Key APIs/classes: `main`
- External dependencies: `flutter`, `flutter_test`
- Relationships: Depends on `lib/core/theme/app_theme.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/contributions/widgets/stats_sections.dart`; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `untracked/current-worktree -` with summary "No committed history for this path."; current worktree status `??`.
- Safe modification note: Update tests with behavior changes instead of after them.

### `test/streak_calculation_test.dart`
- Purpose: Test coverage for streak calculation test.
- Key APIs/classes: `main`
- External dependencies: `flutter_test`
- Relationships: Depends on `lib/core/utils/app_utils.dart`, `lib/features/contributions/models/contribution_models.dart`, `lib/features/contributions/services/contribution_metrics.dart`; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `tracked`.
- Safe modification note: Update tests with behavior changes instead of after them.

### `test/sync_logic_test.dart`
- Purpose: Test coverage for sync logic test.
- Key APIs/classes: `main`
- External dependencies: `flutter`, `flutter_test`, `shared_preferences`
- Relationships: Depends on `lib/core/storage/storage_service.dart`, `lib/features/contributions/services/contribution_metrics.dart`; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `tracked`.
- Safe modification note: Update tests with behavior changes instead of after them.

### `test/theme_contrast_test.dart`
- Purpose: Test coverage for theme contrast test.
- Key APIs/classes: `_srgbToLinear`, `_relativeLuminance`, `_contrastRatio`, `_expectAaLargeOrNormal`, `main`
- External dependencies: `dart:math`, `flutter`, `flutter_test`
- Relationships: Depends on `lib/core/theme/app_theme.dart`; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-23 7c85939` with summary "Bulk update: Staging local changes across codebase."; current worktree status `tracked`.
- Safe modification note: Update tests with behavior changes instead of after them.

### `integration_test/exploratory_user_journeys_test.dart`
- Purpose: Integration test for exploratory user journeys test.
- Key APIs/classes: `_seedContributionData`, `_pumpUntilFound`, `_tryScreenshot`, `_tapVisible`, `main`
- External dependencies: `dart:math`, `flutter`, `flutter_test`, `integration_test`
- Relationships: Depends on `lib/app/app_entry.dart`, `lib/core/storage/storage_service.dart`, `lib/features/contributions/models/contribution_models.dart`; referenced by no tracked reverse imports in documented source.
- Modification history: last committed touch `2026-03-24 f16a0c3` with summary "refactor: ship architecture consolidation and membership fixes"; current worktree status `M`.
- Safe modification note: Low-to-medium risk; keep references and contracts synchronized.

## Remaining Directories and Generated Areas

- `.codex/`: local AI-agent skill definitions and scripts; not shipped runtime behavior.
- `.idea/`: IDE metadata.
- `docs/`: intentionally removed as a markdown documentation surface; this file replaces it.
- `.dart_tool/`, `build/`, `coverage/`: generated outputs safe to regenerate.
- `functions/node_modules/`: npm vendor tree, intentionally not documented file-by-file.

## Safe Modification Guide

1. Prefer changing pure layers first: `lib/app/product/services/*`, `lib/features/contributions/services/contribution_metrics.dart`, and `lib/features/wallpaper/models/*`.
2. Treat `lib/core/storage/storage_service.dart`, `lib/features/auth/services/oauth_service.dart`, `lib/features/auth/services/identity_service.dart`, `functions/index.js`, and `firestore.rules` as contract-critical.
3. Keep `lib/features/wallpaper/widgets/ui_render.dart` and `lib/features/wallpaper/services/wallpaper_service.dart` backward compatible with saved configs and target-size assumptions.
4. Update Android native code in lockstep with Dart MethodChannel callers (`github_wallpaper/wallpaper` and `github_wallpaper/system`).
5. If you touch OAuth redirects or app IDs, update Android manifest, iOS plist, environment config, and backend assumptions together.
6. When changing settings or sync preferences, update both `StorageService` and the relevant controllers/pages.
7. After cross-cutting changes, at minimum run `flutter analyze lib test` and `flutter test`.

## Quick Location Guide

- Startup: `lib/app/app_entry.dart`, `lib/app/services/bootstrap_service.dart`.
- GitHub session model: `lib/features/auth/services/oauth_service.dart`, `lib/features/auth/services/identity_service.dart`, `functions/index.js`, `firestore.rules`.
- Dashboard numbers: `lib/features/contributions/services/contribution_metrics.dart`, `lib/app/product/services/insight_engine.dart`, `lib/app/product/services/surface_builders.dart`.
- Wallpaper visuals: `lib/features/wallpaper/models/wallpaper_templates.dart`, `lib/features/wallpaper/models/theme_presets.dart`, `lib/features/wallpaper/widgets/ui_render.dart`, `lib/features/wallpaper/pages/customize_page.dart`.
- Notifications: `lib/app/services/notification_service.dart`, `lib/features/settings/pages/notifications_page.dart`, `functions/index.js`.
- Admin controls: `admin/index.html`, `admin/app.js`, `admin/config.js`, `functions/index.js`.
