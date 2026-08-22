# 05 — The Month Editor reads as one row per day

**What to build:** A month is scannable. Each day is a heading you can find while scrolling, over one row of six equal square buttons — the six Shift Codes, all visible, none clipped, no sideways scroll. The four items `docs/UI/base.md` has owed this screen since it shipped, all four at once, because the first two are the widget swap and the other two are two numbers.

The stock `SegmentedButton` goes. Six segments joined edge to edge on a phone cannot hold six letters without the default padding fighting them, and its border and dividers are unreachable from a button style. In its place, six equal-width buttons — the selected one filled, the rest outlined — spaced apart, one row, sized so the row fills the width whatever the phone. It is `catui`'s separate-buttons idiom, forced to equal shares and one line rather than allowed to wrap; that variant does not exist in the package and is built here, with a note saying it goes upstream when a second app wants it.

What is drawn is the Shift Code; what is spoken is the Italian name. That trade stays exactly as it is — the row only fits because of it.

The day heading grows, and the rows get vertical space between them so a month stops reading as one block. Still no divider closing a row: once rows breathe, a line between two outlined controls is ink competing with outlines.

Nothing about the screen's behaviour moves. The snapshot it opens with, the back button that discards, the single batched Save, the sticky failure banner, and the refusal to put a day back to "not entered yet" all stand.

`docs/UI/base.md` retires with this ticket: its Calendar items were either done or deleted by ticket 03, and its Month Editor items are these four.

**Blocked by:** 02

**Status:** done

- [x] All six Shift Codes are on one row on a narrow phone, none clipped, nothing scrolling sideways
- [x] The six are equal width and fill the row
- [x] The chosen Shift Type is filled and the other five are outlined
- [x] Each choice draws its Shift Code and announces its Italian name
- [x] The day heading is visibly larger than before
- [x] There is clear vertical space between one day's row and the next, and no divider
- [x] Tapping the already-selected choice still leaves the day as it was — no day can return to "not entered yet"
- [x] Saving, failing to save, and leaving by the back button all behave exactly as before
- [x] `docs/UI/base.md` is deleted
- [x] The Month Editor's existing widget tests still pass, adjusted only where they named the widget that was replaced
