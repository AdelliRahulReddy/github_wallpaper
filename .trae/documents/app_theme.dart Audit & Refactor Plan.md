## Scope
- Audited the full file [app_theme.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/app_theme.dart#L1-L490) for: unused imports, dead code, duplication, naming consistency, Flutter theming best practices, and organization.
- Also verified usage of key helpers/tokens across the `lib/` tree (to distinguish “dead” vs “shared API”).

## Audit Report (Issues)
| Lines | Severity | Issue | Why it matters | Recommendation |
|---:|:---:|---|---|---|
| 93-108 | High | Partial `ColorScheme` definition | Only a subset of roles are explicitly set; remaining roles may fall back to defaults, producing inconsistent colors across components (buttons, containers, surfaces, etc.), especially under Material 3. | Prefer `ColorScheme.fromSeed(...)` + `copyWith(...)` to explicitly control key roles, or define a full light/dark `ColorScheme` so all roles are intentional. |
| 5-490 | Medium | Mixed responsibilities in one file (theme + extensions + UI widgets) | Increases coupling and makes theme changes riskier; encourages importing “theme” to get widgets, or vice versa, which grows dependencies. | Split into dedicated files (e.g., `theme/app_theme.dart`, `theme/app_theme_ext.dart`, `widgets/app_card.dart`, `widgets/metric_tile.dart`). Keep this file as “theme only”. |
| 219-230 | Medium | Dead/unused helper: `skyByIndex(int index)` | No call sites found; increases API surface and maintenance cost. | Remove it, or add a call site and tests if it’s intended for onboarding/background selection. |
| 245-246 | Medium | Dead/unused helper: `isSkyDarkByIndex(int index)` | No call sites found; same maintenance cost as above. | Remove it, or replace current call sites that compute darkness by index if needed. |
| 328-333 | Low | Unused `BuildContext` helpers: `appTheme` and `text` | `colors` / `isDark` are used indirectly by shared widgets, but `appTheme` and `text` appear unused outside this file. Extra extension API adds noise and potential naming collisions. | Remove unused getters or move the extension to a separate file and only keep what’s used. |
| 323-324 | Medium | `AppThemeExt.of(context)` uses `!` (crash-on-missing) | If a route/screen uses a different ThemeData (tests, isolated widgets), this throws at runtime. | Provide a safe fallback (`?? AppThemeExt(isLight: ...)`) or throw a clearer error explaining how to register the extension. |
| 253-258 | Low | `glassCard({double blur = 0.1})` misnamed parameter | `blur` is used as opacity (`withValues(alpha: blur)`), which is misleading and error-prone. | Rename param to `opacity`/`tintOpacity` or implement actual blur via `BackdropFilter`/`ImageFilter.blur` if blur is desired. |
| 253-258 | Low | `glassCard` uses light border color always | `border: ... lightSurface ...` can look wrong in dark mode and ignores `ColorScheme.outline`. | Make border color depend on theme (`outline`/`outlineVariant`) or tint, and allow override. |
| 339-374 | Medium | `AppCard` uses `GestureDetector` instead of Material tap handling | Loses Material ripple, focus/hover states, and may reduce accessibility cues. | Wrap with `Material` + `InkWell`/`InkResponse` (with matching `borderRadius`) when `onTap != null`. |
| 394-407, 463-482 | Low | Repeated typography/style blocks (`GoogleFonts.plusJakartaSans(...)`) | Duplicates style definitions outside `ThemeData.textTheme`, increasing drift risk when fonts/sizes change. | Use `Theme.of(context).textTheme.*` styles and only tweak deltas via `copyWith(...)`, or define reusable `TextStyle` getters in theme extension. |
| 95 | Low | Dark-mode `primary` differs semantically from light (`skyDayAccent` vs `primaryBlue`) | If `primary` is used for “brand” actions, the brand color changes between modes; may or may not be desired. | Decide intent: keep brand constant across brightness, or define explicit `brandPrimaryLight/brandPrimaryDark` tokens and document usage. |
| 301 | Low | Redundant getter `heatmapTodayHighlight` | Simple alias to `heatmapHighlight`; not harmful but adds surface area. | Inline usages or keep only if it meaningfully conveys semantics; otherwise remove. |
| 311-320 | Low | `lerp` assumes equal `heatmapLevels.length` | Safe today (both lists are length 5), but future edits could cause out-of-range errors. | Add a defensive check (or use `min(lengths)`), or assert equal lengths. |

## Verification (What’s actually used)
- Imports are all used: `material.dart` (widgets/theme), `services.dart` (`SystemUiOverlayStyle`), `google_fonts.dart`.
- Sky helpers used: `skyGradient`, `skyAccent`, `isSkyDark`, `skyTextColor`, `skySubtextColor`, `skyAccentByIndex` have call sites in splash/onboarding (so keep). `skyByIndex` / `isSkyDarkByIndex` appear unused.
- Core palette tokens are used across pages (e.g., `warningOrange`, `errorRed`, `successGreen`, `primaryBlue` have call sites).
- Spacing/radius/font tokens are referenced across multiple pages (no obvious dead constants).

## Remediation Plan (If you want me to implement fixes)
1. Remove dead helpers (`skyByIndex`, `isSkyDarkByIndex`) and unused context getters.
2. Make `AppThemeExt.of` safer (fallback or clearer failure).
3. Update `glassCard` API (rename param + make border theme-aware).
4. Refactor `AppCard` to use Material + InkWell for better UX/accessibility.
5. Consolidate repeated text styles to `textTheme` (reduce `GoogleFonts.plusJakartaSans(...)` duplication).
6. Optionally split file into `theme/` + `widgets/` modules to reduce coupling.
7. Validate with analyzer/tests after refactor.
