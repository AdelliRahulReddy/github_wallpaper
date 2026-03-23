# Lib Folder Map

This document is the practical map of `lib/`. Despite the name, it covers the whole Flutter app, not just UI screens.

## Root

- `lib/main.dart`: Thin entrypoint that forwards startup to the real app bootstrap in `core/app/app_entry.dart`.

## Core

### `lib/core/app`

- `lib/core/app/app_entry.dart`: App bootstrap, Firebase/service initialization, top-level providers, auth gate, lifecycle observers, and initial route decisions.
- `lib/core/app/main_nav_screen.dart`: Main 4-tab shell that owns loaded contribution data, refresh flow, tab navigation, and cross-screen sync state.
- `lib/core/app/main_nav_screen_part.dart`: Helper extension for the main shell that builds the bottom navigation scaffold and handles wallpaper apply requests.

### `lib/core/constants`

- `lib/core/constants/environment_config.dart`: Central runtime config values and environment flags used across the app.
- `lib/core/constants/firebase_options.dart`: Generated Firebase platform options used during app startup.

### `lib/core/errors`

- `lib/core/errors/app_exceptions.dart`: App-specific exception types for GitHub, auth, storage, wallpaper, and context/setup failures.

### `lib/core/theme`

- `lib/core/theme/app_theme.dart`: Theme entrypoint that exposes shared spacing, radii, typography, and theme factories.
- `lib/core/theme/app_theme_extensions.dart`: Theme extensions and convenience accessors used by screens for settings tokens and custom colors.
- `lib/core/theme/app_theme_factory.dart`: Builds the actual light/dark `ThemeData` used by the app.

### `lib/core/utils`

- `lib/core/utils/app_utils.dart`: Shared utility barrel file that wires together constants, strings, error handling, refresh policy, and misc helpers.
- `lib/core/utils/app_utils_constants.dart`: App-wide constants such as spacing, timing windows, wallpaper reserve sizes, and storage defaults.
- `lib/core/utils/app_utils_error_handling.dart`: Logging, sanitization, debounce helpers, validation helpers, snackbar helpers, and centralized error handling utilities.
- `lib/core/utils/app_utils_misc.dart`: Date, color, rendering, and schedule helpers used by multiple features.
- `lib/core/utils/app_utils_refresh.dart`: Sync refresh throttling and skip-decision logic.
- `lib/core/utils/app_utils_strings.dart`: Centralized user-facing copy, URLs, labels, and canned strings.

## Data Layer

### `lib/data/datasources/local`

- `lib/data/datasources/local/device_config_service.dart`: Captures live device metrics such as size, pixel ratio, and safe areas for wallpaper rendering.
- `lib/data/datasources/local/storage_service.dart`: Local persistence layer for auth session, cached GitHub data, settings, wallpaper config, reminders, and app flags.

### `lib/data/datasources/remote`

- `lib/data/datasources/remote/oauth_service.dart`: GitHub OAuth + PKCE flow handling and Firebase custom-token session exchange.
- `lib/data/datasources/remote/remote_config_service.dart`: Loads and exposes remote app configuration from Firebase Remote Config / Firestore-backed config surfaces.

### `lib/data/models`

- `lib/data/models/app_models.dart`: Main model barrel containing contribution entities, wallpaper target enum, and shared parsing helpers.
- `lib/data/models/app_models_cached_data.dart`: Cached GitHub payload model with derived helpers for streaks, today commits, and summarized stats.
- `lib/data/models/app_models_repository_models.dart`: Models for repository contribution ranking and language usage breakdowns.
- `lib/data/models/app_models_wallpaper_config.dart`: User wallpaper customization model, serialization, defaults, and sanitization.
- `lib/data/models/theme_presets.dart`: Built-in heatmap theme definitions and theme lookup helpers.
- `lib/data/models/wallpaper_templates.dart`: Higher-level wallpaper templates/presets that apply multiple config changes together.

### `lib/data/repositories`

- `lib/data/repositories/github_service.dart`: GitHub GraphQL repository layer for fetch, sync, cache refresh, auth checks, and post-sync side effects.
- `lib/data/repositories/github_service_part.dart`: GitHub response parsing, milestone notification dispatch, auth status verification, and client cleanup helpers.

## Features

### Auth Screens

- `lib/features/auth/screens/onboarding_features.dart`: Feature showcase widgets and animated visuals used inside onboarding.
- `lib/features/auth/screens/onboarding_screen.dart`: Multi-slide onboarding flow that introduces the product before account setup.
- `lib/features/auth/screens/onboarding_slides.dart`: Individual onboarding slide implementations and shared onboarding slide shell.
- `lib/features/auth/screens/setup_screen.dart`: GitHub connect/setup page shown before a user can enter the main app.
- `lib/features/auth/screens/splash_screen.dart`: Splash/loading experience shown while the app is initializing.

### Settings Screens

- `lib/features/settings/screens/settings_screen.dart`: Settings entry screen and controller for profile, notifications, sync, support, and logout/disconnect flows.
- `lib/features/settings/screens/settings_screen_components.dart`: Reusable settings UI building blocks such as cards, tiles, chips, and section wrappers.
- `lib/features/settings/screens/settings_screen_notifications.dart`: Notification preferences screen for reminders, celebrations, and related schedules.
- `lib/features/settings/screens/settings_screen_profile.dart`: Profile screen, GitHub identity display, and local display-name editing flow.
- `lib/features/settings/screens/settings_screen_support.dart`: About/support screen with privacy/help/contact links and version info.
- `lib/features/settings/screens/settings_screen_view.dart`: View-building extension for the main settings page layout.
- `lib/features/settings/screens/settings_screen_wallpaper_sync.dart`: Wallpaper sync preferences screen for update schedule, frequency, and related sync controls.

### Wallpaper Screens: Customize

- `lib/features/wallpaper/screens/customize/customize_screen.dart`: Customize screen state owner for theme/template selection, preview state, quote generation, and apply flow.
- `lib/features/wallpaper/screens/customize/customize_screen_celebration.dart`: Success celebration overlay shown after wallpaper apply completes.
- `lib/features/wallpaper/screens/customize/customize_screen_controls.dart`: High-level controls layout below the preview.
- `lib/features/wallpaper/screens/customize/customize_screen_control_helpers.dart`: Shared helper widgets and helper methods for control sections.
- `lib/features/wallpaper/screens/customize/customize_screen_control_sections.dart`: Individual customize control groups for quotes, sizing, opacity, placement, and reset/apply actions.
- `lib/features/wallpaper/screens/customize/customize_screen_guides.dart`: Preview overlay guides that visualize native safe areas and placement zones.
- `lib/features/wallpaper/screens/customize/customize_screen_preview.dart`: Main wallpaper preview card and surrounding preview UI.
- `lib/features/wallpaper/screens/customize/customize_screen_templates.dart`: Template selector UI and template-application helpers.
- `lib/features/wallpaper/screens/customize/customize_screen_themes.dart`: Theme selection UI for heatmap color presets.
- `lib/features/wallpaper/screens/customize/customize_screen_theme_gallery.dart`: Scrollable theme gallery/pager used by the customize screen.
- `lib/features/wallpaper/screens/customize/customize_screen_view.dart`: Overall customize page layout that stitches preview, templates, themes, and controls together.

### Wallpaper Screens: Home

- `lib/features/wallpaper/screens/home/home_page.dart`: Home dashboard controller that receives cached/synced data and coordinates refresh, settings, and stats navigation.
- `lib/features/wallpaper/screens/home/home_page_achievements.dart`: Achievement badges and milestone section for the home dashboard.
- `lib/features/wallpaper/screens/home/home_page_feed.dart`: Today hero card and recent activity feed cards shown near the top of home.
- `lib/features/wallpaper/screens/home/home_page_heatmap.dart`: Quote card and last-30-days heatmap widgets for the home dashboard.
- `lib/features/wallpaper/screens/home/home_page_insights.dart`: Productivity insight cards and quick-number summaries on home.
- `lib/features/wallpaper/screens/home/home_page_streaks.dart`: Weekly goal, journey snapshot, streak, and week-strip sections on home.
- `lib/features/wallpaper/screens/home/home_page_view.dart`: Main home page composition, header layout, and section ordering.

### Wallpaper Screens: Stats

- `lib/features/wallpaper/screens/stats/stats_page.dart`: Stats screen controller that owns page state, refresh path, and section composition.
- `lib/features/wallpaper/screens/stats/stats_page_header.dart`: Stats page header summary and current-year-only notice card.
- `lib/features/wallpaper/screens/stats/stats_page_state.dart`: View/state extension for building the stats page body.

### Wallpaper Screens: Wrapped

- `lib/features/wallpaper/screens/wrapped/wrapped_screen.dart`: GitHub Wrapped experience controller for the recap carousel.
- `lib/features/wallpaper/screens/wrapped/wrapped_screen_cards.dart`: Wrapped-specific stat cards, repo cards, language cards, and empty-state widgets.
- `lib/features/wallpaper/screens/wrapped/wrapped_screen_recap.dart`: Recap slide widgets and share/export logic for wrapped results.
- `lib/features/wallpaper/screens/wrapped/wrapped_screen_slide_shell.dart`: Reusable slide shell used by the wrapped carousel.
- `lib/features/wallpaper/screens/wrapped/wrapped_screen_view.dart`: Overall wrapped screen layout and page assembly.

## Feature Widgets

### `lib/features/wallpaper/widgets`

- `lib/features/wallpaper/widgets/ui_render.dart`: Core wallpaper renderer and preview painter that draw the contribution heatmap, labels, stats, and quote onto canvas output.

### `lib/features/wallpaper/widgets/stats`

- `lib/features/wallpaper/widgets/stats/stats_sections.dart`: Barrel/part file that groups all reusable stats-page section widgets.
- `lib/features/wallpaper/widgets/stats/stats_sections_glance.dart`: At-a-glance stat tiles grid.
- `lib/features/wallpaper/widgets/stats/stats_sections_heatmap.dart`: Full-year heatmap card for the stats screen.
- `lib/features/wallpaper/widgets/stats/stats_sections_highlights.dart`: Streak history and most-active-days highlight cards.
- `lib/features/wallpaper/widgets/stats/stats_sections_monthly_trend.dart`: Monthly trend chart and legend widgets.
- `lib/features/wallpaper/widgets/stats/stats_sections_rankings.dart`: Top languages and top repositories ranking cards.
- `lib/features/wallpaper/widgets/stats/stats_sections_time_breakdowns.dart`: Weekly/time-of-week breakdown chart cards.
- `lib/features/wallpaper/widgets/stats/stats_sections_wrapped_cta.dart`: Wrapped CTA teaser and recent activity feed components for the stats page.

## Shared Layer

### `lib/shared/services`

- `lib/shared/services/achievement_service.dart`: Calculates home achievements and milestone badges from contribution data.
- `lib/shared/services/background_scheduler.dart`: Background task registration, reminder scheduling, and wallpaper refresh scheduling.
- `lib/shared/services/bootstrap_service.dart`: Startup orchestration that restores session, loads cached data, refreshes metrics, and decides how the app should enter.
- `lib/shared/services/daily_quotes.dart`: Quote generation/fallback service for wallpaper captions and AI/manual quote workflows.
- `lib/shared/services/notification_service.dart`: Local notification setup, permission handling, topic subscription behavior, and notification delivery helpers.
- `lib/shared/services/refresh_result.dart`: Structured result model returned by refresh/sync operations.
- `lib/shared/services/share_utils.dart`: Share/export helpers for cards, images, and wrapped content.
- `lib/shared/services/telemetry_service.dart`: Client telemetry, error logging, and admin-visible crash/report pipelines.
- `lib/shared/services/wallpaper_service.dart`: Wallpaper generation, placement math, device-safe positioning, caching, and final apply/export flow.
- `lib/shared/services/widget_service.dart`: Home-screen widget updater that pushes streak/commit totals into the companion widget.

### `lib/shared/state`

- `lib/shared/state/app_state.dart`: Pure presentation/state helpers for formatting, contribution analytics, cache validation, theme mode state, and settings preference state.

### `lib/shared/widgets`

- `lib/shared/widgets/app_components.dart`: Shared app UI primitives such as cards, section headers, metric tiles, and hero metric cards.
- `lib/shared/widgets/hover_lift.dart`: Small interaction wrapper that adds hover/touch lift behavior to widgets.
- `lib/shared/widgets/share_card.dart`: Share card entrypoint used to render summary cards for export/share flows.
- `lib/shared/widgets/share_card_heatmap.dart`: Mini heatmap section used inside share cards.
- `lib/shared/widgets/share_card_metrics.dart`: Metric rows and trend summaries used inside share cards.
- `lib/shared/widgets/stylized_pill.dart`: Reusable stylized pill/chip component used across the app.
- `lib/shared/widgets/wrapped_share_card.dart`: Wrapped-specific share card renderer.

## Navigation Summary

- Auth/bootstrap flow starts in `lib/main.dart` -> `lib/core/app/app_entry.dart`.
- Main logged-in experience is controlled by `lib/core/app/main_nav_screen.dart`.
- The 4 primary tabs are:
  - Home: `lib/features/wallpaper/screens/home/home_page.dart`
  - Stats: `lib/features/wallpaper/screens/stats/stats_page.dart`
  - Customize: `lib/features/wallpaper/screens/customize/customize_screen.dart`
  - Settings: `lib/features/settings/screens/settings_screen.dart`

## Maintenance Notes

- Files using `part` are intentionally split to keep large screens/features readable.
- `features/` owns user-facing product flows.
- `shared/` owns reusable services, state helpers, and widgets.
- `data/` owns persistence, remote access, and serializable models.
- `core/` owns bootstrap, theme, constants, exceptions, and shared utility policy.
