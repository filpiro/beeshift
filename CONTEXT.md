# Beeshift

A personal app for viewing and entering one worker's shift schedule, replacing a static PDF table. Single user, two devices.

## Language

**Shift**:
The work assignment recorded for one specific calendar day. A day has either exactly one Shift or none.
_Avoid_: entry, assignment, turn

**Shift Type**:
One of the six fixed kinds a Shift can be. Fixed for v1 and not user-configurable, but held as data rather than hardcoded, so a seventh becomes an insert rather than a code change.
_Avoid_: shift (unqualified — that's the day's record), category, kind

**Shift Code**:
The single letter identifying a Shift Type (`7`, `3`, `N`, `S`, `R`, `F`). The only thing shown in a calendar day cell.
_Avoid_: symbol, letter, abbreviation

**Rotation**:
The recurring pattern that determines which Shift Type falls on which day. It produces every Shift Type except Ferie.

### The six Shift Types

**Primo** (`7`):
A morning shift. Working day.

**Secondo** (`3`):
An afternoon shift. Working day.

**Notte** (`N`):
A night shift. Working day.

**Smonto** (`S`):
The mandatory recovery day immediately following a Notte. Non-working. Always follows an `N` — never appears on its own.

**Riposo** (`R`):
A scheduled day off produced by the Rotation. Non-working, and not chosen by the worker.

**Ferie** (`F`):
Requested and approved leave. Non-working, and the only Shift Type the worker chooses rather than receives from the Rotation.

_Note_: Smonto, Riposo and Ferie are all non-working days but are **not** interchangeable — they differ by what caused the day off.

### Screens

**Calendar**:
The default screen. A read-only month view of the Data Window, one page per month. It never writes.
_Avoid_: home, month view

**Month Editor**:
The screen for recording Shifts, reached from the Calendar. It edits whichever month the Calendar is showing, pre-loaded with that month's existing Shifts, and commits every change in one batch. The only place in the app that writes.
_Avoid_: Insert Shifts, bulk insert, insert screen

### Scope

**Data Window**:
The current calendar month plus the following one — the range the app displays and lets the user edit. It is a *viewing* rule, not a storage rule: Shifts outside it are retained, never purged.

**Empty day**:
A day with no Shift recorded. Since the six Shift Types cover every real day, this only ever means "not entered yet" — never "a day with no shift". Consequently a Shift is never removed, only overwritten.
