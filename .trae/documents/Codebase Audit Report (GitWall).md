## Scope & Method
- Reviewed all app logic in Dart under `lib/`, Android platform channel under `android/`, and Firebase Cloud Functions under `functions/`.
- Categorized findings into: critical bugs/logical errors, duplication, hardcoded values, performance bottlenecks, and security risks.

## Findings (Prioritized)

### Critical

#### C-1: Incorrect “last update” semantics + duplicate caching writes
- **Category**: Logical error, duplication
- **Evidence**:
  - `GitHubService.getContributions` returns cached data when not stale (no network) and otherwise fetches, then writes cache + `lastUpdate`: [app_services.dart:L227-L268](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L227-L268)
  - `MainNavPage._syncData` always writes cache + `lastUpdate` after calling `getContributions`, even if it returned cached data: [main_nav_page.dart:L110-L158](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/main_nav_page.dart#L110-L158)
- **Impact**:
  - If `force=false` and cached data is not stale, `_syncData` updates `lastUpdate` anyway → background/resume throttles and “Last Sync” UI can claim a refresh occurred when no API request happened.
  - Duplicate writes increase I/O and make “source of truth” unclear.
- **Remediation**:
  - Make one component authoritative for cache + `lastUpdate`.
  - Preferred: `GitHubService.getContributions` returns `{data, didFetch}` (or similar) and callers only update `lastUpdate` when `didFetch==true`.
  - Alternative: remove `StorageService.setCachedData`/`setLastUpdate` from `_syncData` and rely on `GitHubService` only; ensure `_syncData(force:true)` is used when an actual refresh is required.

#### C-2: “Today contributions” timezone logic is internally inconsistent
- **Category**: Logical error
- **Evidence**:
  - Analyzer stores keys as UTC-midnight derived from contribution dates: [app_state.dart:L24-L28](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_state.dart#L24-L28)
  - “Fix” attempts to use local calendar day but creates a UTC date from local components: [app_state.dart:L30-L36](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_state.dart#L30-L36)
  - Contribution day parsing returns UTC for `YYYY-MM-DD`: [app_models.dart:L41-L44](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_models.dart#L41-L44)
- **Impact**:
  - On non-UTC timezones, `todayContributions` and streak calculations can be off by 1 day, depending on how GitHub’s API date semantics align with user-local day.
- **Remediation**:
  - Decide the invariant explicitly:
    - If GitHub dates should be treated as UTC dates: use `DateTime.now().toUtc()` for “today key”.
    - If GitHub dates represent user-local day: parse day strings as local `DateTime(year,month,day)` (not UTC) and keep all comparisons in local calendar time.
  - Add a unit test matrix for multiple timezones (UTC± offsets) to lock behavior.

### High

#### H-1: Sensitive user profile/cache data stored unencrypted in SharedPreferences
- **Category**: Security / privacy
- **Evidence**:
  - Username stored in SharedPreferences: [app_services.dart:L69-L76](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L69-L76)
  - Full cached contribution payload stored as JSON string: [app_services.dart:L77-L92](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L77-L92)
  - Payload includes repo names/URLs, `isPrivate`, language usage, etc. (constructed in parsing): [app_services.dart:L316-L356](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L316-L356)
- **Impact**:
  - Data is readable on rooted devices; while Android backups are disabled ([AndroidManifest.xml:L10-L17](file:///c:/Users/adell/Desktop/github_wallpaper/android/app/src/main/AndroidManifest.xml#L10-L17)), the data is still plaintext at rest.
- **Remediation**:
  - Store cached data encrypted-at-rest (encrypted file or secure storage). If payload size is large, prefer encrypted file storage rather than keychain/secure storage.
  - Consider storing only derived aggregates instead of full repo/language details if not required offline.

#### H-2: Customizer preview rendering is CPU-heavy and can cause UI jank
- **Category**: Performance bottleneck
- **Evidence**:
  - Preview repaints via `CustomPaint` + `WallpaperPreviewPainter`: [customize_page.dart:L340-L413](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/customize_page.dart#L340-L413)
  - Painter calls `MonthHeatmapRenderer.render` directly on each paint: [ui_render.dart:L559-L604](file:///c:/Users/adell/Desktop/github_wallpaper/lib/ui_render.dart#L559-L604)
  - Renderer allocates per paint (cells list, multiple `TextPainter`s): [ui_render.dart:L25-L31](file:///c:/Users/adell/Desktop/github_wallpaper/lib/ui_render.dart#L25-L31), [ui_render.dart:L77-L116](file:///c:/Users/adell/Desktop/github_wallpaper/lib/ui_render.dart#L77-L116), [ui_render.dart:L195-L242](file:///c:/Users/adell/Desktop/github_wallpaper/lib/ui_render.dart#L195-L242)
- **Impact**:
  - Slider-driven updates can trigger frequent paints; repeated allocations can increase frame time and battery usage.
- **Remediation**:
  - Render preview to an `ui.Image` only on config changes (debounced) and display via `RawImage`/`Image.memory`.
  - Cache per-month cell coordinates and static text painters (weekday labels/header) keyed by `(month, theme, scale bucket)`.

#### H-3: AppCheck/FCM init failures are swallowed; backend enforcement posture is unclear
- **Category**: Security / resilience
- **Evidence**:
  - AppCheck activation failure is caught and app continues: [app_services.dart:L771-L789](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L771-L789)
  - Cloud function sends a periodic broadcast to a topic: [index.js:L11-L33](file:///c:/Users/adell/Desktop/github_wallpaper/functions/index.js#L11-L33)
  - No Firestore/Storage rules present in repo; `firebase.json` only configures functions/emulators: [firebase.json:L1-L13](file:///c:/Users/adell/Desktop/github_wallpaper/firebase.json#L1-L13)
- **Impact**:
  - If you expect App Check to protect backend resources, “continue on failure” reduces effective protection unless backend strictly enforces AppCheck.
- **Remediation**:
  - Enforce AppCheck at the backend and/or degrade functionality (disable auto-update) when activation fails.
  - Add explicit backend rules/config to repo (where applicable) so security posture is reviewable.

### Medium

#### M-1: Magic numbers duplicate existing constants (validation)
- **Category**: Hardcoded values
- **Evidence**:
  - Hardcoded `39` and `200`: [app_utils.dart:L100-L112](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_utils.dart#L100-L112)
  - Existing constants `usernameMaxLength` / `quoteMaxLength`: [app_utils.dart:L182-L203](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_utils.dart#L182-L203)
- **Remediation**:
  - Replace literals with `AppConstants.usernameMaxLength` and `AppConstants.quoteMaxLength`.

#### M-2: FCM topic name duplicated across app and cloud function
- **Category**: Duplication / hardcoded
- **Evidence**:
  - App topic constant: [app_utils.dart:L190-L199](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_utils.dart#L190-L199)
  - Function constant: [index.js:L11-L13](file:///c:/Users/adell/Desktop/github_wallpaper/functions/index.js#L11-L13)
- **Remediation**:
  - Centralize via configuration (function env var + documented app constant), or generate both from a shared config artifact.

#### M-3: Cloud Function schedule comment mismatches actual schedule
- **Category**: Incorrect logic pattern / maintainability
- **Evidence**:
  - `SCHEDULE = "every 60 minutes"` but comment says “Every 15 minutes”: [index.js:L12-L16](file:///c:/Users/adell/Desktop/github_wallpaper/functions/index.js#L12-L16)
- **Remediation**:
  - Align comments and schedule string; ensure ops expectations match runtime.

#### M-4: Error messaging duplicated/inconsistent across layers
- **Category**: Duplication
- **Evidence**:
  - ErrorHandler literals: [app_utils.dart:L13-L31](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_utils.dart#L13-L31)
  - AppStrings contains similar but different messages: [app_utils.dart:L121-L170](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_utils.dart#L121-L170)
  - Exception string for rate limit duplicates again: [app_exceptions.dart:L33-L36](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_exceptions.dart#L33-L36)
- **Remediation**:
  - Use `AppStrings` as the single UX-string source; keep exception types semantic-only.

### Low

#### L-1: Month names allocated on each header render
- **Category**: Micro-performance / hardcoded list
- **Evidence**:
  - Inline month list allocation: [app_utils.dart:L245-L246](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_utils.dart#L245-L246)
- **Remediation**:
  - Convert month array to `static const`.

#### L-2: Preview painter carries an unused `target` parameter
- **Category**: Dead/unused code
- **Evidence**:
  - `target` is stored and used only in `shouldRepaint`, not in rendering: [ui_render.dart:L559-L604](file:///c:/Users/adell/Desktop/github_wallpaper/lib/ui_render.dart#L559-L604)
- **Remediation**:
  - Remove `target` or feed it into renderer (if target-specific rendering is intended).

#### L-3: Customize “fit to width” clamps scale independently from global constants
- **Category**: Hardcoded value / behavior drift
- **Evidence**:
  - Clamp to `0.5..8.0`: [customize_page.dart:L91-L98](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/customize_page.dart#L91-L98)
  - Global min/max scale constants exist: [app_utils.dart:L199-L202](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_utils.dart#L199-L202)
- **Remediation**:
  - Clamp using `AppConstants.minWallpaperScale`/`AppConstants.maxWallpaperScale`.

### Informational (Not a direct vulnerability)

#### I-1: Firebase client configuration committed (API keys/project IDs)
- **Category**: Security hygiene / exposure surface
- **Evidence**:
  - Firebase options in source: [firebase_options.dart:L29-L73](file:///c:/Users/adell/Desktop/github_wallpaper/lib/firebase_options.dart#L29-L73)
  - Android google-services.json contains same key: [google-services.json:L1-L29](file:///c:/Users/adell/Desktop/github_wallpaper/android/app/google-services.json#L1-L29)
- **Notes**:
  - These values are typically not treated as secrets, but they increase abuse potential if backend rules are weak.

## Remediation Plan (If you want fixes applied)
1. Fix `lastUpdate` semantics by making fetch-vs-cache explicit; remove duplicated writes.
2. Define a single timezone invariant for contributions and correct `todayContributions`/streak computations; add tests.
3. Reduce preview jank by caching preview renders (debounced image generation) or caching paint-time allocations.
4. Centralize constants and strings (validation max lengths, FCM topic, error strings).
5. Add/track backend security posture (AppCheck enforcement, rules in repo if applicable).

If you confirm, I will implement fixes for items C-1 and C-2 first (highest user-visible impact), then proceed down the plan.