# 03 — The Shell and its Bottom Bar

**What to build:** The floating edit button is gone. In its place a Bottom Bar floats over the Calendar: a rounded pill hugging two icon buttons, centred above the bottom edge. The left one goes to Settings, where a Theme Mode picker changes the app's appearance on the spot. The right one opens the Month Editor exactly as the old button did.

The Shell is what holds the two destinations. It owns an index and an `IndexedStack`, so switching to Settings and back leaves the Calendar on the month it was on with the Filter it had — nothing rebuilds, nothing reloads. There is no router; the reasoning is in ADR 0004.

The Settings button is a destination and is drawn active while Settings is showing — a filled rounded pill behind an accented glyph, against a bare muted glyph when it is not. Tapping it while it is already active returns to the Calendar, which is the only way back and has to be obvious. The edit button is an action, never active: it pushes the Month Editor on the root navigator, full-screen, covering the bar, with its own back button and Save exactly where they are today. Nothing about the editor's behaviour changes in this ticket.

The Shell mounts only once the database is open, so no bar is drawn over the connect-error screen or the opening spinner. The edit button is disabled while the Calendar has no grids — first load in flight, or first load failed — because editing a schedule that could not be read is meaningless. The Settings button stays live throughout: a dead network must not cost the worker their theme.

The Calendar keeps a strip clear at the bottom, as it did for the floating button, sized to the bar and its margin, so the last week of the month is never behind it.

Settings holds one control: Theme Mode as light, dark or system, drawn with `catui`'s separate-buttons group, applying the instant it is tapped. It does not survive a restart yet — that is ticket 04.

The bar and its active-pill rule live in one shared widget taking a list of destinations, so a third would be a list entry. None is added.

**Blocked by:** 02

**Status:** done

- [x] There is no floating edit button anywhere in the app
- [x] A floating pill sits centred above the bottom edge of the Calendar, hugging two icon buttons rather than spanning the screen
- [x] The Settings button shows Settings, and shows it as active while it does
- [x] Tapping the active Settings button returns to the Calendar
- [x] Coming back from Settings finds the Calendar on the same month with the same Filter selections
- [x] The edit button opens the Month Editor full-screen with no bar visible over it, on the month the Calendar was showing, pre-loaded
- [x] The Month Editor still has its own back button and its Save in the app bar, and saving still returns to a refreshed Calendar
- [x] The edit button is disabled while the Calendar has no grids, and the Settings button is not
- [x] No bar is drawn over the connect-error screen or the opening spinner
- [x] The last row of a six-row month is fully visible above the bar
- [x] Settings offers light, dark and system, and tapping one repaints the app immediately
- [x] Both bar buttons are announced by name to a screen reader
- [x] A Shell-level widget test covers the bar, the active state, the round trip to Settings, the editor push and the disabled edit button
