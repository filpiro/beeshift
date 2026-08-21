# 06 — The Calendar in its new clothes

**What to build:** The last pass over the Calendar and the Filter, so both look like they were drawn with the rest of the app rather than inherited from it. Behaviour is frozen: this ticket may not change a single thing the user can do.

The day tiles take the shared corner radius instead of their own number, today's fill and the outline on every other tile come from the palette, and the reduced opacity that marks a filler or muted day is the one it already is. Today is still the only filled tile, and still only on the page that owns the day.

The Filter's two groups stay two groups of chips under the same two headings, multi-select, no check marks, each announcing its Italian name. Ticket 02 gave them the app's corners; anything left that still reads as framework default — a stray tint, a size that fights the rest of the screen — is settled here.

The month title, the seven inert weekday initials, the swipe between the two months and pull-to-refresh are all untouched.

If nothing is left to do after ticket 02, close this as done and say so. It exists so the check happens, not so a diff does.

**Blocked by:** 02, 03

**Status:** ready-for-agent

- [ ] Day tiles use the shared corner radius and take every colour from the palette
- [ ] Today is still filled in the accent, still only on the page that owns the day
- [ ] Filler and muted days are dimmed exactly as before, and never dimmed twice
- [ ] Both filter groups still draw the same chips under the same headings, still multi-select, still without check marks
- [ ] Every chip still announces its full Italian name and its selected state
- [ ] The OR-within, AND-across rule and the Empty-day rule are unchanged
- [ ] A six-row month on a short screen still fits above the Bottom Bar with nothing overflowing
- [ ] Swipe, pull-to-refresh, the resume refresh and the month title all behave as before
- [ ] The whole suite passes with no assertion about behaviour rewritten
