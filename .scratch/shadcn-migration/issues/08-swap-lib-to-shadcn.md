# 08 — Swap lib/ to shadcn_flutter

Type: task
Status: resolved
Blocked by: 06
Map: ../map.md
Model: Opus 5.5 · Effort: high

## Question

Build ticket. Execute [the spec](../spec.md) §1–§7 over `lib/` and `pubspec.yaml`.
Read the spec first; read each file before editing it (`CLAUDE.md`).

Order: `pubspec.yaml` + `pws -c flutter pub get`, then spec §7 rows 2–14 top to bottom
(shared files before the pages that use them).

Done when:

- `grep -rn "package:flutter/material.dart\|package:catui" lib` prints nothing.
- `pws -c flutter analyze lib` reports no issues. (`test/` still fails; that is ticket 09.)
- Any place where the package API differs from the spec is noted under `## Answer`.

## Answer

Done. `lib/` has no `material.dart` or `catui` import; `flutter analyze lib` is clean.
Logic tests (cubits, repository) pass: 50/50. The six UI test files fail, as expected
(ticket 09): compile errors on Material/catui types, and `main_test` finds Material's
`CircularProgressIndicator`/`FilledButton` types, not shadcn's.

Where the package differs from the spec (package wins):

- **`RefreshTrigger` moved inside each page.** It ignores any scroll notification with
  `depth != 0` (`refresh_trigger.dart:554`). Around the `PageView`, the only depth-0
  scrollable is the horizontal carousel, so a vertical pull never fires, and a sideways
  overscroll on page one could. Applied the spec's §9 fallback now: each `_MonthGrid`
  is wrapped in its own `RefreshTrigger`. Still confirm on the emulator (ticket 10).
- **`ButtonVariance.outline` fills at rest, not only on hover** (`input.scaleAlpha(0.3)`,
  0.5 on hover; `button.dart:3790`). `pickedStyle` adds
  `.withBackgroundColor(color:, hoverColor:, focusColor: Colors.transparent)`.
- **`withForegroundColor` falls back to the ghost default on hover and focus**
  (`button.dart:3231`). The bar sets `hoverColor` and `focusColor` to the same colour,
  so a focused button keeps its active/muted glyph.
- **Ghost's disabled colour is `mutedForeground`** (`button.dart:3861`), the same as an
  idle bar button, so the spec's "a disabled button still dims" does not hold on its
  own. The bar sets `disabledColor: mutedForeground.withValues(alpha: 0.4)`.
- `theme.dart` doc comment: `ValueGetter<Color>` in backticks (analyzer
  `unintended_html_in_doc_comment`).

For ticket 10 (found in review, not fixed here):

- **Toast may sit under the status bar.** `ToastLayer` pads a fixed
  `baseContainerPadding * 1.5` with no `MediaQuery` (`toast.dart:632`), and the
  Calendar's layer is outside its `SafeArea`. Check on the emulator.
- **Bar tooltips open below the button** (Tooltip default `anchorAlignment:
  bottomCenter`, `tooltip.dart:284`), flipping only on overflow. Check on the emulator.
- `CONTEXT.md` "Shift Colour" still says per flavor / through the theme / yellow (§10).
- `month_editor_cubit.dart:52` comment says "banner"; left alone, spec says no change
  to cubits.
