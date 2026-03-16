# 🗺️ Project Structure Guide (Non-Coder Friendly)

Welcome! This guide explains what each part of the **GitHub Wallpaper** app does. Think of this as the "Anatomy" of the application.

---

## 🏗️ Core Engine (`lib/`)
These files are the "brain" and "skeleton" of the app. They handle logic, data, and styles that are used everywhere.

| File | Purpose & Detail | Analogy |
| :--- | :--- | :--- |
| **`main.dart`** | **The starting point.** <br>• Initializes Firebase (for crash reports). <br>• Sets up local storage to remember your settings. <br>• Ensures the app handles crashes gracefully. | **The Ignition Key** |
| **`app_theme.dart`** | **Visual Identity.** <br>• Stores all color palettes (GitHub Greens, Dark Mode Greys). <br>• Defines how big text and buttons should be. <br>• Handles "Glass" effects and shadows. | **The Style Guide** |
| **`app_services.dart`** | **Logic Hub.** <br>• Fetches your actual code commits from GitHub. <br>• Sets the image as your real phone wallpaper. <br>• Manages pop-up notifications and health alerts. | **The Engine Room** |
| **`ui_render.dart`** | **Drawing Logic.** <br>• Calculates exactly where each "contribution square" goes. <br>• Adds the text quotes and the color legend. <br>• Converts everything into a high-quality picture. | **The Artist** |
| **`app_models.dart`** | **Data Blueprints.** <br>• Defines a "User" (username, avatar, bio). <br>• Defines a "Wallpaper Design" (colors, scale, position). <br>• Ensures data is organized correctly before saving. | **The Blueprints** |
| **`app_utils.dart`** | **Helper Tools.** <br>• Provides a list of fixed text (like error messages). <br>• Contains the "Logger" that tracks what the app is doing. <br>• Formats confusing dates into easy-to-read text. | **The Swiss Army Knife** |
| **`app_state.dart`** | **Current Memory.** <br>• Remembers which screen you are currently looking at. <br>• Tracks if a data refresh is currently in progress. <br>• Manages global banners (like the "Token Expired" warning). | **The Memory** |
| **`background_scheduler.dart`** | **Automatic Sync.** <br>• Tells the phone: "Wake up every X hours to update the wallpaper." <br>• Handles tasks that run even when you aren't using the app. | **The Alarm Clock** |
| **`app_exceptions.dart`** | **Error Handler.** <br>• Catches specifically when GitHub is down or your token is wrong. <br>• Translates "Code Errors" into "Human Messages" you can understand. | **The Warning Lights** |
| **`theme_presets.dart`** | **Palette Library.** <br>• Defines heatmap color palettes (GitHub, Monochrome, Tokyo Night, etc.). <br>• Powers the palette picker in Customize. | **The Paint Rack** |
| **`wallpaper_templates.dart`** | **Template Presets.** <br>• One-tap layout presets (scale/opacity/corners/quote defaults). <br>• Powers the Templates picker in Customize. | **The Style Pack** |
| **`daily_quotes.dart`** | **Quote Engine.** <br>• Provides a deterministic “today’s quote” without network calls. | **The Fortune Cookie** |
| **`share_card.dart`** | **Share Renderer (UI).** <br>• Builds the “stat card” layout that gets exported as an image. | **The Poster Designer** |
| **`share_utils.dart`** | **Share Tools.** <br>• Captures widgets as PNG and opens the native share sheet. | **The Export Button** |
| **`widget_service.dart`** | **Home Widget Bridge.** <br>• Pushes streak/today/total stats into the Android/iOS widget storage and triggers refresh. | **The Widget Messenger** |

---

## 📱 User Interface (`lib/pages/`)
These are the actual screens you see and interact with in the app.

| Page | What it does |
| :--- | :--- |
| **`splash_screen.dart`** | **First Impression.** <br>• Shows the logo and version number. <br>• Loads your previous data so you don't have to wait on the main screen. |
| **`onboarding_page.dart`** | **The Intro.** <br>• Explains the core features to a brand new user. <br>• Asks for permissions (like notifications) in a friendly way. |
| **`setup_page.dart`** | **Login & Entry.** <br>• Validates your GitHub Token directly with the API. <br>• Provides links to find your token. <br>• Does the first-ever download of your commit history. |
| **`home_page.dart`** | **Your Dashboard.** <br>• Shows your stats (Total commits, streaks). <br>• Lists your top GitHub repositories. <br>• Displays the "Action Required" banner if something breaks. |
| **`customize_page.dart`** | **The Studio.** <br>• Live preview of how your wallpaper looks. <br>• Sliders for scale, position, and transparency. <br>• "Apply" button to save it to your phone. |
| **`settings_page.dart`** | **Control Center.** <br>• Manage your tokens and account. <br>• Toggle Dark/Light mode manually. <br>• Links to support, privacy policy, and developer info. |
| **`main_nav_page.dart`** | **Navigation.** <br>• Controls the bottom bar movement. <br>• Monitors authentication in the background to warn you if your token dies. |
| **`wrapped_page.dart`** | **Wrapped (Year in Review).** <br>• Story-like pages for highlights: totals, streaks, peak day, top repo, top language. |

---

## 📦 Project Configuration (Root)
Important files sitting in the main folder that manage the "Project" itself.

| File | Purpose |
| :--- | :--- |
| **`pubspec.yaml`** | **The Ingredient List.** <br>• Lists every external library (like Google Fonts or Firebase) the app needs to work. |
| **`README.md`** | **The Manual.** <br>• A high-level overview for people looking at the code from GitHub. |
| **`PROJECT_STRUCTURE.md`** | **The Map.** <br>• This file! It helps you navigate the project without needing to read the code. |

---

> [!TIP]
> If you want to change how the app **looks**, go to `app_theme.dart`.  
> If you want to change how the **wallpaper is drawn**, go to `ui_render.dart`.  
> If you want to change how the **GitHub data is fetched**, go to `app_services.dart`.
