## Investigation Report
- **Observed behavior**: Wallpaper can change minutes–hours after the user logs in and swipes the app away.
- **Key finding**: The app can set wallpaper from an FCM background handler (headless Dart execution), so the UI does not need to be open.

## Root Cause
- **Auto-update is effectively enabled by default** because `StorageService.getAutoUpdate()` falls back to `true` when the preference hasn’t been set ([app_services.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L118-L122)).
- During bootstrap, the app initializes FCM and **subscribes the device to a topic** if auto-update is enabled ([app_services.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L789-L808), [app_services.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L702-L719)).
- A Cloud Scheduler function sends a **data-only** message to topic `daily-updates` on a fixed interval (default: `every 60 minutes`) with `data.type = "refresh"` ([functions/index.js](file:///c:/Users/adell/Desktop/github_wallpaper/functions/index.js#L15-L33)).
- On Android, data messages can wake the app into a background isolate; the handler `_bgH` treats any message whose `type` *contains* `refresh` as a signal to refresh and then calls `WallpaperService.refreshWallpaper(isBackground: true)` ([app_services.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L637-L666)).
- `refreshWallpaper()` fetches GitHub data and calls `generateAndSetWallpaper()` which will apply a new wallpaper if there is no previous saved wallpaper hash/path (common right after login) ([app_services.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L528-L584), [app_services.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L418-L451)).

## Why It Happens Even If the User Never Set Wallpaper
- There is **no guard** like “user has explicitly applied at least once” before auto-refresh applies wallpaper.
- With default auto-update behavior, a fresh install can be subscribed to the topic and will eventually receive a refresh push.

## Affected Code Sections
- **Default-on auto update**: [StorageService.getAutoUpdate](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L118-L122)
- **Topic subscribe/unsubscribe**: [FcmService.syncTopicSubscription](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L702-L719)
- **Background wallpaper change trigger**: [_bgH](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L637-L666)
- **Refresh applies wallpaper**: [WallpaperService.refreshWallpaper](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart#L528-L584)
- **Server-side scheduler**: [triggerDailyUpdateV2](file:///c:/Users/adell/Desktop/github_wallpaper/functions/index.js#L15-L66)
- **Permissions enabling wallpaper change**: `android.permission.SET_WALLPAPER` ([AndroidManifest.xml](file:///c:/Users/adell/Desktop/github_wallpaper/android/app/src/main/AndroidManifest.xml#L5-L9))

## Proposed Fix (Prevent Unauthorized Wallpaper Modification)
### 1) Make auto-update opt-in (safe default)
- Change `StorageService.getAutoUpdate()` default from `true` → `false` so fresh installs do not subscribe or refresh automatically.

### 2) Require explicit “user applied wallpaper at least once” before any auto-apply
- Add a persisted boolean like `keyHasAppliedWallpaper`.
- Set it to `true` only on the user’s explicit “Set Wallpaper” action path (e.g., [MainNavPage._handleSetWallpaper](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/main_nav_page.dart#L157-L189) or the customize/apply UI).
- Gate all refresh-triggered apply behavior behind:
  - `autoUpdateEnabled == true` AND
  - `hasAppliedWallpaper == true`

### 3) Disable background wallpaper application entirely (strongest guarantee)
- Update `_bgH` so it **never calls** `WallpaperService.refreshWallpaper(isBackground: true)`.
- Instead, only set `pending_wp_refresh` and exit.
- Update the startup handler in [main.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/main.dart#L124-L163) so that pending refresh:
  - is consumed without applying wallpaper unless the user has explicitly opted in and applied at least once.

### 4) Tighten message matching
- Replace `m.data['type']?.contains('refresh')` with strict equality `== 'refresh'` to avoid unintended matches.

## Verification Plan
- **Fresh install**: log in, do not set wallpaper, swipe app away → wait for scheduled push window → wallpaper must not change.
- **Opt-in path**: enable Auto Update, apply wallpaper once, swipe app away → next scheduled push should update wallpaper (only if you want to keep this feature).
- **Opt-out path**: disable Auto Update → confirm unsubscribe and no background changes.
- **Regression**: manual “Set Wallpaper” flow still works and uses the native channel ([MainActivity.kt](file:///c:/Users/adell/Desktop/github_wallpaper/android/app/src/main/kotlin/com/rahulreddy/githubwallpaper/MainActivity.kt#L32-L93)).

## Implementation Steps
1. Update auto-update default to `false` and ensure topic sync respects it.
2. Add and persist `hasAppliedWallpaper` and set it only on user-initiated apply.
3. Modify FCM foreground/background handlers and pending-refresh startup path to never auto-apply unless both gates are satisfied.
4. Update message type check to strict equality.
5. Add a small test harness/manual checklist to validate the above flows.
