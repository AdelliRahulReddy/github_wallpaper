# GitWall Codebase Audit Report

Audit date: 2026-02-15  
Repository root: `c:\Users\adell\Desktop\github_wallpaper`

## Executive Summary

Overall risk: **Medium** (production-ready core flows, but several operational/reliability and repo-hygiene risks remain).

What looks solid:
- Flutter static analysis is clean (`flutter analyze`: **0 issues**) and unit/widget tests pass (`flutter test`: **8/8**).
- Cloud Functions dependency audit is clean (`npm audit`: **0 vulnerabilities**).
- Core flows (boot → sync → wallpaper apply → background refresh) are clearly structured and documented in [bug-discovery-architecture-and-flows.md](file:///c:/Users/adell/Desktop/github_wallpaper/docs/bug-discovery-architecture-and-flows.md).

Primary risks to address next:
- **Repository hygiene risk**: generated Flutter Windows “ephemeral” artifacts exist under `windows/flutter/ephemeral/` but are **not ignored** by [.gitignore](file:///c:/Users/adell/Desktop/github_wallpaper/.gitignore#L26-L64). If tracked in git, this bloats the repo and causes unstable diffs.
- **Background concurrency risk**: refresh/apply code uses in-process locks, but background triggers can run in **separate isolates/processes**, allowing double-refresh and temp-file deletion races.
- **Backend deploy risk**: Functions runtime is pinned to **Node 22** in [functions/package.json](file:///c:/Users/adell/Desktop/github_wallpaper/functions/package.json#L4-L11); confirm Firebase Functions supports it in your target environment.
- **Coverage gap**: integration tests exist but are **not reliably runnable** in this environment; CI does not run analyze/tests.

## Project Structure & Architecture

### Stack
- Flutter (Dart) client; Android-first for wallpaper apply (README: [README.md](file:///c:/Users/adell/Desktop/github_wallpaper/README.md#L56-L62))
- Firebase: Core, Messaging (FCM), Crashlytics, App Check
- GitHub GraphQL API over HTTPS
- Firebase Cloud Functions (scheduled “refresh” push to topic)

### Core Modules (Flutter)
- App bootstrap + routing: [main.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/main.dart#L43-L224)
- Storage, GitHub sync, wallpaper generation/apply, FCM handlers, bootstrap services: [app_services.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart)
- Background WorkManager scheduling: [background_scheduler.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/background_scheduler.dart)
- Rendering pipeline: [ui_render.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/ui_render.dart)
- Major UI: [home_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/home_page.dart), [customize_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/customize_page.dart), [settings_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/settings_page.dart)

### Key Runtime Flows
- Boot flow: `main()` → `BootstrapService.boot()` → select onboarding vs main nav  
  - [main.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/main.dart#L43-L224), [BootstrapService.boot](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L958-L1024)
- Sync flow: UI calls `GitHubService.getContributions()` which is the cache writer  
  - [GitHubService.getContributions](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L384-L436)
- User-initiated wallpaper apply: `WallpaperService.generateAndSetWallpaper()` → Android method channel fallback → persist last hash/path  
  - [WallpaperService.generateAndSetWallpaper](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L608-L645), [MainActivity.kt](file:///c:/Users/adell/Desktop/github_wallpaper/android/app/src/main/kotlin/com/rahulreddy/githubwallpaper/MainActivity.kt#L11-L97)
- Background refresh: Cloud Scheduler → FCM data message `type=refresh` → `_bgH` and/or WorkManager task  
  - [functions/index.js](file:///c:/Users/adell/Desktop/github_wallpaper/functions/index.js#L12-L66), [_bgH](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L846-L885), [callbackDispatcher](file:///c:/Users/adell/Desktop/github_wallpaper/lib/background_scheduler.dart#L18-L55)

## Technical Debt Metrics (Quantified)

### Size / Hotspots
- Dart files (lib/test/integration_test): **22**
- Total Dart LOC (lib/test/integration_test): **8033**

Largest Dart files by LOC (top 10):
- 1424 [home_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/home_page.dart)
- 912 [app_services.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart)
- 759 [customize_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/customize_page.dart)
- 594 [settings_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/settings_page.dart)
- 588 [ui_render.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/ui_render.dart)
- 564 [onboarding_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/onboarding_page.dart)
- 500 [setup_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/setup_page.dart)
- 493 [app_utils.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_utils.dart)
- 449 [app_models.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_models.dart)
- 379 [app_theme.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_theme.dart)

### Complexity Proxies
Top “branching density” files (count of `if(`, `switch(`, `catch` occurrences; proxy only):
- 66 if / 2 switch / 24 catch — [app_services.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart)
- 34 if / 0 switch / 1 catch — [app_utils.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_utils.dart)
- 27 if / 1 switch / 3 catch — [main_nav_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/main_nav_page.dart)

### Silent Catch Blocks
Occurrences of `catch (_) {}` across `lib/`: **10**  
- [main.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/main.dart#L17-L41) (Crashlytics recording)
- [app_services.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L846-L956) (background init helpers)
- [app_utils.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_utils.dart#L153-L176) (Crashlytics log)
- [home_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/home_page.dart#L40-L51)
- [customize_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/customize_page.dart) (see file for occurrences)

## Detailed Issue Inventory (With Locations)

Legend: **Severity** = Critical / High / Medium / Low.

### High Severity

**H-01 — Repository Hygiene: Flutter “ephemeral” artifacts not ignored**
- Location: `windows/flutter/ephemeral/` (directory exists; contains binaries, symlinks, and generated plugin content)
- Related config: [.gitignore](file:///c:/Users/adell/Desktop/github_wallpaper/.gitignore#L26-L64)
- Risk:
  - If committed: huge repo size, slow clones, noisy diffs, and accidental inclusion of build outputs.
  - Even if not committed: missing ignore rules increases risk of accidental commits.
- Remediation:
  - Add ignore patterns for `**/flutter/ephemeral/`, `**/.plugin_symlinks/`, and platform build outputs.
  - If already tracked, remove from git index while keeping local generation (e.g., `git rm -r --cached windows/flutter/ephemeral`).
- Success criteria:
  - Repo contains no generated `ephemeral` artifacts; clean `git status` after `flutter pub get`.
- Tests:
  - N/A (repo hygiene), but verify with `git status` after regenerating.

**H-02 — Background concurrency: cross-isolate double-refresh + temp-file deletion race**
- Locations:
  - Background FCM handler: [_bgH](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L846-L885)
  - WorkManager task: [callbackDispatcher](file:///c:/Users/adell/Desktop/github_wallpaper/lib/background_scheduler.dart#L18-L55)
  - Temp-file cleanup + save: [WallpaperService._save](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L701-L729)
- Risk:
  - `Lock()` usage in Dart only protects within a single isolate; FCM background + WorkManager can execute in different isolates/processes.
  - Concurrent runs can both decide “proceed”, fetch twice, and one run can delete the other run’s temp wallpaper file during cleanup.
- Remediation options:
  - Persisted mutex: store a “refresh in progress” lease (timestamp + owner token) in `SharedPreferences` and enforce it in both entry points.
  - Make `_save` safe under concurrency: only delete older files (by mtime) and/or write to a unique directory per run; delete after apply completes.
  - Prefer one background mechanism: either set a pending flag in `_bgH` and let WorkManager handle the actual refresh, or vice versa.
- Success criteria:
  - No duplicate network fetch within a configured window even under simultaneous triggers.
  - No missing wallpaper file errors during apply.
- Tests:
  - Add a unit test for the persisted lease logic.
  - Add an integration test scenario that triggers both refresh pathways.

**H-03 — Backend deploy risk: Functions runtime pinned to Node 22**
- Location: [functions/package.json](file:///c:/Users/adell/Desktop/github_wallpaper/functions/package.json#L4-L11)
- Risk:
  - Firebase Functions support for Node 22 may be limited depending on your Firebase/CLI/runtime version and project region settings.
- Remediation:
  - Confirm supported runtimes for your Firebase project; pin to a known-supported Node major if needed (commonly Node 20).
- Success criteria:
  - Successful deploy and scheduled trigger runs reliably.
- Tests:
  - Deploy to a staging project; validate scheduler and delivery behavior.

### Medium Severity

**M-01 — FCM delivery profile: “high” priority message may increase battery impact**
- Location: [functions/index.js](file:///c:/Users/adell/Desktop/github_wallpaper/functions/index.js#L19-L29)
- Risk:
  - High-priority data messages can increase wakeups and battery usage; may be throttled or behave differently across OEMs.
- Remediation:
  - Consider `priority: "normal"` for periodic refresh; rely on WorkManager for “guaranteed” execution where needed.
  - Document the intended behavior and rationale (user expectations vs battery).
- Success criteria:
  - Refreshes occur at expected cadence without excessive wakeups.
- Tests:
  - Field test on at least one Samsung/Xiaomi device with battery optimizations enabled.

**M-02 — Sensitive config committed: clarify policy for public repo**
- Locations:
  - `android/app/google-services.json` (file exists)
  - [lib/firebase_options.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/firebase_options.dart)
  - Ignore rules are commented out in [.gitignore](file:///c:/Users/adell/Desktop/github_wallpaper/.gitignore#L54-L57)
- Risk:
  - While Firebase client keys aren’t “secrets” in the same way as private keys, publishing project identifiers may be undesirable.
- Remediation:
  - Decide policy: keep committed (simpler onboarding) vs remove and require `flutterfire configure`.
  - If removed, update README and CI to ensure local generation.
- Success criteria:
  - Clear documented setup path; no accidental secret exposure.
- Tests:
  - Clean-clone setup instructions succeed.

**M-03 — Dependency drift: multiple major updates available; `js` is discontinued**
- Source: output from `flutter pub outdated`
- Risk:
  - Security and compatibility fixes may be missed; major upgrades can introduce breaking changes.
  - Discontinued transitive packages may eventually become ecosystem blockers (web builds in particular).
- Remediation:
  - Create an upgrade plan in stages; prioritize security-critical/runtime-facing deps first.
  - Track the discontinued `js` transitive dependency root cause (which package brings it in) and whether it affects supported platforms.
- Success criteria:
  - Dependencies updated without regressions; tests and analysis remain clean.
- Tests:
  - Run unit/widget tests and at least one Android device smoke test per upgrade batch.

**M-04 — Android SDK level: compile/target SDK 36 may be ahead of stable toolchains**
- Location: [android/app/build.gradle.kts](file:///c:/Users/adell/Desktop/github_wallpaper/android/app/build.gradle.kts#L24-L44)
- Risk:
  - Toolchain incompatibilities; Play policy and device behavior changes.
- Remediation:
  - Confirm required SDK level; align with stable Flutter/AGP guidance unless there’s a specific need.
- Success criteria:
  - Release builds succeed consistently in CI; install works on target device OS versions.
- Tests:
  - Android release build verification + runtime smoke test.

**M-05 — Test execution gap: integration tests not runnable in this Windows environment**
- Location: [exploratory_user_journeys_test.dart](file:///c:/Users/adell/Desktop/github_wallpaper/integration_test/exploratory_user_journeys_test.dart)
- Observed:
  - Running `flutter test integration_test -d windows` fails due to missing `atlstr.h` (Windows toolchain/ATL dependency from `flutter_secure_storage_windows`).
- Remediation:
  - Run integration tests on Android emulator/device (recommended for app’s primary platform).
  - Add CI that runs integration tests on an Android runner or Firebase Test Lab.
- Success criteria:
  - Integration tests execute in CI on Android.

### Low Severity

**L-01 — Swallowed exceptions reduce diagnosability**
- Locations:
  - [main.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/main.dart#L17-L41), [app_services.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L846-L956)
- Risk:
  - Silent failures make it harder to understand why refresh/apply didn’t occur, especially on OEM-restricted devices.
- Remediation:
  - Log sanitized, non-sensitive breadcrumbs (respecting Crashlytics consent).
  - Prefer `catch (e, s)` with at least debug logging where safe.
- Success criteria:
  - Clear, privacy-safe diagnostics for background failures.

**L-02 — “God files” increase maintenance cost**
- Locations:
  - [app_services.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart)
  - [home_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/home_page.dart)
- Remediation:
  - Split into smaller units (Storage/GitHub/Wallpaper/FCM/Bootstrap; separate UI sections into widgets).
- Success criteria:
  - Reduced file size; clearer ownership boundaries; faster reviews.

## Testing Coverage Evaluation

### Current Tests
- Unit/widget tests (pass): `test/`
  - [streak_calculation_test.dart](file:///c:/Users/adell/Desktop/github_wallpaper/test/streak_calculation_test.dart)
  - [error_handler_safe_snackbar_test.dart](file:///c:/Users/adell/Desktop/github_wallpaper/test/error_handler_safe_snackbar_test.dart)
  - [home_greeting_test.dart](file:///c:/Users/adell/Desktop/github_wallpaper/test/home_greeting_test.dart)
  - [onboarding_overflow_test.dart](file:///c:/Users/adell/Desktop/github_wallpaper/test/onboarding_overflow_test.dart)
- Integration test (present, not executed here): [exploratory_user_journeys_test.dart](file:///c:/Users/adell/Desktop/github_wallpaper/integration_test/exploratory_user_journeys_test.dart)

### Key Untested / Under-tested Paths
- Background concurrency scenarios (FCM + WorkManager firing close together)
- Wallpaper file lifecycle (temp cleanup vs apply)
- Error-path behavior:
  - GitHub API non-JSON response handling
  - Token invalid/expired while background refresh attempts
  - Rate-limit backoff correctness
- Android-specific behavior:
  - MethodChannel apply on OEM variants (fallback correctness)

## Prioritized Remediation Roadmap (Action Plan)

Effort scale: XS / S / M / L (relative; no time commitments).

1) **Stop repo bloat & accidental commits (High, S)**
- Add ignore rules for ephemeral/plugin symlink/build artifacts.
- Remove tracked generated artifacts if present.

2) **Make background refresh robust across isolates (High, M)**
- Add persisted lease/mutex.
- Make wallpaper temp file cleanup concurrency-safe.
- Decide a single “source of truth” background pathway (FCM sets pending; WorkManager executes).

3) **Validate backend runtime compatibility (High, XS–S)**
- Confirm Node major support; pin accordingly.

4) **Stabilize and automate test execution (Medium, M)**
- Add CI jobs: `flutter analyze`, `flutter test`, `npm audit`/lint.
- Run integration tests on Android (emulator or Test Lab).

5) **Dependency upgrade program (Medium, M–L)**
- Upgrade in batches; re-run tests each batch.
- Track discontinued `js` dependency and its root.

## Verification Status (This Audit)
- `flutter analyze`: PASS (0 issues)
- `flutter test`: PASS (8 tests)
- `npm audit` (functions): PASS (0 vulnerabilities)
- `flutter test integration_test`:
  - Interactive device selection avoided; Windows run attempted and failed due to missing ATL headers (environment limitation)

