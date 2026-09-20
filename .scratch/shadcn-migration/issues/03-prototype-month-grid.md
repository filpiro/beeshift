# 03 — Prototype the month grid and day cell in shadcn

Type: prototype
Status: resolved
Blocked by: 01, 02
Map: ../map.md

## Question

`lib/features/calendar/calendar_view.dart` is 488 lines and the single biggest risk on
this map. Its `_MonthGrid` and `_DayCellView` are hand-built `Column`/`Row` layouts that
paint each day with its Shift Colour. Everything else on this map is a swap; this one is
a judgement call about how it should look and behave under shadcn tokens.

Build a cheap, throwaway prototype — use `/prototype` — and put it in front of the user
to react to. It must answer:

1. **Hand-rolled grid, or `shadcn_flutter`'s `Calendar`?** Read
   `components/utility/calendar.md`. Can its day cell be overridden to carry an arbitrary
   per-day background colour and the Italian shift letter? If it cannot, the existing
   hand-rolled grid stays and only its colours and radius change — which is the cheaper
   answer and the one to favour unless the prototype shows otherwise.
2. **Does `density: Reduced` wreck the day cell?** Reduced density shrinks padding and
   tap targets. Show the cell at Reduced against the current build.
3. **Do the frozen Shift Colours still read** against a Slate dark surface the way they
   did against Catppuccin Mocha? Contrast of the day number over each of the six hues.

**Hard requirement, from ticket 02.** Deleting the `ShiftColors` `ThemeExtension` is the
single thing blocking a Material-free `lib/`. The prototype must show the frozen `const`
map working end to end at all three call sites, not just at the day cell.

Link the prototype from this ticket. Do not merge it. Resolve with a decision, not code.

## Prototype

https://claude.ai/artifact/VAfxwB38vcADAGjgFvAR1Q — static HTML mock: the month grid
on the Catppuccin Mocha ground beside the shadcn `darkSlate` ground, the six Shift Codes
at their frozen hues, measured contrast on both, and the cell at three viewport sizes.
Not Flutter: `shadcn_flutter` is not yet a dependency and this map does not add one.

## Answer

Accepted by the user on the prototype, 2026-09-20.

### 1. The hand-rolled grid stays

`shadcn_flutter`'s `Calendar` cannot carry a day cell of beeshift's shape. Its whole
surface is `now`, `value`, `view`, `selectionMode`, `onChanged`, `isDateEnabled` and
`stateBuilder` — and `stateBuilder` is `DateState Function(DateTime)`, returning
enabled / disabled / selected. A state, not a widget and not a colour. There is no
day-cell builder, no per-day background slot, and nowhere to put the Shift Code. It also
exists to *select* dates, which the Calendar page never does — the Month Editor is the
only way in.

So `_MonthGrid` and `_DayCellView` survive the migration as they are. The changes are
narrow and mechanical:

- `AppTokens.radius` becomes the shadcn radius (ticket 01: `ThemeData.radius` multiplier).
- `theme.colorScheme.outlineVariant` (the resting tile border) becomes
  `ColorScheme.border` — `#1E293B` on `darkSlate`.
- `theme.colorScheme.primary` (the stand-in for a day with no Shift) becomes the
  Amber accent layered by ticket 01's `copyWith`.
- `theme.textTheme.labelMedium` / `.titleLarge` become shadcn typography slots — left to
  the token-mapping work, not decided here.

The `LayoutBuilder` square-ceiling sizing, the `Opacity` double-dim rule, the `Stack`,
the `FittedBox` scaling and today's Shift-Coloured border are all untouched.

### 2. `density: Reduced` does not reach the day cell

`ThemeData.density` scales the padding of `shadcn_flutter`'s own components — buttons,
inputs, list tiles. `_DayCellView` is `Padding` + `DecoratedBox` + `Stack` with literal
insets (`EdgeInsets.all(2)`, `top: 6`, `right: 6`, `left: 8`, `bottom: 4`) over a side
computed by `LayoutBuilder` from the viewport. Nothing in it reads density, so the tile
keeps exactly the size it has today at any density setting. No per-widget override is
needed, and the map's "density fallout" fog closes with it.

The cell also has no gesture handling of any kind, so the usual Reduced-density worry —
shrinking tap targets — does not apply here at all.

### 3. The frozen Shift Colours read better on Slate, not worse

`ColorSchemes.darkSlate` grounds at `#020817`; Catppuccin Mocha grounds at `#1e1e2e`.
The hues are frozen and unchanged, so every one gains roughly 22% contrast:

| Shift | Hue | on Mocha | on Slate |
| :--- | :--- | ---: | ---: |
| primo `7` | `#fab387` peach | 9.27:1 | 11.30:1 |
| secondo `3` | `#89b4fa` blue | 7.79:1 | 9.50:1 |
| notte `N` | `#cba6f7` mauve | 8.07:1 | 9.85:1 |
| smonto `S` | `#94e2d5` teal | 11.01:1 | 13.43:1 |
| riposo `R` | `#a6e3a1` green | 11.03:1 | 13.46:1 |
| ferie `F` | `#f5c2e7` pink | 10.74:1 | 13.10:1 |

The weakest pair clears WCAG AAA (4.5:1) twice over. No hue needs adjusting.

**A correction to the question as asked.** The ticket asks for "contrast of the day number
over each of the six hues". There is no colour slab behind the day number — the tile face
is transparent. The Shift Colour paints the *Shift Code letter* and, on today, the tile
*border*. The table above measures what is actually drawn. The day number itself is
`ColorScheme.foreground` (`#F8FAFC`) on the ground: 19.12:1, up from Mocha's 11.34:1.
The resting border sits at 1.37:1 against the ground (Mocha: 1.30:1) — decoration, not
text, so no threshold applies.

### What this prototype did not show

The ticket's hard requirement from 02 — the frozen `const` map working end to end at all
three call sites — is **not** demonstrated. `shadcn_flutter` is not a dependency of this
repo and this map does not add one (standing decision 1: plan only), so a runnable Flutter
prototype was not available. The prototype is a static HTML mock of the rendered result.

This is not a gap in the route: ticket 01 already settled the carrier — `ThemeData` has no
`extensions` slot, the hues no longer vary by flavor, so `ShiftColors` becomes a top-level
`const Map<ShiftType, Color>` and the `ThemeExtension` is deleted. The three call sites —
`calendar_view.dart:213`, `calendar_view.dart:413`, `month_editor_view.dart:82` — are a
mechanical swap of `ShiftColors.of(context)` for a lookup in that `const` map. The
spec (06) records that swap; the build session proves it with `pws -c flutter analyze`.
