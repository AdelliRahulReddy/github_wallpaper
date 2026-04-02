# Share Template System

Date: April 1, 2026

## Overview

The share system now has four core templates:

- `Daily Flex`
- `Repo Focus`
- `Streak Milestone`
- `Monthly Snapshot`

All four core templates now export in `Story 9:16` only.

`Wrapped` remains available as a seasonal recap asset and is also story-only.

## Product Rationale

The old system had only two templates, which left clear gaps:

- `Daily Flex` handled momentum, but not milestone moments.
- `Repo Focus` handled project storytelling, but not broader recap content.
- The system needed clearer intent-based template selection instead of relying on just a couple of generic share cards.

The new four-template system covers the four highest-value sharing intents:

1. `Daily Flex`
Purpose: everyday progress, consistency, and current momentum.
Best for: frequent posting, status updates, and quick “I’m building” shares.

2. `Repo Focus`
Purpose: spotlight one repository when a single project carries the story.
Best for: launches, sprint highlights, and public project promotion.

3. `Streak Milestone`
Purpose: celebrate habit retention and streak checkpoints.
Best for: 7-day, 14-day, 30-day, and larger streak moments.

4. `Monthly Snapshot`
Purpose: summarize a broader progress window with reflective framing.
Best for: month-end recaps, growth posts, and performance summaries.

This keeps the system simple enough to browse quickly while covering the main social motivations behind sharing developer activity.

## Recommendation Logic

Template ordering now follows share intent instead of static ordering:

- recommend `Streak Milestone` when the current streak hits a milestone
- recommend `Repo Focus` when one repository strongly dominates contribution share
- recommend `Monthly Snapshot` when broader recap content is more meaningful
- always keep `Daily Flex` available as the baseline default

If a recommended template is not already selected, it is surfaced first in the picker. The picker still exposes all four core templates.

## Format Rules

There is now one supported export format for the core share system:

- `Story 9:16`

This means:

- no `Social 4:5` option
- no `Square 1:1` option
- no compact-layout branch to maintain in the core share picker
- every template is designed around the same vertical export canvas

The result is a simpler system with one clear export target and less layout drift between templates.

## Theme Integration

Theme inheritance is centralized through the share palette layer.

The share cards inherit:

- wallpaper theme accent
- accent-derived border and surface tones
- heatmap levels
- export frame gradient
- secondary and tertiary accent roles

Result:

- every template respects current custom theme color styles
- each template still keeps its own identity through layout and emphasis
- all templates share the same card language, spacing rhythm, type hierarchy, and export framing

## Template Behavior

### Daily Flex

- full momentum card with hero, daily stats, and heatmap

### Repo Focus

- full project spotlight with richer repo breakdown

### Streak Milestone

- celebratory streak hero with milestone framing

### Monthly Snapshot

- richest recap format with month total, supporting metrics, trends, and heatmap

## UI/UX Changes

- kept the four-template catalog instead of collapsing back to a single generic card
- removed `Social` and `Square` from the share template system
- made `Story 9:16` the only supported export format for all four core templates
- replaced the wrapped chip cloud with a horizontal template rail
- removed scrolling from the share sheet preview flow and kept the preview inside a fixed stage
- made `Share this moment` a sticky bottom action instead of part of the scrolling content
- standardized all four core templates around the same story-card density and spacing contract
- added a heatmap section to all four core templates
- fixed month-only cards so month totals and trends use the same month window
- aligned the implementation and docs around one story-first export path
- kept `Repo Focus` repository ranking so the strongest repo is selected instead of blindly using the first repo

## Verification

Verified with targeted widget coverage:

- `test/share_card_layout_test.dart`
- `test/home_share_sheet_test.dart`

Covered behaviors:

- all four core templates render in story format without overflow
- the share chooser exposes the four core templates through a horizontal rail
- the share chooser keeps the primary share CTA pinned at the bottom
- the share chooser no longer exposes social or square format options
- repo focus picks the strongest repository
