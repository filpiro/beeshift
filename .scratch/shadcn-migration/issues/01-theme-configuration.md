# 01 — Pin the ShadcnApp theme, and find a home for Shift Colours

Type: research
Status: resolved
Map: ../map.md

## Question

Two halves, both answerable from `.claude/skills/shadcn-flutter/guides/theming.md`,
`guides/colors.md`, `components/getting_started/theme.md`, and the pub.dev API docs.

**A. The theme object.** Produce the exact `ShadcnApp` + `ThemeData` Dart snippet for the
agreed settings, with every value named against a real API member:

| Setting | Value | Real API member? |
| --- | --- | --- |
| themeMode | Dark (default) | `ShadcnApp.themeMode` — confirm the enum |
| baseColors | Slate | `ColorSchemes.darkSlate` / `.lightSlate` — confirm both exist |
| accentColors | Amber | how an accent is layered onto a base scheme — is there a `ColorSchemes` variant, a `copyWith`, or a `Colors.amber` shade table? |
| radius | Rounded | `ThemeData.radius` is a `double` multiplier (default `0.5`). What number is "Rounded"? |
| density | Reduced | `ThemeData.density` takes a `Density`. List the enum values. |
| scaling | Default | `ThemeData.scaling`, default `1.0` |
| surfaceOpacity | Solid | Does `surfaceOpacity` exist on `ThemeData`? If yes, what is "Solid"? If no, say so. |
| surfaceBlur | Medium | Same question. |

Then give the **Light counterpart**, built from the same Slate + Amber pair, since the
Light/Dark/System switch survives (map Notes, standing decision 3). Confirm `ShadcnApp`
accepts `theme` + `darkTheme` + `themeMode` the way `MaterialApp` does — the existing
`ThemeCubit` drives exactly that.

**B. The Shift Colours carrier.** `lib/shared/shift_colors.dart` is a Material
`ThemeExtension<ShiftColors>`, read via `Theme.of(context).extension<ShiftColors>()`.
Material's `Theme` is going away. Find out:

- Does `shadcn_flutter`'s `ThemeData` support extensions, or any equivalent slot?
- If not, what is the idiomatic carrier — a plain `InheritedWidget`, a top-level `const`
  map, or something the package provides?
- Since the six hues are now frozen constants (standing decision 4) and no longer vary by
  flavor, does the carrier need to be theme-aware at all, or is a plain `const` table enough?

Record the six current Catppuccin **Mocha** hex values for `primo`, `secondo`, `notte`,
`smonto`, `riposo`, `ferie` so the build session can paste them in. Source them from the
`catui` package, not from memory.

## Answer

Sources actually read: local skill docs `guides/theming.md`, `guides/colors.md`,
`guides/installation.md`, `components/application/wrapper.md`,
`components/getting_started/theme.md` (note: that file is mislabelled — its content is
`NavigationBarTheme`, nothing about `ThemeData`); pub.dev dartdoc for **shadcn_flutter
0.0.54**: `ThemeData`, `ThemeData/surfaceOpacity`, `ThemeData/surfaceBlur`, `ColorSchemes`,
`ColorScheme`, `ColorScheme/copyWith`, `ColorShades`, `Colors`, `Density`, `ShadcnApp`,
`ThemeMode`, `ComponentTheme`, `ComponentThemeData`, `Data`; package source
`catppuccin_flutter-1.0.0/lib/src/flavors/mocha.dart`.

### A. The theme object

`ThemeData` constructor, confirmed from the dartdoc class page — full list:
`colorScheme` (`ColorScheme`, default `ColorSchemes.lightSlate`), `radius` (`double`, default
`0.5`), `scaling` (`double`, default `1`), `typography` (`Typography`, default
`const Typography.geist()`), `iconTheme` (`IconThemeProperties`), `platform`
(`TargetPlatform?`), `surfaceOpacity` (`double?`), `enableFeedback` (`bool?`), `surfaceBlur`
(`double?`), `density` (`Density`, default `Density.defaultDensity`).
**There is no `extensions` field** — see part B.

| Setting | Verdict |
| --- | --- |
| themeMode | **Confirmed.** `ShadcnApp.themeMode` is `ThemeMode`, default `ThemeMode.system`; values `system`, `light`, `dark`. The page sits under the `shadcn_flutter` library, so the symbol comes out of `package:shadcn_flutter/shadcn_flutter.dart`. Whether it is a *distinct* enum or a re-export of Material's is **UNCONFIRMED** (dartdoc shows no source path). Treat it as distinct: `ThemeCubit` currently imports Material's `ThemeMode` — the build session must re-point that import. Persistence is unaffected, `.name`/`values.asNameMap()` give the same three strings. |
| baseColors Slate | **Confirmed.** `ColorSchemes.lightSlate` and `ColorSchemes.darkSlate` both exist (constants). `ColorSchemes` also exposes methods `gray()`, `neutral()`, `slate()`, `stone()`, `zinc()` taking a `ThemeMode`. |
| accentColors Amber | **No `ColorSchemes` amber variant exists** and `ColorScheme` has no `fromAccent`. The real mechanism is `ColorScheme.copyWith`, whose parameters are **`ValueGetter<Color>?`, not `Color?`** — you must pass closures: `copyWith(primary: () => ...)`. Confirmed params include `primary`, `primaryForeground`, `ring`, `accent`, `accentForeground`. Shade table confirmed: `Colors.amber` is a `const ColorShades` (shades 50–950); `ColorShades` implements `ColorSwatch` and offers `operator []`, named getters `shadeNNN`, and `get()`. Snippet uses `Colors.amber.shade500` (non-nullable getter; `[500]` returns `Color?` through `ColorSwatch`). |
| radius Rounded | `ThemeData.radius` is a `double` multiplier, default `0.5` — confirmed. **"Rounded" is UNCONFIRMED as an API name**: there is no `Radius`/`ThemeRadius` enum or named constant anywhere in the dartdoc or the local guides. The word comes from the shadcn/ui theme picker (0 / 0.3 / 0.5 / 0.75 / 1.0 rem). The only worked example in `guides/theming.md` is `radius: 0.7, // Rounder corners`. Proposal: **`radius: 0.75`**, the picker step above the default. Judgement call, not an API fact. |
| density Reduced | **Confirmed.** `Density` is a **class, not an enum**: `Density({required double baseContainerPadding, required double baseGap, required double baseContentPadding})` with static constants `compactDensity` (8px base), `defaultDensity` (16px base), `reducedDensity` (12px base), `spaciousDensity` (20px base), plus `copyWith()` and `lerp()`. "Reduced" → `Density.reducedDensity`. |
| scaling Default | **Confirmed.** `ThemeData.scaling`, `double`, default `1`. Omit it, or pass `1.0`. |
| surfaceOpacity Solid | **The field exists.** `ThemeData.surfaceOpacity`, `double?`, documented as "Default opacity for surface overlays (0.0 to 1.0)." No named constant for "Solid" — **UNCONFIRMED as an API name**. Solid = fully opaque = **`1.0`**. |
| surfaceBlur Medium | **The field exists.** `ThemeData.surfaceBlur`, `double?`, documented only as "Default blur radius for surface effects." Units, null-behaviour and any recommended values are **not documented** — UNCONFIRMED. No named "Medium" constant. Consumed per-widget, e.g. `AlertDialog.surfaceBlur` ("If null, uses theme default blur value"). Proposal: **`8.0`** as a mid blur radius, to be eyeballed on the emulator. |

**Conflict worth flagging:** `surfaceOpacity: 1.0` makes surfaces fully opaque, so nothing
shows through them and `surfaceBlur` has no visible effect on those same surfaces. The two
agreed settings ("Solid" + "Medium") partly cancel. Keep both — blur still applies to modal
backdrops whose own `surfaceOpacity` is overridden — but expect "Medium" to be invisible in
normal use, and do not spend build time tuning it.

`ShadcnApp` accepts `theme` (`ThemeData`, default `const ThemeData()`), `darkTheme`
(`ThemeData?`, default `null`) and `themeMode` (`ThemeMode`, default `ThemeMode.system`) —
**confirmed**, same shape as `MaterialApp`, so `ThemeCubit` drives it unchanged.
Note there is no `ThemeData.dark()` named constructor in the dartdoc constructor list
(`guides/theming.md` shows `ThemeData.dark(colorScheme: ...)` in one example — that example
is **UNCONFIRMED** against the API page; use the plain constructor as below).

#### Ready-to-paste snippet

```dart
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Amber is beeshift's accent, layered onto the Slate base scheme.
/// ColorScheme.copyWith takes ValueGetter<Color>, hence the closures.
ColorScheme _amber(ColorScheme base, Color foreground) => base.copyWith(
  primary: () => Colors.amber.shade500,
  primaryForeground: () => foreground,
  ring: () => Colors.amber.shade500,
);

ThemeData _theme(ColorScheme scheme) => ThemeData(
  colorScheme: scheme,
  radius: 0.75,                      // "Rounded"; default is 0.5
  scaling: 1.0,                      // default
  density: Density.reducedDensity,   // "Reduced"
  surfaceOpacity: 1.0,               // "Solid"
  surfaceBlur: 8.0,                  // "Medium" — no named constant; tune on device
);

final ThemeData lightTheme =
    _theme(_amber(ColorSchemes.lightSlate, Colors.slate.shade950));
final ThemeData darkTheme =
    _theme(_amber(ColorSchemes.darkSlate, Colors.slate.shade950));

// In MainApp.build, replacing MaterialApp one-for-one:
// ShadcnApp(
//   theme: lightTheme,
//   darkTheme: darkTheme,
//   themeMode: themeMode,   // from ThemeCubit
//   home: ...,
// )
```

Amber-500 is a light hue in both brightnesses, so `primaryForeground` is dark in both —
that is why the light and dark builds share one foreground. If the build session wants the
`accent`/`accentForeground` pair amber-tinted too, the same `copyWith` closures cover it.

### B. The Shift Colours carrier

- **`shadcn_flutter`'s `ThemeData` has no `extensions` slot.** The dartdoc property list is
  exhaustive (`colorScheme`, `density`, `enableFeedback`, `iconTheme`, `radius`, `scaling`,
  `surfaceBlur`, `surfaceOpacity`, `typography`) — nothing extension-shaped, and no
  `ThemeExtension` class in the library. `Theme.of(context).extension<ShiftColors>()` has no
  equivalent.
- **Two real package-provided carriers exist, both confirmed:**
  - `ComponentTheme<T extends ComponentThemeData>` — `ComponentTheme({Key? key, required T data, required Widget child})`, with static `of<T>(BuildContext)` (throws) and `maybeOf<T>(BuildContext)` (nullable). `ComponentThemeData` is an abstract marker base class with no required members, so a user class *can* extend it. This is the closest analogue to a Material theme extension.
  - `Data<T>` — a general inherited-data widget with **no type bound**, constructors `Data(...)`, `Data.inherit()`, `Data.boundary()`, and statics `of<T>()`, `maybeOf<T>()`, `find<T>()`, `maybeFind<T>()`, `findRoot<T>()`, `maybeFindRoot<T>()`. Works for any arbitrary class.
- **Verdict: use neither.** Standing decision 4 freezes the six hues, and nothing else about
  them varies — not by flavor, not by brightness, not by any runtime input. A carrier that
  never carries a second value is an `InheritedWidget` earning nothing. Ship a top-level
  `const` table and delete the widget plumbing:

```dart
// lib/shared/shift_colors.dart — replacement body
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'shift_type.dart';

/// Catppuccin Mocha, frozen. Was ShiftColors.forFlavor; see ADR-0005 and
/// standing decision 4 of the shadcn migration map.
const shiftColors = <ShiftType, Color>{
  ShiftType.primo:   Color(0xFFFAB387), // peach
  ShiftType.secondo: Color(0xFF89B4FA), // blue
  ShiftType.notte:   Color(0xFFCBA6F7), // mauve
  ShiftType.smonto:  Color(0xFF94E2D5), // teal
  ShiftType.riposo:  Color(0xFFA6E3A1), // green
  ShiftType.ferie:   Color(0xFFF5C2E7), // pink
};
```

  Only three call sites change, all mechanical:
  `lib/features/calendar/calendar_view.dart:213` (`final colors = ShiftColors.of(context);`
  → `const colors = shiftColors;` or read the map directly),
  `lib/features/calendar/calendar_view.dart:413`
  (`ShiftColors.of(context)[shift]` → `shiftColors[shift]!`),
  `lib/features/month_editor/month_editor_view.dart:82`.
  `lib/shared/theme.dart:26` (`extensions: [ShiftColors.forFlavor(flavor)]`) disappears with
  the file. `copyWith`/`lerp`/`ThemeExtension` all go: nothing lerps a frozen table.
  If a per-brightness variant is ever wanted again, promote the map to a `Data<ShiftColors>`
  above the shell — that is the upgrade path, not a reason to build it now.

### The six hex values

Source: `catppuccin_flutter-1.0.0/lib/src/flavors/mocha.dart` (the palette `catui` re-exports),
mapped through the existing `ShiftColors.forFlavor` in `lib/shared/shift_colors.dart`.

| ShiftType | Catppuccin Mocha name | Hex |
| --- | --- | --- |
| `primo` | peach | `0xFFFAB387` |
| `secondo` | blue | `0xFF89B4FA` |
| `notte` | mauve | `0xFFCBA6F7` |
| `smonto` | teal | `0xFF94E2D5` |
| `riposo` | green | `0xFFA6E3A1` |
| `ferie` | pink | `0xFFF5C2E7` |

Note the current app takes these from `catppuccin.mocha` only in dark mode; light mode uses
`catppuccin.latte` (`lib/shared/theme.dart`). Freezing on Mocha means the calendar keeps the
dark-mode hues in **both** themes — a deliberate, visible change in light mode, consistent
with decision 4 but worth a glance on the emulator.

### UNCONFIRMED, summarised

1. `ThemeMode` being shadcn's own enum rather than a Material re-export (name + three values are confirmed; provenance is not).
2. "Rounded" as a radius value — no such named constant; `0.75` is a proposal.
3. "Medium" as a `surfaceBlur` value — the field exists, its units and defaults are undocumented; `8.0` is a proposal.
4. `ThemeData.dark(...)` named constructor shown in `guides/theming.md` — absent from the dartdoc constructor list.
5. `components/getting_started/theme.md` does not document `ThemeData` at all; it is `NavigationBarTheme` under a wrong filename. Do not send future sessions there.
