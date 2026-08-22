# Flutter Environment

* Flutter is installed on Windows.
* The workspace lives on Windows.
* Claude Code, Codex, Opencode runs from WSL.

All path handling and shell commands must account for this split environment.

## Commands

**Always** run Flutter/Dart commands through PowerShell using `pws` (alias for `pwsh.exe`).

```bash
pws -c flutter run
pws -c dart pub get
```

**Do not** run Flutter/Dart commands directly from WSL.

This repo use custom env, alwayse use `--dart-define-from-file=env.json`

`libsql_dart` (Turso/rust connector) uses Dart native-assets hooks that cargo-build
per Android ABI under `.dart_tool/hooks_runner/`. Each ABI leaves its own ~2GB
cargo `target/` cache, never cleaned.

`--target-platform` only exists on `flutter build`, not `flutter run` — it errors
with "Could not find an option named" if passed to `run`. `flutter run` builds for
whatever device/emulator you're attached to, so the cache stays single-ABI as long
as you always run against the same device architecture. Switching between an
arm64 device and an x86_64 emulator is what stacks the caches.

```bash
pws -c flutter run --dart-define-from-file=env.json
pws -c flutter build apk --dart-define-from-file=env.json --target-platform=android-arm64
```

If `.dart_tool` balloons again (multiple ABI dirs under
`.dart_tool/hooks_runner/shared/libsql_dart/build/`), run `pws -c flutter clean`.

# Rules

- Before editing any file, read it first. Before modifying a function, use `ast-grep` to retrive all callers. Research before you edit.

## Test
You can use active emulator 

## Agent skills

### Issue tracker

Issues live as markdown files under `.scratch/<feature-slug>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Default five-role vocabulary; the label string equals the role name. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.