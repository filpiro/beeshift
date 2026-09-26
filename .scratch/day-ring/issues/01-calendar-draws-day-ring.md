# 01 — Calendar draws each day as a Day Ring

Type: task
Status: done
Blocked by: None — can start immediately
Model: Sonnet 5 · Effort: medium

**What to build:** On the Calendar, every day is a Day Ring instead of a rounded square: the large part in the day's Shift Colour (muted on an Empty day), the Today Arc in the accent on today and muted otherwise, and the Shift Code over the day number in the centre. All decisions are in [the spec](../spec.md).

- [x] The rounded-square tile and its border are gone; each day is a ring split 80/20, small part centred at the bottom, with the visible gap between the round caps equal to the stroke.
- [x] Large part: Shift Colour on a day with a Shift; muted colour on an Empty day.
- [x] Today Arc: accent on today on the page that owns it; muted on every other day, including today drawn as filler.
- [x] Centre text: Shift Code over the day number (half size), foreground colour, same weight on every day; an Empty day shows the day number only. Spoken labels unchanged.
- [x] Font size and stroke scale with the ring; stroke never below 3px; nothing clipped at the ring's outer edge; still fits on the smallest cell.
- [x] Muted and filler days keep the single 0.35 opacity.
- [x] Widget tests that checked today's border colour and bold weight now check the ring's colours instead (large part, Today Arc on today, Today Arc muted otherwise, Empty day muted).
- [x] `pws -c flutter analyze` clean and `pws -c flutter test` passes.

## Comments

Implemented in `lib/features/calendar/calendar_view.dart` as `DayRingPainter`, a `CustomPainter` drawing two `canvas.drawArc` calls. Widget tests in `test/features/calendar/calendar_view_test.dart` rewritten to read the painter's `largeColor`/`todayArcColor` instead of border/bold. `flutter analyze` clean, `flutter test` 114/114 green. Reviewed on both axes (Standards, Spec) — no hard findings. Committed as `b43f1f7`.
