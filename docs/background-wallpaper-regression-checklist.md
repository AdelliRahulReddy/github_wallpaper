# Background Wallpaper Change Regression Checklist

## Goal
Confirm the app never changes the system wallpaper without an explicit user action, and that auto-updates only work after opt-in.

## Pre-reqs
- Android device (physical preferred)
- App installed fresh (clear app storage between scenarios)
- Device has network connectivity

## Scenario A: Fresh install, no opt-in, no wallpaper set
1. Install the app fresh.
2. Log in / complete onboarding.
3. Do not tap any “Set Wallpaper” action.
4. Swipe the app away from recents (do not force-stop).
5. Wait 1–2 hours (or until the next backend refresh push would normally arrive).
6. Expected:
   - Home/lock wallpaper does not change.

## Scenario B: Opt-in enabled, but user never set wallpaper
1. Install the app fresh.
2. Log in / complete onboarding.
3. Open Settings.
4. Enable Auto Update.
5. Do not tap any “Set Wallpaper” action.
6. Swipe the app away from recents.
7. Wait 1–2 hours.
8. Expected:
   - Home/lock wallpaper does not change.

## Scenario C: User applies once, then opt-in enabled (auto-update allowed)
1. Install the app fresh.
2. Log in / complete onboarding.
3. Go to Customize.
4. Tap “Set Wallpaper” (home/lock/both).
5. Open Settings.
6. Enable Auto Update.
7. Swipe the app away from recents.
8. Wait 1–2 hours.
9. Expected:
   - Wallpaper may update only after the refresh push arrives.
   - Wallpaper never updates if Auto Update is turned off.

## Scenario D: Opt-out disables future updates
1. With Scenario C already set up (user has applied once and enabled Auto Update), open Settings.
2. Disable Auto Update.
3. Swipe the app away from recents.
4. Wait 1–2 hours.
5. Expected:
   - Wallpaper does not change.

