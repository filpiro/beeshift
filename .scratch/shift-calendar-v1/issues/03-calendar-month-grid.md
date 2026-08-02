# 03 — Calendar month grid

**What to build:** A real Calendar for one month, replacing the throwaway list. Open the app and see the current month laid out as a proper grid, with each day showing its number and — where a Shift is recorded — its Shift Code.

Weeks run Monday to Sunday, and every row is a full seven days, so the month's leading and trailing edges are padded with days from the adjacent months. Those filler days are not blank placeholders: because Shifts are never purged, last month's data is still there, and showing it dimmed gives the continuity that makes a Rotation readable. Filler days with nothing recorded simply come back empty, from the same code path.

One query per load, spanning the **entire visible grid** rather than the exact month bounds — that is what makes the filler data available without a second fetch.

The computed grid — which cells exist, which are filler, what each one shows — belongs in the Calendar's state, not in the widget. That is what makes it reachable from the project's primary test seam, and it is the reason this ticket also establishes the testing conventions everything after it follows.

**Blocked by:** 02.

**Status:** done

- [x] The current month renders as a grid with day numbers and Shift Codes
- [x] Weeks start Monday; every row has exactly seven cells
- [x] Filler days from adjacent months render their Shift Code dimmed, and render empty when nothing is recorded
- [x] Exactly one query per load, covering the whole visible grid rather than the month bounds
- [x] The grid is exposed by the Calendar's state, so it can be asserted without rendering a widget
- [x] The primary test seam exists: a fake repository implementing the concrete repository's implicit interface, with "now" injected rather than read from the system clock
- [x] Grid shape is tested through state for a month starting on a Monday, one starting on a Sunday, and a 28-day February
- [x] Day cells have no gesture handling of any kind

## Comments

Built as `CalendarCubit` (`lib/calendar_cubit.dart`) holding `List<DayCell>?`
— null until the first load — plus `CalendarPage` (`lib/calendar_page.dart`),
which only draws what the state already decided. `flutter_bloc` added, per the
spec's state-management decision.

Grid dates come from `DateTime(year, month, i + 1 - leading)`: out-of-range
days normalise into the adjacent month, so there is no `Duration` arithmetic
and therefore no daylight-saving drift.

The fake repository lives at `test/fake_shifts_repository.dart` and records
every range it was asked for, which is how the one-query-per-load assertion
works. It will carry the sync-ordering assertions in 06.

Grid shapes covered: June 2026 (Monday start), February 2026 (Sunday start,
six leading filler days) and February 2027 (28 days on a Monday — the only
shape with no filler at all).

**Verified on the emulator, and 02's rendering problem is gone.** The Pixel 9
emulator (Android 16, API 36) draws the grid correctly — 02's Impeller
`Requested texture size (1, 1)` failure did not reproduce, and `sync()` did not
hang either. August 2026 renders as six rows starting Saturday, with 27–31 July
and 1–6 September dimmed at the edges, and the `N` `S` `R` that 02 hand-inserted
into Turso showing on the 3rd to the 5th. Screenshot taken via
`adb exec-out screencap`.

`flutter analyze` clean, nine tests pass.

### Review

Two-axis review run against the ticket and the spec. No missing or partial
requirements on either axis, and no hard standards violations.

Acted on: an `int` named `cells` inside `_gridDates` shadowed the meaning
"cells" carries everywhere else (a list of `DayCell`) — renamed `cellCount`.

Raised and deliberately left: `main.dart` still awaits `sync()` on cold start,
which the spec rules out as a trigger. It is 02's line, and 06 owns sync
triggers; removing it now would leave the app with no sync at all until 06
lands. Recorded on 06 as an explicit deletion step.

Raised and rejected: that whole-cell `Opacity` dims a filler day's number as
well as its Shift Code, where the ticket only asks for the Code to be dimmed.
The emulator screenshot shows filler numbers still legible at 0.35, and dimming
the whole cell is what makes the edges read as adjacent months.
