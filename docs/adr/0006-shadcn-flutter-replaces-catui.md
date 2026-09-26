# `shadcn_flutter` replaces `catui`

Supersedes the house-style half of ADR-0004 ("The look") and all of ADR-0005. The navigation half of ADR-0004 stands.

Beeshift takes its widgets, theme and icons from `shadcn_flutter` (0.0.54). `catui` and `package:flutter/material.dart` are gone from `lib/`. The app is a `ShadcnApp`; `ThemeCubit` drives its `theme`, `darkTheme` and `themeMode` unchanged, and the fresh-install default stays `ThemeMode.system`.

## The theme

`lib/shared/theme.dart` builds both themes from shadcn's Slate schemes with an Amber accent layered on: `primary` and `ring` are amber-500, `primaryForeground` is slate-950. The rest is fixed: `radius: 0.75`, `scaling: 1.0`, `Density.reducedDensity`, `surfaceOpacity: 1.0`, `surfaceBlur: 8.0`. The radius and blur are judgement values, not API constants.

## Shift Colours

Six Tailwind hues from shadcn's palette, shade 300 on the dark ground and shade 700 on the light one: orange (Primo), blue (Secondo), violet (Notte), teal (Smonto), green (Riposo), pink (Ferie). Amber is the accent and red is the error colour, so neither is a Shift Colour — the same rule ADR-0005 made for yellow and red.

They live in `ShiftColors`, a static class with a `dark` and a `light` table, and `ShiftColors.of(context)` picks one by the theme's brightness.

**A `ThemeExtension`, as ADR-0005 chose** — no longer possible. shadcn's `ThemeData` has no `extensions` slot.

**A static brightness-keyed class** — chosen. ADR-0005 rejected a `const` table because it would need one table per flavor and would sit outside the theme. Both objections shrink here: there are exactly two brightnesses, the two tables sit side by side in one file, and the lookup still goes through `Theme.of(context)` for the brightness. What is lost is the lerp on theme switch; the colours snap instead.

## Consequences

A seventh Shift Type needs an entry in both tables. Call sites read `ShiftColors.of(context)[type]!`, so a missing entry throws in the first test that draws it.

Accepted: orange-300 (Primo) sits close to the amber-500 accent (1.27:1), and day tiles are 9px round rather than catui's 8px.
