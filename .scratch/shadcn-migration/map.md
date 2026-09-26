# Map: catui/Material → shadcn_flutter migration

Status: done
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
   *Superseded by 07: shadcn palette, one table per brightness.*

## Decisions so far

<!-- one line per resolved ticket -->

- [01 — Theme configuration](issues/01-theme-configuration.md) — `ShadcnApp(theme:, darkTheme:, themeMode:)` mirrors `MaterialApp`, so the switch survives untouched. `ThemeData(colorScheme: ColorSchemes.lightSlate/.darkSlate, radius: 0.75, scaling: 1.0, density: Density.reducedDensity, surfaceOpacity: 1.0, surfaceBlur: 8.0)`; Amber layered via `ColorScheme.copyWith`, whose params are `ValueGetter<Color>?` — closures, not colours. shadcn `ThemeData` has **no `extensions` slot**, so `ShiftColors` becomes a top-level `const Map<ShiftType, Color>` and the `ThemeExtension` is deleted (3 call sites). Mocha hexes captured. "Rounded" and "Medium" have no API constants — 0.75 / 8.0 are proposals, and `surfaceOpacity: 1.0` will hide the blur anyway.

- [02 — Component mapping](issues/02-component-mapping.md) — 20 of 22 rows map cleanly against the 0.0.54 dartdoc. `AppBar` is both a class and a `Scaffold(headers: [...])` slot; buttons are `PrimaryButton`/`TextButton`/`OutlineButton`/`IconButton.ghost`; `SnackBar`→`showToast`; icons are `LucideIcons`. **A 100% Material-free `lib/` is reachable**, and the only thing standing in the way is the `ShiftColors` `ThemeExtension` — so standing decision 4 is load-bearing, not tidy-up. All three custom widgets survive; none has a shipped replacement. `picked_style.dart` is the hardest rewrite: every token it reads is absent from shadcn's ThemeData and it must return a `ButtonStyle`. shadcn ships its own `ThemeMode` with identical enum names, so `ThemeCubit`'s saved preferences stay valid — import swap only. No `Segmented*` symbol exists anywhere in the package.

- [03 — Prototype the month grid and day cell](issues/03-prototype-month-grid.md) — **The hand-rolled `_MonthGrid` / `_DayCellView` stay.** shadcn's `Calendar` exposes only `stateBuilder` returning a `DateState` (enabled/disabled/selected) — no day-cell builder, no per-day colour, nowhere for the Shift Code — and it exists to select dates, which the Calendar page never does. The swap is narrow: `AppTokens.radius`→shadcn radius, `outlineVariant`→`ColorScheme.border`, `primary`→the Amber accent, textTheme slots left to token mapping. **`density: Reduced` never reaches the cell** — its insets are literals over a `LayoutBuilder` side, and the cell has no gesture handling, so no tap target shrinks. **Every frozen hue gains ~22% contrast** on `darkSlate`'s `#020817` vs Mocha's `#1e1e2e`; weakest is secondo blue at 9.50:1. The Shift Colour paints the *letter* and today's *border*, not a slab behind the day number. [Prototype](https://claude.ai/artifact/VAfxwB38vcADAGjgFvAR1Q) is HTML, not Flutter — the map adds no dependency — so 02's "const map at all three call sites" is recorded in the spec, not demonstrated.

- [04 — Prototype the shell](issues/04-prototype-shell-chrome.md) — **`FloatingBottomBar` stays**, reskinned to `card`/`border`/Amber tokens; shadcn `NavigationBar` is a flat full-width strip with no insets. **`barReserve` contract holds**: shadcn `Scaffold` never touches `viewPadding`; the bar stays in the Shell `Stack`, not `footers:` (that double-counts the inset). Settings/Month Editor use `headers: [AppBar, Divider]`, and their body `SafeArea` must be `top: false` — shadcn `AppBar` already takes the top inset. Calendar gets `headers: []`. Toast moves to `ToastLocation.topCenter`, overriding 02 (bottomLeft sits under the bar). [Prototype](https://claude.ai/artifact/SzSfXu8B5xt3JmukuXAJ7p).

- [05 — Choose the control that replaces CatSegmented](issues/05-segmented-control.md) — Premise was stale: `CatSegmented` has one use (Settings Theme Mode); the Filter is `FilterChip`, and `EqualRowSegmented` is the Month Editor's. **Theme Mode → `Tabs(expand: true)`**, index ↔ `ThemeMode.values`. **Filter → `Toggle`, keeps coloured letters.** **`EqualRowSegmented` and `pickedStyle` both survive**; `pickedStyle` now returns one shadcn `ButtonStyle` (outline + Shift Colour foreground/border) shared by `Toggle` and `OutlineButton`.

- [07 — What colour is a shift in Light mode?](issues/07-light-mode-shift-colours.md) — **Neither Latte nor Mocha: shadcn's own palette.** Orange / blue / violet / teal / green / pink; shade 300 in Dark, 700 in Light; all pass AA. `ShiftColors` becomes a class of two `const` maps with `of(context)` reading `Theme.of(context).brightness`. Replaces standing decision 4 and 01's single table. Accepted risk: `primo` orange sits near Amber.

- [06 — Write the migration spec](issues/06-write-the-spec.md) — **[Spec](spec.md) locked; build tickets 08 → 10.** Fresh-install theme stays `system`. Overrides 05: the Filter is a `Button` + `pickedStyle`, because `Toggle` forces a filled style when on. Settings tabs map by an explicit list (enum order differs). Month Editor strips the top inset itself. Typography by nearest size.

- [08 — Swap lib/ to shadcn_flutter](issues/08-swap-lib-to-shadcn.md) — **`lib/` is Material- and catui-free; `analyze lib` clean.** Four package deviations: `RefreshTrigger` only hears depth-0 scrolls, so it now wraps each `_MonthGrid` (spec §9 fallback, applied up front); `ButtonVariance.outline` fills at rest, so `pickedStyle` forces a transparent background; `withForegroundColor` reverts on hover/focus, so the bar pins those too; ghost's disabled colour equals idle, so the bar sets `disabledColor` to dim. UI tests still fail — ticket 09.

- [10 — Verify on the emulator, then update the docs](issues/10-verify-and-docs.md) — **Migration verified on screen, Dark and Light; user accepted.** Fixed invisible status-bar icons in Light (`AnnotatedRegion` in `ShadcnApp.builder`) and widened the floating bar's padding and icon gaps. ADR-0006 and `CONTEXT.md` written; ADR-0004 (look) and 0005 marked superseded.

## Not yet specified

Nothing. The way is clear; see the [spec](spec.md) and build tickets 08–10.

## Out of scope

- State management. `flutter_bloc` and every cubit stay as they are.
- Data layer. `libsql_dart`, `shifts_repository.dart`, Turso sync — untouched.
- Italian copy and date formatting (`italian_dates.dart`).
- Any new feature, screen, or behaviour change. This is a like-for-like re-skin.
