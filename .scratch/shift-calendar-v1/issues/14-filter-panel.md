# 14 — Making the Filter a control you can see

**What to build:** A collapsible `Filtri` panel under the month title holding both filter groups, and a weekday header that goes back to being a header.

Ticket 13 shipped the Filter's behaviour and it is right — nothing about muting, the OR/AND rule, the Empty-day rule or the never-stored rule changes here. What it got wrong is the chrome. The Weekday Filter was folded into the weekday header on the reasoning that seven letters already on screen beat seven more; the cost, unaccounted for, is that those letters look exactly like what they are — column headings — and nothing on the screen suggests they can be tapped. A filter you have to already know about is not a filter. On top of that the two groups spoke in different idioms, chips above and bare letters below, so they never read as one control, and nothing named them, grouped them, or said at a glance that a filter was on.

So: the weekday header reverts to inert text — no `InkWell`, no tap action, no selected state — and both groups move into one panel that announces itself. Ticket 13's "no second row of weekday letters anywhere" is retired deliberately. Two ways to set the same filter would be worse than one, and duplicating the seven letters is the price of a control that is visible.

The panel is an `ExpansionTile` titled `Filtri`, collapsed on open, sitting between the month title and the weekday header. Reading order is what am I looking at, then how is it narrowed, then the days. Collapsed it costs about one row — less than the two rows it replaces, so the grid is roomier shut than it is today. Expanded it pushes the grid down rather than floating over it; `_MonthGrid` already sizes to whatever box it gets, and an overlay covering the days you are filtering would defeat the point.

Selections show as the tile's `subtitle`, comma separated, shifts first: `N, S, M`. Nothing selected means no subtitle and no wasted row, which is also the answer to "is a filter on?" without opening anything. `Azzera` sits in the tile's `trailing` slot and appears only when something is selected — the chevron moves to `leading` via `controlAffinity` to make room, so clearing works while the panel is shut. Ticket 13 left clear-all out pending evidence the taps annoy; they annoy.

Inside, two labelled rows: `Turni` over the six Shift Codes, `Giorni` over the seven weekday initials, both `FilterChip`s in the same idiom now that nothing has to stay centred over a column. The labels are what separate the groups — a heading each and the whitespace between them, no borders. They also settle the one collision the shared idiom creates: `S` is Smonto under `Turni` and Sabato under `Giorni`, and the heading above each row says which. The two `M`s stay two `M`s: `L M M G V S D` in fixed order is what the header over these columns has always shown, position disambiguates them there and still does here, and a screen reader says `Martedì` and `Mercoledì` regardless.

Expansion is widget-local state, not `CalendarState`. Whether a disclosure is open is not something a read-only Cubit over Shifts and the Filter should be able to answer. The panel lives outside the `PageView`, so it survives swiping between months either way.

Out of scope: any change to what muting looks like, to the truth table, or to the Filter's lifetime. `CONTEXT.md` needs no edit — its **Filter** and **Matched/Muted** entries describe behaviour and never said where the controls live, so they read correctly unchanged. No ADR: no new term, and moving controls into a disclosure panel is layout, not a trade-off that is hard to reverse.

**Status:** done

- [x] An `ExpansionTile` titled `Filtri` sits between the month title and the weekday header, collapsed when the Calendar opens
- [x] The weekday header's seven letters have no tap action, no selected state and no button semantics — they are headings again
- [x] Expanding reveals a `Turni` row of six Shift Code chips and a `Giorni` row of seven weekday-initial chips, each row under its own heading
- [x] Both rows are `FilterChip`s and a selected chip in either uses the same selected colour, leaving `primary` meaning today and nothing else
- [x] The tile's subtitle lists the selected codes comma separated, shifts before weekdays, and is absent when nothing is selected
- [x] The subtitle is *spoken* as the full Italian names — the one place a code has neither a heading nor a row position to be read by
- [x] `Azzera` appears in the tile's trailing slot only when something is selected, clears both groups, and is reachable without expanding the panel
- [x] Expanding pushes the grid down; the grid reflows and never overflows
- [x] Expansion state is held by the widget, not `CalendarState`, and swiping between the months leaves the panel open and its selection intact
- [x] Every chip announces its full Italian name — `Notte`, `Martedì` — and its selected state to a screen reader
- [x] `CalendarCubit` and `CalendarState` are unchanged: `muted`, `toggleShift` and `toggleWeekday` keep their current behaviour and their current tests pass untouched
- [x] `calendar_page_test.dart` finds weekday chips by scoping to the `Giorni` group rather than by bare label
- [x] Nothing about the Filter is written to disk

## Comments

Shape agreed in a grilling session, reopening ticket 13's presentation only.

Ticket 13 stays `done` and is not rewritten — it is a true record of what shipped and why, and the reasoning being overturned here is worth keeping legible.

`ExpansionTile` rather than a hand-rolled header plus `AnimatedSize`: header, rotating chevron, animation and `onExpansionChanged` all come free. `controlAffinity: ListTileControlAffinity.leading` is what frees `trailing` for `Azzera`, since `trailing` otherwise replaces the chevron.

Weekday chips keep single letters rather than moving to `Lu Ma Me`. Two-letter abbreviations would kill the `M`/`M` ambiguity outright, but they read badly and the group headings already handle the collision that actually matters, which is `S` across the two groups.

Not verified on the emulator — widget tests only.

`flutter analyze` clean, 91 tests pass.

### Review

Two-axis review of the diff.

The Spec axis killed one acceptance criterion outright: "the panel does not rebuild when the carousel changes page" was false and ticked on nothing. `_FilterPanel` is built inside the page's single `BlocBuilder`, `showPage` emits a new `CalendarState`, and `CalendarState` has no `==` — so every swipe rebuilds it. What actually matters is that the `ExpansionTile`'s own state survives, which it does by element reuse. The criterion now says the true thing and a test proves it: swipe, and the panel is still open with its chip still selected.

Both axes independently found the subtitle. It drew bare letters and was read aloud as bare letters, which is the one place in the app a Shift Code has neither a heading nor a fixed row position to be decoded by — a lone `S` is Smonto or Sabato, a lone `M` is either weekday. `_summary` now takes a `spoken` flag and the tile carries the Italian names as its `semanticsLabel`. The letters stay on screen: that was settled deliberately, and the residual ambiguity is visual only.

Left as designed, not fixed: the *visible* subtitle still shows a bare `S`. Spelling it out would either double the tile's width or need per-group prefixes, both of which were considered and rejected before any code.

Also acted on: `_ChipGroup` was named for its Material primitive rather than the domain and is now `_FilterGroup`, deriving its key from its heading so the string cannot drift between the two; the weekday-header comment narrated diff history and now states the design; the Martedì/Mercoledì pair — the whole justification for keeping single letters — was never asserted and now is.

Raised and left alone: `weekdayNames[day][0]` now appears three times in one file, but the helper that would fold it away would fight `italian_dates.dart`'s stated reason for having no separate list of initials. `shiftFilter`/`weekdayFilter` travel as a pair through one more site than ticket 13 counted; still one class, still not worth a `Filter` type.

The old widget tests counted `FilterChip`s and located them by bare label, which thirteen chips break twice over — the count is wrong and `'S'` matches two chips meaning different things. Every chip finder is now scoped to its group's key.

`flutter analyze` clean, 91 tests pass.
