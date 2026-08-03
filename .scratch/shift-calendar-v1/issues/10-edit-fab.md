# 10 — Reaching the Month Editor from a FAB

**What to build:** The way into the Month Editor becomes a floating action button in the bottom-right corner instead of a full-width button parked under the carousel.

The icon is a pencil, not a plus. The Month Editor opens pre-loaded with the month's existing Shifts and every change it makes is an overwrite — a Shift is never created from nothing and never removed. A plus would promise a create action the screen does not have.

The button cannot live on the Scaffold in `main.dart`: that Scaffold also hosts the loading spinner and the database-connect error screen, and an edit button floating over "Impossibile aprire il database" is an invitation to edit something that failed to open. The Calendar gets its own Scaffold so the button exists exactly when the Calendar does.

What is lost is the current button's adjacency — sitting directly beneath the carousel, it made obvious that it acts on the month you swiped to rather than on some month it picked for you. That job now belongs to the month name at the top of the screen, which is why this ticket comes after 09.

A floating button overlaps whatever is under it. On a short screen the grid fills the height and the last row reaches the bottom, so the grid reserves enough space beneath it that the FAB never covers a day.

**Blocked by:** 09.

**Status:** done

- [x] The Month Editor is reached from a floating action button in the bottom-right corner, carrying a pencil icon
- [x] The `Modifica` button below the carousel is gone
- [x] The button opens the Month Editor on whichever month is on screen, and the Calendar still re-queries on the way back
- [x] The button is not present on the loading screen or the database-connect error screen
- [x] The button never covers a day cell, including on a short screen where the grid fills the available height

## Comments

`CalendarPage` returns its own `Scaffold`, and `main.dart` no longer wraps
everything in one: each of the three states — spinner, connect error, Calendar
— brings its own. So the FAB cannot exist unless the Calendar does, without
anything having to hide it. Within the Calendar it is `null` while `grids` is
`null`, which covers the Calendar's own first load.

The grid reserves `_fabReserve` (80dp: a 56dp button, the Scaffold's 16dp
bottom margin, 8dp of gap) as bottom padding on the carousel rather than
inside `_MonthGrid`. That keeps 09's `side = min(width / 7, height / rows)`
arithmetic untouched — it just gets a shorter box. On a tall phone the tiles
are already width-capped, so the reserve costs nothing visible.

`tooltip: 'Modifica'` is not decoration: an icon-only button is nameless to a
screen reader. The word is the one the old button carried.

Tests: the overlap criterion is asserted geometrically — every tile's rect
inside the `PageView` against the FAB's rect, on a 360x420 screen where the
grid does reach the bottom. Checked it bites by setting the reserve to zero;
it fails. The Month Editor's tests now tap the FAB instead of the text, and
`main_test` asserts on the FAB's absence rather than on the old label.

**Verified on the emulator.** Pixel 9, Android 16: Agosto 2026 with the pencil
FAB bottom-right clear of the 31 August row, and tapping it opens the editor
on Agosto 2026.

`flutter analyze` clean, 59 tests pass.

### Review

Self-review of the diff, inline. `ScaffoldMessenger.of` in the pull-to-refresh
handler now resolves above the Calendar's Scaffold rather than below the app's
— it still finds `MaterialApp`'s messenger, and the failed-pull test still
sees the SnackBar. The reserve is a constant rather than measured from the
real FAB; a measured one would need a key and a post-frame pass to save 80dp
of nothing on screens where the grid does not reach the bottom.
