# GitWall Live Features

This file describes the current live app behavior, not older monetization or feature-flag plans.

## Product Model

- GitWall is currently free to use.
- There is no active subscription, paywall, trial, or premium gate in the live Flutter app.
- The app centers on GitHub contribution sync, stats, wallpaper generation, and notifications.

## Auth And Session

- GitHub sign-in through OAuth
- Firebase custom-token session creation
- Stored-session restore on app launch
- Reconnect GitHub flow from settings and auth-error banners
- Disconnect/logout flow with local cleanup

## Data And Sync

- GitHub contribution fetch
- repository and language aggregation
- local cached contribution data
- manual sync
- scheduled background sync on Android
- daily or interval-based auto-update settings
- pending wallpaper refresh handling
- sync throttling and stale-data recovery

## Home And Stats

- home dashboard with contribution summaries
- current streak, longest streak, totals, trends
- activity feed and quick numbers
- dedicated stats screen
- year-scoped stats messaging
- repository and language breakdowns

## Wallpaper

- wallpaper preview and generation
- apply to home, lock, or both
- saved customization settings
- device-aware placement using dimensions and safe insets
- wallpaper caching to avoid unnecessary re-renders
- manual and sync-triggered wallpaper refresh

## Customization

- scale
- opacity
- corner radius
- padding
- positioning/layout controls
- theme and template selection
- safe preview behavior

## Notifications

- streak reminders
- streak saved confirmation
- weekly digest
- sync failure alerts
- sync success alerts
- GitHub auth error alerts
- admin broadcast notifications

## Sharing

- share image/card flows for GitHub activity snapshots

## Admin And Operations

- web admin for `app_config`
- maintenance mode
- forced update messaging
- broadcast notifications
- telemetry logs and crash-feed visibility
- admin whitelist management

## Diagnostics And Safety

- Crashlytics consent-aware reporting
- sanitized logging
- client error telemetry ingestion through Cloud Functions
- cached-data corruption recovery
- auth-error state instead of destructive forced logout during token failures

## Not Live

The following are not live product behavior today:

- subscription billing
- trial logic
- paywalls
- premium/free feature gating
- remote `feature_flags` driven access control
