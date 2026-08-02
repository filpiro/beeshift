# 04 — Today and current-week highlighting

**What to build:** The glance test. Open the app and know instantly where you are in the month without reading a single date — today is visually distinct, and the week containing today is banded so the days immediately around it stand out.

This is what turns the grid from a table into something you can read in under a second, which is the whole point of replacing the PDF.

"Today" is derived from device-local time — single user, single timezone, no UTC modelling — and, like the grid, it is identified in the Calendar's state rather than decided inside a widget, so it can be asserted directly. Recomputing it when the app comes back to the foreground is a later ticket; here it is established once per load.

**Blocked by:** 03.

**Status:** ready-for-agent

- [ ] Today's cell is visually distinct from every other cell
- [ ] The week containing today is highlighted as a band across all seven of its cells
- [ ] Both are identified in state, and are assertable with an injected "now"
- [ ] With an injected "now" on the first of a month, the current-week band correctly covers filler days belonging to the previous month
- [ ] With an injected "now" on the last day of a month, the band correctly covers filler days belonging to the following month
- [ ] Highlighting is independent of whether the day has a Shift recorded
