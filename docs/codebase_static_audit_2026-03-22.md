# Codebase Static Audit

Date: 2026-03-22
Method: static code review only
Runtime checks skipped on purpose: no `flutter analyze`, no `flutter build`, no device run

## Scope

Reviewed:
- `lib/`
- `functions/`
- `admin/`
- `firestore.rules`
- `test/` for intent and coverage signals

Severity scale:
- `Critical`: exploitable or data-corrupting issue with immediate production risk
- `High`: major logic or product failure that materially breaks user trust or platform behavior
- `Medium`: meaningful bug, silent failure path, or operational risk
- `Low`: code health, duplication, or dead-path issue with lower immediate blast radius

No `Critical` finding was confirmed from static review alone. The highest-confidence issues are `High`.

## Findings

### 1. High: reminder and weekly-digest worker performs a GitHub sync every 30 minutes

Evidence:
- `lib/shared/services/background_scheduler.dart:31-34`
- `lib/shared/services/background_scheduler.dart:225-237`

Why this matters:
- The `streak-reminder-check` task starts by calling `GitHubService.syncGitHubData(isBackground: true)` before it even decides whether a reminder or digest should be shown.
- That task is registered every 30 minutes.
- Result: enabling streak reminders or weekly digest creates frequent background GitHub traffic, even if the user did not opt into frequent wallpaper refreshes.

Impact:
- avoidable battery and network usage
- more chances to hit GitHub/API throttling
- background behavior does not match the settings surface the user sees

Recommended direction:
- separate reminder scheduling from data refresh
- use cached data first for reminder/digest evaluation
- only refresh on an explicit sync policy, not on every reminder heartbeat

### 2. High: wallpaper schedule settings are stored in the UI but not actually enforced by the scheduler

Evidence:
- `lib/features/settings/screens/settings_screen_wallpaper_sync.dart:47-68`
- `lib/data/datasources/local/storage_service.dart:221-258`
- `lib/shared/services/background_scheduler.dart:196-217`
- `lib/core/utils/app_utils_refresh.dart:14-83`

Why this matters:
- The settings screen lets users choose daily vs weekly and pick a time.
- Those values are persisted.
- `BackgroundScheduler.scheduleUpdates()` ignores them and always registers a periodic task using `AppConstants.autoUpdateIntervalMinutes`.
- `RefreshPolicy.shouldRefresh()` contains the missing daily/interval logic, but static search found no call sites outside its own definition.

Impact:
- the exposed daily/weekly/time controls are effectively dead
- users can believe they configured one schedule while the app keeps another
- bug reports around "wrong sync time" are expected

Recommended direction:
- make `scheduleUpdates()` consume stored schedule mode/time/interval
- call `RefreshPolicy.shouldRefresh()` from the background execution path
- remove dead schedule scaffolding if the product only wants a fixed periodic model

### 3. High: admin broadcast receipt metrics can be inflated by replaying acks with different `messageId` values

Evidence:
- `functions/index.js:229-255`
- `functions/index.js:275-294`
- `functions/index.js:425-455`
- `functions/index.js:526-528`

Why this matters:
- The server deduplicates receipt events using `uid + event + messageId`.
- `messageId` comes from the client request body.
- A client can send the same `broadcastId` and `event` repeatedly with different `messageId` values and keep incrementing `received_count`, `displayed_count`, or `opened_count`.
- `authenticateAppRequest()` only verifies a Firebase token. It does not add a stronger server-side constraint to the aggregate key.

Impact:
- admin dashboard delivery counters are not trustworthy
- a single user can distort campaign analytics
- this undermines operational decisions based on broadcast metrics

Recommended direction:
- dedupe by `(broadcastId, uid, event)` server-side
- treat client `messageId` as metadata only, not part of the uniqueness key
- add per-user rate limiting and consider App Check

### 4. High: malformed contribution dates silently become "today", which can corrupt streaks and stats

Evidence:
- `lib/data/models/app_models.dart:47-50`

Why this matters:
- If `AppDateUtils.parseDate(j['date'])` fails, `ContributionDay.fromJson` falls back to `DateTime.now().toLocal()`.
- That does not fail fast or skip bad data. It rewrites the bad record into the current day.

Impact:
- incorrect current streak
- incorrect "today" contribution count
- incorrect heatmap cell and derived stats
- misleading reminder and celebration notifications

Recommended direction:
- reject malformed days explicitly
- skip invalid records with telemetry, or throw and invalidate the payload/cache
- never replace a bad source date with the current date

### 5. Medium: wallpaper reuse hashing ignores device metrics and safe insets even though rendering depends on them

Evidence:
- `lib/shared/services/wallpaper_service.dart:37-45`
- `lib/shared/services/wallpaper_service.dart:146-163`
- `lib/shared/services/wallpaper_service.dart:210-219`
- `lib/shared/services/wallpaper_service.dart:223-255`
- `lib/data/datasources/local/storage_service.dart:480-510`

Why this matters:
- `_hash()` only includes username, target, day data, and wallpaper config.
- `_gen()` and `DeviceCompatibilityChecker.applyPlacement()` also depend on stored width, height, pixel ratio, and safe insets.
- If those device inputs change, the hash can still match and the old image is reused.

Impact:
- stale wallpaper composition after device/profile/layout changes
- wrong placement around notches, lock-screen clock space, or different targets

Recommended direction:
- include device metrics and safe-inset signature in the wallpaper hash
- or invalidate cached wallpaper whenever device metrics change

### 6. Medium: many caught failures become silent in production because `AppLog.error` does not report outside debug mode

Evidence:
- `lib/core/utils/app_utils_error_handling.dart:166-188`
- `lib/data/datasources/local/storage_service.dart:34-41`
- `lib/data/datasources/local/storage_service.dart:123-137`
- `lib/shared/services/bootstrap_service.dart:67-84`
- `lib/shared/services/background_scheduler.dart:178-221`

Why this matters:
- `AppLog.info()` writes sanitized breadcrumbs to Crashlytics in release, but `AppLog.error()` only `debugPrint`s in debug mode and does nothing in release.
- Many services catch exceptions, call `AppLog.error(...)`, then keep going or return fallback values.
- Examples:
  - secure cached-data load failures are swallowed
  - cache decode failure returns `null`
  - Firebase session restore failure falls through to anonymous sign-in
  - WorkManager initialization/scheduling failure is logged but not surfaced

Impact:
- production supportability is weak
- users can land in degraded states with little or no diagnostic trail
- several "silent failure" classes are real, not theoretical

Recommended direction:
- route caught service-level errors to Crashlytics or a telemetry sink when consent allows
- reserve silent fallback only for explicitly non-critical paths
- attach user-visible fallback state where the failure changes behavior

### 7. Medium: admin observability panels are mostly unwired

Evidence:
- `admin/app.js:208`
- `admin/app.js:256`
- `lib/shared/services/telemetry_service.dart:13-41`
- `firestore.rules:24-41`

Why this matters:
- The admin dashboard reads `admin_metrics`, `admin_crash_reports`, and `logs`.
- No producer was found for `admin_metrics` or `admin_crash_reports`.
- `TelemetryService` writes to `logs` using the client SDK, but Firestore rules explicitly deny writes to `/logs`.

Impact:
- dashboard sections can stay empty even when the app is failing
- operators may assume telemetry is healthy when the pipeline is actually disconnected

Recommended direction:
- decide whether admin telemetry should be written by Cloud Functions or a privileged backend
- if client logging is intended, rules and schema need to support it safely
- otherwise remove or label dead dashboard panels until they are wired

### 8. Medium: logout does not clear sync-success notification preferences or last-sent state

Evidence:
- `lib/data/datasources/local/storage_service.dart:375-386`
- `lib/data/datasources/local/storage_service.dart:596-643`

Why this matters:
- Sync-success preference keys exist and are read during background sync.
- `logout()` removes many user-scoped settings, but it does not remove:
  - `keySyncSuccessNotificationsEnabled`
  - `keySyncSuccessLastSentDay`

Impact:
- next account on the same device can inherit prior account notification behavior
- last-sent suppression can leak across sessions and suppress the wrong user's first success notification

Recommended direction:
- clear both keys on logout
- review all user-scoped notification keys as a group rather than piecemeal

### 9. Medium: the admin dashboard can delete the current or last admin with no safeguard

Evidence:
- `admin/app.js:675-685`
- `firestore.rules:8-21`

Why this matters:
- `deleteAdmin()` deletes any admin document after a browser confirm.
- Firestore access immediately depends on the caller still having an enabled admin doc.
- Deleting the current admin or the last enabled admin can lock operators out until Firestore is repaired manually.

Impact:
- accidental self-lockout
- possible full admin dashboard lockout

Recommended direction:
- block self-delete in the UI
- block deletion of the last enabled admin
- enforce the same invariant server-side, not only in the client

### 10. Low: logout and disconnect flows are near-duplicate implementations

Evidence:
- `lib/features/settings/screens/settings_screen.dart:95-129`
- `lib/features/settings/screens/settings_screen.dart:132-167`

Why this matters:
- `_handleLogout()` and `_handleDisconnectGitHub()` perform almost the same teardown sequence.
- This is a classic drift point for future behavior changes.

Impact:
- one path can be updated while the other quietly diverges

Recommended direction:
- extract a single session-reset helper with configurable dialog copy

### 11. Low: sync plumbing contains dead or duplicate paths

Evidence:
- `lib/core/utils/app_utils_refresh.dart:14-83`
- `lib/data/repositories/github_service.dart:73-75`
- `lib/data/repositories/github_service.dart:125-136`
- `lib/data/datasources/local/storage_service.dart:559-574`

Why this matters:
- `RefreshPolicy` is implemented but currently unused.
- `StorageService.getEffectiveLastSync()` checks `keyLastBackgroundSync`, but no writer for that key was found.
- `recordSyncSuccess()` is called once in `getContributions()` and again in `syncGitHubData()`.

Impact:
- harder reasoning around sync behavior
- duplicate writes and dead branches make future fixes riskier than needed

Recommended direction:
- remove or wire the unused policy/timestamp path
- keep sync timestamp writes in one layer only

## Coverage Gaps And Follow-Up Targets

Highest-value follow-up tests after fixes:
- background scheduling logic around daily/weekly/time behavior
- reminder/digest job behavior without forced GitHub sync
- broadcast ack dedupe and replay resistance
- malformed cache/API payload handling for contribution dates
- wallpaper cache invalidation when device metrics change

Observed backend/admin coverage gap:
- no automated test surface was found for `functions/` or `admin/`

