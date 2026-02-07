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
├── app_constants.dart     # Configuration constants
├── exceptions.dart        # Custom exceptions
├── models.dart            # Data models, date utils
├── services.dart          # GitHub, Wallpaper, Storage, FCM
├── theme.dart             # App theme
├── utils.dart             # Error handling, validation, strings
└── pages/
    ├── onboarding_page.dart
    ├── main_nav_page.dart
    ├── home_page.dart
    ├── customize_page.dart
    └── settings_page.dart
```

## Production Readiness

See [PRODUCTION_READINESS_REPORT.md](PRODUCTION_READINESS_REPORT.md) for full audit.

## License

MIT
