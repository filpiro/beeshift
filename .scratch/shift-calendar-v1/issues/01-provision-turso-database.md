# 01 — Provision the Turso database

**What to build:** A live Turso database with the `shifts` table in it, and the two credentials the app needs, in a form the app can consume without either of them ever reaching version control. Nothing in the app works until this exists — there is no local-only fallback.

This one is done by a human, not an agent: it needs a Turso account, an interactive browser login, and a token that must never be pasted into a file an agent can commit. The step-by-step commands live in the database setup guide committed alongside the schema.

**Blocked by:** None — can start immediately.

**Status:** ready-for-human

- [ ] Turso CLI installed and authenticated
- [ ] A `beeshift` database exists
- [ ] The committed schema has been applied to it, and the `shifts` table is present
- [ ] Inserting an invalid Shift Code is rejected by the `CHECK` constraint — verified once, by hand
- [ ] A non-expiring auth token has been created, with the rotation path understood
- [ ] The sync URL and token are in a gitignored `env.json` at the repo root
- [ ] An `env.example.json` with the same keys and empty values is committed
- [ ] `env.json` is listed in `.gitignore` before the token is ever written into it
