# Shift Viewer App — Functional Specification

## Purpose
Replace a static PDF table of work shifts with a mobile-first, highly usable app to view and insert personal work shifts.

## Scope (v1)
- Platform: Android phone only.
- No navbar in v1.
- Two screens only: Calendar (default) and Insert Shifts.
- Data window: current month + next month only. No history kept.

## Screens

### 1. Calendar (default screen)
- Month grid, calendar-style.
- Weeks always start Monday, end Sunday. Weeks at month boundaries show days from the adjacent month so every row is a full 7-day week.
- Current week visually highlighted (e.g. background band).
- Current day visually highlighted (e.g. filled circle/border).
- Each day cell:
  - Always shows the day number.
  - Shows the shift code if a shift is recorded for that day.
  - Shows nothing extra if no shift is recorded (indefinite — no default value, no reminder, per product decision).
- Navigation: horizontal swipe (left/right) switches between the current month and the next month ONLY — a 2-page carousel, not infinite paging. This matches the data window: there is nothing beyond these two months to page to.
- Pull-to-refresh: swipe down triggers a manual sync against Turso, then re-reads the local replica and refreshes what's on screen. This is the only way data changed on another device becomes visible without restarting the app (see Data & Sync Model below — periodic auto-sync is disabled by design).
- Long-press on a day → opens an edit dialog:
  - Radio group with the 6 shift types, pre-selected to that day's current shift (nothing selected if empty).
  - Save / Cancel actions.
  - Save overwrites the existing value directly — no confirmation prompt (silent overwrite, per product decision).
- Floating action button (FAB) → opens the Insert Shifts screen.

### 2. Insert Shifts
- Purpose: fast bulk entry for an upcoming period.
- Shows a list of the days of "next month" (a scoped list, not a full calendar).
- Each list item:
  - Day (date + weekday label).
  - Radio group with the 6 shift types.
- Tapping a shift type selects it immediately for that day (no per-item save step).
- A single explicit "Save" action persists all selections in the list as one batch. Any day that already had a shift recorded is silently overwritten (same rule as long-press edit) — no confirmation dialog.

## Shift Types
6 fixed types, single-letter codes, radio-button (mutually exclusive) per day:

| Code | Meaning (IT) | Meaning (EN) |
|---|---|---|
| 7 | Primo | Morning / first shift |
| 3 | Secondo | Afternoon / second shift |
| N | Notte | Night shift |
| S | Smonto | Off-shift / post-night rest |
| R | Riposo | Rest day |
| F | Ferie | Vacation / leave |

Codes are fixed for v1, not user-configurable. Only the letter is shown in the calendar cell; the full label can be used in the edit dialog / insert list for clarity.

## Data Window Rule
- Only 2 months of data are meaningful: the current calendar month and the following month.
- No historical data is retained. When the real-world month rolls over, the previous month's shifts are not preserved — records outside the [current, current+1] window can be purged (see architecture.md for a suggested hook).
- Consequence: adjacent-month filler days shown in the calendar grid (for the "always full week" rule) are only ever from the current or next month — never a 3rd month — since the stored window itself is only 2 months wide and the carousel only has 2 pages.

## Data & Sync Model
- The Turso remote database is still the single source of truth, but the UI never talks to it directly — the UI always reads the **local embedded replica**; a dedicated **Sync Manager** is the only thing that talks to Turso, and it does so exclusively at defined trigger points, not on a timer.
- Layers: `UI → Repository → Local Database (embedded replica) → Sync Manager → Turso`. The Repository only ever reads/writes the local replica; the Sync Manager owns pushing/pulling against Turso and is invoked explicitly by the UI layer at specific moments, not automatically in the background.
- Sync strategy, no periodic/interval auto-sync:
  - **App open / restart**: run `sync()` once, before the startup purge-check and fetch.
  - **Insert / edit / delete**: save the write, then run `sync()`.
  - **Pull-to-refresh** (Calendar screen): run `sync()` manually, then re-fetch.
- Package: `libsql_dart`, embedded replica mode (`turso_dart` stays out of scope, still under active development, revisit once Turso ships an official Dart sync client).
- Single user, may run on 2 devices, but v1 explicitly does NOT handle concurrent-edit conflicts (last write wins, untracked). Treat it as effectively mono-device from a correctness standpoint.
- Backend: Turso (libSQL). See `database-models.md` for the schema.
- See `architecture.md` for the concrete module/folder layout, the Sync Manager implementation, and the exact query flow per screen/action.

## State Management
- `flutter_bloc` (Cubit-based).

## Exact Query Flow (drives the repository + Sync Manager design in architecture.md)

### App startup
1. Sync Manager: run `sync()` once.
2. One SELECT (local) to check whether any `shifts` rows exist before the first day of the current month.
3. Only if step 2 finds rows: one DELETE (local, propagates to Turso as a normal write) removing them. Skipped entirely if nothing is found.
4. One SELECT (local) fetching all shifts for the current month + next month, single query, single date range, covers both months for the Calendar screen.

### Long-press edit (single day)
- One write query (local UPSERT: insert if the day has no row yet, overwrite if it does).
- Sync Manager: run `sync()` right after the write.
- The UI only reflects the new value once both the write and the sync succeed, no optimistic update before that. On failure, the day keeps showing its previous value and an error is surfaced.

### Insert Shifts screen (bulk, new month)
- One single write query for the whole batch (local multi-row UPSERT), triggered by the one "Save" button.
- Sync Manager: run `sync()` right after the batch write.
- Edge case, explicitly deprioritized for v1: if a day in the target month already has a shift set and the user wants to see/pre-select it in the bulk-insert list, that's not built, the user is expected to fix that specific day via long-press edit on the Calendar screen instead. The bulk Insert screen always starts blank/unselected regardless of existing data.

### Pull-to-refresh (Calendar screen)
- Sync Manager: run `sync()`.
- Re-run the same fetch as startup step 4 (current + next month), no purge re-check needed on every pull-to-refresh.

## Open Points To Validate With Claude Code
1. Calendar cells that fall outside the [current, next] window at the grid edges (e.g. last row of "next month" bleeding into a 3rd month): render as non-interactive placeholder cells with no data, to preserve the "always full week" visual rule.
2. Connectivity failures: writes require reaching the remote to sync back, so a write can still fail if offline even though the local replica exists. UI needs a clear, non-blocking error state for both the startup load and any write action. Not designed in detail here.
3. Visual/color differentiation per shift type is left to a UI/UX pass, not specified here.

## Linked Documents
- `database-models.md` — Turso/libSQL schema, tables, migration/seed script convention.
- `architecture.md` — Flutter module structure, Cubit/state layout, repository pattern, libsql_dart wiring example.
