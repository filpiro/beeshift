# 11 — Month Editor rows you can actually hit

**What to build:** A day in the Month Editor becomes one legible line and one row of six choices, instead of a small heading over a wrapped cloud of radio buttons.

The six Shift Types go into a single-row segmented control showing only Shift Codes. This reverses 07's decision — "names, not codes: nobody should have to remember what S means" — and the reversal is forced rather than chosen: six Italian names cannot fit one row on a phone, "Secondo" alone needs more than the ~65dp a sixth of the width gives. It is also the right call independently. The user of this app reads `7 3 N S R F` off a real schedule as their working vocabulary, and `CONTEXT.md` already makes the Shift Code the thing that identifies a Shift Type. The full names do not disappear entirely — they stay as the accessibility labels, so a screen reader still says "Smonto".

Nothing selected is a real state, not an edge case: an Empty day means "not entered yet", and the control must be able to show that. It must not be able to return to it — there is still no way to clear a day, and a mistake is corrected by picking a different Shift Type.

The day line reads `12 Martedì` — the full weekday name, not an abbreviation — at a size you can read while scrolling. Rows get real vertical spacing, and the divider closing each row is deleted: once rows breathe, a line between them is redundant ink, and the segmented control's own outline already anchors each row visually. Across thirty-one rows that is thirty-one fewer lines competing with thirty-one outlined controls.

Out of scope, deliberately: highlighting today or weekends in the list, and scrolling the list to today when it opens.

**Blocked by:** 09 — the Italian weekday and month names it reads from live in the file 09 creates.

**Status:** done

- [x] Each day row reads as the day number followed by the full Italian weekday name, at a larger size than today's
- [x] The six Shift Types are a single row of square-ish segments showing only Shift Codes, never wrapping to a second line
- [x] The selected Shift Type is visibly distinct from the other five, with no check icon stealing space from the letter
- [x] A day with no Shift recorded shows nothing selected
- [x] There is no way to return a day to nothing selected once a Shift Type is chosen
- [x] Each choice announces its full Italian name to a screen reader, and every tap target is at least 48dp
- [x] Rows are separated by space, not by a divider
- [x] `RadioGroup`, `Radio` and the wrapping layout are gone from the Month Editor
- [x] `CONTEXT.md`'s Shift Code entry no longer claims the code is shown only in a calendar day cell

## Comments

`SegmentedButton<ShiftType>` with `emptySelectionAllowed: true` and
`showSelectedIcon: false`. Its layout does the "never wraps" work for free:
each segment is `min(intrinsic width, maxWidth / 6)`, so six segments always
divide the row rather than overflow it. The style only narrows the horizontal
padding — the default is wider than a single letter can pay for — and sets a
48dp minimum height.

The one thing the control does not do by itself is refuse to go back to
nothing: with an empty selection allowed, tapping the selected segment clears
it. `onSelectionChanged` drops the empty set, so an Empty day can be shown but
never returned to. Verified by removing the guard and watching the test fail,
and again live with two taps on the same code.

Accessibility rides on `Text(shift.code, semanticsLabel: shift.label)` — the
letter is drawn, the Italian name is spoken. That is the whole of what is left
of 07's "names, not codes", and `shift_type.dart`'s doc comments now say so.

Rows are `vertical: 12` with no `Divider`. `_weekdayAbbreviations` is deleted;
the day line reads `1 Sabato` from `weekdayNames`, at `titleMedium`.

`CONTEXT.md`'s Shift Code entry no longer claims the code is a calendar-cell
thing, and ticket 07 carries a superseded note like 04 does.

**Verified on the emulator.** Pixel 9, Android 16: Agosto 2026 with one row of
`7 3 N S R F` per day, the recorded Shift filled, Empty days bare, and tapping
a selected code twice leaving it selected.

`flutter analyze` clean, 62 tests pass.

### Review

Self-review of the diff, inline. Raised and left alone: the segmented control
is rebuilt for every day in a lazy list, six segments each — cheap enough at
31 rows that measuring it would cost more than it saves. Also unchanged: there
is still no scroll-to-today and no weekend or today highlight in the list,
both explicitly out of scope here.
