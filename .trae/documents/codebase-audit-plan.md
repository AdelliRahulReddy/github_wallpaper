## Goal
Produce a comprehensive audit report of the entire repository that identifies remaining issues after recent fixes, quantifies technical debt, evaluates testing coverage, and proposes a prioritized remediation roadmap with measurable success criteria.

## Scope
- Flutter/Dart app code under `lib/`, `test/`, `integration_test/`
- Android build + native glue under `android/`
- Firebase Cloud Functions under `functions/`
- CI/CD + repo hygiene under `.github/`, Firebase config files, and build configs

## Deliverables (Artifacts)
- `AUDIT_REPORT.md`
  - Executive summary + risk assessment
  - Detailed issue inventory (with file paths + line ranges)
  - Technical debt metrics (counts + simple computed metrics)
  - Prioritized remediation roadmap (severity/impact/effort)
  - Testing strategy for validating fixes using existing test infrastructure
- `ISSUE_INDEX.csv` (optional, if it improves scanability)
  - One row per issue: category, severity, file, line range, description, proposed fix, test note

## Severity Model (Used Throughout)
- Critical: security, data loss, crash on common path, credential leakage
- High: crash on edge path, severe correctness bug, background task instability
- Medium: performance regressions, maintainability hotspots, inconsistent UX behavior
- Low: style issues, minor refactors, documentation gaps

## Approach
### 1) Codebase Understanding & Documentation Review
- Inventory repository structure and key entry points.
  - Flutter entry: `lib/main.dart`
  - Service layer hub: `lib/app_services.dart`
  - Rendering pipeline: `lib/ui_render.dart`
  - Scheduling/background behavior: `lib/background_scheduler.dart`
  - Cloud scheduler trigger: `functions/index.js`
- Read and summarize existing docs and architectural notes.
  - `README.md`, `docs/*`
- Produce a module/dependency map:
  - Runtime dependencies from `pubspec.yaml`
  - Android build plugins and variants from `android/app/build.gradle.kts`
  - Functions runtime and deps from `functions/package.json`
  - CI workflows and security checks from `.github/workflows/*`

### 2) Technical Debt Assessment
- Duplicate code scan:
  - Identify repeated blocks in UI pages and services (string constants, repeated widget trees, repeated serialization/caching logic).
  - Propose extraction points (utility functions, widgets, service helpers).
- Dependency review:
  - Flag heavy/multipurpose deps (e.g., large UI/animation packages) and verify if usage is justified and scoped.
  - Identify unused or minimally-used packages by searching import usage frequency.
- Dead code / unused members:
  - Combine static checks (`flutter analyze`) with manual scans for unused files/functions, debug-only branches, and unreachable code.
- Complexity hotspots:
  - Identify large functions/classes (length + nested branching depth).
  - Provide a “top N hotspots” list with remediation suggestions (split functions, isolate side effects, adopt smaller abstractions).

### 3) Bug Detection & Code Quality Analysis
- Crash-risk review:
  - Null-safety boundaries (`!`, `as`, nullable access), JSON parsing assumptions, platform channel calls, file I/O.
- Concurrency and race conditions:
  - Background scheduler + sync interactions; verify locking patterns (e.g., `synchronized`) and cache writes.
  - Identify possible double-fetch, double-apply wallpaper, or stale-state races.
- Performance review:
  - Rendering pipeline allocations, image encoding/decoding, repeated network calls, large in-memory buffers.
  - Background task frequency and battery-impact risk.
- Error handling & logging:
  - Look for swallowed exceptions, inconsistent error surfaces to users, noisy logs, missing Crashlytics breadcrumbs.
- Security review:
  - Token storage handling (`flutter_secure_storage` usage), accidental logging of secrets, GitHub API usage (headers, scopes).
  - Functions: validate no secrets hard-coded; verify message validation; check for abuse vectors.
  - Client: validate URL launching, input validation, external content rendering (avoid injection vectors).

### 4) Testing Coverage Evaluation
- Catalog existing tests:
  - Unit tests under `test/`
  - Integration tests under `integration_test/`
- Map tests to critical flows:
  - Onboarding → token set → first sync → wallpaper generation/apply
  - Background update path (FCM + WorkManager)
  - Caching behavior and refresh semantics
- Identify missing coverage:
  - Error states (network failures, invalid token, API rate limits)
  - Rendering determinism (golden-like checks if feasible)
  - Scheduler edge cases (app killed/restarted, background isolation init)
- Assess test quality:
  - Mocking strategy, determinism, assertions that validate behavior (not just “no crash”).

### 5) Implementation Plan Development (Remediation Roadmap)
- For each issue, record:
  - Severity, impact, affected module(s), recommended fix, and required tests.
- Prioritize by:
  - User impact + frequency, security risk, crash likelihood, maintenance cost.
- Define measurable success criteria:
  - Example: “No duplicate fetch in 60-minute window under background triggers”, “No token ever logged”, “`flutter analyze` clean”, “tests cover error states”.
- Define testing requirements:
  - Which tests to add/extend and what scenarios they must cover.

## Execution Steps (Read-Only First, Then Verification Commands)
1. Read and summarize key docs and configs (README, docs, pubspec, gradle, functions config).
2. Trace end-to-end flows by reading core Dart modules and UI pages; build a flow map.
3. Run repository-wide searches for known risk patterns:
   - null assertions, `catch (e) {}` swallowing, `print`, direct file I/O, platform-specific branches, `DateTime.now()` usage in logic, JSON parsing without validation.
4. Compile an issue inventory with file paths and line ranges.
5. After plan approval (execution phase), run verification tooling to ground findings:
   - `flutter analyze`
   - `flutter test`
   - `flutter test integration_test` (or the repo’s integration runner)
   - Functions dependency audit (`npm audit`) and optional lint if configured
6. Produce `AUDIT_REPORT.md` and (optionally) `ISSUE_INDEX.csv`.

## Success Criteria (Audit Quality Bar)
- Report is actionable: every issue includes a concrete fix suggestion and a test note.
- All critical/high risks have clear reproduction notes or rationale.
- File locations include line ranges for fast navigation.
- Roadmap is prioritized and grouped by theme (security, correctness, performance, maintainability, testing).
