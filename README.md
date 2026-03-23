# GitWall

GitWall turns a GitHub contribution graph into a phone wallpaper and a compact personal dashboard. The app fetches GitHub activity, caches it locally, renders wallpaper-safe heatmaps, and gives the user Home, Stats, Customize, Wrapped, and Settings flows around that data.

## Features

- GitHub OAuth sign-in with local session restore
- Auto-refreshing contribution sync with background scheduling
- Heatmap wallpaper generation for home, lock, or both screens
- Theme presets, templates, quotes, sizing, opacity, and placement controls
- Home dashboard for today, streaks, goals, quick insights, and achievements
- Stats screen for year heatmaps, trends, languages, repositories, and breakdowns
- Wrapped-style recap and share/export flows
- Local notifications for reminders, celebrations, and sync-related events
- Local caching and offline-friendly startup behavior

## Getting Started

### Prerequisites

- Flutter SDK `^3.5.0`
- Android device/emulator for wallpaper features
- GitHub OAuth app with callback `gitwall://oauth/callback`
- Firebase project configured for the app

### Quick Setup

1. Clone the repository.
   ```bash
   git clone https://github.com/AdelliRahulReddy/github_wallpaper.git
   cd github_wallpaper
   ```
2. Install dependencies.
   ```bash
   flutter pub get
   ```
3. Configure Firebase for the project.
   - Run `flutterfire configure` if needed.
   - Ensure `lib/core/constants/firebase_options.dart` matches your Firebase project.
4. Configure GitHub OAuth.
   - Detailed steps are in [docs/GITHUB_OAUTH_SETUP.md](docs/GITHUB_OAUTH_SETUP.md).
5. Run the app.
   ```bash
   flutter run
   ```

## Tech Stack

- Flutter + Dart for the app UI and app logic
- GitHub GraphQL API for contribution data
- Firebase for auth/session support, config, telemetry, and backend functions
- `flutter_secure_storage` and `shared_preferences` for local persistence
- WorkManager for background refresh scheduling
- `flutter_local_notifications` for reminders and milestone notifications
- Android wallpaper APIs for wallpaper apply flow
- Home Widget integration for companion widget updates

## Project Structure

```text
github_wallpaper/
├── assets/                     # Images, icons, and bundled assets
├── docs/                       # Product, setup, audit, and maintenance notes
├── functions/                  # Firebase Cloud Functions
├── lib/
│   ├── core/                   # App bootstrap, constants, theme, errors, utilities
│   ├── data/                   # Models, storage, remote services, repositories
│   ├── features/               # User-facing screens and feature-specific UI
│   ├── shared/                 # Cross-feature services, state, and widgets
│   └── main.dart               # Flutter entrypoint
├── test/                       # Unit and widget tests
└── web/                        # Web shell assets
```

## Lib Map

For a file-by-file explanation of the current `lib/` folder, see [docs/screens.md](docs/screens.md).

## Main Product Areas

- `lib/core/app/app_entry.dart`: app startup and route gating
- `lib/core/app/main_nav_screen.dart`: logged-in 4-tab shell
- `lib/features/wallpaper/screens/home/`: dashboard experience
- `lib/features/wallpaper/screens/stats/`: deeper analytics
- `lib/features/wallpaper/screens/customize/`: wallpaper preview and customization
- `lib/features/wallpaper/screens/wrapped/`: recap/share flow
- `lib/features/settings/screens/`: profile, notifications, support, and sync preferences
- `lib/shared/services/wallpaper_service.dart`: wallpaper generation and apply pipeline
- `lib/data/repositories/github_service.dart`: GitHub fetch and sync logic

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
