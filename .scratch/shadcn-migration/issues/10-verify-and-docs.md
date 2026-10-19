# 10 — Verify on the emulator, then update the docs

Type: task
Status: resolved
Blocked by: 09
Map: ../map.md
Model: Opus 5.5 · Effort: medium

## Question

Build ticket. HITL: the user looks at the screen with you.

1. Run [the spec](../spec.md) §9 step 4 on the active emulator:
   `pws -c flutter run --dart-define-from-file=env.json`. Walk every check in Dark and in
   Light. Fix what fails; the `RefreshTrigger` fallback is in §9.
2. Write the docs in spec §10: ADR-0006 in `docs/adr/`, the "Shift Colour" entry in
   `CONTEXT.md`. Mark ADR-0004 (house style half) and ADR-0005 as superseded by 0006.
3. Re-run `pws -c flutter analyze` and `pws -c flutter test` after any fix.

Done when every §9 check passes on screen and the user accepts the look.

## Answer

**Verified on the Pixel 9 emulator, Dark and Light; the user accepted the look.** All §9 checks pass. `analyze` clean, 114 tests pass.

Two fixes made during the walk:
- **Status bar icons.** Material's `AppBar` used to set them per brightness; shadcn does not, so Light drew white icons on white. `ShadcnApp.builder` in `lib/main.dart` now wraps the app in an `AnnotatedRegion<SystemUiOverlayStyle>` keyed on `Theme.of(context).brightness`.
- **Bar spacing, at the user's request.** `FloatingBottomBar` padding 4 → 12 horizontal / 8 vertical, 12 between icons; `_barHeightAndGap` 64 → 72 so the grid still clears the taller bar.

Docs per §10 were already in the working tree and match the spec: ADR-0006, the "Shift Colour" entry in `CONTEXT.md`, superseded notes on ADR-0004 (house-style half) and ADR-0005.
