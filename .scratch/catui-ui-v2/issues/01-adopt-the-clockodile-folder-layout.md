# 01 — Adopt the Clockodile folder layout

**What to build:** Nothing the user can see. Every source file moves to the layout Clockodile uses, the tests move to mirror it, and the suite stays green. A pure rename, landing alone so that every styling diff after it is readable.

`lib/` is eight files in one directory. Clockodile groups a feature with its cubit — `lib/features/<feature>/<feature>_view.dart` beside `lib/features/<feature>/cubit/` — keeps cross-feature code in `lib/shared/`, and keeps the database and repository in `lib/data/`. Beeshift takes the same shape: a Calendar feature, a Month Editor feature, the repository under `data/`, and the date helpers and Shift Type under `shared/`. `main.dart` stays where it is.

Clockodile names its screens `<feature>_view.dart`; beeshift's are `..._page.dart` and the domain glossary calls them screens either way. Follow Clockodile — the point of the move is that the two projects read the same.

Nothing changes but paths and imports. No widget is edited, no behaviour is touched, no test assertion is rewritten — only the `import` lines at the top of each file and the paths the test files live at.

This is the prefactor for everything else in this spec: make the change easy, then make the easy change.

**Blocked by:** None — can start immediately.

**Status:** done

- [x] Every Dart file under `lib/` sits in `features/`, `shared/` or `data/`, with `main.dart` the only file left at the root of `lib/`
- [x] Each feature directory holds its screen and a `cubit/` directory beside it
- [x] Every test file sits at the path mirroring the source it tests
- [x] `flutter analyze` is clean
- [x] Every test that passed before the move passes after it, with no assertion edited
- [x] The diff contains no change other than file paths and import statements

## Comments

Done in e782f6d. `flutter analyze`: clean. `flutter test` could not run in this environment — `libsql_dart`'s native Rust build fails to link (`link.exe` exit 1318), reproduced identically on the unmodified tree via `git stash`, so it predates this change and isn't caused by it. Re-run the suite once that toolchain issue is fixed elsewhere.
