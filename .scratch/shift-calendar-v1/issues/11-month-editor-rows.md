# 11 — Month Editor rows you can actually hit

**What to build:** A day in the Month Editor becomes one legible line and one row of six choices, instead of a small heading over a wrapped cloud of radio buttons.

The six Shift Types go into a single-row segmented control showing only Shift Codes. This reverses 07's decision — "names, not codes: nobody should have to remember what S means" — and the reversal is forced rather than chosen: six Italian names cannot fit one row on a phone, "Secondo" alone needs more than the ~65dp a sixth of the width gives. It is also the right call independently. The user of this app reads `7 3 N S R F` off a real schedule as their working vocabulary, and `CONTEXT.md` already makes the Shift Code the thing that identifies a Shift Type. The full names do not disappear entirely — they stay as the accessibility labels, so a screen reader still says "Smonto".

Nothing selected is a real state, not an edge case: an Empty day means "not entered yet", and the control must be able to show that. It must not be able to return to it — there is still no way to clear a day, and a mistake is corrected by picking a different Shift Type.

The day line reads `12 Martedì` — the full weekday name, not an abbreviation — at a size you can read while scrolling. Rows get real vertical spacing, and the divider closing each row is deleted: once rows breathe, a line between them is redundant ink, and the segmented control's own outline already anchors each row visually. Across thirty-one rows that is thirty-one fewer lines competing with thirty-one outlined controls.

Out of scope, deliberately: highlighting today or weekends in the list, and scrolling the list to today when it opens.

**Blocked by:** 09 — the Italian weekday and month names it reads from live in the file 09 creates.

**Status:** ready-for-agent

- [ ] Each day row reads as the day number followed by the full Italian weekday name, at a larger size than today's
- [ ] The six Shift Types are a single row of square-ish segments showing only Shift Codes, never wrapping to a second line
- [ ] The selected Shift Type is visibly distinct from the other five, with no check icon stealing space from the letter
- [ ] A day with no Shift recorded shows nothing selected
- [ ] There is no way to return a day to nothing selected once a Shift Type is chosen
- [ ] Each choice announces its full Italian name to a screen reader, and every tap target is at least 48dp
- [ ] Rows are separated by space, not by a divider
- [ ] `RadioGroup`, `Radio` and the wrapping layout are gone from the Month Editor
- [ ] `CONTEXT.md`'s Shift Code entry no longer claims the code is shown only in a calendar day cell
