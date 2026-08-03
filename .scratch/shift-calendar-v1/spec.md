# Shift Calendar v1

Status: ready-for-agent

## Problem Statement

I receive my work schedule as a static PDF table. To answer "what am I working on the 17th?" I have to find the file, open it, and read across a dense grid on a phone screen. It doesn't tell me what today is, it doesn't highlight the week I'm in, and there is no way to record a change when I swap a shift with a colleague — the PDF is stale the moment anything moves.

I also use two devices. Whatever I write down on one has to be visible on the other, without me thinking about it.

## Solution

A phone app whose default screen is a proper month Calendar showing my Shift Code on each day, with today highlighted, so the answer to "what am I on?" is one glance with no reading.

Entering a schedule is a single screen — the Month Editor — reached from the Calendar. It lists the days of whichever month I'm looking at, each with the six Shift Types as radio buttons, pre-filled with whatever is already recorded. I tap my way down the month and press Save once.

Everything is stored in the cloud, so the second device sees it. Reads always come from a local copy, so opening the app is instant and never waits on the network.

## User Stories

1. As a shift worker, I want the app to open directly on the Calendar, so that I see my schedule without navigating anywhere.
2. As a shift worker, I want the Calendar to open instantly, so that checking a single day is not slower than looking at the PDF.
3. As a shift worker, I want each day cell to show its Shift Code, so that I can read the month at a glance.
4. As a shift worker, I want every day cell to always show its day number, so that I can locate a specific date even when no Shift is recorded.
5. As a shift worker, I want today to be visually distinct, so that I can orient myself instantly without checking the date.
6. ~~As a shift worker, I want the current week highlighted as a band, so that I can see the days immediately around today.~~ **Dropped in ticket 09.** Shipped in ticket 04, then removed when day cells became separate rounded tiles: a row-wide stripe behind detached tiles reads as a rendering fault, not a highlight. Today's filled tile answers "what am I on?" directly, which is the question the problem statement actually asks; the band only ever answered a weaker one.
7. As a shift worker, I want weeks to run Monday to Sunday, so that the grid matches how my Rotation is actually written.
8. As a shift worker, I want every week row to be a full seven days, so that the grid never looks ragged at the month boundaries.
9. As a shift worker, I want the filler days at the start and end of a month to show their Shift Codes dimmed, so that I can see the tail of the previous week's Rotation without switching months.
10. As a shift worker, I want filler days that have no recorded Shift to simply appear blank, so that the grid never invents information.
11. As a shift worker, I want to swipe horizontally between this month and next month, so that I can check an upcoming schedule.
12. As a shift worker, I want swiping to stop at those two months, so that I never get lost paging into empty months.
13. As a shift worker, I want a day with no Shift recorded to show nothing extra, so that I can tell at a glance which days I still have to enter.
14. As a shift worker, I want to pull down on the Calendar to refresh, so that I can immediately see something I just entered on my other device.
15. As a shift worker, I want the app to fetch changes whenever I bring it back to the foreground, so that it is normally already up to date before I think to refresh.
16. As a shift worker, I want the highlighted "today" to correct itself when I reopen the app the next morning, so that it never quietly points at yesterday.
17. As a shift worker, I want the visible months to roll forward when a new month begins, so that the app doesn't keep showing me a month that has ended.
18. As a shift worker, I want a button on the Calendar that opens the Month Editor, so that recording a schedule is one tap away.
19. As a shift worker, I want the Month Editor to edit whichever month I am currently looking at, so that I am never surprised by editing the wrong month.
20. As a shift worker, I want the Month Editor to show which month it is editing, so that I can confirm it before I start tapping.
21. As a shift worker, I want the Month Editor to list every day of the month with its date and weekday, so that I can follow my paper Rotation down the list without losing my place.
22. As a shift worker, I want each day in the Month Editor to offer all six Shift Types as radio buttons, so that recording a day is a single tap.
23. As a shift worker, I want the Shift Types labelled with their names and not just their codes, so that I don't have to remember what `S` means.
24. As a shift worker, I want the Month Editor to arrive pre-filled with the Shifts already recorded for that month, so that I can see my progress instead of a blank screen.
25. As a shift worker, I want to be able to leave the Month Editor half-finished and come back later, so that an interruption doesn't cost me the work I already did.
26. As a shift worker, I want my taps to register immediately without a per-day save step, so that entering a month is thirty taps and nothing else.
27. As a shift worker, I want one Save button that commits the whole month at once, so that I am not waiting on the network thirty times.
28. As a shift worker, I want days I didn't touch to keep exactly what they had, so that editing one day cannot damage the rest of the month.
29. As a shift worker, I want to correct a day I got wrong by simply choosing a different Shift Type, so that fixing a mistake is the same action as making the entry.
30. As a shift worker, I want the Calendar to show my changes as soon as I come back from saving, so that I can confirm the month landed correctly.
31. As a shift worker, I want anything I save to be visible on my other device, so that I only ever have to enter a schedule once.
32. As a shift worker, I want my past months to still be there, so that I can look back at what I actually worked.
33. As a shift worker, I want a clear, blocking error if a save fails, so that I never walk away believing a month was recorded when it wasn't.
34. As a shift worker, I want my selections kept on screen when a save fails, so that I can retry without re-entering the month.
35. As a shift worker, I want to be told when a pull-to-refresh fails, so that I know I am looking at older data.
36. As a shift worker, I want a failed background refresh to stay silent, so that I am not interrupted by errors for something I never asked for.
37. As a shift worker, I want the Calendar to keep showing my data when a refresh fails, so that a bad signal never leaves me with an empty screen.
38. As a shift worker, I want a clear error with a retry option if the app cannot open its database at all, so that I understand why nothing is working.

## Implementation Decisions

### Storage

One table, and that is the entire schema:

```sql
CREATE TABLE IF NOT EXISTS shifts (
  date TEXT PRIMARY KEY,
  code TEXT NOT NULL CHECK (code IN ('7','3','N','S','R','F'))
);
```

- The day is an ISO `YYYY-MM-DD` string, not a `YYYYMMDD` integer. Both conversion directions are stdlib one-liners, so no date-conversion module exists. See ADR-0003.
- There is **no `shift_types` reference table**. Shift Types are a Dart enum carrying the Shift Code, the Italian label and the display order — the enum is the source of truth, and exhaustive switches give compile-time safety an FK could not. The `CHECK` constraint is a cheap backstop so a bad row fails loudly at the database. See ADR-0003.
- Schema lives in a single hand-run SQL file executed with the Turso CLI. The app never creates or migrates schema. A migrations directory gets created when the first real migration exists, not before. There is no seed script.

### Data lifecycle

- **Nothing is ever purged.** The original design deleted rows before the current month at every startup; that was removed. A year of Shifts is a few kilobytes, so destroying history bought nothing and risked real data loss.
- **Nothing is ever deleted.** The six Shift Types cover every real day (`R` and `F` cover non-working days), so an Empty day only ever means "not entered yet". There is no delete operation in the UI, the repository, or the SQL.
- The Data Window (current month + next month) is therefore a **viewing** rule only, never a storage rule.

### Database client and sync

- `libsql_dart` in embedded replica mode, `readYourWrites` enabled, sync interval omitted so no background timer runs. See ADR-0001 and ADR-0002.
- **Writes are not local.** libSQL forwards writes to the Turso primary synchronously; they are not written to the local file first. Offline, a write fails cleanly — nothing is queued, nothing is half-written. This is accepted: writes happen roughly once a month, deliberately, with the phone in hand.
- **Sync has exactly two trigger points, both of them pulls**: app resume, and pull-to-refresh. There is **no sync after a write** — the write already reached the primary, and `readYourWrites` means the writing device sees it immediately. A post-write sync would push nothing and pull nothing.
- The trigger is app *resume*, not cold start: Android rarely kills the app, so a cold-start-only trigger would almost never fire. Resume also recomputes "today" and re-derives the Data Window, which is what stops the highlight going stale overnight and the carousel going stale across a month boundary.
- `today` comes from device-local time. Single user, single timezone; no UTC modelling.
- The replica file lives in the application support directory, not the cache directory, so Android cannot reclaim it under storage pressure. It is still disposable — if lost, the next sync repopulates it.
- Credentials are supplied at build time from a gitignored JSON file, with a committed example alongside it, using a dedicated scoped Turso token. The token is recoverable from the built APK; this is accepted for a sideloaded single-user app, and the mitigation is keeping it out of version control and being able to rotate it.

### Data access

A single concrete `ShiftsRepository` owns the client and exposes: connect, sync, fetch a date range, and upsert a batch. There is **no separate interface** — Dart's implicit interfaces mean a fake can implement a concrete class, so an abstract class would buy literally nothing. There is **no `SyncManager`**: its stated invariant ("the only thing that talks to Turso") is false, because every write talks to Turso directly. There are no table/column name constants.

Only two write operations exist in the app, and after the removal of single-day editing, only one survives: batch upsert. The repository is constructor-injected; with one dependency and two screens there is no service locator.

### Calendar

- Read-only. It never writes. Its state holder exposes load and refresh only.
- Two-page carousel: current month and next month. No infinite paging.
- Day cells have **no gesture handling at all** — no tap, no long-press. The FAB is the only route into editing. Tap-to-edit was considered and rejected: accidental taps while scrolling are worse than the tap it saves.
- The computed grid — cells, which are filler, which is today — lives **in the Calendar's state, not in the widget**, so that it is testable through the state seam.
- One query per load, spanning the **whole visible grid** (first visible cell to last visible cell), not the exact month bounds. Filler days therefore come back with their real data and render dimmed. No placeholder cell variant exists.

### Month Editor

- Named for what it does; it is not "Insert Shifts". It edits, it is not insert-only, and it is not fixed to next month.
- Targets the month the Calendar is showing, passed in from the Calendar so it cannot drift independently.
- Pre-loaded with the target month's existing Shifts. This removes the only place in the original design where data could be lost: a blank re-entry silently overwriting work already done.
- Radio taps mutate local selections only. One Save commits everything as a single batch upsert.
- Days with no selection are **not written**. Untouched days keep their value; Empty days stay empty.
- On success it pops back and the Calendar re-queries locally — no sync needed, since the write is already visible.

### Error handling

Only the write failure is unmissable; everything else degrades to "you are looking at slightly older data".

| Failure | Behaviour |
|---|---|
| Cannot connect to the database | Full-screen error with Retry. There is no app without it. |
| Save fails | Stay on the Month Editor. Selections preserved, sticky inline banner, Save still enabled. Never a transient toast — it would be missed. |
| Pull-to-refresh fails | Transient message. Data stays on screen. |
| Resume sync fails | Silent. No UI. The user never asked for it. |

### State management

`flutter_bloc`, Cubit-based — two Cubits, one for the Calendar and one for the Month Editor. Chosen for developer familiarity and maintainability rather than minimalism; a `ValueNotifier` approach was considered and rejected on those grounds.

## Testing Decisions

A good test here asserts **externally observable behaviour**: given a fake repository and a fixed clock, what does the state expose, and what did the repository get asked to do. It does not assert on private fields, call counts for their own sake, or widget internals.

### Primary seam — the Cubits, driven through a fake `ShiftsRepository`

This is the only seam that really matters, and it is deliberately the highest one available. Because the computed grid lives in the Calendar's state, this single seam covers the grid math too — no separate unit seam for date arithmetic.

Coverage expected at this seam:

- Data Window derivation, and the wider visible-grid range the query actually spans
- Monday-start weeks, full seven-day rows, which cells are filler, filler days carrying data
- Today identification (the current-week band was dropped in ticket 09)
- `today` recomputation on resume, explicitly including the month-rollover case
- Sync ordering: sync-then-query on resume and on pull-to-refresh, and **no sync after a write** — this is a real regression risk, since the original design specified the opposite
- Month Editor pre-load, untouched days retaining their value, and the exact contents of the batch payload
- Every error behaviour in the table above, especially selections surviving a failed save

The fake repository is a plain class implementing the concrete repository's implicit interface. "Now" is injected rather than read from the system clock, so rollover and overnight cases are testable without waiting.

### Conditional seam — the repository against a temporary local database

Covers only what a fake cannot: the batch upsert round-trip (its SQL builds placeholders dynamically, and it is the one path where data loss is possible), the range query, and the `CHECK` rejecting an invalid code. It runs against a purely local libSQL file — no sync, no network, no credentials.

**This seam is gated on reality.** `libsql_dart` ships native assets, and there is a known issue with the shared library failing to load on x86_64 Android — the standard emulator target on Windows. If the library will not load under the test runner, **drop this seam rather than fight it**; the SQL gets verified by hand against Turso instead.

### No prior art

The repository is a bare Flutter scaffold with no dependencies and no tests, so these seams establish the conventions rather than follow them.

### Not tested

Widget tests. Two screens of layout, with the decision-rich logic already lifted into state.

## Out of Scope

- **iOS and tablet.** Android phone only.
- **A navbar or any third screen.**
- **Offline writes.** Requires a different client mode and reintroduces conflict handling. Revisit if entering shifts without signal ever becomes real.
- **Concurrent-edit conflict resolution.** Single user, two devices, last write wins, untracked. No version columns, no optimistic locking. Explicitly rejected as complexity with no payer.
- **Deleting a Shift**, and any confirmation prompt before overwriting one.
- **Purging or archiving old Shifts.**
- **Viewing or editing months outside the Data Window**, including past months — the data is retained, it is simply not reachable in v1.
- **Per-Shift-Type colours and any wider visual design pass.** The one deliberately open question; the app ships readable in monochrome first.
- **Auto-suggesting `S` after an `N`.** The invariant is recorded in the glossary; the convenience built on it is not v1.
- **Opening the Month Editor scrolled to a specific day.** The fallback if single-day correction proves annoying in practice.
- **Background or periodic sync**, retry with backoff, and any write queue.
- **A "last synced" indicator.**
- **User-configurable Shift Types**, and any users, auth or multi-tenancy.
- **Runtime credential entry via secure storage.** Considered; rejected as disproportionate for a sideloaded personal app.

## Further Notes

**Verify the native library before building anything on top of it.** `libsql_dart` has a known issue loading its shared library on x86_64 Android, which is the default emulator on a Windows host. Get a bare connect working on the real target first — this may mean developing against a physical device from day one, and it also determines whether the conditional test seam exists.

**Two decisions actively contradict the documents in `docs/initial/`** and will look like oversights to anyone reading those first. They are deliberate: there is no `shift_types` table (ADR-0003), and there is no sync after a write (ADR-0002). The initial documents are superseded by this spec and the ADRs.

**Several deletions were deliberate, not omissions.** No repository interface, no `SyncManager`, no service locator, no constants file, no seed script, no purge, no delete. Each was considered against the ladder and removed for a stated reason. Re-adding any of them should be a decision, not a reflex.

**Flutter runs on Windows while the agent runs in WSL.** All Flutter and Dart commands go through PowerShell, per the repo's `CLAUDE.md`.

**Glossary terms are load-bearing.** Shift, Shift Type, Shift Code, Rotation, Data Window, Empty day, Calendar, Month Editor are defined in `CONTEXT.md`. Use them in code, issue titles and tests; avoid the synonyms the glossary lists.
