# Error Handling Question Bank

This document is the source question bank for GitWall error handling.

It is intentionally written as questions first so product, engineering, QA, and support can align before writing final user copy, recovery flows, logs, alerts, and fallback behavior.

Scope rules:
- cover both user-side and developer-side failure questions
- include silent failures, partial failures, stale-state problems, confusing UX, and observability gaps
- do not include paywall, subscription, billing, restore purchase, premium gate, or upgrade flow questions because those are not part of the live app

## User-Side Questions

### GitHub Sign-In and Session
- What if GitHub sign-in fails before the browser opens?
- What if GitHub sign-in opens but never returns to the app?
- What if the OAuth callback opens the app but no session is created?
- What if the user cancels GitHub sign-in midway?
- What if GitHub says access was denied?
- What if the stored token exists but has already expired?
- What if GitHub access was revoked outside the app?
- What if reconnect succeeds on GitHub but the app still shows disconnected?
- What if the user disconnects GitHub and cached data remains visible?
- What if the user reconnects with a different GitHub account?
- What if the GitHub username changes after a previous login?
- What if the user logs out and still receives stale auth warnings?

### Startup and App Entry
- What if the splash screen stays visible too long?
- What if the app opens to setup instead of home for a returning user?
- What if the app opens to onboarding again for an existing user?
- What if the app launches with cached data but fresh sync fails?
- What if the app launches offline for the first time after installation?
- What if the app launches after device time or timezone changed?
- What if maintenance mode toggles while the user is already using the app?
- What if force update is enabled remotely while the user is in the app?
- What if app initialization partly succeeds and partly fails?
- What if app initialization finishes but the wrong first screen appears?

### Sync and Freshness
- What if pull-to-refresh spins but no visible change happens?
- What if sync succeeds but the visible stats do not refresh?
- What if sync finishes but the last-sync label does not update?
- What if sync is throttled and the user thinks the app is broken?
- What if sync fails silently in background but no warning is shown?
- What if sync fails because the user is offline?
- What if sync fails because GitHub is rate-limiting the app?
- What if sync fails because GitHub API is temporarily down?
- What if sync runs twice from two triggers close together?
- What if sync succeeds but wallpaper does not update?
- What if wallpaper updates but the home stats still show older data?
- What if stale cached data looks current because dates are confusing?

### Stats Accuracy and Edge Cases
- What if today has contributions on GitHub but the app still shows zero?
- What if current streak is lower than what the user expects?
- What if longest streak is wrong after timezone travel?
- What if total contributions differ from the GitHub calendar view?
- What if weekly total looks wrong on Sunday or Monday boundaries?
- What if monthly totals look different from user expectations?
- What if a year selector is chosen and some cards still show current-year behavior?
- What if the app shows “best weekday” that feels incorrect to the user?
- What if peak day is wrong because of malformed or missing data?
- What if the user had no contributions and cards still look “active”?
- What if Feb 29 contributions appear missing during leap year?
- What if wrapped says “Last 365 Days” during or after a leap year?

### Home Screen and Navigation UX
- What if the home header uses the wrong name?
- What if the edited display name does not appear immediately on home?
- What if the avatar fallback letter is wrong after editing the display name?
- What if the first home screen feels cramped on smaller devices?
- What if the first home fold has too much dead space?
- What if cards on the first home fold are ordered poorly for user focus?
- What if scrolling causes the header to collapse too aggressively?
- What if tapping settings from the avatar feels inconsistent?
- What if the user returns from settings and home still shows stale state?
- What if home is visually fine on one phone but clumsy on another?

### Wallpaper Generation and Application
- What if wallpaper preview renders correctly but the applied wallpaper is wrong?
- What if wallpaper applies only to home when the user selected both?
- What if wallpaper applies only to lock when the user selected home?
- What if wallpaper appears cropped on tall devices?
- What if wallpaper looks blurred or pixelated?
- What if wallpaper generation succeeds but the output is blank?
- What if wallpaper generation fails after sync but the user sees no cause?
- What if safe insets are wrong and content sits under camera cutouts?
- What if the device dimensions stored in cache are outdated?
- What if the preview does not match the device’s real wallpaper crop rules?
- What if the user changes theme or layout and old wallpaper cache is reused?
- What if lock screen preview differs from applied lock screen result?

### Notifications
- What if notification permission is denied and the user expects reminders?
- What if streak reminder fires after the user already committed?
- What if streak reminder never fires even though it is enabled?
- What if weekly digest fires on the wrong day?
- What if sync issue notifications repeat too often?
- What if admin announcements arrive after the user disabled them?
- What if notifications are enabled in-app but blocked in system settings?
- What if permission was granted once but later revoked?
- What if reminders stop after logout and do not resume after reconnect?
- What if a user gets reminders based on stale contribution data?

### Sharing and Social Output
- What if the share sheet does not open?
- What if share image is blank?
- What if share image is low quality?
- What if share image text is clipped on smaller devices?
- What if sharing crashes only on some Android versions?
- What if sharing works once and fails on the second attempt?
- What if wrapped share and home share behave differently?

### Profile and Settings
- What if the display name editor opens but save does nothing?
- What if canceling a settings flow leaves the screen in a broken state?
- What if a setting switch changes visually but is not persisted?
- What if a setting is persisted but background behavior does not honor it?
- What if the user clears the display name and the app still shows the custom one?
- What if reconnect changes the account but keeps the old custom display name?
- What if settings show connected while other screens show auth error?
- What if logout sends the user to the wrong screen?

### Quotes and Personalization
- What if the daily quote does not load?
- What if the AI quote is empty?
- What if the AI quote is too long for the wallpaper layout?
- What if the quote tone selection is ignored?
- What if fallback quote never appears when AI is unavailable?
- What if quote cache survives too long and feels stale?
- What if special characters in a quote break rendering?

### Storage, Recovery, and Device State
- What if cached data is corrupted?
- What if secure storage token data is corrupted?
- What if local preferences are partially cleared by the OS?
- What if device storage is too full to save wallpaper output?
- What if app data is cleared and the user expects the old wallpaper state to return?
- What if device time is set incorrectly and reminders or sync labels look wrong?
- What if the user changes locale and date formatting becomes inconsistent?
- What if the app is restored on a new device with no valid local cache?

## Developer-Side Questions

### Auth and Session Implementation
- What if GitHub returns a structurally valid response but missing username?
- What if OAuth exchange succeeds but Firebase restore fails?
- What if auth restore should be treated as recoverable instead of destructive?
- What if auth errors are converted to generic errors and lose recovery intent?
- What if reconnect writes only some session fields before failing?
- What if logout or disconnect leaves background work scheduled?
- What if logout clears too much and destroys useful offline cache?
- What if logout clears too little and leaks prior-session state?

### Data Integrity
- What if malformed contribution dates reach the model layer?
- What if duplicate days are present in cached or fetched data?
- What if contribution days are unsorted when computing streaks?
- What if repository metadata is missing but stats code assumes it exists?
- What if cached contribution payload version changes and old data still parses?
- What if stale sensitive cache and base cache disagree?
- What if partial GitHub response writes corrupted cache over good cache?
- What if date normalization mixes local time and UTC inconsistently?

### Leap Year, Timezone, and Calendar Math
- What if a rolling “365 days” view should really be calendar-year aware?
- What if Feb 29 falls inside streak calculations spanning month boundaries?
- What if local timezone conversion shifts a GitHub day backward or forward?
- What if DST transition changes local midnight assumptions?
- What if current-year stats compare against a non-leap prior year incorrectly?
- What if year heatmap grid assumptions break when a leap year ends midweek?
- What if weekly windows are calculated differently across screens?
- What if “today” is derived from local time in one place and UTC in another?

### Background Scheduling
- What if WorkManager schedules multiple logically identical jobs?
- What if periodic background checks are more aggressive than product copy implies?
- What if schedule settings are stored but only partly enforced?
- What if background sync is skipped but the skip reason is not surfaced anywhere?
- What if pending wallpaper refresh is consumed too early?
- What if background sync fails repeatedly without telemetry?
- What if reminder jobs rely on stale cache and never self-correct?
- What if background work runs during an active foreground sync?

### UI State and Lifecycle
- What if `notifyListeners()` fires after provider disposal?
- What if a dialog or bottom sheet is popped while focused text fields still hold dependents?
- What if a screen awaits a modal result and calls `setState()` after unmount?
- What if a `BuildContext` from a disposed route is used for snackbars?
- What if a share flow throws from a post-frame callback after overlay teardown?
- What if a route replacement happens while subordinate overlays are still open?
- What if IndexedStack screens hold stale local state after underlying storage changes?
- What if a state refresh path updates one surface but not sibling surfaces?

### Wallpaper Rendering Pipeline
- What if wallpaper hash keys miss layout-affecting parameters?
- What if device safe insets change after first launch?
- What if generated wallpaper dimensions do not match stored device profile?
- What if transparent or zero-opacity settings produce visually empty output?
- What if preview and final render use different layout math?
- What if render failures are swallowed and the caller assumes success?
- What if isolate or image encoding failures are not represented in telemetry?
- What if large devices and small devices require different first-fold or preview heuristics?

### Notifications and Messaging
- What if admin broadcast topic subscription state drifts from auth state?
- What if client-side toggles are changed but FCM subscription is not refreshed?
- What if notification permission requests happen at product-wrong times?
- What if sync failure notifications fire on throttled skips?
- What if reminder dedupe keys fail across timezone changes?
- What if broadcast acknowledgements can be inflated or replayed?
- What if local notification content uses stale cached metrics?
- What if notification taps need navigation intents that are not wired yet?

### Observability and Supportability
- What if an error is caught, logged locally, and then disappears in release builds?
- What if telemetry captures too little context to diagnose the failure?
- What if telemetry captures too much context and risks sensitive data exposure?
- What if the user-facing message is actionable but the developer log is vague?
- What if the developer log is specific but the user message is misleading?
- What if crash reporting consent is off and production support loses all traces?
- What if silent failures accumulate in logs but never surface as product issues?
- What if support cannot distinguish auth errors from network errors from stale cache?

### Remote Config and Admin Controls
- What if remote config fails to load and default values hide a serious issue?
- What if maintenance mode flips on while bootstrap is mid-run?
- What if force-update version parsing behaves unexpectedly on non-standard version strings?
- What if admin UI exposes controls that the live app no longer consumes?
- What if docs say a config exists but the app has no live reader for it?
- What if real-time config listeners outlive the widget that depends on them?
- What if admin messages assume premium or paywall surfaces that no longer exist?

### Product Consistency
- What if docs promise behavior the code no longer implements?
- What if settings labels imply schedule precision the scheduler does not actually provide?
- What if home, stats, wrapped, and wallpaper each define “recent” differently?
- What if one screen uses total contributions and another uses filtered contributions?
- What if display name, username, and GitHub handle are mixed inconsistently?
- What if reconnect UX suggests data loss when cached data is still usable?
- What if product copy still references subscription or premium concepts removed from code?
- What if support docs and in-app recovery actions drift apart over time?

## High-Priority Questions To Answer First

These should usually be converted into concrete product behavior, logs, and tests before lower-priority edge cases:

1. What if GitHub auth expires silently and the user still has usable cached data?
2. What if sync succeeds but visible stats or wallpaper do not refresh?
3. What if cached data is corrupted and causes recurring failures?
4. What if background jobs run but schedule settings are not actually honored?
5. What if reminders or digests fire from stale data?
6. What if date math diverges across local time, UTC, DST, or leap-year boundaries?
7. What if a widget lifecycle bug creates framework assertions instead of clean user-facing errors?
8. What if telemetry is too weak to diagnose silent production failures?

## Notes

- This file is a question bank, not the final support copy.
- Final implementation work should map each important question to:
  - user-facing message
  - fallback behavior
  - retry or recovery action
  - developer log
  - telemetry event
  - test coverage
