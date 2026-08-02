# 02 — Connect to Turso and read Shifts

**What to build:** The tracer bullet — narrow, but cutting through every layer. Launch the app on a real Android device and see Shifts that genuinely came from Turso, via the local replica.

The app opens an embedded replica in the application support directory (not the cache directory, which Android can reclaim), with read-your-writes enabled and no sync interval, using credentials supplied at build time from the gitignored environment file. A single concrete `ShiftsRepository` owns the client and can connect, sync, and fetch a date range. Shift Types exist as an enum carrying the Shift Code, the Italian label and the display order.

The UI is a deliberately throwaway list of `date → Shift Code`, replaced in the next ticket. Its only job is to prove the path is real.

This ticket also settles the project's biggest technical unknown: `libsql_dart` ships native assets, and its shared library is known to fail loading on x86_64 Android — the default emulator on a Windows host. Establish now whether you develop against a physical device, and whether the library loads under the test runner at all. That answer decides whether the repository-level test seam exists for the rest of the project; if it doesn't load, drop that seam rather than fight it and verify SQL by hand against Turso instead.

**Blocked by:** 01 — the database and credentials must exist.

**Status:** in-progress — blocked on a physical device for the two on-device checks.

- [ ] The app connects to the replica on a real device and stays connected
- [ ] Rows inserted directly into Turso by hand appear in the app after a sync
- [x] The repository exposes connect, sync, fetch-by-date-range, and batch upsert; no other public surface
- [x] There is no repository interface, no sync manager, no constants file — see the spec's list of deliberate deletions
- [x] Shift Types are an enum; there is no reference table and no reference-data load at startup
- [x] Whether the native library loads under the test runner is recorded on this ticket, and the conditional test seam is either established or explicitly dropped
- [x] If the seam exists: batch upsert round-trip, range query, and `CHECK` rejection are covered against a temporary local database with no network

## The native library question — answered

**The conditional test seam exists. Keep it.** `libsql_dart` loads and runs
under `flutter test` on the Windows host, and `test/shifts_repository_test.dart`
passes against a temporary local libSQL file with no network and no credentials.

It also **loads on x86_64 Android** — the spec expected it not to. The emulator
still isn't usable, for two unrelated reasons:

- **Sync hangs.** After pulling the db file, the client stalls forever at
  `libsql::hrana::stream: opening stream` and never returns from `sync()`.
  The identical replica code against the same Turso database completes in four
  seconds on the Windows host, so this is the emulator, not the repository.
- **Nothing renders.** Impeller reports
  `Requested texture size (1, 1) exceeds maximum supported size of (0, 0)`,
  so the app surface is blank and `screencap` returns an empty image.

Rows hand-inserted into Turso *did* reach the device: pulling
`/data/data/com.example.beeshift/files/replica.db` off the emulator and opening
it shows exactly the three rows that were inserted. The data path is proven end
to end; only the on-device *display* is unverified.

**Develop against a physical device.**

## Toolchain note

`libsql_dart` compiles its native library from Rust at build time, so Windows
needs `rustup` plus the Android targets. Recorded in the README; installed on
this machine. A first Android build takes ~10 minutes and the Rust artifacts
under `.dart_tool/hooks_runner` reach ~7.7 GB.
