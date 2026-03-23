# Stats Logic Audit

This document explains the current `Stats` implementation in GitWall, what was fixed recently, how each section is driven, what is year-scoped vs recent-scoped, and where the trust boundaries still are.

## Summary

Current Stats is best understood as:
- strong selected-year analytics for day-based contribution data
- recent-window analytics for repo/language aggregate data
- based on the last ~370 days of GitHub data, not lifetime history

The UI now communicates that scope directly on the Stats page.

## 1. Dataset Boundary

### Source of truth
- Stats is driven from the cached GitHub contribution dataset in `CachedContributionData`.
- The GitHub fetch currently requests a rolling window of the last `370` days, not lifetime GitHub history.

Relevant code:
- `lib/data/repositories/github_service.dart`
- `lib/core/utils/app_utils_constants.dart`
- `lib/data/models/app_models_cached_data.dart`

Key implication:
- Stats is only as complete as the last ~370 days of GitHub contribution data.
- Because of that, the app can usually represent:
  - the current year
  - part of the previous year
- It is not a full lifetime analytics system.

### Normalization
`CachedContributionData` rebuilds total contributions from merged daily rows and does not trust any incoming precomputed total.

Relevant code:
- `lib/data/models/app_models_cached_data.dart`

This is good for trust because:
- duplicate same-day rows are merged
- totals are recomputed from normalized days

## 2. Year Filter Behavior

### How year options are built
- The year list is derived from the actual years present in `data.days`.
- The selected year defaults to:
  - current year, if present
  - otherwise the newest available year

Relevant code:
- `lib/features/wallpaper/screens/stats/stats_page_state.dart`

### What the year filter truly scopes
The year filter currently scopes all day-based contribution sections:
- subtitle
- year heatmap
- at-a-glance tiles
- weekly breakdown
- monthly trend
- streak history
- most active weekdays

It does **not** attempt to retro-scope repository/language aggregates historically, because that data is only available as recent aggregate repo data from the fetch window, not per-year repo history.

Because of that:
- `Top Languages`
- `Top Repos`
- `Wrapped`

are shown only for the current year view.

This is intentional and is now more honest than pretending those cards are year-specific.

## 3. Stats Page Structure

### Header subtitle
Current logic:
- current year: `X contributions this year`
- past year: `X contributions in YYYY`

Relevant code:
- `lib/features/wallpaper/screens/stats/stats_page_state.dart`
- `lib/features/wallpaper/screens/stats/stats_page_header.dart`

### Scope notice
The page now shows a visible scope note under the subtitle:
- all views: `Based on the last 12 months of GitHub activity`
- past-year views: `Some insights are current-year only`

This was intentionally shortened so it is readable in-product instead of feeling like a disclaimer wall.

### Empty states
Handled states:
- loading with no data
- error with no data
- no data
- no years in data

This avoids the previous crash/invalid selection path when the year list was empty.

## 4. Per-Section Logic

### A. Year Heatmap

Widget:
- `StatsYearHeatmapCard`

Relevant code:
- `lib/features/wallpaper/widgets/stats/stats_sections_heatmap.dart`

How it works:
- builds a calendar grid for the selected year
- pads to full weeks so layout stays rectangular
- uses cached day rows keyed by date
- tapping a populated day opens day detail bottom sheet

Metrics shown above the heatmap:
- `activeDays`: count of selected-year days with contributions > 0
- `yearTotal`: sum of selected-year contributions

Color intensity:
- uses `RenderUtils.getContributionLevel(...)`
- quartiles are recalculated from selected-year contribution counts

Important trust note:
- heat intensity is now year-scoped
- that means a lower-activity year is no longer visually compressed by a higher-activity recent year

Tradeoff:
- colors are more truthful inside the selected year
- cross-year heat intensity is less directly comparable by eye

### B. At A Glance

Widget:
- `StatsAtAGlanceGrid`

Relevant code:
- `lib/features/wallpaper/widgets/stats/stats_sections_glance.dart`

Tiles:
- `Live Streak` or `Year-end Streak`
- `Best in YYYY`
- `Active Days`
- `Peak Day`
- `Total Commits`
- `Avg/Day`

Logic:
- `Active Days`: selected-year days with count > 0
- `Peak Day`: highest single-day contribution count inside selected year
- `Total Commits`: sum of selected-year contribution counts
- `Best in YYYY`: selected-year longest streak

Streak behavior:
- current year uses overall `currentStreak`
- past year uses `yearStats.currentStreak`, which represents the streak value at year end

Average/day behavior:
- current year uses elapsed days from Jan 1 to today
- past year uses full days in that calendar year

This was fixed because earlier logic divided current-year totals by the entire year length, which understated the average.

### C. Weekly Breakdown

Widget:
- `StatsWeeklyBreakdownCard`

Relevant code:
- `lib/features/wallpaper/widgets/stats/stats_sections_time_breakdowns.dart`

How it works:
- takes the last 8 weekly buckets ending at:
  - today for current year
  - Dec 31 for past year
- each bar sums 7 daily contribution values
- highlights the best week among those 8 bars

Presentation note:
- current year is labeled `LAST 8 WEEKS`
- past year is labeled `LAST 8 WEEKS OF YYYY`
- past-year view explicitly states it shows the last 8 weeks of that year, not the entire year

Trust note:
- this is truly date-scoped because it sums actual daily contribution rows by date
- the limitation is now labeling/scope, not incorrect math

### D. Monthly Trend

Widget:
- `StatsMonthlyTrendCard`

Relevant code:
- `lib/features/wallpaper/widgets/stats/stats_sections_monthly_trend.dart`

How it works:
- builds 12 monthly totals for selected year
- builds 12 monthly totals for prior year
- renders side-by-side bars for each month

Delta chip:
- current year compares current month vs previous month
- past year compares December vs November of that past year

Important fix:
- January now correctly compares against last December of the previous year
- previously it incorrectly compared January against January/zero path

### E. Streak History

Widget:
- `StatsStreakHistoryCard`

Relevant code:
- `lib/features/wallpaper/widgets/stats/stats_sections_highlights.dart`

Rows:
- `Live streak` or `Ending streak`
- `Best (last 12 months)`
- `Best in YYYY`
- count of streaks `7+` days in selected year

Logic:
- `Best ever`: computed from all loaded days
- `Best in YYYY`: recomputed from selected-year days only
- streak counts are recomputed from ordered daily rows

Important trust boundary:
- `Best (last 12 months)` means best within the loaded rolling dataset, not guaranteed lifetime GitHub history
- since the fetch window is ~370 days, this can still miss older streaks

### F. Most Active Days

Widget:
- `StatsMostActiveDaysCard`

Relevant code:
- `lib/features/wallpaper/widgets/stats/stats_sections_highlights.dart`

How it works:
- sums all selected-year contributions grouped by weekday
- visualizes each weekday as a relative bar
- highlights the strongest weekday

Important fix:
- if there is no activity in the selected year, it no longer silently crowns Monday
- it now shows an honest empty state

### G. Recent Top Languages

Widget:
- `StatsTopLanguagesCard`

Relevant code:
- `lib/features/wallpaper/widgets/stats/stats_sections_rankings.dart`
- `lib/data/models/app_models_cached_data.dart`

How it works:
- language scores are derived from repository contribution aggregates
- if repo language sizes exist, commit counts are distributed proportionally across languages
- otherwise primary language gets the repo’s commit weight
- result is normalized into percentages

Trust note:
- this is a **recent aggregate** based on repo contribution data in the loaded window
- it is not reconstructed per calendar year
- for that reason it is only shown in current-year view

UX note:
- the page now explicitly explains this when you view a past year

### H. Recent Top Repos

Widget:
- `StatsTopReposCard`

Relevant code:
- `lib/features/wallpaper/widgets/stats/stats_sections_rankings.dart`

How it works:
- takes repositories with `commitCount > 0`
- sorts descending by commit count
- displays top 6

Trust note:
- also recent-window aggregate only
- not year-filtered historically
- only shown on current-year view

Past-year UX:
- instead of silently disappearing, current-year-only sections are replaced with a placeholder card explaining that `Top Languages`, `Top Repos`, and `Wrapped` are only available on the current-year view

### I. Recent Wrapped

Widget:
- `StatsYearWrappedCtaCard`

Relevant code:
- `lib/features/wallpaper/widgets/stats/stats_sections_wrapped_cta.dart`

Current behavior:
- explicitly labeled `RECENT WRAPPED`
- explicitly labeled `Last 365 Days`
- shows:
  - best month
  - top language
  - longest streak

Important fix:
- it no longer pretends to be selected-year wrapped
- it is now honestly framed as recent-window wrapped

## 5. Shared Metric Engine

The common stat engine is `ContributionAnalyzer`.

Relevant code:
- `lib/shared/state/app_state.dart`

### Current streak
Logic:
- starts from today
- if today has zero contributions, it starts from yesterday
- walks backward while daily contribution count stays > 0

Meaning:
- there is a built-in grace behavior for “no commit yet today”

### Longest streak
Logic:
- iterates ordered days
- increments streak on consecutive active days
- resets on inactive day or date gap

### Totals
Computed from actual day rows:
- total contributions
- active day count
- peak single day
- today contributions
- most active weekday

### Trend windows
`computeTrend(window: 7|30)` now uses equal-length windows:
- current window: exactly `window` days including today
- previous window: exactly the `window` days immediately before that

This was fixed because earlier logic used an off-by-one date range.

## 6. What Was Fixed

Recently fixed issues:
- year picker now reflects the active year correctly
- selected-year subtitle now tells the truth for past years
- scope notice now explains the dataset boundary in shorter product copy
- current-year and past-year streak labels are different and more accurate
- misleading `Best ever` wording changed to `Best (last 12 months)`
- January monthly comparison bug fixed
- off-by-one bug in trend window math fixed
- fake year-scoped Wrapped card removed and replaced with recent wrapped framing
- past-year screens no longer silently hide recent-only languages/repos/wrapped cards; they now show a current-year-only placeholder
- empty `Stats` state no longer breaks on missing years
- most-active-weekday chart no longer silently shows a bogus winner on zero activity
- current-year `Avg/Day` now uses elapsed days instead of dividing by the entire year
- heatmap color intensity is now recalculated per selected year instead of using the full recent dataset
- weekly breakdown labeling now clearly states it is the last 8 weeks rather than implying whole-year weekly behavior
- missing `StatsYearHeatmapCard` widget restored after cleanup

## 7. Trust Model

### High trust
These are directly derived from daily contribution rows and are safe to trust within the loaded dataset:
- year total
- active days
- peak day
- weekly breakdown math
- monthly totals
- streak calculations
- weekday activity totals
- heatmap day detail
- year-scoped heatmap intensity

### Medium trust
These are correct for the loaded dataset, but the loaded dataset is only recent:
- best recent streak
- recent total commit-based achievements
- wrapped best month

### Lower trust for historical interpretation
These are honest now, but should be read as recent-window aggregates, not historical full-year truths:
- top languages
- top repos
- wrapped CTA
- recent-best streak wording if a user assumes the dataset is lifetime

## 8. Remaining Limits

Still true today:
- Stats is not lifetime analytics; it is rolling recent analytics
- only ~370 days are fetched from GitHub
- repo/language data is not stored by calendar year, so true historical year-scoped repo/language stats are not available
- if you want true lifetime or true historical yearly repo/language views, the app would need:
  - a much larger persisted dataset
  - or server-side historical snapshots
  - or year-partitioned GitHub aggregation

## 9. PM Verdict

Current Stats is now much more trustworthy than before.

What it does well:
- selected-year daily contribution analytics
- year-scoped streak and activity storytelling
- honest handling of recent-only aggregates
- explicit communication of dataset/scope limits in the UI
- avoids silent disappearance of current-year-only insights on past-year views

What it is not:
- full lifetime GitHub analytics
- fully year-scoped repo/language analytics

So the current product position should be:
- `Stats = recent contribution analytics with strong selected-year day-based insights`
- not `full historical GitHub intelligence`
