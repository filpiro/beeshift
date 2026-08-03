# 09 — The Calendar as a tile grid

**What to build:** The Calendar stops looking like a bare table and starts looking like a calendar. The month you are on is named at the top, every day is a square tile you can see the edges of, and exactly one tile is filled — today's.

Three things change at once because they are one decision. Making each day a square tile with its own border means the current-week band can no longer be drawn: a row-wide stripe behind detached, rounded, gapped tiles reads as a rendering bug, not as a highlight. So the band goes, and with it `isCurrentWeek` — which is not just a widget change, since the flag is decided in the Calendar's state. Today's tile, filled with the primary colour, is now the only highlight on the screen, and it answers the question the spec actually asks — "what am I on?" — more directly than the band ever did.

Squareness is a ceiling, not a lock. The tile side is the smaller of the width each column gets and the height each row gets, so on a tall phone the grid is square and top-aligned with space left below it, and on a short or landscape screen the tiles compress rather than overflow. The invariant that survives from 03 is the one that matters: the whole month is always on screen, nothing clipped, nothing scrolled.

Today can appear twice in the Data Window — the next month's grid opens with filler days belonging to the current month, which in the last week of a month includes today itself. It is filled only on the page that owns it. A dimmed tile carrying a loud primary fill is neither one thing nor the other, and the highlight belongs to the month it is a day of.

The month name is decided by `visibleMonth` in the Calendar's state and drawn outside the carousel, next to the weekday initials. It swaps when the page settles rather than sliding with the grid — the weekday row underneath it cannot slide, so a sliding title would tear the header in half. It always carries the year, because the Data Window crosses a year boundary every December.

The Italian month and weekday strings currently live inside the Month Editor's file and are about to be needed here too. They move to one file of their own. The weekday-initials list is deleted rather than moved: the first letter of each full weekday name is already exactly `L M M G V S D`.

**Blocked by:** None — can start immediately.

**Status:** done

- [x] The visible month's name and year are shown above the weekday row, and change when the carousel settles on the other page
- [x] Every day is a rounded tile with a visible border, sized to the smaller of its column width and its row height, so it is square at most
- [x] The grid is top-aligned and never overflows, on both a tall phone and a short screen
- [x] The whole month is still on screen with no scrolling and nothing clipped, for both five-row and six-row months
- [x] Today's tile is filled with the primary colour, with its day number and Shift Code drawn in the contrasting on-primary colour
- [x] The stadium disc behind today's day number is gone
- [x] A day that is today but is drawn as a filler day is not filled
- [x] The current-week band is gone from the Calendar, and `isCurrentWeek` is gone from the Calendar's state — not merely unread
- [x] Italian month and weekday names live in one shared file, and the separate weekday-initials list no longer exists
- [x] `spec.md` and ticket 04 record that the current-week highlight was deliberately dropped, and why
- [x] Tests covering the removed band are removed or rewritten, not left asserting a feature that no longer exists

## Comments

`side = min(maxWidth / 7, maxHeight / rows)`, measured once per page in the
`LayoutBuilder` that was already there for the scroll view. The grid is then a
`SizedBox` of `side * 7` by `side * rows`, top-aligned — so squareness is a
ceiling and a short screen compresses the tiles instead of overflowing. The
rows stay `Expanded` inside that box, which keeps the arithmetic in one place.

Each tile is a `DecoratedBox` with a `RoundedRectangleBorder`. Today drops the
outline rather than drawing one on top of its fill. Cell contents sit in a
`FittedBox(scaleDown)`, so the day number and Shift Code shrink rather than
clip when the tiles get small — that is what makes the short-screen case a
layout question instead of a minimum-width question.

`isCurrentWeek` is gone from `DayCell`, and with it `_weekStart`/`_weekEnd` and
the half-open range test from `load`. The four band tests went too; the two
that survived as today-only assertions are the shape ones. `weekdayNames` in
the new `italian_dates.dart` is the full names, and the Calendar's column
headings index into their first letters, so there is no second list to keep in
step. The Month Editor still has its own abbreviated list — ticket 11 deletes
it when it switches to full names.

Ticket 04's band removal is recorded in three places rather than one: this
ticket, a superseded note at the top of 04 itself, and user story 6 in the
spec, which is struck through with the reason rather than deleted. The spec's
Problem Statement is left as written — it is a record of what was true when it
was written, not a live requirement.

**Verified on the emulator.** The Pixel 9 (Android 16, API 36) shows Agosto
2026 with Monday 3 August filled and carrying its `N`, the July filler days
dimmed, and the whole six-row month above the fold with the space below it
empty — which is where ticket 10's FAB goes. Swiping renames the header to
Settembre 2026 and leaves the 31 August filler tile unfilled.

`flutter analyze` clean, 57 tests pass.

### Review

Self-review of the diff, inline. One thing raised and left alone: today's tile
has no semantic label marking it as today, so a screen reader hears a bare day
number. That is not a regression — the stadium disc it replaced had none
either — and it is not this ticket's scope. Worth a ticket if the app ever
needs to be usable without sight.
