# beeshift

A personal shift-schedule app. See `CONTEXT.md` for the language, `docs/adr/`
for the decisions, and `database/README.md` for provisioning Turso.

## Running

Credentials come from the gitignored `env.json` at build time:

```powershell
flutter run --dart-define-from-file=env.json
```

Running from VS Code works too — `.vscode/launch.json` passes the same flag.
Launch any other way and the credentials are empty strings, which surfaces as
`Impossibile aprire il database`.

## Prerequisites

`libsql_dart` compiles its native library from Rust at build time, so a Rust
toolchain is required on the machine running Flutter (Windows here, not WSL):

```powershell
winget install Rustlang.Rustup
rustup target add aarch64-linux-android x86_64-linux-android
```

Tests need no credentials and no network — they run against a temporary local
libSQL file:

```powershell
flutter test
```
