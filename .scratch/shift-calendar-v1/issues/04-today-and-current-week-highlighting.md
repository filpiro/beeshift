# 04 — Today and current-week highlighting

> **Half superseded by ticket 09.** The current-week band is gone, and so is
> `DayCell.isCurrentWeek` — the flag, its range test, and its tests, not just
> the `ColoredBox` that drew it. Making each day a separate rounded tile left
> the band nothing coherent to paint on: a row-wide stripe behind detached,
> gapped tiles reads as a rendering fault. Today's highlight survives, promoted
> from a stadium disc behind the day number to a filled tile, and is now the
> only highlight the Calendar has. Everything below about `isToday` still
> holds; everything about the band is history.

**What to build:** The glance test. Open the app and know instantly where you are in the month without reading a single date — today is visually distinct, and the week containing today is banded so the days immediately around it stand out.

This is what turns the grid from a table into something you can read in under a second, which is the whole point of replacing the PDF.

"Today" is derived from device-local time — single user, single timezone, no UTC modelling — and, like the grid, it is identified in the Calendar's state rather than decided inside a widget, so it can be asserted directly. Recomputing it when the app comes back to the foreground is a later ticket; here it is established once per load.

**Blocked by:** 03.

**Status:** done

- [x] Today's cell is visually distinct from every other cell
- [x] The week containing today is highlighted as a band across all seven of its cells
- [x] Both are identified in state, and are assertable with an injected "now"
- [x] With an injected "now" on the first of a month, the current-week band correctly covers filler days belonging to the previous month
- [x] With an injected "now" on the last day of a month, the band correctly covers filler days belonging to the following month
- [x] Highlighting is independent of whether the day has a Shift

## Comments

`DayCell` gained `isToday` and `isCurrentWeek`, both decided in `CalendarCubit`
and merely drawn by `CalendarPage`. `_today` is `DateTime(now.year, now.month,
now.day)` — the injected instant flattened to a day, so a "now" carrying a time
of day still matches exactly one cell.

The band is a half-open range test against `_weekStart`.. `_weekEnd` (the Monday
of today's week and the Monday after), not grid-index arithmetic. That is what
makes it correct when the band spills across a month boundary: the filler cells
are inside the range like any other date, so nothing special-cases them. Both
bounds use 03's day-number normalisation (`DateTime(y, m, d - (weekday - 1))`),
so there is still no `Duration` arithmetic and no daylight-saving drift.

Drawn as a per-row `ColoredBox` rather than per cell, so the band reads as one
continuous stripe with no seams between days, plus a filled stadium behind
today's day number. Monochrome scheme colours only — per-Shift-Type colours
remain out of scope.

Edge cases tested at the state seam with dates chosen for their shape:
1 February 2026 (a Sunday, so the band is six January filler days plus the 1st)
and 30 June 2026 (a Tuesday, so it runs five days into July).

**Verified on the emulator.** The Pixel 9 (Android 16, API 36) shows August
2026 with today, Sunday the 2nd, discced, and the band covering 27–31 July
filler plus the 1st and 2nd — the previous-month spill case live rather than
only in a test. The emulator's `/data` was 93% full and rejected the install
(`INSTALL_FAILED_INSUFFICIENT_STORAGE`); lowering
`sys_storage_threshold_max_bytes` cleared it, since the 100 MB debug APK does
fit in the 407 MB free.

`flutter analyze` clean, fifteen tests pass.

### Review

Two-axis review run against the ticket and the spec. No missing or partial
requirements on either axis, no scope creep, and no hard standards violations.

Raised and rejected: the `weekday - 1` idiom now appears twice, in `_gridDates`
and in `_weekStart`, suggested for extraction into a shared `_mondayOf`. The
two shapes differ — the grid needs the offset as a number inside a loop over
day numbers, the band needs an absolute date — so a shared helper would either
re-derive the offset anyway or push the loop back onto `Duration` arithmetic,
which 03 deliberately removed. recorded
