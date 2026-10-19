# 06 — Write the migration spec

Type: task
Status: resolved
Blocked by: 01, 02, 03, 04, 05
Map: ../map.md
Model: Opus 5.5 · Effort: high (resolved; for reference)

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

Resolved 2026-09-23. [The spec](../spec.md) is written and locked. Build tickets:
[08 — Swap lib/ to shadcn_flutter](08-swap-lib-to-shadcn.md) →
[09 — Port the widget tests](09-port-widget-tests.md) →
[10 — Verify on the emulator, then update the docs](10-verify-and-docs.md).

Not quite "nothing left to decide". Settled in this session:

- **[07 — What colour is a shift in Light mode?](07-light-mode-shift-colours.md)** was open
  and unwired; the user resolved it here (shadcn palette, 300 dark / 700 light).
- **Fresh-install theme stays `ThemeMode.system`** (user). Standing decision 2's
  "Dark (default)" is the look, not the first-launch mode; a test locks `system` in.
- **05 overridden: the Filter uses `Button`, not `Toggle`.** `Toggle.build` swaps the
  given style for a filled `ButtonStyle.secondary` whenever `value` is true
  (`button.dart:312`). `pickedStyle` returns `ButtonStyle(variance: ...)`, since
  `withBorder`/`withForegroundColor` return `AbstractButtonStyle` and `OutlineButton`
  takes no style.
- **Settings `Tabs` must not use `ThemeMode.values[i]`.** shadcn's enum order is
  `system, light, dark`; the tabs read Chiaro, Scuro, Sistema.
- **Month Editor needs `MediaQuery.removePadding(removeTop: true)`**, not just
  `SafeArea(top: false)`: its `ListView` pads itself from `MediaQuery`, and shadcn
  `Scaffold` leaves the top inset in (04).
- **Typography fog closed** by a nearest-size rule (spec §5).

Cleared from the fog: typography, Month Editor (read in full; falls out of the mapping),
verification (spec §9), `catui` teardown order (spec §7, one ticket, no staging).
