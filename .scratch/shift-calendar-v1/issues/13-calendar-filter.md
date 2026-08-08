# 13 — Narrowing the Calendar to the days you care about

**What to build:** Two rows of one-letter controls above the grid that dim every day you did not ask for.

The question the Calendar cannot answer today is "when am I on nights next month" — the answer is there, spread over forty-two tiles, and finding it means reading all of them. The Filter answers it by taking everything else away: pick `N`, and every day that is not a Notte drops to the same opacity a day outside the month already has. Nothing moves, nothing disappears, the month keeps its shape — the days that matter are simply the only ones left bright. Picking `N` and `L` together answers "which Mondays am I on nights".

Two groups, and they behave differently on purpose. Within a group the selections are alternatives — `N` and `7` means either. Across the groups they are conditions — a Weekday Filter and a Shift Filter both have to be satisfied. An empty group is not a filter at all and passes everything, which is what makes "nothing selected" mean "the whole month" rather than "nothing".

An Empty day is muted the moment any Filter is on. This is the one rule that has to be stated rather than derived: "no Shift Type selected" means all six of them, not "including the days with none". A day with nothing recorded cannot match a question about Shift Types, and it does not become an answer just because the question was only about weekdays.

The Weekday Filter is the weekday header that is already there. The Calendar draws `L M M G V S D` over the seven columns; those letters become the control rather than gaining a duplicate row of the same seven letters directly above them. That keeps one new row on screen instead of two, and the letters stay centred over the columns they label — which is why they stay a plain tappable letter rather than becoming chips, whose own padding would pull them off the column centres.

Today's tile dims with everything else when it does not match. Its filled tile is the loudest thing on the screen and an exception for it would read as "today matched" — it survives at 0.35 perfectly legibly, and the Filter gets to be one rule with no carve-outs. For the same reason muted and filler are the same visual state and never compound: 0.35 is a floor, not a multiplier.

The Filter is a way of reading, so it never reaches the Month Editor — that screen exists to write, and hiding days you can write to would be a trap. It is also never stored. It lives in `CalendarState` and dies with the process: resume, pull-to-refresh and coming back from the editor all keep it, a restart does not. Nothing is written to disk, which means no storage code, no migration and no stale filter greeting you a week later.

Out of scope, deliberately: a clear-all control (thirteen visible toggles are their own undo — add one only if the taps actually annoy in use), and per-cell day semantics. A screen reader announces a cell as `"13"` then `"N"` today rather than `"13 Notte"`; that gap is real, predates this ticket, and belongs to its own.

**Status:** done

- [x] A row of six `FilterChip`s, one per Shift Code, sits between the month title and the weekday header
- [x] The weekday header's seven letters toggle the Weekday Filter, still centred over their columns, with no second row of weekday letters anywhere
- [x] A selected control in either row is visibly distinct and uses the same selected colour in both, leaving `primary` meaning today and nothing else
- [x] With nothing selected, every day draws exactly as it does now
- [x] Selections combine as OR within a group and AND across the two, and the grid updates on the tap with no confirm step
- [x] A day that does not match draws at 0.35, including today, and a day outside the month is never dimmer than 0.35
- [x] A day with no Shift recorded is muted whenever either group has a selection
- [x] The Filter applies to both months in the carousel
- [x] The Filter survives a resume, a pull-to-refresh and a return from the Month Editor, and is gone after a restart
- [x] The Month Editor shows every day of its month regardless of the Filter
- [x] Each control announces its full Italian name — `Notte`, `Lunedì` — and its selected state to a screen reader
- [x] Nothing about the Filter is written to disk
- [x] `CalendarState` answers whether a given day is muted; the widget makes no filtering decision of its own
- [x] `CONTEXT.md` defines Filter, matched and muted

## Comments

Shape agreed in a grilling session before any code.

State is two sets on `CalendarState` — the selected `ShiftType`s and the selected weekday numbers — plus a `muted(DayCell)` method, with the toggles on `CalendarCubit`. Deliberately not recomputed into `DayCell` at load time the way `isFiller` and `isToday` are: those are settled once per load, whereas this changes on every tap, and rebuilding both grids to flip a boolean would be churn. The state answers the question instead, so the widget still decides nothing.

The shift row is a centred `Wrap` rather than a `Row` of `Expanded` or a horizontal scroll view: six single-letter chips fit one line on a phone, and if they ever do not, wrapping to a second line beats overflowing — and beats a scroll view competing with the pull-to-refresh and the `PageView` for the same gesture.

`CONTEXT.md` gained Filter and Matched/Muted entries. No ADR: "we did not persist it" is the requirement restated, not an architectural decision with a live alternative.

Built test-first at the state seam: the truth table went into `calendar_cubit_test.dart` before `muted` existed, and the widget tests only prove the wiring — that a tap reaches the Filter and the grid redraws at 0.35.

The weekday control is a plain tappable letter inside a 48dp box, not a `FilterChip`: a chip's padding would have pulled the letter off the centre of the column it labels, and the column heading is what it is. It carries `Semantics(label:, button:, selected:)` because the bare initial says nothing out loud — and `onTap` as well, which is the bug the review caught: `excludeSemantics: true` takes the `InkWell`'s tap action with it, so without restating the action the control announced itself perfectly to a screen reader and then did nothing. The test now asserts `hasTapAction`, not just the label.

`muted` judges a filler day on the same terms as any other and the answer changes nothing on screen — the widget dims filler either way. Left as is rather than special-cased: an `isFiller` branch in the rule would be a line of code that draws nothing.

**Verified on the emulator.** Pixel 9, Android 16: `3` alone leaves only the four `3` days bright with today dimmed along with everything else, `3` + `D` narrows to the two `3` Sundays, both survive a pull-to-refresh and a background/resume, and a force-stop and relaunch comes back with nothing selected.

`flutter analyze` clean, 85 tests pass.

### Review

Two-axis review of the diff. Both axes independently found the missing semantic tap action, fixed above. Also acted on: `filtering` was public with one caller and is now inlined; the filler-day test's stated reason was wrong and is rewritten; the widget tests' pump helper duplicated the existing one and now shares it; three gaps got tests — the second carousel page, the Month Editor being untouched by the Filter, and the chips' spoken names.

Raised and left alone: `shiftFilter` and `weekdayFilter` travel as a pair through the constructor, `copyWith` and `load`, which is a `Filter` value type wanting to be born. It would be a real refactor for a feature this size, and the pair only travels inside one class.
