# Quote System

Date: 2026-04-03

Status: current local-only quote architecture.

## Purpose

GitWall no longer depends on runtime AI quote generation. Quotes now come from a bundled curated catalog that is scored locally against recent GitHub activity and user preferences.

## Core Design

- Source: `lib/features/contributions/data/curated_quote_pool.dart`
- Models: `lib/features/contributions/models/quote_models.dart`
- Selector and persistence: `lib/features/contributions/services/daily_quotes.dart`
- Storage hooks: `lib/core/storage/storage_service.dart`

The catalog is finite and capped at `<= 1000` entries. Each quote carries:

- tone
- coding-level fit
- activity categories
- streak bucket compatibility
- commits-today bucket compatibility
- weekly-activity bucket compatibility

## Activity Tracking

The selector derives a `QuoteActivityProfile` from cached contribution data and stores the latest profile locally.

Tracked signals:

- current streak
- commits today
- 7-day total
- active days this week
- active days this month
- week-over-week delta
- top repository share
- tone preference
- coding-level preference

Derived categories:

- `reset`
- `protect`
- `rebound`
- `momentum`
- `celebrate`
- `focus`
- `consistency`
- `deep_work`
- `generic`

## Selection Logic

1. Build the activity profile from cached GitHub data.
2. Reuse the persisted quote if the same day and the same profile fingerprint still apply.
3. Otherwise score the local catalog by:
   - tone match
   - coding-level fit
   - category priority
   - streak bucket match
   - commits-today bucket match
   - weekly bucket match
   - recent-history penalties
4. Choose deterministically from the highest-ranked small candidate set so the quote feels stable, not random.
5. On manual refresh, block the current quote id and rotate within the top candidates.

## Fallback Behavior

- If smart quotes are disabled in remote config, the app falls back to a deterministic local baseline quote.
- If no catalog candidate survives scoring filters, the same deterministic fallback path is used.
- Home and Customize continue to render a quote even when no fresh selection has been persisted yet.

## Admin Surface

The remote config kill switch is now:

- `smart_quotes_enabled`

Legacy `ai_quotes_*` config fields are only read as backward-compatible fallbacks by the Flutter app and are no longer part of the primary admin schema.
