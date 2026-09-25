# Spec: catui/Material → shadcn_flutter migration

Status: locked 2026-09-23
Map: [map.md](map.md)
Build tickets: [08](issues/08-swap-lib-to-shadcn.md) → [09](issues/09-port-widget-tests.md) → [10](issues/10-verify-and-docs.md)

This is the only thing a build session needs to read. Every decision here was made on the
map; the ticket that made it is linked in brackets for the "why", not the "what".

## Goal

Re-skin beeshift from `catui` (Catppuccin on Material) to `shadcn_flutter` 0.0.54.
Like-for-like: no new feature, no behaviour change, no state or data change.
At the end, `lib/` imports neither `package:flutter/material.dart` nor `package:catui`.

Out of scope: `flutter_bloc` and every cubit's logic, the data layer (`libsql_dart`,
`shifts_repository.dart`, sync), Italian copy and `italian_dates.dart`.

## Environment

Flutter runs on Windows, the agent runs in WSL. Run every Flutter/Dart command through
`pws -c ...`. `run` and `build` always carry `--dart-define-from-file=env.json`.
See `CLAUDE.md`. API source of truth: the pub cache at
`/mnt/c/Users/filippo.pirola.PL/AppData/Local/Pub/Cache/hosted/pub.dev/shadcn_flutter-0.0.54/lib/src/`.
When this spec and the package disagree, the package wins; note the deviation in the ticket.

## 1. `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  shadcn_flutter: ^0.0.54     # added
  flutter_bloc: ^9.1.1
  libsql_dart: ^0.9.0+0.9.30
  path_provider: ^2.1.6
  shared_preferences: ^2.5.5
  # catui git dependency: removed

flutter:
  # uses-material-design: true — removed. No Icons.* remain; icons are LucideIcons.
```

Then `pws -c flutter pub get`. Do not add `shadcn_flutter_material` or
`shadcn_flutter_cupertino` — nothing needs them [02].

## 2. Theme [01]

`ShadcnApp` takes `theme`, `darkTheme`, `themeMode` exactly like `MaterialApp`, so
`ThemeCubit` drives it unchanged. shadcn ships its own `ThemeMode` (`system`, `light`,
`dark`; same names), so stored preferences stay valid — import swap only.
**Fresh-install default stays `ThemeMode.system`** (user, 2026-09-23: no behaviour change).

`lib/shared/theme.dart`, whole new body:

```dart
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Beeshift's accent: Amber, layered onto shadcn's Slate base scheme.
/// ColorScheme.copyWith takes ValueGetter<Color>, hence the closures.
ColorScheme _amber(ColorScheme base) => base.copyWith(
  primary: () => Colors.amber.shade500,
  primaryForeground: () => Colors.slate.shade950,
  ring: () => Colors.amber.shade500,
);

ThemeData _theme(ColorScheme scheme) => ThemeData(
  colorScheme: _amber(scheme),
  radius: 0.75, // "Rounded"; shadcn default is 0.5
  scaling: 1.0,
  density: Density.reducedDensity,
  surfaceOpacity: 1.0, // "Solid"
  surfaceBlur: 8.0, // "Medium"; no named constant, invisible under opacity 1.0
);

final ThemeData lightTheme = _theme(ColorSchemes.lightSlate);
final ThemeData darkTheme = _theme(ColorSchemes.darkSlate);
```

`0.75` and `8.0` are judgement values, not API constants. Do not tune them.

## 3. Shift Colours [07, supersedes 01's single Mocha table]

Six Tailwind hues from shadcn's palette. Shade 300 in Dark, shade 700 in Light.
Amber (accent) and red (error) are never Shift Colours.

| ShiftType | Hue | Dark (300) | Light (700) |
| --- | --- | --- | --- |
| `primo` | orange | `0xFFFDBA74` | `0xFFC2410C` |
| `secondo` | blue | `0xFF93C5FD` | `0xFF1D4ED8` |
| `notte` | violet | `0xFFC4B5FD` | `0xFF6D28D9` |
| `smonto` | teal | `0xFF5EEAD4` | `0xFF0F766E` |
| `riposo` | green | `0xFF86EFAC` | `0xFF15803D` |
| `ferie` | pink | `0xFFF9A8D4` | `0xFFBE185D` |

shadcn's `ThemeData` has no `extensions` slot, so the `ThemeExtension` goes.
`lib/shared/shift_colors.dart`, whole new body:

```dart
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'shift_type.dart';

/// The Shift Colour of each Shift Type: shadcn's palette, shade 300 on the
/// dark ground and 700 on the light one. See ADR-0006.
///
/// Amber is the app's accent and red is the error colour, so neither is
/// here. A day with no Shift has no Shift Colour — the accent stands in.
abstract final class ShiftColors {
  static const dark = <ShiftType, Color>{
    ShiftType.primo: Color(0xFFFDBA74), // orange-300
    ShiftType.secondo: Color(0xFF93C5FD), // blue-300
    ShiftType.notte: Color(0xFFC4B5FD), // violet-300
    ShiftType.smonto: Color(0xFF5EEAD4), // teal-300
    ShiftType.riposo: Color(0xFF86EFAC), // green-300
    ShiftType.ferie: Color(0xFFF9A8D4), // pink-300
  };

  static const light = <ShiftType, Color>{
    ShiftType.primo: Color(0xFFC2410C), // orange-700
    ShiftType.secondo: Color(0xFF1D4ED8), // blue-700
    ShiftType.notte: Color(0xFF6D28D9), // violet-700
    ShiftType.smonto: Color(0xFF0F766E), // teal-700
    ShiftType.riposo: Color(0xFF15803D), // green-700
    ShiftType.ferie: Color(0xFFBE185D), // pink-700
  };

  static Map<ShiftType, Color> of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
```

Every call site keeps `ShiftColors.of(context)[type]` and adds `!`.

## 4. Widget mapping [02, with overrides from 04 and 05]

| Today | shadcn_flutter | Note |
| --- | --- | --- |
| `MaterialApp` | `ShadcnApp(theme:, darkTheme:, themeMode:, home:)` | |
| `Scaffold(appBar:, body:)` | `Scaffold(headers: [...], child:)` | No `appBar`/`body` params. |
| `AppBar(title:, actions:)` | `AppBar(title:, trailing:)` inside `headers: [AppBar(...), const Divider()]` | AppBar takes the top inset itself [04]. |
| `FilledButton` | `PrimaryButton(onPressed:, child:)` | |
| `TextButton` | `TextButton` (shadcn's) | Same name. |
| `OutlinedButton` (equal row) | `Button(style: pickedStyle(...), onPressed:, child:)` | `OutlineButton` has no `style` param. |
| `FilterChip` (Filter) | `Button(style: pickedStyle(...), onPressed:, child: Semantics(selected:, ...))` | **Overrides 05.** `Toggle` swaps its style for a filled `ButtonStyle.secondary` whenever `value` is true (`button.dart:312`), which kills the coloured-border look. |
| `IconButton(tooltip:, style:)` | `Tooltip(tooltip: (_) => TooltipContainer(child: Text(label)), child: IconButton(variance: ..., icon:, onPressed:, shape: ButtonShape.circle))` | shadcn `IconButton` has no `tooltip`. |
| `CircularProgressIndicator` | `CircularProgressIndicator` (shadcn's) | Not `Spinner` (not exported). |
| `ScaffoldMessenger` + `SnackBar` | `showToast(context:, builder: (context, overlay) => SurfaceCard(child: Text(...)), location: ToastLocation.topCenter)` | `topCenter`, not `bottomLeft`: bottom sits under the bar [04]. |
| `MaterialBanner` | `Alert(destructive: true, content: Text(...))` | Non-dismissible by construction. |
| `RefreshIndicator(notificationPredicate:)` | `RefreshTrigger(onRefresh:, child:)` | No predicate. Verify on emulator (§9). |
| `MaterialPageRoute` | `ShadcnPageRoute(builder:)` | `Navigator.push/pop` unchanged. |
| `CatSegmented<ThemeMode>` | `Tabs(expand: true, index:, onChanged:, children: [TabItem(...)])` | Index-keyed; see settings in §7. |
| `Material(color:, elevation:, shape: StadiumBorder())` | `DecoratedBox(decoration: ShapeDecoration(color:, shape: StadiumBorder(side:), shadows: [...]))` | Plain widgets, no shadcn widget needed. |
| `ThemeExtension<ShiftColors>` | `ShiftColors.of(context)` (§3) | |
| `Colors.transparent` in the Filter | deleted | `Button` + outline has no fill. |
| `AppTokens.radius` | `theme.radiusMd` | `radius * 12`, scaled by density: about 9px at 0.75; catui's was 8. |
| `AppTokens.segmentGap` | literal `8` | |
| `LucideIcons.*` | `LucideIcons.*` from `shadcn_flutter` | Import swap only. |
| `StadiumBorder`, `RoundedRectangleBorder`, `ShapeDecoration`, `BorderSide` | unchanged | `painting.dart`, not Material. |

**Residual Material: none.** `lib/` ends with zero `material.dart` imports. The only
Material dependency that ever blocked this was `ThemeExtension`, gone per §3.

## 5. Token and typography mapping

Colour tokens (all on `Theme.of(context).colorScheme`, shadcn's):

| Material | shadcn |
| --- | --- |
| `primary` | `primary` (Amber, via §2) |
| `outlineVariant` | `border` |
| `onSurfaceVariant` | `mutedForeground` |
| `surfaceContainerHigh` | `card` |
| `errorContainer` | not read; `Alert(destructive: true)` owns it |

Text styles. shadcn's `ThemeData` has `typography`, not `textTheme`. Rule: the nearest
size, weight kept where Material set one. Read as `Theme.of(context).typography.<slot>`.

| Material slot (size/weight) | Used by | shadcn |
| --- | --- | --- |
| `labelSmall` (11) | weekday header letters | `typography.xSmall` (12) |
| `labelMedium` (12, w500) | "Tema", Filter headings, day number | `typography.xSmall.copyWith(fontWeight: FontWeight.w500)` |
| `titleMedium` (16, w500) | `pickedStyle` letter | `typography.base` (16), weight set by `pickedStyle` |
| `titleLarge` (22) | month title, Shift Code in the cell, editor day title | `typography.xLarge` (20) |

Existing `?.copyWith(...)` on these becomes `.copyWith(...)`: shadcn's slots are
non-nullable. Text colour comes from the ambient `DefaultTextStyle` (`foreground`).

## 6. Layout decisions

- **Month grid [03].** `_MonthGrid` and `_DayCellView` stay hand-rolled. shadcn's
  `Calendar` has no day-cell builder. Swaps only: radius, `outlineVariant`→`border`,
  `primary` stays `primary`, text slots per §5. `density` never reaches the cell.
- **Shell [04].** `FloatingBottomBar` stays, re-skinned. It stays in the Shell's `Stack`,
  never in `footers:` (that counts the inset twice). `barClearance`, `barReserve`,
  `barBottomMargin` are untouched. The Calendar keeps `SafeArea(bottom: false)` and
  `barReserve` padding. The Calendar gets no header.
- **Top inset under a header [04].** shadcn `Scaffold` does not strip top padding from
  its child's `MediaQuery`. Any page with an `AppBar` header must not re-apply the top
  inset: `SafeArea(top: false, ...)` for Settings, and
  `MediaQuery.removePadding(context: context, removeTop: true, child: ...)` around the
  Month Editor body, because its `ListView` pads itself from `MediaQuery`.
- **Segmented control [05].** Theme Mode → `Tabs(expand: true)`. The Filter keeps its
  coloured letters. `EqualRowSegmented` and `pickedStyle` both survive.

## 7. File-by-file work order

All 16 files in `lib/`. "Import swap" means: delete `package:flutter/material.dart` and
`package:catui/catui.dart`, add `package:shadcn_flutter/shadcn_flutter.dart`.

| # | File | Edits |
| --- | --- | --- |
| 1 | `pubspec.yaml` | §1. |
| 2 | `lib/shared/theme.dart` | Whole body per §2. `ChipThemeData` and `extensions:` die. |
| 3 | `lib/shared/shift_colors.dart` | Whole body per §3. |
| 4 | `lib/shared/shift_type.dart` | No change. |
| 5 | `lib/shared/italian_dates.dart` | No change. |
| 6 | `lib/features/settings/cubit/theme_cubit.dart` | Import swap (for `ThemeMode`). Nothing else; default stays `ThemeMode.system`. |
| 7 | `lib/shared/widgets/picked_style.dart` | Import swap. New return type `ButtonStyle`, body below. Update the doc comment: two consumers are now both `Button`. |
| 8 | `lib/shared/widgets/equal_row_segmented.dart` | Import swap. `AppTokens.segmentGap` → `8`. `OutlinedButton(style: OutlinedButton.styleFrom(...))` → `SizedBox(height: 48, child: Button(style: pickedStyle(...), onPressed:, child: Semantics(...)))`. Drop the `[CatSegmented]` doc references (plain text instead). |
| 9 | `lib/shared/widgets/floating_bottom_bar.dart` | Import swap. `Material(...)` → `DecoratedBox(decoration: ShapeDecoration(color: colorScheme.card, shape: StadiumBorder(side: BorderSide(color: colorScheme.border)), shadows: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2))]))`. `_BarButton` → `Tooltip(tooltip: (_) => TooltipContainer(child: Text(label)), child: IconButton(key: Key(label), variance: ButtonVariance.ghost.withForegroundColor(color: active ? primary : mutedForeground), shape: ButtonShape.circle, onPressed:, icon: Icon(icon, semanticLabel: label)))`. Colour goes on the variance, not the `Icon`, so a disabled button still dims. Keep `Key(label)`. Inset maths untouched. |
| 10 | `lib/features/shell/shell_view.dart` | Import swap. `Scaffold(body:)` → `Scaffold(child:)`. `MaterialPageRoute<void>` → `ShadcnPageRoute<void>`. |
| 11 | `lib/features/settings/settings_view.dart` | Import swap. `Scaffold(headers: [AppBar(title: const Text('Impostazioni')), const Divider()], child: SafeArea(top: false, ...))`. "Tema" label per §5. `CatSegmented` → `Tabs(expand: true, index: _modes.indexOf(mode), onChanged: (i) => context.read<ThemeCubit>().setMode(_modes[i]), children: [for (final m in _modes) TabItem(child: Text(_labels[m]!))])` with `static const _modes = [ThemeMode.light, ThemeMode.dark, ThemeMode.system]`. **Not** `ThemeMode.values[i]`: the enum order is `system, light, dark`, the tab order is Chiaro, Scuro, Sistema. |
| 12 | `lib/features/month_editor/month_editor_view.dart` | Import swap. `Scaffold(headers: [AppBar(title: Text(monthTitle(month)), trailing: [TextButton(...)]), const Divider()], child: MediaQuery.removePadding(removeTop: true, ...))`. `MaterialBanner` → `Alert(destructive: true, content: const Text(...))`. `ShiftColors.of(context)` → `final colors = ShiftColors.of(context);` then `colors[shift]!`. Day title per §5. |
| 13 | `lib/features/calendar/calendar_view.dart` | Import swap. `Scaffold(body:)` → `Scaffold(child:)`. SnackBar → `showToast` per §4. Both `FilledButton` → `PrimaryButton`. `RefreshIndicator` → `RefreshTrigger(onRefresh: _pullToRefresh, child: PageView(...))`, predicate deleted. `_FilterLetter`: `FilterChip` → `Button` per §4, `Semantics(selected: selected, child: Text(code, semanticsLabel: label))` inside. `_FilterControls` and `_DayCellView`: `ShiftColors.of(context)[x]!`. `_DayCellView`: `AppTokens.radius` → `theme.radiusMd`, `outlineVariant` → `border`. Text slots per §5. Update the comment "which is what RefreshIndicator listens to". |
| 14 | `lib/main.dart` | Import swap. `MaterialApp` → `ShadcnApp` (same three params + `home`). Two `Scaffold(body:)` → `Scaffold(child:)`. `FilledButton` → `PrimaryButton`. |
| 15 | `lib/data/shifts_repository.dart` | No change. |
| 16 | `lib/features/calendar/cubit/calendar_cubit.dart`, `lib/features/month_editor/cubit/month_editor_cubit.dart` | No change (no UI types). |

`picked_style.dart` body:

```dart
/// ...doc comment kept, reworded for Button...
ButtonStyle pickedStyle(
  ThemeData theme, {
  required Color color,
  required bool selected,
}) {
  final ink = selected ? color : theme.colorScheme.mutedForeground;
  final edge = Border.all(color: selected ? color : theme.colorScheme.border);
  return ButtonStyle(
    variance: ButtonVariance.outline
        .withBorder(border: edge, hoverBorder: edge, focusBorder: edge)
        .copyWith(
          // Every state: hover must not repaint the letter it is identifying.
          textStyle: (context, states, style) => style.merge(
            theme.typography.base.copyWith(
              color: ink,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
  );
}
```

If `ButtonVariance.outline` paints a fill on hover, add
`.withBackgroundColor(hoverColor: Colors.transparent)`; check on the emulator (§9).

## 8. Tests

Six test files build a `MaterialApp` or read Material/catui types. Each must be ported:

- Harness: `MaterialApp(theme: lightTheme, ...)` → `ShadcnApp(theme: lightTheme, ...)`.
- `find.byTooltip('X')` → `find.byKey(const Key('X'))` (shadcn `Tooltip` is not Material's).
- `find.byType(FilterChip)` / `OutlinedButton` / `MaterialBanner` / `SnackBar` /
  `RefreshIndicator` → the §4 replacement.
- `lightTheme.extension<ShiftColors>()!` → `ShiftColors.light`; `catppuccin.*` hue checks
  → the §3 hex table. `colorScheme.outlineVariant` → `colorScheme.border`.
- `test/shared/shift_colors_test.dart`: keep "six distinct colours" and "neither accent
  nor error", per brightness; replace "the flavor's own" with the §3 table; keep the
  widget test that `ShiftColors.of` reads the right table under each theme.
- `theme_cubit_test.dart`: import swap only; the `ThemeMode.system` default test stays.
- Settings: if a test taps a segment by label, Chiaro/Scuro/Sistema must map to
  light/dark/system (the §7 row 11 ordering trap).

Pure logic tests (`calendar_cubit_test`, `month_editor_cubit_test`,
`shifts_repository_test`, `fake_shifts_repository`) are untouched.

## 9. Verification

The build is done when all of these hold:

1. `grep -rn "package:flutter/material.dart\|package:catui" lib test` prints nothing.
2. `pws -c flutter analyze` reports no issues.
3. `pws -c flutter test` passes.
4. `pws -c flutter run --dart-define-from-file=env.json` on one emulator (same ABI as
   before — see `CLAUDE.md` on the libsql cache), then check by eye, in Dark **and** Light:
   - Calendar: grid fits, last row clears the floating bar, today's border and Shift
     Codes use the §3 hues.
   - Pull down on the grid: `RefreshTrigger` fires from inside the `PageView`.
     **If it does not**, move `RefreshTrigger` inside each page, wrapping `_MonthGrid`.
   - Filter letters: unpicked = grey outline, grey letter; picked = coloured outline,
     bold coloured letter, no fill, including under hover/press.
   - Month Editor: header not double-padded at the top; Salva works; the save-failure
     `Alert` shows (airplane mode, then Salva).
   - Settings: Chiaro/Scuro/Sistema switch the theme on tap and survive an app restart.
   - Toast appears at the top after a failed pull (airplane mode).
   - Bar: tooltips on long-press; Modifica dims while grids are loading.

## 10. Docs

- **ADR-0006** "shadcn_flutter replaces catui": supersedes the house-style half of
  ADR-0004 and all of ADR-0005. Records: shadcn theme per §2, Shift Colours per §3 as
  a static brightness-keyed class (not a theme extension — shadcn has none).
- **`CONTEXT.md`, "Shift Colour"**: "taken per flavor so latte and mocha each read
  correctly, and read through the theme" → "one shade per brightness, from shadcn's
  palette". Keep "Yellow is the accent and red is the error colour". Drop other
  Catppuccin wording if any.

## Known risks, accepted

- `primo` orange sits close to the Amber accent (orange-300 vs amber-500: 1.27:1) [07].
- `radius: 0.75` makes day tiles 9px round, not catui's 8px.
- `surfaceBlur: 8.0` has no visible effect while `surfaceOpacity` is `1.0` [01].
