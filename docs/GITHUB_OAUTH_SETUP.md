# GitHub OAuth Configuration Guide

This document outlines the secure GitHub OAuth setup for GitWall. The mobile app now uses AppAuth for the authorization step only, while a Firebase HTTPS Cloud Function performs the token exchange and mints a Firebase custom token.

## Prerequisites

1. A GitHub account.
2. Access to Firebase Functions secret configuration.
3. Access to your Firebase and GitHub console settings.

## Step 1: Create or Update the GitHub OAuth App

1. Go to GitHub [Developer Settings - Applications](https://github.com/settings/developers).
2. Open the GitWall OAuth app or register a new one.
3. Set the callback URL to `gitwall://oauth/callback`.
4. Keep the generated client ID.
5. Save the client secret for Firebase Functions only.
6. Make sure the app can request these scopes:
   - `read:user`
   - `user:email`

## Step 2: Configure Firebase Function Secrets

The GitHub client secret must never live in Flutter code. Set these Firebase Functions secrets:

| Variable Name | Description |
| :--- | :--- |
| `GITHUB_CLIENT_ID` | Public GitHub OAuth client ID |
| `GITHUB_CLIENT_SECRET` | GitHub OAuth client secret |

Example:

```bash
firebase functions:secrets:set GITHUB_CLIENT_ID
firebase functions:secrets:set GITHUB_CLIENT_SECRET
```

## Step 3: Configure Flutter Build Values

Only non-secret values belong in the app:

| Variable Name | Description | Default |
| :--- | :--- | :--- |
| `GITHUB_CLIENT_ID` | Public GitHub OAuth client ID | Existing GitWall client ID |
| `GITHUB_REDIRECT_URI` | Deep-link callback URL | `gitwall://oauth/callback` |
| `GITHUB_CODE_EXCHANGE_URL` | HTTPS Cloud Function URL | `https://us-central1-gitwall-d63cc.cloudfunctions.net/exchangeGitHubCode` |

Example:

```bash
flutter run --dart-define=GITHUB_CLIENT_ID=YOUR_CLIENT_ID
```

## Step 4: Platform Redirect Configuration

- Android redirect scheme: `gitwall`
- Android redirect receiver:
  - Scheme: `gitwall`
  - Host: `oauth`
  - Path: `/callback`
- iOS URL scheme: `gitwall`

## Step 5: Firebase Requirements

- Android package name: `com.rahulreddy.githubwallpaper`
- Android SHA-1 currently present in `android/app/google-services.json`:
  - `a98818da6cfb094d3547b9a1080f95c0581ae375`
- iOS bundle identifier should be:
  - `com.rahulreddy.githubwallpaper`

If iOS support is required, register that iOS app in Firebase, download the matching `GoogleService-Info.plist`, place it in `ios/Runner/`, and regenerate `lib/config/firebase_options.dart` with FlutterFire so the iOS `appId` and bundle ID match.

## Step 6: Runtime Flow

1. Flutter starts AppAuth authorization with PKCE.
2. GitHub redirects back to `gitwall://oauth/callback`.
3. Flutter sends the authorization code and PKCE verifier to `exchangeGitHubCode`.
4. The Firebase Function exchanges the code with GitHub, fetches `/user` and `/user/emails`, chooses the verified email, and creates a Firebase custom token for the app session.
5. Flutter signs into Firebase with that custom token and stores the GitHub access token locally for GitHub API calls.
