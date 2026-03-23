
# Quote System — Agent Instructions

## What We Are Building

Replace the current per-user Gemini API call with a smarter system.
Instead of calling Gemini for every single user, we generate quotes once
per day for every possible user profile combination and store them in
Firestore. The app then just reads the right quote for each user.

---

## How Personalization Works

A quote feels personal based on 4 things we already know about the user:

1. **Current streak** — how many consecutive days they have committed
2. **Quote tone** — Friendly, Motivational, or Roast (user picks this in setup)
3. **Coding level** — New to coding, Beginner, Regular coder, Hardcore developer
4. **Today's commits** — how many commits they made today

We bucket each of these into groups:

- Streak: 0 days / 1–3 / 4–7 / 8–14 / 15–30 / 31–60 / 61–100 / 100+
- Tone: Friendly / Motivational / Roast
- Coding level: New / Beginner / Regular / Hardcore
- Today's commits: 0 / 1–2 / 3–5 / 6+

Total combinations: 8 × 3 × 4 × 4 = **384 unique quote profiles**.

Every user falls into exactly one of these 384 buckets.
Two users in the same bucket get the same quote — and that is fine
because their situation is identical.

---

## Step 1 — Cloud Function (Daily Quote Generator)

Write a Firebase Cloud Function that runs once every day at midnight IST.

The function loops through all 384 combinations and calls the AI model for each one.
The prompt for each call should be short and structured like this:

```
Write one short quote (max 20 words) for a developer.
Streak: 15 days. Tone: Motivational. Level: Regular coder. Commits today: 2.
Only return the quote text. No quotation marks. No explanation.
```

After generating all 384 quotes, write them to a single Firestore document
at path: `daily_quotes/{YYYY-MM-DD}` using today's date.

Each quote is stored as a key-value pair inside that document.
The key is built by joining the four bucket values with underscores.

Example keys:
- `15_30d_Motivational_Regular_1_2c`
- `0d_Roast_Hardcore_0c`
- `100pd_Friendly_Beginner_6pc`

Also delete any documents in `daily_quotes` older than 7 days to keep storage clean.

---

## Step 2 — App Side (Reading the Quote)

In `lib/shared/services/daily_quotes.dart`, replace the current AI call with a Firestore read.

When the app needs a quote, do this in order:

1. Get the user's current streak from `data.stats.currentStreak` and map to bucket
2. Get their tone from `StorageService.getQuoteTone()`
3. Get their coding level from `StorageService.getCodingLevel()`
4. Get today's commits from `data.stats.todayContributions` and map to bucket
5. Join all four with underscores to build the key
6. Read today's document from `daily_quotes/{today}` in Firestore
7. Return the value at that key
8. Cache it locally for the rest of the day — no repeat Firestore reads

If Firestore is unavailable or the document does not exist yet,
fall back to the existing local hardcoded quote list. Never show an empty quote.

---

## Step 3 — Pro User Regeneration

Free users always get the pool quote. Do not show them a regenerate button.

Pro users see a regenerate button. When they tap it, call the AI model
directly with the user's exact data rather than buckets. This gives a
truly unique quote each time and feels premium.

Check `PremiumState.isPro` before showing the regenerate button.
If not Pro, hide the button entirely. Do not disable it — hide it.

---

## Bucket Mapping Reference

**Streak → bucket name:**
- 0 → `0d`
- 1 to 3 → `1_3d`
- 4 to 7 → `4_7d`
- 8 to 14 → `8_14d`
- 15 to 30 → `15_30d`
- 31 to 60 → `31_60d`
- 61 to 100 → `61_100d`
- 101 and above → `100pd`

**Today's commits → bucket name:**
- 0 → `0c`
- 1 to 2 → `1_2c`
- 3 to 5 → `3_5c`
- 6 and above → `6pc`

**Tone** — use exact string from StorageService: `Friendly` / `Motivational` / `Roast`

**Coding level** — use exact string from StorageService: `New` / `Beginner` / `Regular` / `Hardcore`
```