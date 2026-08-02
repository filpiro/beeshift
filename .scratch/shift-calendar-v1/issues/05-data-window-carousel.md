# 05 — Data Window carousel

**What to build:** Swipe horizontally to move between this month and next month, and stop there. Two pages, not infinite paging — the Data Window is the current month plus the following one, and there is nothing beyond it to page to.

Both pages are served by the load that already happened; the query range widens to cover both months' visible grids rather than firing a second fetch on swipe. Which page is showing becomes part of the Calendar's state, because the next tickets depend on it: the editor targets the visible month, and resume has to re-derive the window when the real-world month rolls over.

Note that the Data Window is a *viewing* rule only. Shifts outside it are retained and are never purged — they are simply not reachable in v1.

**Blocked by:** 03.

**Status:** done

- [x] Swiping left and right moves between the current month and the next month
- [x] Paging stops at both ends; there is no third page
- [x] Today and current-week highlighting behave correctly on both pages, including when today's week straddles the boundary between them
- [x] The visible month is exposed in state
- [x] Both pages render from a single load, with no fetch triggered by swiping
- [x] The derived window is asserted against an injected "now", including a December "now" where the next month falls in the following year

## Comments

The state stopped being a bare `List<DayCell>?` and became `CalendarState`:
the Data Window's two `months`, one grid per month in `grids` (null until the
first load), and `visibleIndex`. `visibleMonth` is a getter over the two, which
is what 07 will target and what 06 will re-derive on rollover.

The next month is `DateTime(now.year, now.month + 1)` — month 13 normalises
into January of the following year, the same trick 03 used for out-of-range
day numbers, so the December case needs no branch of its own.

`_gridDates` took a `month` parameter and is now called once per page. The
query spans `_dates.first.first` to `_dates.last.last`, so both grids arrive
from the single fetch that already happened; `showPage` only emits and never
touches the repository. That is what makes swiping free.

Drawn as a `PageView` with exactly two children, so paging stops at both ends
by construction rather than by clamping an index. The weekday initials stayed
outside the carousel — they are identical on both pages, so sliding them would
be motion that says nothing. The per-month grid moved into `_MonthGrid`.

**Verified on the emulator.** On the Pixel 9 (Android 16, API 36): page one is
August 2026 with today discced and its week banded, swiping left lands on
September (31 August dimmed at the head, 1–4 October at the tail), a second
left swipe is a no-op — the screenshot is byte-identical — and swiping back
returns byte-identically to page one. The device log shows exactly **one**
query across the whole session, which is the no-fetch-on-swipe criterion
observed rather than only mocked.

`flutter analyze` clean, twenty-one tests pass.

### Review

Two-axis review run against the ticket and the spec. No missing or partial
requirements on either axis, no scope creep, and no hard standards violations.

Acted on: a test title escaped an apostrophe where its siblings avoid the
construction; reworded.

Raised and rejected: that `months` is fixed at construction with no note about
going stale in a long session — that is exactly 06's job, and the `_today`
comment already points there. Also that `_dates.first.first` reads as a message
chain; it is indexing a local list of lists, not walking someone else's object.

Noted for later: `_MonthGrid` bands a row by reading `cells[row].isCurrentWeek`
alone, which holds only because rows are whole Monday-first weeks. True by
construction today, and the reviewer was right that nothing states it.
