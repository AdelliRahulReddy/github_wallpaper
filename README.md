# GitWall

GitWall is a free Flutter app that turns GitHub activity into a lock-screen-first wallpaper, a compact developer dashboard, shareable recap cards, and a background refresh workflow.

Current product rule: all user-facing features are free. There is no active paywall, membership gate, or subscription flow in the app.

## What The App Does

- Connects a GitHub account through OAuth and restores a Firebase-backed app session.
- Fetches contribution data from the GitHub GraphQL API and caches it locally.
- Selects context-aware motivational quotes from a bundled curated pool instead of calling an AI API at runtime.
- Renders lock-screen-first wallpapers with safe-area-aware previewing and application.
- Shows Home, Stats, Customize, and Settings tabs around the cached GitHub activity.
- Generates story-format share cards for `Daily Flex`, `Repo Focus`, `Streak Milestone`, and `Monthly Snapshot`.
- Runs background refreshes on Android with WorkManager.
- Sends local notifications for sync issues, reminders, celebrations, and weekly digest flows.
- Receives admin broadcast pushes through Firebase Cloud Messaging.

## Product Notes

- Wallpaper apply flow in Customize is currently lock-screen only.
- The app keeps a free-only experience across settings, customize, stats, and onboarding flows.
- Admin tooling exists as a separate web control surface for app config, broadcasts, whitelisting, metrics, and incident visibility.

## Setup

### Prerequisites

- Flutter SDK `>=3.24.0
- Dart SDK `^3.5.0`
- Android device or emulator for wallpaper and background-sync behavior
- Firebase project configured for the app
- GitHub OAuth app with callback `gitwall://oauth/callback`

### Quick Start

1. Clone the repository.
   ```bash
   git clone https://github.com/AdelliRahulReddy/github_wallpaper.git
   cd github_wallpaper
   ```
2. Install packages.
   ```bash
   flutter pub get
   ```
3. Configure Firebase.
   - Ensure `lib/core/constants/firebase_options.dart` matches your Firebase project.
   - Ensure Cloud Functions and Firestore rules are deployed if you need auth exchange, admin broadcasts, and remote config.
4. Configure GitHub OAuth.
   - Register `gitwall://oauth/callback`.
   - Align the values in `lib/core/constants/environment_config.dart` with your deployment.
5. Run the app.
   ```bash
   flutter run
   ```

## Main Tech

- Flutter + Dart
- GitHub GraphQL API
- Firebase Auth, Firestore, Messaging, Crashlytics, and Cloud Functions
- `flutter_secure_storage` + `shared_preferences`
- WorkManager
- `flutter_local_notifications`
- Android wallpaper APIs + `wallpaper_manager_plus`
- Home Widget integration

## Docs

- [CODEBASE.md](CODEBASE.md): current repository index and architecture map
- [docs/quote_system_2026-04-03.md](docs/quote_system_2026-04-03.md): local smart-quote catalog, scoring, and fallback design
- [docs/notification_audit_2026-04-03.md](docs/notification_audit_2026-04-03.md): notification inventory, issues, and validation
- [docs/admin_control_surface_2026-04-03.md](docs/admin_control_surface_2026-04-03.md): admin dashboard capabilities, limits, and cleanup notes
- [docs/share_template_system_2026-04-01.md](docs/share_template_system_2026-04-01.md): share-template system design
- [docs/codebase_audit_2026-04-01.md](docs/codebase_audit_2026-04-01.md): historical remediation audit

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
