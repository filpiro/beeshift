# A single `shifts` table, keyed by ISO date

```sql
CREATE TABLE IF NOT EXISTS shifts (
  date TEXT PRIMARY KEY,
  code TEXT NOT NULL CHECK (code IN ('7','3','N','S','R','F'))
);
```

That is the whole schema. Shift Types live in the app as a Dart enum, not in a reference table, and the day is stored as an ISO `YYYY-MM-DD` string rather than a `YYYYMMDD` integer.

## Considered Options

**A separate `shift_types` table with an FK** — rejected. The stated justification was that a seventh Shift Type would then be an insert rather than a code change. It wouldn't be: the table holds only `id` and `code`, while the Italian labels, the display order, the radio buttons and any future per-type colour all live in the app regardless. A new Shift Type requires an app release either way, so the second table bought flexibility that never existed, at the cost of a JOIN on the app's hottest query, a seed script, a reference-data load at startup, a repository, a model, and an `id`→`code` indirection carried through every Cubit.

**`INTEGER` day key as `YYYYMMDD`** — rejected. It sorts and range-queries exactly as well as ISO text and saves about 1 KB across the app's entire lifetime, but both conversion directions become hand-rolled digit arithmetic. With ISO text they are `DateTime.parse(s)` and `d.toIso8601String().substring(0, 10)` — so the date-conversion module disappears instead of needing tests. ISO text is also SQLite's canonical date format and is readable in `turso db shell`.

## Consequences

The enum is the real source of truth for Shift Types: exhaustive `switch` gives compile-time safety an FK never could. The `CHECK` constraint is kept as a cheap backstop so a bad row fails loudly at the database rather than silently reaching the UI. Adding a seventh Shift Type therefore needs a migration to widen the `CHECK` — alongside the app release it already required.

Since the seed script is gone and there is one table, the SQL scripts collapse to a single `database/schema.sql`. Create `database/migrations/0001-*.sql` when the first real migration exists, not before. These are still run by hand with the Turso CLI; the app never creates or migrates schema.
