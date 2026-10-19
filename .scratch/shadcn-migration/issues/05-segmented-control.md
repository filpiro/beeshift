# 05 — Choose the one control that replaces CatSegmented

Type: grilling
Status: resolved
Blocked by: 02
Map: ../map.md

## Question

`CatSegmented` is the last catui widget in `lib/` and has four uses across two very
different jobs:

- **Settings — Theme Mode.** `settings_view.dart`: three mutually exclusive options
  (`Chiaro` / `Scuro` / `Sistema`), single-select, applies on tap.
- **Calendar — Filter.** `calendar_view.dart` `_FilterControls` / `_FilterLetter` /
  `_FilterGroup`, alongside `equal_row_segmented.dart` and `picked_style.dart`. These are
  shift-type filters that carry the Shift Colours and read as coloured letters.

Ticket 02 will have listed the shadcn candidates (`tab_list`, `tabs`, `multiple_choice`,
`chip`, `button` toggle group). Grill the user to decide:

1. Are these one control or two? The Settings case is a plain single-select;
   the Filter case is colour-bearing and may be multi-select. Forcing both into one widget
   may be false economy — but two widgets is two things to maintain.
2. Does the Filter keep its coloured-letter look, or does it become standard shadcn chips
   or toggle buttons and give that look up?
3. What happens to `equal_row_segmented.dart` and `picked_style.dart` — deleted, or kept
   as the Filter's layout with shadcn tokens inside?

Use `/grilling` and `/domain-modeling`. Do not answer on the user's behalf.

## Answer

Resolved 2026-09-23 by grilling; the user took every recommendation.

**The ticket's premise was stale.** `CatSegmented` has **one** use, not four:
`settings_view.dart:31` (Theme Mode). The Calendar Filter is `FilterChip` ×13
(`calendar_view.dart:290`, already mapped to `Toggle` in 02 row 10), and
`EqualRowSegmented` serves the Month Editor (`month_editor_view.dart:98`), not the
Calendar. So "one control or two" was already answered by the code: the Filter and the
Month Editor share a *look* (`pickedStyle`), not a widget, and Theme Mode shares neither.

1. **Settings — Theme Mode → `Tabs(expand: true)`.** Three `TabItem(child: Text(...))`
   for Chiaro / Scuro / Sistema; `index: mode.index`, `onChanged: (i) =>
   cubit.set(ThemeMode.values[i])` (shadcn's `ThemeMode`, same enum order — 02).
   Shipped, equal shares, reads as a segmented control. Theme Mode has no Shift Colour,
   so the coloured-letter look does not apply. Rejected: `ButtonGroup` of
   `OutlineButton`s (hand-rolled selected state), `MultipleChoice` (no exported item
   widget), `TabList` (no `expand`).
2. **Filter keeps its coloured-letter look.** `FilterChip` → `Toggle(value:, onChanged:,
   child: Text(code, semanticsLabel: label), style: pickedStyle(...))`. Like-for-like
   re-skin: the Shift Colour is identification, not decoration (CONTEXT.md).
3. **Both custom widgets survive.**
   - `equal_row_segmented.dart` stays the Month Editor's single-select, one-line,
     equal-width row. `OutlinedButton` → `OutlineButton`; `minimumSize: Size(0, 48)` →
     a `ConstrainedBox`/`SizedBox(height: 48)` around it; `AppTokens.segmentGap` → a
     literal gap; `catui` import dropped. The in-button `Semantics(selected:)` stays.
   - `picked_style.dart` keeps its contract (no fill; hairline border and bold letter in
     the Shift Colour when picked; quiet outline and `mutedForeground` at normal weight
     when not). **New return type: one shadcn `ButtonStyle`** — `ButtonStyle.outline()`
     composed with `.withForegroundColor(...)` / `.withBorder(...)` (button.md
     example 17) — fed to both `Toggle.style` and `OutlineButton.style`. It takes
     `ThemeData` (shadcn's) and reads `colorScheme.border` / `.mutedForeground` in place
     of `outlineVariant` / `onSurfaceVariant` (02 row 18). The label text scale stays
     with the open typography fog.

After this, `CatSegmented` has no replacement left to choose; its last use goes with
`catui`.
