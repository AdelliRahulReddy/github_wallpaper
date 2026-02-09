## Findings
- The Home page greeting is currently hardcoded as `WELCOME BACK 👋`, so brand‑new users will always see “Welcome back” on their first successful setup/login. See [home_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/home_page.dart#L141-L152).
- The app already uses `SharedPreferences` for onboarding state, so we can safely persist a one-time “first login” flag without breaking existing installs.
- The onboarding 3rd slide displays the email from `AppStrings.supportEmail` in [app_utils.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_utils.dart#L211-L216).
- GitHub PAT setup guidance is currently a single link in [README.md](file:///c:/Users/adell/Desktop/github_wallpaper/README.md#L34-L36), and the Setup UI doesn’t provide step-by-step token creation help.

## Fix Homepage Greeting (New vs Returning)
1. Add a new preference key (e.g. `keyFirstLoginGreetingPending`) in `AppConstants` (in [app_utils.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_utils.dart)).
2. Add `StorageService` helpers to read and clear that flag (in [app_services.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart)), with safe defaults when storage isn’t initialized.
3. In [setup_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/setup_page.dart), after successful credential validation and before navigating to `MainNavPage`, set the “first login greeting pending” flag to `true`.
4. In [home_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/home_page.dart), decide the greeting based on that flag:
   - If pending: show `WELCOME 👋` (or equivalent “Welcome” text) and clear the flag asynchronously so it only happens once.
   - Otherwise: show `WELCOME BACK 👋`.
5. Edge cases / error handling:
   - If clearing the flag fails, do not crash; keep showing the computed greeting.
   - If the flag is missing (existing users), default to returning-user behavior (shows “Welcome back”), preserving backward compatibility.

## Improve Setup Page Token Instructions (Step-by-Step + Scopes)
1. Update [README.md](file:///c:/Users/adell/Desktop/github_wallpaper/README.md#L34-L36) “GitHub Token” section into a numbered guide:
   - Where to find token creation: GitHub → Settings → Developer settings → Personal access tokens.
   - Recommend a token type (Classic recommended for simplicity).
   - Set expiration.
   - Scopes to select:
     - Minimum: `read:user`.
     - Optional (for private repo contribution breakdowns): `repo`.
   - Copy token once, paste into app.
2. Update [setup_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/setup_page.dart) UI to include user-facing documentation:
   - Add a short step-by-step “How to create a token” block under the token field.
   - Add a “Create one here →” link using the existing `url_launcher` dependency (pattern already used in [settings_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/settings_page.dart#L1-L20)).
   - If the URL can’t be opened, show a friendly error via `ErrorHandler` (no silent failure).

## Update Onboarding Slide Email
1. Change `AppStrings.supportEmail` to `adellirahulreddy@gmail.com` in [app_utils.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_utils.dart#L211-L216).
2. Update the contact email in [PRIVACY_POLICY.md](file:///c:/Users/adell/Desktop/github_wallpaper/PRIVACY_POLICY.md#L116-L118) to match, keeping content consistent.

## Tests (Verification)
1. Add widget tests to verify greeting behavior:
   - When the new “first login greeting pending” flag is `true`, Home shows “WELCOME 👋”.
   - When the flag is absent/`false`, Home shows “WELCOME BACK 👋”.
2. Run the full Flutter test suite (`flutter test`) to ensure no regressions.

## Files Expected To Change
- [home_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/home_page.dart)
- [setup_page.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/pages/setup_page.dart)
- [app_services.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_services.dart)
- [app_utils.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_utils.dart)
- [README.md](file:///c:/Users/adell/Desktop/github_wallpaper/README.md)
- [PRIVACY_POLICY.md](file:///c:/Users/adell/Desktop/github_wallpaper/PRIVACY_POLICY.md)
- `test/` (new test file for greeting logic)