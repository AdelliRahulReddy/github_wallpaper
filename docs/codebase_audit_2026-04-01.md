# Codebase Audit And Remediation Pass

Date: April 1, 2026

## Scope

This pass covered:

- static analysis with `flutter analyze`
- full Flutter test suite plus targeted share-flow regressions
- coverage generation with `flutter test --coverage`
- Cloud Functions dependency audit with `npm audit --omit=dev`
- manual review of the share flow, story-card templates, Firestore rules, and the wallpaper renderer failure path

This is a remediation pass, not a formal certification that every module in the repository is defect-free.

## Executive Summary

### Fixed in this pass

- share sheet rebuilt as a fixed-height flow with a horizontal template rail, non-scrolling preview stage, and sticky bottom export CTA
- all four core story templates now follow one mobile-safe composition model with richer stats, heatmap coverage, and overflow-safe sizing
- `Monthly Snapshot` now uses month-window trends instead of mixing month totals with global 7-day and 30-day values
- wallpaper renderer clamp bug fixed in `ui_render.dart`, unblocking the full test suite
- Cloud Functions dependencies upgraded to `firebase-admin ^13.7.0` and `firebase-functions ^7.2.2`
- `npm audit fix` removed the previously observed high-severity dependency findings from the Functions package
- CI workflow added for Flutter analyze, Flutter tests with coverage, and scheduled/high-severity Functions dependency auditing

### Current measured state

- `flutter analyze`: clean
- `flutter test`: passed
- `flutter test --coverage`: passed
- line coverage: `5612 / 10500 = 53.4%`
- `npm audit --omit=dev`: `9 low`, `0 high`, `0 critical`

## Findings

### UI/UX

#### Resolved

- The share chooser used a scroll-first bottom sheet, which made the preview and CTA fight for space on phones.
- The template picker used wrapped chips instead of a horizontal browsing pattern, causing the header region to consume too much height.
- Core templates were inconsistent in density and content, with missing heatmaps, weak alignment, and overflow on real devices.
- Heatmap sizing was unstable for short date windows and could create oversized grids.

#### Remaining

- The broader application still needs a wider responsive and accessibility sweep beyond the share surfaces. This pass did not re-audit every page against WCAG 2.1 AA.

### Logic

#### Resolved

- `Monthly Snapshot` no longer combines month-only totals with global trend windows.
- The wallpaper renderer no longer throws `ArgumentError: Invalid argument(s)` when the computed card height exceeds the safe vertical area.

#### Remaining

- The repository-wide coverage target requested by product (`80%`) is not met. Current measured line coverage is `53.4%`.

### Security

#### Resolved

- Cloud Functions dependency upgrades plus `npm audit fix` removed the previously observed high-severity advisories related to `fast-xml-parser`, `node-forge`, and `path-to-regexp`.

#### Reviewed

- `firestore.rules` remains deny-by-default outside explicitly allowed collections and uses ownership/admin checks for user and admin document access.

#### Remaining

- `npm audit --omit=dev` still reports `9 low` vulnerabilities in a transitive Google Cloud dependency chain rooted under `firebase-admin`.
- The suggested automatic fix path for the remaining low findings is `npm audit fix --force`, which would downgrade to `firebase-admin@10.3.0`. That is a breaking and backward-moving change, so it was intentionally not applied.
- A deeper manual review of `functions/index.js` and `admin/app.js` should still be scheduled for sink-by-sink validation and access-control review.

### Documentation And Process

#### Resolved

- Share-template behavior documentation updated.
- Codebase index updated for the share flow.
- CI automation added for future regression detection.

#### Remaining

- Architectural decisions are still only partially recorded. Larger cross-cutting systems should eventually gain ADR-style decision notes instead of relying on scattered markdown and code comments.

## Prioritized Remediation Plan

### P0

- Raise automated coverage from `53.4%` to `80%` by targeting untested service and controller layers first: auth flow, repository sync, admin surfaces, notifications, and Functions contracts.

### P1

- Complete a dedicated security review of `functions/index.js`, `admin/app.js`, and admin-facing Firestore access paths.
- Track the remaining low-severity Functions dependency findings and remove them when the upstream chain offers a non-breaking path.

### P1

- Run a broader UI accessibility audit on onboarding, settings, admin pages, and stats screens with explicit WCAG 2.1 AA checks for focus order, contrast, tap target sizes, and text scaling.

### P2

- Add ADR-style documentation for share architecture, auth/session mapping, and telemetry/monitoring decisions.

## Verification Checklist

- [x] `flutter analyze`
- [x] `flutter test`
- [x] `flutter test --coverage`
- [x] targeted share layout regression tests
- [x] Functions dependency upgrade
- [x] Functions dependency audit reduced to low-severity findings only
- [x] CI workflow added

## Files Changed In This Pass

- `lib/features/contributions/services/share_service.dart`
- `lib/features/contributions/widgets/share_card.dart`
- `lib/features/wallpaper/widgets/ui_render.dart`
- `lib/features/contributions/models/share_template_catalog.dart`
- `functions/package.json`
- `functions/package-lock.json`
- `.github/workflows/ci.yml`
- `docs/share_template_system_2026-04-01.md`
- `docs/codebase_audit_2026-04-01.md`
- `CODEBASE.md`
- `test/share_card_layout_test.dart`
- `test/home_share_sheet_test.dart`
- `test/customize_quote_access_test.dart`
