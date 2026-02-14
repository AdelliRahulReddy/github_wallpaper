# 🎨 GitWall

Display your GitHub contributions as a stunning, auto-updating wallpaper on your phone. Turn your hard work into art.

## ✨ Features

- **🖼️ Aesthetic Heatmap Wallpapers** – Convert your GitHub contribution graph into beautiful, customizable wallpapers for both Home and Lock screens.
- **🔄 Silent Sync** – Wallpapers refresh automatically in the background via Firebase Cloud Messaging without interrupting your workflow.
- **🎨 Deep Customization** – Adjust dark/light themes, scale, opacity, positioning, and add custom motivational quotes.
- **📊 Advanced Insights** – Dedicated dashboard for streaks, contribution stats, weekend analysis, and historical trends.
- **🛡️ Secure & Private** – Your GitHub tokens are stored locally using Flutter Secure Storage; your data stays yours.
- **💎 Premium Design** – Built with a centralized design system ("Single Source of Truth") for a polished, consistent look.

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: `^3.5.0`
- **Device**: Android (Live wallpaper features)
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

## 🔐 GitHub Token Setup

To fetch your contribution data, GitWall requires a GitHub Personal Access Token (PAT).

1. Navigate to **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**.
2. Click **Generate new token (classic)**.
3. Select the `read:user` scope.
4. Copy the generated token and paste it into the app during setup.

> [!TIP]
> [Generate a token automatically](https://github.com/settings/tokens/new?scopes=read:user&description=GitWall) with the required scope pre-selected.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart)
- **Backend/Push**: [Firebase](https://firebase.google.com) (FCM, Firestore, Functions)
- **API**: [GitHub GraphQL API](https://docs.github.com/en/graphql)
- **Storage**: Flutter Secure Storage, SharedPreferences

## 📁 Project Structure

```text
lib/
├── main.dart              # App entry & initialization
├── app_utils.dart         # Design tokens, strings, & constants
├── app_services.dart      # GitHub, FCM, & Wallpaper logic
├── ui_render.dart         # Custom heatmap & wallpaper rendering
├── app_models.dart        # Type-safe data models
├── app_state.dart         # Analytics & trend calculators
└── pages/                 # UI layers & navigation flow
```

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
