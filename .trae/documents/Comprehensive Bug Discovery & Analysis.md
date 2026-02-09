## Context & Architecture (Reviewed)
- **Platform/stack**: Flutter (SDK >= 3.24, Dart ^3.5) with Firebase (Core/Messaging/AppCheck/Crashlytics) and a native Android wallpaper channel ([pubspec.yaml](file:///c:/Users/adell/Desktop/github_wallpaper/pubspec.yaml), [MainActivity.kt](file:///c:/Users/adell/Desktop/github_wallpaper/android/app/src/main/kotlin/com/rahulreddy/githubwallpaper/MainActivity.kt)).
- **Entry/init flow**: Splash → `BootstrapService.boot()` → Onboarding gate → Main tabs ([main.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/main.dart)).
- **Primary user flows**:
  - Onboarding → Setup (GitHub username + PAT) ([onboarding_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/onboarding_page.dart), [setup_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/setup_page.dart)).
  - Main: Dashboard (data), Customize (preview/apply), Settings (auto-update/cache/logout) ([main_nav_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/main_nav_page.dart)).
- **Background behavior**: Push-driven refresh/pending refresh via FCM topic messages + scheduler function ([app_services.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart), [functions/index.js](file:///c:/Users/adell/Desktop/github_wallpaper/functions/index.js)).

## Initial Bug Candidates Found From Static Review (Pre-Run)
These are “code-confirmed” behaviors; screenshots/logs will be collected during execution.
1. **Dark mode never activates**
   - Repro: set device theme to Dark → app remains Light.
   - Expected: app follows system or allows toggle.
   - Actual: `themeMode: ThemeMode.light` forces light mode.
   - Severity: Medium (UX expectation).
   - Location: [main.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/main.dart#L75-L86).
2. **Login state can be inconsistent with actual credentials**
   - Repro: token missing/corrupted but onboarding flag remains true → app opens Main UI; sync fails with “Credentials missing”.
   - Expected: redirect to Setup/Login when token invalid/missing.
   - Impact: user stuck; repeated errors.
   - Severity: High.
   - Locations: onboarding gate uses `isOnboardingComplete()` only ([main.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/main.dart#L150-L189)); token read/corruption handling ([app_services.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L53-L63)); sync throws credentials missing ([main_nav_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/main_nav_page.dart#L119-L133)).
3. **Wallpaper reuse hash ignores device metrics**
   - Repro: change display scale/orientation → apply again with same config/data may reuse cached wallpaper file sized for old metrics.
   - Expected: regenerate when device metrics change.
   - Severity: Medium.
   - Locations: hash excludes width/height/pixelRatio/safeInsets ([app_services.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L588-L603)); metrics saved separately ([app_services.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L727-L743)).
4. **Wallpaper file deletion risks**
   - Repro: apply wallpaper; then apply again; if write/apply fails after deleting old file, the previous wallpaper file path is gone.
   - Expected: keep last good wallpaper until new one is confirmed.
   - Severity: Medium.
   - Location: deletes old path before writing new wallpaper ([app_services.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L513-L531)).
5. **UX copy mismatch for background updating**
   - Repro: onboarding and settings imply automatic updates even when opt-in is off / gating applies.
   - Expected: copy matches actual behavior and consent.
   - Severity: Low–Medium.
   - Locations: onboarding strings ([app_utils.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_utils.dart#L163-L171)); Settings subtitle ([settings_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/settings_page.dart#L295-L311)).

## Execution Plan (Steps 1–8)
### 1) Codebase & Flow Deep-Dive
- Build a call-graph style map for:
  - Setup/login → token storage → first sync → dashboard render
  - Customize → generate preview → apply wallpaper (native + fallback)
  - Settings → auto-update toggle → FCM subscription behavior
  - Background refresh: FCM → pending flag → startup consumption
- Output: an “Architecture + Data Flow” section in the final report with file links.

### 2) End-User Journey Exploration (Manual + Exploratory)
Run the app on:
- Android emulator + at least one physical Android device (OEM differences impact wallpaper APIs).
- Test matrix:
  - Fresh install, offline/online, invalid username/token, expired token, rate limit.
  - Dashboard refresh states (loading/error/partial data).
  - Customize edge cases: long quote, empty quote, landscape, large text scale.
  - Settings: auto-update toggle, clear cache, privacy/support links, logout.
  - Background: app swiped away, pending refresh behavior, notification permission variations.

### 3) Bug Capture & Documentation (Per Issue)
For each issue found, collect:
- Repro steps (numbered), expected vs actual.
- Severity (Critical/High/Medium/Low) + user impact.
- Affected components (UI/page/service/module).
- Evidence:
  - Screenshot(s) and/or short screen recording.
  - Relevant logs (Flutter logs, and Android logcat if needed).
  - Crashlytics breadcrumbs if applicable.
- Output: one bug report per issue in a consistent template (Markdown), plus an index table.

### 4) Prioritization Model
Rank bugs using:
- **Criticality**: data loss/security/app crash/background permission issues.
- **Frequency**: always vs intermittent vs edge-case.
- **Business impact**: onboarding/login blockers, wallpaper apply failures, trust issues.
- Output: prioritized backlog table with rationale.

### 5) “Comprehensive Bug Reports” Deliverables
- Create `docs/bug-reports/` with:
  - `index.md` (table of contents + priority list)
  - `BUG-###.md` files (one per bug)
  - `assets/` for screenshots (with consistent naming)
- Environment details included: app version, Flutter/Dart versions, device model, Android version.

### 6) Fix Recommendations (Root Cause + Approach)
For each bug report:
- Root cause analysis with exact code references.
- Proposed fix strategy (minimal-risk first).
- Estimated effort (S/M/L) and risk.

### 7) Testing Strategy (Prevent Regression)
- **Unit tests**: refresh policy, token/login gating rules, caching decisions.
- **Widget tests**: onboarding/setup validation, error rendering, settings toggles.
- **Integration tests** (if added): full login → sync → customize → apply → logout flows.
- **Golden tests** (optional): heatmap rendering stability for common configs.

### 8) Final Summary Report + Timeline
- Provide a final rollup:
  - Bugs grouped by severity.
  - Priority order with business reasoning.
  - Estimated timeline for resolution (based on final bug counts + effort sizing).

## Estimated Timeline (Provisional, will be refined after discovery)
- Discovery + documentation: 0.5–1.5 days
- Critical/High fixes + verification: 1–3 days
- Medium/Low fixes + regression test hardening: 1–4 days

If approved, I will proceed to run the full exploration, capture logs/screenshots, write the bug report set under `docs/bug-reports/`, and (optionally) start landing fixes in priority order with tests.