## Root Cause (Current Behavior)
- Auto-update is currently *not* a true device-side schedule; it’s primarily push-driven and/or “on next app launch”. In [_bgH](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L802-L839), any failure during background refresh sets `pending_wp_refresh`, which is only consumed on startup in [AppInitializer._runPendingRefresh](file:///c:/Users/adell/Desktop/github_wallpaper/lib/main.dart#L156-L209). This makes updates appear to only happen after opening the app.
- The intended WorkManager-based scheduler is present but not functional:
  - [BackgroundScheduler](file:///c:/Users/adell/Desktop/github_wallpaper/lib/services/background_scheduler.dart) has broken imports (relative paths) and calls non-existent logging APIs, so it’s effectively unusable.
  - Settings toggle only subscribes to FCM topic; it does not explicitly schedule/cancel WorkManager ([settings_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/settings_page.dart#L267-L306)).
- Background isolates likely lack plugin registration. In both FCM background handling and WorkManager callbacks, plugins like `flutter_secure_storage`, `path_provider`, and `wallpaper_manager_plus` require `DartPluginRegistrant.ensureInitialized()`; without it, calls tend to throw and trigger the “pending until next launch” fallback.

## Implementation (Android-First)
### 1) Make background execution actually work (Headless isolate readiness)
- Add `DartPluginRegistrant.ensureInitialized()` at the start of:
  - the FCM background handler [_bgH](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L802-L839)
  - the WorkManager callback dispatcher in [background_scheduler.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/services/background_scheduler.dart)
- Ensure background refresh paths initialize storage + Firebase only once and log structured outcomes (success/skip reason/failure).

### 2) Fix and wire up WorkManager scheduling
- Repair [background_scheduler.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/services/background_scheduler.dart):
  - Correct relative imports (`../app_services.dart`, `../app_utils.dart`).
  - Use existing `AppLog.info/error` signatures (or extend `AppLog` with `warn` if needed).
  - Ensure `Workmanager().executeTask` returns `true` for “completed (even if skipped)” vs `false` only for “retry-worthy failure”.
- In app startup (already present in [main.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/main.dart#L197-L203)):
  - Keep `BackgroundScheduler.initialize()`.
  - If auto-update enabled, call `BackgroundScheduler.scheduleUpdates()`.
- Update Settings toggle so enabling/disabling auto-update also schedules/cancels WorkManager immediately (not only on next launch).

### 3) Interval support (“specified intervals”)
- Add a persisted setting for auto-update interval (e.g., 1h/3h/6h/12h/24h; enforce Android minimum of 15 min).
- Update scheduler to use the chosen interval.
- Keep FCM as an additional “best effort immediate refresh” trigger, but do not rely on it for correctness.

### 4) Reboot survival & device constraints
- Rely on WorkManager’s persistence through reboot (manifest already includes `RECEIVE_BOOT_COMPLETED` and `WAKE_LOCK`: [AndroidManifest.xml](file:///c:/Users/adell/Desktop/github_wallpaper/android/app/src/main/AndroidManifest.xml#L1-L56)).
- Add a one-time reschedule-on-boot safety net only if OEM behavior requires it (optional; WorkManager typically suffices).

### 5) Battery optimization exemptions (user-facing)
- Add a Settings entry that:
  - shows current battery optimization state (Android only)
  - deep-links to “Ignore battery optimizations” prompt/settings via a small Android method-channel helper
  - links to a doc section for common OEM “auto-start / background activity” settings

### 6) Logging and diagnostics
- Add an “Auto-update diagnostics” panel:
  - last run time, last result, last error message (sanitized), last schedule interval
  - keep a small rolling buffer in SharedPreferences for quick on-device debugging
- Ensure Crashlytics breadcrumbs are recorded only when consent is enabled (already enforced in [main.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/main.dart#L30-L82)).

### 7) Remove/clarify dead code
- `android/.../WallpaperWorker.kt` is currently unused and references a Dart method-channel that doesn’t exist; remove it or clearly deprecate it to avoid confusion.

## Verification & Test Coverage
### Automated
- Add Dart tests for:
  - scheduler enable/disable logic (persists interval, invokes schedule/cancel)
  - background refresh decision logic (`RefreshPolicy.shouldRefresh`) and “pending” behavior

### Manual / Device Matrix (documented, repeatable)
- Provide a test checklist + ADB recipes for:
  - app swiped away (not force-stopped), verify periodic WorkManager runs
  - reboot: confirm reschedule + first run occurs
  - Battery Saver on/off
  - Doze: `adb shell dumpsys deviceidle force-idle` and verify next run window
  - OEM-specific restrictions (Samsung/Xiaomi/Oppo/OnePlus)

## Deliverables (Concrete Files/Areas Updated)
- Fix scheduling + background isolate registration in:
  - [app_services.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart)
  - [background_scheduler.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/services/background_scheduler.dart)
  - [settings_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/settings_page.dart)
- Add Android method-channel helper for battery optimization intents:
  - [MainActivity.kt](file:///c:/Users/adell/Desktop/github_wallpaper/android/app/src/main/kotlin/com/rahulreddy/githubwallpaper/MainActivity.kt)
- Add docs + test checklist under [docs/](file:///c:/Users/adell/Desktop/github_wallpaper/docs)

If you approve this plan, I’ll implement it end-to-end, then run the existing test suite and add the new tests/docs.