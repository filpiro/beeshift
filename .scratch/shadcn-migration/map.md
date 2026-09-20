# Map: catui/Material → shadcn_flutter migration

Status: open
Created: 2026-09-20

## Destination

A locked migration spec at `.scratch/shadcn-migration/spec.md`: every UI element in
`lib/` mapped to a named `shadcn_flutter` widget, the `ShadcnApp` theme pinned to the
agreed settings, and `catui` + `package:flutter/material.dart` gone from the dependency
list. Planning only — no app code is changed on this map. A later build session executes
the spec.

## Notes

**Domain.** `beeshift` is a Flutter shift-calendar app. 16 Dart files, ~1900 lines.
UI surface is small: 8 `Scaffold`, 2 `AppBar`, 7 buttons, 2 `CircularProgressIndicator`,
1 `SnackBar`, 4 `CatSegmented`. `catui` supplies the Catppuccin theme (`catTheme`,
`Flavor`, `AppTokens`) and `CatSegmented`. Everything else is stock Material.

Custom widgets that are *layout*, not theme, and may survive the swap:
`lib/shared/widgets/floating_bottom_bar.dart`, `equal_row_segmented.dart`,
`picked_style.dart`.

**Skills every session consults.** `/shadcn-flutter` (local docs under
`.claude/skills/shadcn-flutter/`, the primary source — do not web-fetch first),
`/grilling`, `/domain-modeling`. API reference:
https://pub.dev/documentation/shadcn_flutter/latest/shadcn_flutter/

**Environment.** Flutter runs on Windows, agent runs in WSL. All Flutter/Dart commands
go through `pws -c ...` and carry `--dart-define-from-file=env.json`. See `CLAUDE.md`.

### Standing decisions (set at charting, by the user)

1. **Plan only.** This map produces a spec. It does not edit `lib/`.
2. **Theme settings**, to be expressed in `ShadcnApp`/`ThemeData`:
   `themeMode: Dark` (default), `baseColors: Slate`, `accentColors: Amber`,
   `radius: Rounded`, `density: Reduced`, `scaling: Default`,
   `surfaceOpacity: Solid`, `surfaceBlur: Medium`.
3. **The Light/Dark/System switch stays.** Dark is the default and is specified above;
   a Light counterpart must be derived from the same Slate + Amber pair.
   `ThemeCubit`, the `shared_preferences` persistence, and the Settings control all survive.
4. **Shift Colours freeze.** The six Catppuccin Mocha hues currently produced by
   `ShiftColors.forFlavor` become literal constants. The calendar keeps its present look.
   This removes the last functional reason to keep `catui`.

## Decisions so far

<!-- one line per resolved ticket -->

- [01 — Theme configuration](issues/01-theme-configuration.md) — `ShadcnApp(theme:, darkTheme:, themeMode:)` mirrors `MaterialApp`, so the switch survives untouched. `ThemeData(colorScheme: ColorSchemes.lightSlate/.darkSlate, radius: 0.75, scaling: 1.0, density: Density.reducedDensity, surfaceOpacity: 1.0, surfaceBlur: 8.0)`; Amber layered via `ColorScheme.copyWith`, whose params are `ValueGetter<Color>?` — closures, not colours. shadcn `ThemeData` has **no `extensions` slot**, so `ShiftColors` becomes a top-level `const Map<ShiftType, Color>` and the `ThemeExtension` is deleted (3 call sites). Mocha hexes captured. "Rounded" and "Medium" have no API constants — 0.75 / 8.0 are proposals, and `surfaceOpacity: 1.0` will hide the blur anyway.

- [02 — Component mapping](issues/02-component-mapping.md) — 20 of 22 rows map cleanly against the 0.0.54 dartdoc. `AppBar` is both a class and a `Scaffold(headers: [...])` slot; buttons are `PrimaryButton`/`TextButton`/`OutlineButton`/`IconButton.ghost`; `SnackBar`→`showToast`; icons are `LucideIcons`. **A 100% Material-free `lib/` is reachable**, and the only thing standing in the way is the `ShiftColors` `ThemeExtension` — so standing decision 4 is load-bearing, not tidy-up. All three custom widgets survive; none has a shipped replacement. `picked_style.dart` is the hardest rewrite: every token it reads is absent from shadcn's ThemeData and it must return a `ButtonStyle`. shadcn ships its own `ThemeMode` with identical enum names, so `ThemeCubit`'s saved preferences stay valid — import swap only. No `Segmented*` symbol exists anywhere in the package.

- [03 — Prototype the month grid and day cell](issues/03-prototype-month-grid.md) — **The hand-rolled `_MonthGrid` / `_DayCellView` stay.** shadcn's `Calendar` exposes only `stateBuilder` returning a `DateState` (enabled/disabled/selected) — no day-cell builder, no per-day colour, nowhere for the Shift Code — and it exists to select dates, which the Calendar page never does. The swap is narrow: `AppTokens.radius`→shadcn radius, `outlineVariant`→`ColorScheme.border`, `primary`→the Amber accent, textTheme slots left to token mapping. **`density: Reduced` never reaches the cell** — its insets are literals over a `LayoutBuilder` side, and the cell has no gesture handling, so no tap target shrinks. **Every frozen hue gains ~22% contrast** on `darkSlate`'s `#020817` vs Mocha's `#1e1e2e`; weakest is secondo blue at 9.50:1. The Shift Colour paints the *letter* and today's *border*, not a slab behind the day number. [Prototype](https://claude.ai/artifact/VAfxwB38vcADAGjgFvAR1Q) is HTML, not Flutter — the map adds no dependency — so 02's "const map at all three call sites" is recorded in the spec, not demonstrated.

## Not yet specified

- **Navigation and routing.** `ShellPage` swaps pages by index today. Whether shadcn's
  page-route / tab-pane widgets change that shape is unknown until the shell is prototyped (04).
- **Typography and token mapping.** Italian date and label strings read
  `Theme.of(context).textTheme.*`, and `picked_style.dart` reads `outlineVariant` and
  `onSurfaceVariant` — none of which exist in shadcn's ThemeData (02). shadcn uses
  semantic text extensions (`.h1()`, `.muted()`). Mechanical, but which scale and which
  colour slot each one lands on is undecided. 03 named the two the day cell needs
  (`labelMedium` for the day number, `titleLarge` for the Shift Code) and left them open.
  Sharpest once 04 shows the shell's real widgets.
- **Month editor screen.** `month_editor_view.dart` (121 lines) is unexamined in detail.
  Likely falls out of the mapping table (02), but may hold its own surprises.
- **Verification.** How a plan-only map proves the mapping is right without building —
  and what the build session should run to check itself (`pws -c flutter analyze`, a
  screenshot pass on the emulator). Revisit near 06.
- **`catui` teardown.** The `ShiftColors` carrier is settled (01). What remains unclear is
  the order of removal: the `catui` git dependency, `lib/shared/theme.dart`, and the
  `AppTokens.radius` references that survive in it. Revisit once 02 lands.

## Out of scope

- State management. `flutter_bloc` and every cubit stay as they are.
- Data layer. `libsql_dart`, `shifts_repository.dart`, Turso sync — untouched.
- Italian copy and date formatting (`italian_dates.dart`).
- Any new feature, screen, or behaviour change. This is a like-for-like re-skin.
