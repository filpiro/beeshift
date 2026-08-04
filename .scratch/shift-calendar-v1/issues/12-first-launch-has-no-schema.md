# 12 — A first launch that has nothing to read

**What to build:** The app works the first time it is opened on a device, and says something when it cannot.

A replica file created a moment ago is an empty SQLite database. The schema arrives with the first sync, not with the file — and nothing in the app synced before a read, because opening was deliberately kept instant (ticket 06). So the very first read threw `no such table: shifts`, the exception died in an async gap, and the Calendar sat on its spinner for as long as the app was open. It only ever looked fixed because backgrounding the app fired the resume sync, which created the schema for every launch after that.

Two things are wrong there and both get fixed. The first launch syncs, once, and only while the replica has no schema — every later launch still opens without touching the network. And a first load that fails stops being silent: with nothing on screen to protect there is a message and a Retry, where the retry syncs first, which is exactly the cure for a replica that has never been synced.

The rule from ticket 08 is unchanged for every other failure: once a Calendar is on screen, a failed load emits nothing at all and the data the user is reading stays put.

**Blocked by:** None — can start immediately.

**Status:** done

- [x] A fresh install shows the Calendar on its first launch, with no spinner that never ends
- [x] Launches after the first do not sync before reading
- [x] A first load that fails shows a message and a Retry rather than a spinner
- [x] Retry syncs before reading, so it recovers a replica that has no schema
- [x] A failure with a Calendar already on screen still leaves it exactly as it was
- [x] `load` never throws: it is called from a constructor's cascade, where a throw goes nowhere

## Comments

`ShiftsRepository.hasShiftsTable` asks `sqlite_master`, and `syncIfEmpty` in
`main.dart` syncs only when the answer is no. That keeps ticket 06's promise
for every launch but the first.

`CalendarCubit.load` returns `bool` instead of throwing, and emits
`loadFailed` only when `state.grids == null`. That split is what lets the
first-load error screen exist without touching ticket 08's rule for a loaded
Calendar — the tests that assert an untouched state on a failed refresh still
pass unchanged. `refresh` now syncs, then returns whatever `load` returns.

Tried and cut: a `FirstSyncFailure` exception with its own message on the
error screen. Offline, a fresh install dies inside `connect` — which is what
bootstraps the replica — so the sync branch is nearly unreachable and the
bespoke type was a message for a case that does not arrive. Verified on the
emulator with the network off: the existing "Impossibile aprire il database"
screen is what shows.

**Verified on the emulator.** `adb shell pm clear` for a true first launch:
before the fix, an eternal spinner and `no such table: shifts` in logcat;
after, the Calendar. With the network off, the retry screen rather than a
spinner.

`flutter analyze` clean, 69 tests pass.

### Review

Self-review of the diff, inline. Raised and left alone: `hasShiftsTable` costs
one query on every launch, not just the first. It is a `sqlite_master` lookup
against a local file — cheaper than the branch that would avoid it.
