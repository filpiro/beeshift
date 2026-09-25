# 10 — Verify on the emulator, then update the docs

Type: task
Status: open
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

<!-- filled on resolution -->
