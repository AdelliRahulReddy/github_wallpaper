Issues & PM/UX Findings
Here are the issues I've flagged, categorized by severity:

🔴 High Priority
ID	Area	Issue
S1	Security	Token stored in SharedPreferences — should use flutter_secure_storage for OAuth tokens
A3	Architecture	StorageService has 50+ raw string keys with no constants enum — high risk of typo-driven data bugs
U3	UI	QuickNumberTile hardcoded height: 125 — clips on accessibility text scale
P2	Performance	SliverList has addAutomaticKeepAlives: false — all 11 home sections rebuild on every scroll
🟡 Medium Priority
ID	Area	Issue
ID	Area	Issue
U1	UX	11 sections on Home with no progressive disclosure — cognitive overload on first load
U2	UX	Portrait preview panel uses previewFlex: 6-7 — user can't see the wallpaper at real scale
U6	UX	Stats year picker has no dropdown arrow — affordance is hidden
U7	UX	Notifications is a pushed sub-screen; all other settings are inline — inconsistent pattern
U5	UX	WallpaperAppliedCelebration auto-dismisses at 2500ms with no visible close affordance label
A1	Architecture	10 part-files for CustomizePage make state tracing via extensions difficult — consider a ViewModel
🟢 Low Priority
ID	Area	Issue
U4	A11y	Locked AchievementBadge uses Opacity(0.38) — not semantics-aware for screen readers
AC1	A11y	Multiple Icon widgets missing Semantics labels throughout
U8	UX	data == null on Home shows plain text "No data yet." — needs an empty-state illustration
U9	UX	AdminStateScreen (maintenance/force update) has no illustration — low visual trust signal
I1	i18n	AppStrings is well-maintained but no ARB/intl files — English-only
