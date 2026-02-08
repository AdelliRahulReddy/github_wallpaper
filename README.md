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
2. Run `flutter pub get`
3. Configure Firebase (see `firebase_options.dart`)
4. Run `flutter run`

### GitHub Token

Create a token at [github.com/settings/tokens](https://github.com/settings/tokens/new?scopes=read:user&description=GitHub%20Wallpaper%20App).

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
