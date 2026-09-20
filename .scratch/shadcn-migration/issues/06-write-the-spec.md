# 06 — Write the migration spec

Type: task
Status: open
Blocked by: 01, 02, 03, 04, 05
Map: ../map.md

## Question

Nothing left to decide. Collect every resolved answer on this map into
`.scratch/shadcn-migration/spec.md`, the destination artifact. It must be executable by a
build session that has read nothing else:

- The exact `main.dart` / `ShadcnApp` / `ThemeData` snippet, light and dark (from 01).
- The frozen Shift Colours table with real hex values and its carrier (from 01).
- The full widget mapping table and the residual-Material list (from 02).
- The month grid decision (from 03) and the shell decision (from 04).
- The segmented-control decision (from 05).
- A file-by-file work order over all 16 files in `lib/`, each with its edits named.
- The `pubspec.yaml` change: drop the `catui` git dependency, add `shadcn_flutter`.
- The verification step the build session runs — at minimum
  `pws -c flutter analyze` and `pws -c flutter run --dart-define-from-file=env.json`
  against one emulator, per `CLAUDE.md`.

Then break the spec into build tickets under `.scratch/shadcn-migration/issues/`,
numbered from `07`. The map is done when this ticket resolves.

## Answer

<!-- filled on resolution -->
