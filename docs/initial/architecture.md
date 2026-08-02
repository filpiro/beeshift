# Suggested Architecture — Flutter + libsql_dart (Turso, embedded replica, manual sync)

Example/reference layout, not a mandate, validate/adjust during the Claude Code planning session.

## High-Level Stack
- Flutter (Android only, v1)
- State management: `flutter_bloc` (Cubit)
- DB client: `libsql_dart`, embedded replica mode: local SQLite file, no periodic auto-sync. Sync is triggered explicitly, from the UI layer, at 3 points only: app open, right after any write, and pull-to-refresh.
- Package decision resolved: `libsql_dart`, not `turso_dart` (the latter is still under active development, migrate later once Turso ships an official Dart sync client).

## Layering
```
UI (Cubits + widgets)
  |
Repository            -- reads/writes the LOCAL replica only, no knowledge of syncing
  |
Local Database (embedded replica file)
  |
Sync Manager           -- the ONLY thing that talks to Turso; wraps client.sync()
  |
Turso
```
- The UI layer is what decides WHEN to sync (it knows about lifecycle events like "screen opened" or "pull to refresh"), by calling the Sync Manager directly. It is NOT the Repository's job to trigger syncs, the Repository is a pure local-DB accessor.
- Concretely: Cubits hold both a `ShiftsRepository` and a `SyncManager` reference and orchestrate the call order themselves (sync → repo query, or repo write → sync), matching the flows in specifications.md.

## Folder Structure
```
lib/
  main.dart
  app.dart                        # MaterialApp, theme, initial route
  core/
    db/
      turso_client.dart           # LibsqlClient.replica(...), no syncIntervalSeconds set
      db_constants.dart           # table/column name constants
    sync/
      sync_manager.dart           # wraps client.sync(), the ONLY caller of it in the app
    date/
      date_id.dart                # DateTime <-> YYYYMMDD int conversion (the shifts.id format)
      week_utils.dart              # Monday-start week math, month-grid generation
  data/
    models/
      shift_type.dart              # ShiftType { id, code } — loaded from DB, not hardcoded
      shift.dart                   # Shift { dateId (int, YYMMDD), shiftTypeId }
    repositories/
      shift_types_repository.dart      # interface + impl, loads the 6(+) reference rows
      shifts_repository.dart           # interface
      shifts_repository_impl.dart      # libsql_dart-backed implementation
  features/
    calendar/
      cubit/
        calendar_cubit.dart
        calendar_state.dart
      view/
        calendar_screen.dart
        widgets/
          month_grid.dart
          day_cell.dart
          edit_shift_dialog.dart
    insert_shifts/
      cubit/
        insert_shifts_cubit.dart
        insert_shifts_state.dart
      view/
        insert_shifts_screen.dart
        widgets/
          day_list_item.dart
          shift_radio_group.dart
database/                         # NOT app code, see database-models.md
  schema/
  migrations/
  seed/
```

## Repositories
Pure local-DB accessors. Neither repository ever calls `sync()` — that's exclusively the Sync Manager's job, invoked by the Cubits.

### `ShiftTypesRepository`
Reference data, loaded once per app session (e.g. in `app.dart` before showing the Calendar screen), then held in memory and passed down.
```dart
abstract class ShiftTypesRepository {
  Future<List<ShiftType>> getAll(); // SELECT id, code FROM shift_types (local)
}
```

### `ShiftsRepository`
One method per query from specifications.md's "Exact Query Flow", no sync calls inside.
```dart
abstract class ShiftsRepository {
  /// Local SELECT + conditional local DELETE, only if the SELECT found rows.
  Future<void> purgeBefore(int firstDayOfCurrentMonthId);

  /// Local SELECT joining shifts + shift_types for [fromId, toId].
  Future<Map<int, String>> getShiftsInRange(int fromId, int toId); // dateId -> code

  /// Local UPSERT. Returns success/failure, caller (Cubit) decides when to sync.
  Future<bool> upsertShift(int dateId, int shiftTypeId);

  /// Local multi-row UPSERT for a whole month batch.
  Future<bool> insertMonth(Map<int, int> dateIdToShiftTypeId);
}
```

### `SyncManager`
```dart
class SyncManager {
  SyncManager(this._client);
  final LibsqlClient _client;

  /// Pulls/pushes against Turso. Called explicitly by Cubits at the 3 defined
  /// trigger points only: app open, right after a write, pull-to-refresh.
  /// No periodic timer anywhere in this class.
  Future<bool> syncNow() async {
    try {
      await _client.sync();
      return true;
    } catch (_) {
      return false;
    }
  }
}
```

## DB Client Wiring (embedded replica, no periodic sync)
```dart
// core/db/turso_client.dart
final dir = await getApplicationCacheDirectory();
final localDbPath = '${dir.path}/shifts_local.db';

final client = LibsqlClient.replica(
  localDbPath,
  syncUrl: const String.fromEnvironment('TURSO_DATABASE_URL'),
  authToken: const String.fromEnvironment('TURSO_AUTH_TOKEN'),
  // syncIntervalSeconds intentionally omitted: no background timer.
  // Sync only ever happens via SyncManager.syncNow(), called by the UI layer.
);

await client.connect();
```
Flag to verify against the actual `libsql_dart` API before scaffolding: confirm that omitting `syncIntervalSeconds` truly disables periodic sync rather than falling back to some default interval, and confirm `client.sync()` is the correct manual-trigger method name/signature. The public docs shown to build this file only demonstrate the periodic-interval configuration, not a manual-only one.

Local file lifecycle note: it's disposable cache, not app data. If deleted (reinstall, cache clear), the next `SyncManager.syncNow()` at app-open just repopulates it from Turso. Nothing is lost, because Turso remains the only source of truth.

## Query Implementations

### Startup purge (`purgeBefore`)
```dart
final exists = await client.query(
  'SELECT 1 FROM shifts WHERE id < ? LIMIT 1',
  positional: [firstDayOfCurrentMonthId],
);
if (exists.rows.isNotEmpty) {
  await client.execute(
    'DELETE FROM shifts WHERE id < ?',
    positional: [firstDayOfCurrentMonthId],
  );
}
```

### Fetch window (`getShiftsInRange`)
```dart
final result = await client.query(
  '''
  SELECT shifts.id, shift_types.code
  FROM shifts
  JOIN shift_types ON shift_types.id = shifts.shift_type_id
  WHERE shifts.id BETWEEN ? AND ?
  ''',
  positional: [fromId, toId],
);
```

### Single edit (`upsertShift`)
```dart
await client.execute(
  '''
  INSERT INTO shifts (id, shift_type_id) VALUES (?, ?)
  ON CONFLICT (id) DO UPDATE SET shift_type_id = excluded.shift_type_id
  ''',
  positional: [dateId, shiftTypeId],
);
```

### Bulk insert (`insertMonth`)
One statement, multiple value rows, same UPSERT semantics, so pre-existing days in the target month are safely overwritten even though the Insert screen doesn't pre-load them (see specifications.md edge case note).
```dart
final values = entries.map((_) => '(?, ?)').join(', ');
final positional = entries.expand((e) => [e.dateId, e.shiftTypeId]).toList();
await client.execute(
  '''
  INSERT INTO shifts (id, shift_type_id) VALUES $values
  ON CONFLICT (id) DO UPDATE SET shift_type_id = excluded.shift_type_id
  ''',
  positional: positional,
);
```

## Calendar Screen — State Sketch
```dart
class CalendarState {
  final DateTime currentMonth;        // real "today" month, fixed reference for highlighting
  final int visiblePageIndex;         // 0 = current month, 1 = next month (2-page carousel only)
  final Map<int, String> shiftCodeByDateId; // dateId (YYYYMMDD) -> single-letter code
  final bool isLoading;
  final bool isRefreshing;            // pull-to-refresh in progress, distinct from initial isLoading
  final String? errorMessage;         // sync/read/write failures, shown non-blockingly
}
```
- `CalendarCubit(this._repo, this._sync)`.
- `init()`: `await _sync.syncNow()` → `await _repo.purgeBefore(...)` → `await _repo.getShiftsInRange(...)`. Sequential, in that order, matching specifications.md's startup flow.
- `onPullToRefresh()`: `await _sync.syncNow()` → `await _repo.getShiftsInRange(...)` (no purge re-check here, that's startup-only).
- `month_grid.dart` builds a Monday-start grid, padding leading/trailing days from adjacent months so every row has 7 cells. Days outside the [current, next] window render as inert placeholders (see specifications.md open point 1).
- Long-press -> `edit_shift_dialog.dart` -> on save: `await _repo.upsertShift(dateId, shiftTypeId)` -> if success, `await _sync.syncNow()` -> if both succeed, update `shiftCodeByDateId` in local state. If either step fails, leave state untouched and set `errorMessage`.

## Insert Shifts Screen — State Sketch
```dart
class InsertShiftsState {
  final DateTime targetMonth;                  // "next month"
  final Map<int, int?> selections;              // dateId -> shiftTypeId, local unsaved edits
  final bool isSaving;
  final String? errorMessage;
}
```
- Radio taps update the local `selections` map only, no persistence per item.
- "Save": `await _repo.insertMonth(selections)` -> if success, `await _sync.syncNow()` -> if both succeed, pop back to Calendar and let `CalendarCubit.onPullToRefresh()`-equivalent logic (or a targeted re-fetch) update what's shown. If either step fails, stay on screen with `errorMessage` set, selections preserved so the user doesn't lose input.

## What Was Deliberately Left Out (per product decisions)
- No periodic/background sync, no retry/backoff loop inside `SyncManager`, no write queue. If `syncNow()` fails, the calling Cubit surfaces an error and the user retries the action manually (e.g. pull-to-refresh again).
- No concurrency/conflict resolution (e.g. no version column, no optimistic locking) since 2-device concurrent edits are out of scope for v1.
- No pre-population of existing values in the bulk Insert screen.
- No caching/memoization inside the Repository layer beyond what the embedded replica file itself already provides.

## Linked From
- `specifications.md`
