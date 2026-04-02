# GitWall

GitWall turns a GitHub contribution graph into a phone wallpaper and a compact personal dashboard. The app fetches GitHub activity, caches it locally, renders wallpaper-safe heatmaps, and gives the user Home, Stats, Customize, Wrapped, and Settings flows around that data. All features are included for every user.

The complete technical reference for the repository now lives in [CODEBASE.md](CODEBASE.md).

## ✨ Features:

- **🖼️ Aesthetic Heatmap Wallpapers** – Convert your GitHub contribution graph into beautiful, customizable wallpapers for both Home and Lock screens.
- **🔄 Silent Sync** – Wallpapers refresh automatically in the background via WorkManager and FCM without interrupting your workflow.
- **🎨 Deep Customization** – Adjust scale, opacity, positioning, corner radius, and add custom motivational quotes.
- **📊 Advanced Insights** – Dedicated dashboard for streaks, contribution stats, weekend analysis, and historical trends.
- **🛡️ Secure & Private** – Your GitHub tokens are stored locally using Flutter Secure Storage; your data never leaves your device except to fetch contribution stats.
- **💎 Polished Design System** – Built with a centralized design system ("Single Source of Truth") for a polished, consistent modern look.
- **🕙 Reactive Sync States** – Instant feedback on "Last Synced" times using standardized UTC logic across the app.
- **⚠️ Token Expiration Alerts (v1.2)** – Proactively detects expired or revoked GitHub tokens. Shows a warning banner on the dashboard, sends a background notification, and lets you update your token directly from Settings — no logout required.

### 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.5.0`
- Android device/emulator for wallpaper features
- GitHub OAuth app with callback `gitwall://oauth/callback`
- Firebase project configured for the app

### Quick Setup

1. Clone the repository
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
   - Register the callback `gitwall://oauth/callback` in your GitHub OAuth app.
   - Confirm the values in `lib/core/constants/environment_config.dart` match your deployment.
   - See [CODEBASE.md](CODEBASE.md) for the full auth/backend configuration map.
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
├── CODEBASE.md                 # Full architecture, history, and file reference
├── functions/                  # Firebase Cloud Functions
├── lib/
│   ├── app/                    # Startup shell, product-state assembly, app services
│   ├── core/                   # Constants, theme, errors, storage, and utilities
│   └── features/               # Auth, contributions, settings, and wallpaper modules
│   └── main.dart               # Flutter entrypoint
├── test/                       # Unit and widget tests
└── web/                        # Web shell assets
```

## Lib Map

For the file-by-file explanation of the current `lib/` folder and the rest of the repository, see [CODEBASE.md](CODEBASE.md).

## Main Product Areas

- `lib/app/app_entry.dart`: app startup, maintenance/update gates, and global provider wiring
- `lib/app/pages/main_nav_page.dart`: logged-in 4-tab shell
- `lib/features/contributions/pages/`: dashboard, stats, and wrapped experiences
- `lib/features/wallpaper/pages/customize_page.dart`: wallpaper preview and customization
- `lib/features/settings/pages/`: profile, notifications, support, and sync preferences
- `lib/features/wallpaper/services/wallpaper_service.dart`: wallpaper generation and apply pipeline
- `lib/features/contributions/repositories/contribution_repository.dart`: GitHub fetch and sync logic

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
