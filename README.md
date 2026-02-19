# 🎨 GitWall

Display your GitHub contributions as a stunning, auto-updating wallpaper on your phone. Turn your hard work into art.

---

## ✨ Features

- **🖼️ Aesthetic Heatmap Wallpapers** – Convert your GitHub contribution graph into beautiful, customizable wallpapers for both Home and Lock screens.
- **🔄 Silent Sync (v1.1)** – Wallpapers refresh automatically in the background via WorkManager and FCM without interrupting your workflow.
- **🎨 Deep Customization** – Adjust scale, opacity, positioning, corner radius, and add custom motivational quotes.
- **📊 Advanced Insights** – Dedicated dashboard for streaks, contribution stats, weekend analysis, and historical trends.
- **🛡️ Secure & Private** – Your GitHub tokens are stored locally using Flutter Secure Storage; your data never leaves your device except to fetch stats.
- **💎 Premium Design** – Built with a centralized design system ("Single Source of Truth") for a polished, consistent modern look.
- **🕙 Reactive Sync States** – Instant feedback on "Last Synced" times using standardized UTC logic across the app.

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: `^3.5.0`
- **Device**: Android (Support for Home & Lock screen wallpapers)
- **GitHub Token**: Personal Access Token with `read:user` scope

### Quick Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/AdelliRahulReddy/github_wallpaper.git
   cd github_wallpaper
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration:**
   - Link your project using `flutterfire configure`.
   - Ensure `firebase_options.dart` is correctly generated.

4. **Run the app:**
   ```bash
   flutter run
   ```

# 🔐 GitHub Token Setup

To fetch your contribution data, GitWall requires a GitHub Personal Access Token (PAT).

1. Navigate to **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**.
2. Click **Generate new token (classic)**.
3. Select the `read:user` scope.
4. Copy the generated token and paste it into the app during setup.

> [!TIP]
> [Generate a token automatically](https://github.com/settings/tokens/new?scopes=read:user&description=GitWall) with the required scope pre-selected.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart) - *UI Layer*
- **Native Bridge**: Kotlin (Android WallpaperManager API)
- **Background Jobs**: [WorkManager](https://pub.dev/packages/workmanager)
- **Push Messaging**: [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- **API**: [GitHub GraphQL API v4](https://docs.github.com/en/graphql)
- **Persistence**: 
  - `flutter_secure_storage` (Encrypted tokens)
  - `shared_preferences` (App state & metadata)
- **Theming**: Custom Theme Engine (Single Source of Truth)

## 📁 Project Structure

```text
lib/
├── main.dart              # App entry & service initialization
├── app_utils.dart         # Design tokens, AppStrings, & Constants
├── app_services.dart      # GitHub API, storage, & wallpaper logic
├── ui_render.dart         # Custom painters & wallpaper generators
├── app_models.dart        # Type-safe immutable data models
├── app_state.dart         # Logic for streaks & trend calculations
└── pages/                 # UI pages (Dashboard, Customize, Settings)
```

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
