-- Beeshift schema. Run by hand with the Turso CLI. The app never creates or
-- migrates schema. See ADR-0003 for why there is only one table.
--
--   turso db shell beeshift < database/schema.sql

CREATE TABLE IF NOT EXISTS shifts (
  date TEXT PRIMARY KEY,
  code TEXT NOT NULL CHECK (code IN ('7','3','N','S','R','F'))
);

-- No seed data: Shift Types live in the app as a Dart enum, not in a table.
-- No index on `code`: a few hundred rows, ever.
