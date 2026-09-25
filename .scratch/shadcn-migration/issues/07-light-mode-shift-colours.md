# 07 — What colour is a shift in Light mode?

Type: grilling
Status: resolved
Map: ../map.md
Model: Opus 5.5 · Effort: medium (resolved; for reference)

## Question

Surfaced by ticket 01. Standing decisions 3 and 4 collide.

Today `ShiftColors.forFlavor(flavor)` takes the hues **per flavor**: Light mode draws the
calendar in Catppuccin **Latte** (dark, muted hues on a pale surface), Dark mode draws it
in **Mocha** (light, bright hues on a dark surface). Same six roles, two different tables.

Standing decision 4 froze the hues on Mocha. Standing decision 3 kept the Light/Dark
switch. So as written, Light mode would get Mocha's bright pastels on a pale Slate
surface — washed out, and a visible change from today.

Decide, with the user:

1. **Two frozen tables or one?** Freeze Latte *and* Mocha as two `const` maps and pick by
   brightness — that keeps today's look exactly, at the cost of the carrier having to read
   the current brightness rather than being a plain top-level constant.
2. **Or one table, and accept Light mode changes.** Simplest carrier. Needs the user to
   look at it and accept the new Light calendar.
3. **Or re-derive the Light six from Slate + Amber**, which reopens the question ticket 03
   already asks about contrast, and should only be chosen if 1 and 2 both fail.

Favour option 1 if the user cares that Light mode looks unchanged; it is six more hex
values and one `Theme.of(context).brightness` read, not a design project. Capture the
Latte hexes from `catppuccin_flutter` the same way ticket 01 captured Mocha's.

Feeds ticket 03 (contrast prototype) and ticket 06 (the spec).

## Answer

Resolved 2026-09-23 with the user, during the ticket 06 session.

**None of the three options as written.** The user chose shadcn's own palette over
Catppuccin in both modes: "use shadcn colour based on Amber". That is option 3 with a
fixed recipe, so it reopens no design work:

- **Six Tailwind hues from `shadcn_flutter`'s `Colors`**, each the nearest to today's
  Catppuccin hue. Amber (the accent) and red (the error colour) stay out, as CONTEXT.md
  already requires.
- **Shade 300 in Dark, shade 700 in Light.** Two tables, picked by brightness.
- Hex values read from `shadcn_flutter-0.0.54/lib/src/theme/generated_colors.dart`.

| ShiftType | Hue | Dark (300) | Light (700) | on `#020817` | on `#FFFFFF` |
| --- | --- | --- | --- | ---: | ---: |
| `primo` | orange | `0xFFFDBA74` | `0xFFC2410C` | 11.86:1 | 5.18:1 |
| `secondo` | blue | `0xFF93C5FD` | `0xFF1D4ED8` | 11.09:1 | 6.70:1 |
| `notte` | violet | `0xFFC4B5FD` | `0xFF6D28D9` | 10.84:1 | 7.10:1 |
| `smonto` | teal | `0xFF5EEAD4` | `0xFF0F766E` | 13.52:1 | 5.47:1 |
| `riposo` | green | `0xFF86EFAC` | `0xFF15803D` | 14.25:1 | 5.02:1 |
| `ferie` | pink | `0xFFF9A8D4` | `0xFFBE185D` | 11.03:1 | 6.04:1 |

Every pair clears WCAG AA (4.5:1). Known risk, accepted: `primo` orange sits near the
Amber accent (orange-300 vs amber-500 is 1.27:1). The user kept orange over rose, because
rose sits near red.

**This changes ticket 01's carrier.** The hues now vary by brightness, so a single
top-level `const` map is not enough. `ShiftColors` becomes a class with two `const` maps
and a static `of(context)` that reads `Theme.of(context).brightness` (a real getter on
shadcn's `ThemeData`, `theme.dart:286`). No `InheritedWidget`, no `ThemeExtension`.
Standing decision 4 ("freeze on Mocha") is replaced by this table. The call shape
`ShiftColors.of(context)[type]` survives, with a `!` since a map lookup is nullable.
