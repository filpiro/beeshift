# Turso embedded replica via `libsql_dart`

The app runs on two genuinely-used devices, so a cloud database is mandatory — but usage is overwhelmingly *read* (consulting the calendar), with writes only around once a month plus a handful of corrections. We therefore use Turso (libSQL) with an **embedded replica**: every read hits the local SQLite file, and the network is touched only when syncing or writing. This keeps the common path fast and makes reads a purely local concern. See ADR-0002 for how writes behave.

## Considered Options

- **`libsql_dart`** — chosen. Currently the community package that actually supports embedded replica mode on Dart.
- **`turso_dart` / Turso Sync** — rejected for now. Both are in preview and not fully supported on Dart. Revisit as a migration target once Turso ships an official, stable Dart sync client.
- **Local-only SQLite, no cloud** — rejected. Two-device use is a real requirement, and retrofitting sync later would mean rewriting the data layer.

## Consequences

Turso remains the source of truth, but the app never queries it directly. The local replica file is disposable cache: if it is lost (reinstall, cache clear), the next sync repopulates it.

Concurrency between the two devices is deliberately **not** guarded — no version columns, no optimistic locking, no conflict resolution. Last write wins, untracked. This is a single-user app; guards against self-conflict would be complexity with no payer.
