# GitWall Web Admin

`admin/` is the live web control panel for operating GitWall outside the Flutter app.

## Why this folder lives at the repo root

It is not Flutter code, so keeping it out of `lib/` makes it easier to:

- run and deploy as a separate web app
- deploy directly to Vercel
- iterate without mixing with mobile UI

## Local run

From the repo root:

```powershell
python -m http.server 4173 -d admin
```

Then open:

```text
http://localhost:4173
```

## Auth model

The web admin now uses Firebase Authentication with Google sign-in.

Important:

- Enable the Google provider in Firebase Authentication.
- Add `localhost` to Firebase Authentication authorized domains for local testing.
- The signed-in Google email must exist in Firestore as `admins/<email>` with `enabled: true`.
- The dashboard is live-only. There is no preview mode or demo dataset.
- Firestore listeners update the UI in real time without page refreshes.

## Broadcast notifications

The admin dashboard can send a custom broadcast notification to all updated app installs.

Important:

- Deploy the latest Cloud Functions so `sendAdminBroadcast` exists.
- Rebuild and ship the latest Flutter app so devices subscribe to the broadcast topic.
- Users must open the updated app once and allow notifications.

## Deployment

Point Vercel at the `admin/` directory and deploy it as the web admin app.
