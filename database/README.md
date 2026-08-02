# Database setup

One-time provisioning of the Turso database that backs Beeshift. These steps are run **by hand**, by a human — the app never creates or migrates schema.

Everything here runs fine from WSL; only Flutter itself needs PowerShell.

## 1. Install the Turso CLI

```bash
curl -sSfL https://get.tur.so/install.sh | bash
```

## 2. Log in

```bash
turso auth login
```

If the browser handoff doesn't work from WSL, use the headless flow and paste the token back:

```bash
turso auth login --headless
```

## 3. Create the database

```bash
turso db create beeshift
```

If your account has more than one group, pass `--group <name>`.

## 4. Apply the schema

```bash
turso db shell beeshift < database/schema.sql
```

Verify it landed:

```bash
turso db shell beeshift "SELECT name FROM sqlite_master WHERE type='table'"
```

You should see `shifts`. Then check the `CHECK` constraint actually rejects a bad Shift Code — this is worth doing once, because it's the only server-side guard the app has:

```bash
turso db shell beeshift "INSERT INTO shifts (date, code) VALUES ('2026-01-01','X')"
```

That must fail. If it succeeds, the schema didn't apply as written.

## 5. Collect the two credentials

The sync URL:

```bash
turso db show beeshift --url
```

The auth token:

```bash
turso db tokens create beeshift --expiration never
```

**Use a non-expiring token.** An expiring one doesn't fail loudly — the app just stops syncing on a date you'll have forgotten, and fixing it means a rebuild and a reinstall on both devices. Rotate on demand instead: there is an invalidate/rotate subcommand under `turso db tokens` (`turso db tokens --help`) which invalidates every token for the database, after which you create a fresh one and rebuild.

## 6. Wire the credentials into the app

Create `env.json` at the repo root — **gitignored, never committed**:

```json
{
  "TURSO_DATABASE_URL": "libsql://beeshift-<org>.turso.io",
  "TURSO_AUTH_TOKEN": "<token from step 5>"
}
```

Commit `env.example.json` alongside it with the same keys and empty values, so the required shape is discoverable.

Builds and runs then pass it through:

```bash
pws -c flutter run --dart-define-from-file=env.json
```

## Security note

`--dart-define-from-file` is **not** a secret mechanism. The token is compiled into the APK and can be recovered from the build artifact — anyone holding the APK gets full read/write on this database. That's accepted for a sideloaded single-user app whose data is one person's shift schedule. Two things follow from it: never commit `env.json`, and don't share the built APK.

## Migrations

There aren't any yet. When the first real schema change arrives, create `database/migrations/0001-<description>.sql` and apply it the same way. Never edit an already-applied file — add a new one.
