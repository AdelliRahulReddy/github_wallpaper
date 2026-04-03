# UX Upgrade Plan

Status: implementation plan to improve GitWall polish without regressing the current product.

Important note: this is a UX quality plan, not a monetization plan. GitWall remains free-only.

## What To Ignore From Older Plans

- Do not rebuild onboarding into a generic 5-slide intro.
- Do not add swipe navigation between tabs.
- Do not apply `MediaQuery.textScalerOf(context)` manually to every text widget.
- Do not start by adding packages before proving a real need.
- Do not use "premium" or "world-class" marketing language as a substitute for concrete UX work.
- Do not duplicate Settings/profile work that already exists.

## What To Keep

### 1. Animated Counters

Value: High

- Create a reusable `AnimatedCounter` widget.
- Apply it only to values that visibly change after refresh or sync.
- Good targets:
  - Today commits
  - current streak
  - weekly goal numerator
  - selected top summary metrics where motion stays readable

Rules:

- Keep durations short.
- Animate only on value change.
- Avoid flashy odometer effects.

### 2. Better Loading States

Value: High

- Replace the generic spinner on Home with a real skeleton state.
- Add a similar loading treatment to Stats if needed.
- Match the skeleton structure to the real page hierarchy so loading feels intentional.

Rules:

- Prefer built-in placeholder blocks first.
- Do not add a shimmer package unless native placeholders are clearly insufficient.

### 3. Better Empty And Error States

Value: Medium

- Replace plain text-only empty states with clearer UI.
- Improve retry and reconnect affordances.
- Use icons or simple visual structure first.

Rules:

- Do not add illustration assets unless they clearly improve the experience.
- Keep CTAs explicit and single-purpose.

### 4. Real Accessibility Audit

Value: High

- Check critical interactive targets meet minimum touch-target guidance.
- Verify focus order in navigation and major flows.
- Check overflow behavior on narrow widths and larger text.
- Add `Semantics` where raw text or iconography is ambiguous.

Rules:

- Do not apply blanket text-scaling code to every widget.
- Prefer targeted semantics and layout fixes over broad mechanical changes.

### 5. Selective Motion Polish

Value: Medium

- Add subtle first-load fade or slide polish to top Home cards.
- Add restrained pressed-state feedback on important buttons.
- Add limited navigation polish only if it improves clarity.

Rules:

- Keep motion minimal and purposeful.
- Respect reduced-motion preferences.
- Do not rebuild onboarding or navigation around animation.

### 6. Haptic Feedback

Value: Low to Medium

- Add haptics only to a few high-value actions:
  - GitHub connect
  - wallpaper apply
  - share/export

Rules:

- Do not add haptics to every tap in the app.

## Corrected Priority Order

| Priority | Task | Why |
|----------|------|-----|
| P0 | Skeleton loading | Biggest immediate quality gain |
| P0 | Animated counters | High-visibility polish on key metrics |
| P0 | Accessibility audit | Real product need, reduces UX regressions |
| P1 | Better empty/error states | Current presentation is too plain |
| P1 | Subtle motion polish | Useful if kept restrained |
| P2 | Haptic feedback | Nice to have, not foundational |

## Corrected Action Plan

### Step 1: Loading States

1. Create `lib/core/ui/skeleton_loader.dart`
2. Create a `HomePageSkeleton`
3. Replace the generic Home spinner with the new skeleton
4. Review whether Stats also needs a matching skeleton
5. Verify existing tests still pass

### Step 2: Animated Counters

1. Create `lib/core/ui/animated_counter.dart`
2. Use it in `_HomeTodayHeroCard`
3. Use it in `_HomeCurrentStreakCard`
4. Use it in selected journey/summary metrics where the animation improves readability
5. Ensure counters only animate when values actually change

### Step 3: Accessibility Audit

1. Audit core Home actions and metrics
2. Audit Stats, Settings, onboarding, and bottom navigation
3. Add `Semantics` only where needed
4. Test narrow widths such as `320px`
5. Test large text and fix any overflow or truncation issues that break usability

### Step 4: Empty And Error Polish

1. Review current empty states in Home and Stats
2. Review sync/auth reconnect states
3. Add clearer hierarchy, icon treatment, and CTA wording
4. Keep the design lightweight unless a stronger visual treatment proves necessary

### Step 5: Subtle Motion

1. Add first-load staggered fade or slight slide to top Home cards
2. Add restrained press feedback on primary CTAs
3. Prefer built-in Flutter animation primitives first
4. Do not rebuild onboarding
5. Do not add swipe tab navigation

## Important Constraints

- App is free-only
- Keep the GitHub-authentic character of the app
- Preserve existing working onboarding and navigation structure
- Prefer native Flutter animation and layout tools before new dependencies
- All changes must be verified against existing tests

## Accurate Status Snapshot

| Item | Status |
|------|--------|
| Onboarding | Already exists and should not be replaced blindly |
| Settings grouping | Already exists |
| Profile in Settings | Already exists |
| Navigation model | Works; do not add swipe behavior by default |
| Loading states | Needs stronger skeleton treatment |
| Empty states | Needs polish |
| Animations | Needs only selective, restrained improvements |
| Accessibility | Needs a real audit and targeted fixes |

## Candidate Files

### Likely For Loading Work

- `lib/features/contributions/pages/home_page.dart`
- `lib/features/contributions/pages/stats_page.dart`
- `lib/core/ui/skeleton_loader.dart`

### Likely For Animated Counters

- `lib/core/ui/animated_counter.dart`
- `lib/features/contributions/pages/home_page.dart`

### Likely For Accessibility And Empty-State Work

- `lib/features/contributions/pages/home_page.dart`
- `lib/features/contributions/pages/stats_page.dart`
- `lib/features/settings/pages/settings_page.dart`
- `lib/features/auth/pages/onboarding_page.dart`
- `lib/app/pages/main_nav_page.dart`

## Best First Slice

If another agent needs the safest first implementation slice:

1. Add `HomePageSkeleton`
2. Replace the Home spinner
3. Add `AnimatedCounter` for Today commits and current streak
4. Add missing Home `Semantics` where text is ambiguous
5. Run existing Home and onboarding tests

This gives the best quality-per-risk return.

## Validation Checklist

Run these after each meaningful slice:

```bash
dart analyze
flutter test test/home_profile_layout_overflow_test.dart
flutter test test/home_page_content_test.dart
flutter test test/free_experience_test.dart
flutter test test/onboarding_overflow_test.dart
flutter test test/onboarding_setup_layout_test.dart
```

Add targeted widget tests when introducing:

- skeleton states
- empty states
- animated counters
- semantics changes
- new motion on major surfaces

## Definition Of Done

This plan is successful when:

- loading states feel intentional instead of generic
- empty and reconnect states are clearer and easier to act on
- animated metrics improve feedback without adding noise
- accessibility regressions are less likely because the right screens are audited and tested
- onboarding remains GitHub-first and understandable
- polish increases without rewriting the app’s working structure
