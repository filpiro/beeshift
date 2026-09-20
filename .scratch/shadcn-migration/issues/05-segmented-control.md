# 05 — Choose the one control that replaces CatSegmented

Type: grilling
Status: open
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

<!-- filled on resolution -->
