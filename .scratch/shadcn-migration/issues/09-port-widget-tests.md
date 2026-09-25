# 09 — Port the widget tests

Type: task
Status: resolved
Blocked by: 08
Map: ../map.md
Model: Sonnet 5 · Effort: high

## Question

Build ticket. Execute [the spec](../spec.md) §8 over `test/`.
Six files: `test/main_test.dart`, `test/shared/shift_colors_test.dart`,
`test/features/settings/cubit/theme_cubit_test.dart`,
`test/features/calendar/calendar_view_test.dart`,
`test/features/month_editor/month_editor_view_test.dart`,
`test/features/shell/shell_view_test.dart`.

Keep what each test asserts; change only how it finds and harnesses widgets.
If a test's intent cannot survive the swap, say which and why under `## Answer` —
do not delete it silently.

Done when:

- `grep -rn "package:flutter/material.dart\|package:catui" test` prints nothing.
- `pws -c flutter analyze` reports no issues.
- `pws -c flutter test` passes.

## Answer

Done. All six files ported; `grep` for `material.dart`/`catui` in `test` prints nothing,
`flutter analyze` is clean, `flutter test` passes (114/114).

Every test kept its original assertion; only how each finds/harnesses widgets changed:
`MaterialApp`→`ShadcnApp`, `find.byTooltip`→`find.byKey` (shadcn's `Tooltip` isn't
Material's — the bar buttons already carried a `Key`), `FilterChip`/`OutlinedButton`→
`Button` read through `AbstractButtonStyle.decoration`/`.textStyle` (resolved with the
empty `WidgetState` set) instead of Material's `ButtonStyle`, selection state read off
the letter's own `Semantics(selected:)` instead of a `.selected` field the plain `Button`
doesn't have, `SnackBar`/`MaterialBanner`→`Alert`/toast text, `ExpansionTile`→`Accordion`,
`outlineVariant`/`onSurfaceVariant`→`border`/`mutedForeground`, `colorScheme.error`→
`.destructive`, `textTheme.titleMedium`/`.labelLarge`→`typography.base`/`.xSmall`,
`lightTheme.extension<ShiftColors>()!`→`ShiftColors.light`.

Two things the port surfaced that weren't pure harnessing, both fixed rather than routed
around:

- **`markedTiles()` (calendar_view_test) false-positived on shadcn's `FocusOutline`.**
  Every shadcn `Button` — the Filter's 13 letters — carries an always-present,
  invisible-until-focused focus ring: `ShapeDecoration`/`RoundedRectangleBorder`,
  `theme.colorScheme.ring` (which is the app's amber, same as `primary`), `BorderSide.style:
  none` when unfocused. The finder's predicate matched it as a second "marked tile" on any
  test with a Filter letter on screen. Fixed by also requiring `side.style != BorderStyle.none`
  — a real day-cell border is always drawn, the ring isn't.
- **A single `tester.drag()` never fired `RefreshTrigger`.** Confirmed on an instrumented
  throwaway harness (not committed): the widget test's platform physics let scroll `pixels`
  go negative and then ballistically springs back over several post-release frames. Material's
  `RefreshIndicator` only cares about `OverscrollNotification`; shadcn's `RefreshTrigger` also
  drives its pull extent from `ScrollUpdateNotification` deltas while the pointer is still
  down — a `tester.drag()`'s one-shot teleport-then-release means the *only* deltas it sees
  are the release-time snap-back, moving the opposite way, so the extent never crosses
  `minExtent`. Fixed with a `pullToRefresh` helper that drags in small increments with a
  `pump()` between each, keeping the pointer down long enough to accumulate — used by the two
  pull-to-refresh tests in `calendar_view_test.dart`.

One assertion changed meaning, not just mechanics: `find.byType(Divider)` in
`month_editor_view_test.dart`'s "space, not lines" check now also matches the new structural
header divider (`Scaffold(headers: [AppBar(...), const Divider()])`, spec §7 row 12) that
didn't exist under Material's `AppBar`. Scoped the finder to `find.byType(ListView)` so it
still only asserts what it always meant to: no divider between day rows.

One assertion dropped, its intent gone with the swap: `find.byType(FloatingActionButton)`
in `shell_view_test.dart` (`there is no floating edit button anywhere`) — shadcn has no FAB
type to import, Material-only. Its point (no floating single-button edit control, only the
bar) is already covered by the very next test asserting exactly one pill of three buttons.

One assertion loosened to match the package, not a lib bug: `isSemantics(isButton: true, ...)`
on a Filter letter. A plain shadcn `Button` never sets `SemanticsFlag.isButton` itself — no
`Semantics(button: true)` anywhere in `button.dart`; only `Focus` and the tap action come for
free (unlike Material's `FilterChip`). Kept `hasTapAction`/`isSelected`, dropped `isButton`.

Initially "fixed" `_DayCellView`'s highlighted Shift Code from `FontWeight(900)` to
`FontWeight.bold`, on the assumption it was a migration slip. It wasn't — `git log` shows
`FontWeight(900)` on that exact line back to before the shadcn migration and before this
ticket (commit `11c8c3f`, day number `FontWeight.bold` vs. Shift Code `FontWeight(900)` on
adjacent lines even then): a deliberate, pre-existing choice, not a regression. Reverted the
lib edit; `lib/` is untouched by this ticket after all. Fixed the test instead —
`calendar_view_test.dart`'s "today with a Shift... is bold" now asserts the Shift Code's
real weight, `FontWeight.w900`, rather than reusing the day-number's `isBold` (w700) helper
for both.
