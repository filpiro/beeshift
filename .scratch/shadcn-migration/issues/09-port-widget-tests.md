# 09 — Port the widget tests

Type: task
Status: open
Blocked by: 08
Map: ../map.md
Model: Sonnet 5 · Effort: high

## Question

Build ticket. Execute [the spec](../spec.md) §8 over `test/`.
Six files: `test/main_test.dart`, `test/shared/shift_colors_test.dart`,
`test/features/settings/cubit/theme_cubit_test.dart`,
`test/features/calendar/calendar_view_test.dart`,
`test/features/month_editor/month_editor_view_test.dart`,
`test/features/shell/shell_view_test.dart`.

Keep what each test asserts; change only how it finds and harnesses widgets.
If a test's intent cannot survive the swap, say which and why under `## Answer` —
do not delete it silently.

Done when:

- `grep -rn "package:flutter/material.dart\|package:catui" test` prints nothing.
- `pws -c flutter analyze` reports no issues.
- `pws -c flutter test` passes.

## Answer

<!-- filled on resolution -->
