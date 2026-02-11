## Scope Covered
- Flutter/Dart app code (networking, storage, background behavior, rendering, error handling)
- Android config (manifest, Gradle, network security config, native wallpaper channel)
- Firebase/Cloud Functions (scheduler + FCM topic broadcast), CI workflows

## Findings Report (Categorized)

### Security Vulnerabilities
1) **Sensitive API responses can be persisted and/or reported to Crashlytics**
- **Location**: [app_services.dart:L237-L283](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L237-L283) (throws `GitHubException(...details: res.body)`), [app_utils.dart:L104-L120](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_utils.dart#L104-L120) (`AppLog.error` → Crashlytics)
- **Severity**: High
- **Impact**: If GitHub returns errors with contextual details (or if future code includes more data in error strings), that content can end up in crash reports. At minimum, `res.body` includes account/repo metadata when GitHub returns partial data.
- **Recommended remediation**:
  - Never attach raw response bodies to exception strings destined for logging/telemetry.
  - Introduce a sanitization layer for all errors before logging (strip tokens, repo URLs, usernames; truncate large payloads).
  - In release, log only stable error codes + minimal context.
- **Implementation priority**: P1
- **PoC**: Trigger API error (e.g., rate limiting/403) → `GitHubException.details = res.body` → if surfaced through `AppLog.error(e)` it can be transmitted to Crashlytics.

2) **Release build can be debug-signed when a flag is set**
- **Location**: [build.gradle.kts:L22-L85](file:///c:/Users/adell/Desktop/github_wallpaper/android/app/build.gradle.kts#L22-L85)
- **Severity**: Medium
- **Impact**: A “release” artifact signed with a debug key breaks trust assumptions and can enable easy tampering/impersonation if distributed outside controlled channels.
- **Recommended remediation**:
  - Make debug-signed release impossible in CI/release lanes.
  - Gate it behind an explicit “local-only” build task or require an additional, non-accidental confirmation.
- **Implementation priority**: P2

3) **No TLS pinning for GitHub API (threat-model dependent)**
- **Location**: [app_services.dart:L286-L324](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L286-L324)
- **Severity**: Low (typical for consumer apps)
- **Impact**: On compromised networks/devices (user-installed CAs), a MITM could observe/alter traffic.
- **Recommended remediation**: If the app targets higher-risk environments, add certificate/public-key pinning and fail closed; otherwise document reliance on OS trust store.
- **Implementation priority**: P3

### Privacy Violations / Consent Risks
1) **Private repo names/URLs can be stored unencrypted in SharedPreferences**
- **Location**: cache write/read: [app_services.dart:L77-L93](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L77-L93); repo model persisted: [app_models.dart:L123-L162](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_models.dart#L123-L162)
- **Severity**: High
- **Impact**: If user enables token scope `repo` (UI explicitly suggests this for “private repo stats”), private repo identifiers and URLs can be cached in plaintext app preferences. On rooted devices, via malware, or via local extraction, this leaks sensitive project names.
- **Recommended remediation** (choose one):
  - Encrypt cached contribution payloads (file-based encryption or secure storage-backed encryption key).
  - Or: do not cache private repo details at all (store aggregates only; strip `nameWithOwner`/`url` when `isPrivate == true`).
  - Add a user-facing setting: “Cache private repo details locally” default OFF.
- **Implementation priority**: P1
- **PoC**: After a successful sync with `repo` scope, `cached_data_v2` includes entries like `{nameWithOwner:"org/secret-repo", url:"https://github.com/org/secret-repo", isPrivate:true}`.

2) **Crashlytics collection + error logging can capture user data; duplicate reporting increases exposure**
- **Location**: global handlers: [main.dart:L29-L50](file:///c:/Users/adell/Desktop/github_wallpaper/lib/main.dart#L29-L50) (records errors + also calls `AppLog.error`), Crashlytics enablement: [app_services.dart:L757-L809](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L757-L809), `AppLog.error` always calls `recordError`: [app_utils.dart:L104-L120](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_utils.dart#L104-L120)
- **Severity**: High
- **Impact**: Potentially sends exception strings/stack traces containing usernames, repo names, URLs, file paths, and other identifiers. Duplicate reporting can also inflate telemetry volume.
- **Recommended remediation**:
  - Ensure “Crashlytics enabled” truly gates all reporting paths (including `AppLog.error`).
  - Remove double-reporting (either keep Crashlytics’ Flutter handler OR custom `AppLog.error`, not both).
  - Add redaction for any string that could contain tokens / usernames / repo URLs.
- **Implementation priority**: P1

3) **Auto-update uses silent push topic broadcast; disclosure is incomplete**
- **Location**: toggle copy: [settings_page.dart:L272-L324](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/settings_page.dart#L272-L324); topic subscription: [app_services.dart:L704-L721](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L704-L721); scheduler push every 60 minutes: [index.js:L15-L32](file:///c:/Users/adell/Desktop/github_wallpaper/functions/index.js#L15-L32)
- **Severity**: Medium
- **Impact**: Users may not understand that enabling “Auto Update” subscribes the device to a shared topic receiving periodic data messages (default hourly). Data-only messages can arrive even if notification permission isn’t granted, depending on platform behavior.
- **Recommended remediation**:
  - Update UI copy to explicitly state: “Subscribes your device to periodic silent refresh messages (about hourly).”
  - Offer frequency choices or switch to per-device targeting instead of broadcast topic.
  - Ensure Privacy Policy explicitly mentions Crashlytics diagnostics + push refresh.
- **Implementation priority**: P2

### Performance Issues (Lags, Memory, Battery)
1) **Wallpaper generation is CPU/memory-heavy and runs on the main isolate**
- **Location**: generation: [ui_render.dart:L616-L641](file:///c:/Users/adell/Desktop/github_wallpaper/lib/ui_render.dart#L616-L641); invoked from service with comment “main isolate”: [app_services.dart:L494-L511](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L494-L511)
- **Severity**: High
- **Impact**: `toImage()` + PNG encoding at full device resolution can cause jank, long frames, and potential OOM on high-DPI devices.
- **Recommended remediation**:
  - Cap render resolution and pixel ratio (e.g., max megapixels) and let OS scale.
  - Use `WallpaperManager.desiredMinimumWidth/Height` as an upper bound.
  - Add progressive UX (non-blocking UI, cancellation) and run generation after frame boundary.
- **Implementation priority**: P1

2) **Foreground push can trigger immediate refresh+render work**
- **Location**: [app_services.dart:L687-L693](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L687-L693)
- **Severity**: Medium-High
- **Impact**: If a refresh message arrives while user is actively using the app, it can start network + image generation unexpectedly → perceived lag and battery spikes.
- **Recommended remediation**:
  - Debounce pushes (e.g., coalesce to one refresh per N minutes).
  - Only mark “pending refresh” and do the heavy work on next app resume / when user is idle.
  - If running immediately, show a subtle UI indicator and avoid blocking interactions.
- **Implementation priority**: P1

3) **Potential unbounded month cell cache**
- **Location**: [ui_render.dart:L11-L34](file:///c:/Users/adell/Desktop/github_wallpaper/lib/ui_render.dart#L11-L34)
- **Severity**: Low
- **Impact**: `_cellsCache` retains entries per viewed month; if the renderer is invoked with many different reference months, memory can grow.
- **Recommended remediation**: Replace with LRU cache of small fixed size or clear on app background.
- **Implementation priority**: P3

### UX Problems
1) **Onboarding implies auto-sync “throughout the day” without clarifying opt-in and frequency**
- **Location**: [onboarding_page.dart:L96-L103](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/onboarding_page.dart#L96-L103)
- **Severity**: Medium
- **Impact**: Users can perceive unexpected background behavior once enabled.
- **Recommended remediation**: Clarify that auto-update is optional, explain how it works, and reference settings.
- **Implementation priority**: P2

2) **Artificial minimum splash duration (4s) can feel slow**
- **Location**: [app_services.dart:L774-L779](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L774-L779)
- **Severity**: Low-Medium
- **Impact**: Slower perceived launch; frustration on fast devices.
- **Recommended remediation**: Reduce/remove minimum duration; use progressive loading UI.
- **Implementation priority**: P3

### Version Compatibility / Dependency Risks
1) **Cloud Functions runtime set to Node 22 (may not be supported by Firebase Functions in all environments)**
- **Location**: [functions/package.json:L4-L11](file:///c:/Users/adell/Desktop/github_wallpaper/functions/package.json#L4-L11)
- **Severity**: Medium
- **Impact**: Deployment failures or forced downgrades depending on Firebase/Google support windows.
- **Recommended remediation**: Align to supported LTS (commonly Node 20) and verify with Firebase runtime docs.
- **Implementation priority**: P2

## “No Evidence Of” (Checked)
- No background Android services, receivers, or suspicious exported components in [AndroidManifest.xml](file:///c:/Users/adell/Desktop/github_wallpaper/android/app/src/main/AndroidManifest.xml).
- Cleartext traffic is disabled and a restrictive network security config is present: [AndroidManifest.xml:L10-L18](file:///c:/Users/adell/Desktop/github_wallpaper/android/app/src/main/AndroidManifest.xml#L10-L18), [network_security_config.xml](file:///c:/Users/adell/Desktop/github_wallpaper/android/app/src/main/res/xml/network_security_config.xml).
- FCM background handler does not directly fetch or set wallpaper; it only sets a pending flag: [app_services.dart:L642-L667](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L642-L667).

## Remediation Implementation Plan (If Approved)
1) **Harden privacy & telemetry (P1)**
- Remove raw response body propagation into exceptions/logs.
- Centralize sanitized error reporting; ensure Crashlytics collection gating is respected.
- Eliminate duplicate Crashlytics reporting paths.

2) **Secure local data cache (P1)**
- Either encrypt cached contribution JSON or strip private repo identifiers before caching.
- Add setting + UI disclosure for private repo caching behavior.

3) **Fix push-triggered heavy work (P1)**
- Change foreground message handling to set “pending refresh” only.
- Add debouncing/throttling and perform refresh on app resume/idle, not immediately.

4) **Optimize wallpaper generation path (P1)**
- Add hard caps for render resolution/PR; prefer device desired minimum sizes.
- Add performance guards and user-visible progress/cancellation where appropriate.

5) **Consent transparency updates (P2)**
- Update settings and onboarding copy to disclose topic subscription + approximate frequency.
- Update Privacy Policy to explicitly mention Crashlytics diagnostics + silent refresh messages.

6) **Compatibility hardening (P2)**
- Adjust Functions runtime to a supported Node LTS.
- Add CI checks to prevent accidental debug-signed release artifacts.

7) **Verification (included)**
- Add/extend tests around cache redaction/encryption and refresh throttling.
- Manual validation checklist: toggling Auto Update, receiving refresh message, ensuring no wallpaper update without opt-in, checking cached storage contents.

If you confirm, I’ll implement the P1 items first (privacy + crash reporting + push throttle + cache hardening), then proceed with P2/P3 improvements and verification.