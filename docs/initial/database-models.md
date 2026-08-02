# Database Models — Turso / libSQL

## Folder Convention (in app codebase)
```
/database
  /schema
    001_schema.sql        # creates DB structure — run FIRST, once, via Turso CLI
  /migrations
    0001_description.sql  # ordered, incremental ALTERs — run in sequence via Turso CLI
    0002_description.sql
  /seed
    seed.sql               # initial shift_types rows — run once, right after schema
```
- These are plain `.sql` scripts, not executed by the app at runtime.
- The developer (not the app) runs them manually with the Turso CLI (`turso db shell <db-name> < file.sql`), once at project init and again whenever a new migration is added.
- `schema/001_schema.sql` must be created and applied FIRST, then `seed/seed.sql` — the coding agent needs both before it can query/verify anything against a real database (the app has no logic to create shift types itself).
- Migrations are numbered and additive; never edit an already-applied migration file, add a new one instead.

## Design Decision: Two Tables, Not One
`shift_types` is split out from `shifts` so the set of valid shift codes is data, not a hardcoded constraint. Adding a 7th shift type later is a seed/insert, not a schema migration or an app code change to a CHECK constraint.

### Table: `shift_types`
Small reference table, rarely written after initial seed.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Native auto-incrementing surrogate key. |
| `code` | TEXT | NOT NULL, UNIQUE, `CHECK (length(code) = 1)` | Single-letter code shown in the UI (`7`,`3`,`N`,`S`,`R`,`F`). |

### Table: `shifts`
One row per calendar day that has a recorded shift. No row = no shift for that day.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | INTEGER | PRIMARY KEY | Not autoincrement. Computed by the app from the date as `YYYYMMDD` (e.g. 2026-08-01 -> 20260801). Naturally unique per day, naturally sortable/incrementing, no separate date column needed, and no century ambiguity (resolved from the earlier `YYMMDD` draft). |
| `shift_type_id` | INTEGER | NOT NULL, REFERENCES `shift_types(id)` | FK to the shift type. |

### `001_schema.sql`
```sql
CREATE TABLE IF NOT EXISTS shift_types (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE CHECK (length(code) = 1)
);

CREATE TABLE IF NOT EXISTS shifts (
  id INTEGER PRIMARY KEY,
  shift_type_id INTEGER NOT NULL REFERENCES shift_types (id)
);
```
No extra index needed on `shifts.id` (it's the primary key already). An index on `shift_type_id` is not worth adding at this data volume (a couple hundred rows max, ever).

### `seed/seed.sql`
```sql
INSERT INTO shift_types (code) VALUES ('7'); -- primo / morning
INSERT INTO shift_types (code) VALUES ('3'); -- secondo / afternoon
INSERT INTO shift_types (code) VALUES ('N'); -- notte / night
INSERT INTO shift_types (code) VALUES ('S'); -- smonto / off-shift rest
INSERT INTO shift_types (code) VALUES ('R'); -- riposo / rest day
INSERT INTO shift_types (code) VALUES ('F'); -- ferie / vacation
```

## Data Lifecycle (no history requirement)
- The app is responsible for deleting out-of-window rows itself, at startup, see specifications.md "App startup" flow and architecture.md. No DB-level TTL/trigger.
- Delete condition: `shifts.id < <first day of current month as YYYYMMDD>`.

## Not Modeled (intentionally, v1 scope)
- No `users` table, single-user app, no auth/multi-tenant model.
- No audit/history table, overwrite is silent and destructive by design (single write query, no versioning).
- No optimistic-locking/version column, concurrent edits from 2 devices are explicitly not handled in v1 (last write wins).

## Linked From
- `specifications.md`
