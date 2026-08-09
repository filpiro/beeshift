# 15 — The Filter is always on screen

**What to build:** Both filter groups drawn unconditionally above the month title, no disclosure and no summary, under headings that say what they do.

Ticket 14 made the Filter discoverable by giving it a name and a home. It kept one thing back: the controls themselves, behind a chevron. A collapsed `Filtri` tile is a promise of a control rather than a control, and the price of the promise is a subtitle whose whole job is to say, in bare letters, what the chips would have said plainly had they been on screen. Two representations of one selection, one of them lossy — `S` for Smonto and `S` for Sabato both — plus a clear-all that exists only because the taps that undo a selection are behind the chevron too.

So the disclosure goes. Both `_FilterGroup`s render unconditionally, above the month title. Reading order becomes: how the Calendar is narrowed, what month you are looking at, the days. The controls are the top chrome and the Calendar is one block below the title, rather than the title being orphaned between two clusters of chrome.

The headings say what tapping does: `Filtra per turno` over the six Shift Codes, `Filtra per giorno` over the seven weekday initials. `Turni` and `Giorni` named their contents; these name their effect, which is what a control that is permanently visible has to earn its rows with. The headings still settle the `S` collision, which is the reason they cannot simply be dropped to buy the space back.

`_FilterPanel` becomes `_FilterControls` — "panel" meant the disclosure. Its `_summary` goes with the subtitle: thirteen chips each announcing their own Italian name and selected state make a summary of them noise, and there is nothing left that draws a code without a heading over it. `Azzera` goes too, and `CalendarCubit.clearFilter` with it — every chip is one tap from off, and a fourteenth control competing with the thirteen costs more than the taps it saves.

Ticket 14's clause 9 is moot rather than overturned: `_FilterControls` is stateless and there is no expansion state to hold anywhere, in the widget or in `CalendarState`.

The cost, accepted with open eyes: two headings and two chip rows are permanent, about four rows, where the shut panel cost one. The grid gets what is left and its tiles shrink on every screen. `_MonthGrid` already sizes to its box and `FittedBox` already scales the tiles, so the shrinkage is a smaller tile and never an overflow.

Out of scope: any change to what muting looks like, to the OR/AND rule, to the Empty-day rule or to the Filter's lifetime. The weekday header stays inert. `CONTEXT.md` needs no edit and there is no ADR, for the reason ticket 14 gave — where the controls sit is layout, not a new term and not a trade-off that is hard to reverse.

**Status:** done

- [x] Both filter groups are on screen when the Calendar opens, with nothing to expand and no `ExpansionTile` anywhere
- [x] The groups sit above the month title, which sits above the weekday header, which sits above the grid
- [x] The headings are `Filtra per turno` over six Shift Code chips and `Filtra per giorno` over seven weekday-initial chips
- [x] No `Filtri` title, no subtitle, no summary of the selection in any form, spoken or drawn
- [x] No `Azzera`, and `CalendarCubit.clearFilter` no longer exists
- [x] Tapping a chip still mutes and unmutes exactly as ticket 13 left it, and the two groups still combine OR within and AND across
- [x] A selection survives swiping between the two months
- [x] A six-row month on a short screen still fits: the tiles shrink and nothing overflows
- [x] Every chip announces its full Italian name — `Notte`, `Martedì` — and its selected state
- [x] The weekday header is still seven inert initials with no tap action
- [x] Nothing about the Filter is written to disk

## Comments

Shape agreed in a grilling session, reopening ticket 14's presentation only. Ticket 14 stays `done` and unedited — it is a true record of what shipped, and its clauses 21, 25, 26 and 27 being retired here is worth keeping legible.

Group keys still derive from the heading, so they moved with it: `Key('Filtra per turno')` and `Key('Filtra per giorno')`. Decoupling them would add a parameter to save one test file some churn, when the derivation exists precisely so the two cannot drift.

Chips stay left-aligned under a centred month title. Centring six chips over seven would give two ragged rows aligned with nothing, and a labelled group is read from its left edge.

Not verified on the emulator — widget tests only.

`flutter analyze` clean, 89 tests pass.

### Review

Two-axis review of the diff. Both axes independently found the same hole, and it was the only one worth acting on: deleting the subtitle and `Azzera` tests took the assertions with them, so nothing left in the suite checked a *shift* chip's selected state, and the two "no summary, no clear-all" clauses were guarded only by `find.byType(ExpansionTile)` being empty — a subtitle or an `Azzera` button reintroduced outside a disclosure would have passed. The semantics test now taps both chips and asserts both, and the opening test asserts `Filtri` and `Azzera` are absent by name.

Raised and left alone. The two chip loops are the same five-argument shape twice, but the duplication predates this ticket and both copies fit on one screen. `shiftFilter`/`weekdayFilter` now travel as a pair through a fourth site; `CONTEXT.md` does name **Filter** as one concept, so a type exists in the domain that the code lacks — still not worth minting here, for the reason ticket 14 gave. Untested and knowingly so: that the tiles *shrink* rather than merely fit, that the weekday header sits above the grid, and that nothing about the Filter reaches disk — all three as ticket 13 and 14 left them.
