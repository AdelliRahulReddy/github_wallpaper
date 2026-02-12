# GitWall

Display your GitHub contributions as an auto-updating wallpaper on your phone.

## Features

- **Beautiful heatmap wallpapers** – Turn your GitHub contribution graph into aesthetic wallpapers for Home and Lock screen
- **Auto-updates** – Wallpaper refreshes automatically via Firebase Cloud Messaging
- **Customizable** – Dark/Light themes, scale, opacity, position, custom quotes
- **Secure** – GitHub tokens stored with Flutter Secure Storage
- **Dashboard** – Streaks, stats, weekend analysis, contribution breakdown

## Getting Started

### Prerequisites

- Flutter SDK ^3.5.0
- Android device/emulator (wallpaper feature is Android-only)
- GitHub Personal Access Token with `read:user` scope

### Setup

1. Clone the repo
2. Run `flutter pub get
3. Configure Firebase (see `firebase_options.dart`)
4. Run `flutter run`

### Release Signing (Android)

- Never commit `android/key.properties` or keystore files to the repository.
- Use `android/key.properties.example` as a template and keep your real values local/secret-managed.
- If `android/key.properties` was ever committed, rotate your upload key credentials immediately.

### GitHub Token

You’ll need a GitHub Personal Access Token (PAT) so the app can read your contribution data.

**Option A (Recommended): Classic PAT**

1. Go to GitHub **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**.
2. Click **Generate new token (classic)**.
3. Set a **note** (example: `GitWall`) and choose an **expiration**.
4. Select scopes:
   - Required: `read:user`
   - Optional (only if you want private repo contribution breakdowns): `repo`
5. Click **Generate token**, copy it (GitHub only shows it once), then paste it into the app’s Setup screen.

Quick link (pre-fills `read:user`): https://github.com/settings/tokens/new?scopes=read:user&description=GitWall

## Project Structure

```
lib/
├── main.dart              # App entry, initialization
├── app_utils.dart         # Constants, strings, validation, helpers
├── app_services.dart      # GitHub, wallpaper, storage, FCM services
├── app_models.dart        # Data models and serialization
├── app_state.dart         # Analytics and trend/state helpers
├── app_theme.dart         # Theme + reusable UI widgets
├── app_exceptions.dart    # Custom exceptions
├── ui_render.dart         # Wallpaper/heatmap renderer
└── pages/
    ├── splash_screen.dart
    ├── onboarding_page.dart
    ├── setup_page.dart
    ├── main_nav_page.dart
    ├── home_page.dart
    ├── customize_page.dart
    └── settings_page.dart
```

## License

MIT
