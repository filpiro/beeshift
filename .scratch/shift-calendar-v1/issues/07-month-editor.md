# 07 — Month Editor

**What to build:** The entire write path, and the app's reason to exist beyond viewing. A new schedule arrives; you record it in one pass and it's on both devices.

A button on the Calendar opens the Month Editor for **whichever month the Calendar is showing** — swipe to the month you want, then press it, so you are never surprised by editing the wrong one. The editor lists every day of that month with its date and weekday, each offering the six Shift Types as radio buttons labelled with their names, not just their codes, so you never have to remember what `S` means.

It arrives **pre-loaded with the Shifts already recorded** for that month. This is what makes it safe to leave half-finished and come back to: without it, a blank screen invites you to re-enter from memory and silently overwrite work you already did. It also means the editor doubles as a bulk-correction tool rather than being first-entry-only.

Tapping a radio changes local selections only — no per-day save, no network. One Save commits everything as a single batch upsert. Days you didn't touch keep exactly what they had, and days that were empty and stayed unselected are not written at all. On success it pops back, and the Calendar shows the change from a local re-query — no sync, because read-your-writes means it's already visible.

Nothing is ever deleted. The six Shift Types cover every real day, so an Empty day only ever means "not entered yet", and a mistake is corrected by choosing a different Shift Type rather than by clearing the day.

**Blocked by:** 05 — the editor targets the visible month.

**Status:** ready-for-agent

- [ ] The Calendar's button opens the editor for the month currently on screen, and the editor shows which month that is
- [ ] Every day of the target month is listed with date and weekday
- [ ] Each day offers all six Shift Types as radios, labelled with their names
- [ ] Existing Shifts for the month arrive pre-selected
- [ ] Radio taps mutate local state only; nothing reaches the network until Save
- [ ] Save issues exactly one batch upsert for the whole month
- [ ] Untouched days retain their existing Shift; untouched empty days are not written
- [ ] The batch payload's exact contents are asserted at the state seam for a mixed month — some pre-existing, some newly selected, some left alone
- [ ] After a successful save the editor pops and the Calendar reflects the change
- [ ] No sync is triggered by the save
- [ ] No delete operation exists anywhere in the flow
