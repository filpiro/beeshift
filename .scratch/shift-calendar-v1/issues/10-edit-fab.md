# 10 — Reaching the Month Editor from a FAB

**What to build:** The way into the Month Editor becomes a floating action button in the bottom-right corner instead of a full-width button parked under the carousel.

The icon is a pencil, not a plus. The Month Editor opens pre-loaded with the month's existing Shifts and every change it makes is an overwrite — a Shift is never created from nothing and never removed. A plus would promise a create action the screen does not have.

The button cannot live on the Scaffold in `main.dart`: that Scaffold also hosts the loading spinner and the database-connect error screen, and an edit button floating over "Impossibile aprire il database" is an invitation to edit something that failed to open. The Calendar gets its own Scaffold so the button exists exactly when the Calendar does.

What is lost is the current button's adjacency — sitting directly beneath the carousel, it made obvious that it acts on the month you swiped to rather than on some month it picked for you. That job now belongs to the month name at the top of the screen, which is why this ticket comes after 09.

A floating button overlaps whatever is under it. On a short screen the grid fills the height and the last row reaches the bottom, so the grid reserves enough space beneath it that the FAB never covers a day.

**Blocked by:** 09.

**Status:** ready-for-agent

- [ ] The Month Editor is reached from a floating action button in the bottom-right corner, carrying a pencil icon
- [ ] The `Modifica` button below the carousel is gone
- [ ] The button opens the Month Editor on whichever month is on screen, and the Calendar still re-queries on the way back
- [ ] The button is not present on the loading screen or the database-connect error screen
- [ ] The button never covers a day cell, including on a short screen where the grid fills the available height
