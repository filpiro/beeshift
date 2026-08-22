# 06 — The Calendar in its new clothes

**What to build:** The last pass over the Calendar and the Filter, so both look like they were drawn with the rest of the app rather than inherited from it. Behaviour is frozen: this ticket may not change a single thing the user can do.

The day tiles take the shared corner radius instead of their own number, today's fill and the outline on every other tile come from the palette, and the reduced opacity that marks a filler or muted day is the one it already is. Today is still the only filled tile, and still only on the page that owns the day.

The Filter's two groups stay two groups of chips under the same two headings, multi-select, no check marks, each announcing its Italian name. Ticket 02 gave them the app's corners; anything left that still reads as framework default — a stray tint, a size that fights the rest of the screen — is settled here.

The month title, the seven inert weekday initials, the swipe between the two months and pull-to-refresh are all untouched.

If nothing is left to do after ticket 02, close this as done and say so. It exists so the check happens, not so a diff does.

**Blocked by:** 02, 03

**Status:** done

- [x] Day tiles use the shared corner radius and take every colour from the palette
- [x] Today is still filled in the accent, still only on the page that owns the day
- [x] Filler and muted days are dimmed exactly as before, and never dimmed twice
- [x] Both filter groups still draw the same chips under the same headings, still multi-select, still without check marks
- [x] Every chip still announces its full Italian name and its selected state
- [x] The OR-within, AND-across rule and the Empty-day rule are unchanged
- [x] A six-row month on a short screen still fits above the Bottom Bar with nothing overflowing
- [x] Swipe, pull-to-refresh, the resume refresh and the month title all behave as before
- [x] The whole suite passes with no assertion about behaviour rewritten

## Comments

Only one spot still read as framework default: the day tile's `BorderRadius.circular(12)` in `lib/features/calendar/calendar_view.dart`, a number of its own rather than the shared one. Swapped for `AppTokens.radius` (10). Everything else the ticket asks for was already true post-ticket-02: fill/foreground/outline already come from `theme.colorScheme` (catui's palette), the Filter's chips already carry the app's corner radius via the `chipTheme` override in `theme.dart`, and the 0.35 dimming opacity is untouched. `flutter analyze`: clean. `flutter test`: 98/98 passed. Verified on the emulator (`emulator-5554`): today's tile fills in the accent, day tiles and chips share the same rounding, filler days stay dimmed.
