# 02 — Map every widget to a shadcn equivalent, and decide how far Material goes

Type: research
Status: resolved
Map: ../map.md

## Question

**A. The mapping table.** One row per Material/catui widget currently used in `lib/`,
naming the `shadcn_flutter` replacement and the doc page that proves it exists.
Current inventory (from `grep` over `lib/`):

- `MaterialApp` ×1 → `ShadcnApp`
- `Scaffold` ×8 → `components/layout/scaffold.md`
- `AppBar` ×2 → is there a shadcn app bar, or is it `Scaffold(headers: [...])`?
- `OutlinedButton` ×2, `FilledButton` ×2, `TextButton` ×1, `IconButton` ×2 → `components/control/button.md` variants
- `CircularProgressIndicator` ×2 → `components/other/circular_progress_indicator.md` or `spinner.md`
- `SnackBar` + `ScaffoldMessenger` ×1 (`calendar_view.dart:58`) → `components/feedback/toast.md`
- `Icon` / `Icons.*` → Lucide, per `guides/icons.md`
- `CatSegmented` ×4 → candidates in `components/navigation/tab_list.md`, `tabs.md`, `components/other/multiple_choice.md`, `components/utility/chip.md`. Do not pick the winner here — that is ticket 05. Just list what exists and what each one's API shape is.

Also cover the three local custom widgets — for each, say whether shadcn already
ships the thing, or whether the widget survives as plain Flutter and only its
colours/tokens change:
`lib/shared/widgets/floating_bottom_bar.dart`,
`lib/shared/widgets/equal_row_segmented.dart`,
`lib/shared/widgets/picked_style.dart`.

**B. How far does Material go?** Read `.claude/skills/shadcn-flutter/guides/interop.md`.
The goal is "replace all default components", so establish what that costs:

- With `ShadcnApp` instead of `MaterialApp`, which Flutter primitives still work
  (`MediaQuery`, `Navigator`, `showDialog`, `showModalBottomSheet`, `ScaffoldMessenger`)?
- Which of those has a shadcn-native replacement that should be used instead?
- Is a 100% Material-free `lib/` reachable, or does some corner still need a
  `Material`/`Theme` ancestor? Name the corner if so.
- `flutter_bloc` is framework-agnostic — confirm nothing in the swap touches it.

Output a table plus a short "residual Material" list. No code changes.

## Answer

Sources used, in order: the local skill docs under `.claude/skills/shadcn-flutter/`
(cited as `skill:<path>`); the pub.dev dartdoc for `shadcn_flutter` 0.0.54, checked
against the package's own `index.json` symbol table so that *every* class name below
was confirmed to exist (cited as `api:<Class>`); and the app's own files.

Two local doc pages are docs-site scaffolding and were corrected against the API:
`components/other/spinner.md` documents an **abstract** `Spinner` that is **not
exported** (no `Spinner` symbol in the package index), and
`components/other/multiple_choice.md` / the `MultipleChoice` dartdoc both name
`ChoiceChip` / `ChoiceButton`, **neither of which exists** in the package index.
`guides/icons.md` misspells the class as `LucideIconss`; the real one is
`LucideIcons` (`api:LucideIcons`, and the app already imports it via `catui`).

### Corrected inventory

The ticket's counts come from a raw `grep`. The real call-site counts in `lib/` are:
`MaterialApp` ×1, `Scaffold` ×6 (main ×2, calendar, month_editor, settings, shell),
`AppBar` ×2, `FilledButton` ×2, `TextButton` ×1, `OutlinedButton` ×1 (inside
`equal_row_segmented.dart`), `IconButton` ×1 (inside `floating_bottom_bar.dart`),
`CircularProgressIndicator` ×2, `SnackBar`+`ScaffoldMessenger` ×1,
`CatSegmented` ×1 real use (`settings_view.dart:31`; the other three hits are doc
comments in `equal_row_segmented.dart` / `picked_style.dart`).

Three widgets the ticket's inventory missed, found by reading the files:
`FilterChip` (`calendar_view.dart:290`), `MaterialBanner`
(`month_editor_view.dart:43`), `RefreshIndicator` (`calendar_view.dart:145`),
plus `MaterialPageRoute` (`shell_view.dart:93`).

### A. The mapping table

| # | Today (file:line) | shadcn_flutter replacement | Proof | Notes |
|---|---|---|---|---|
| 1 | `MaterialApp` — `main.dart:100` | `ShadcnApp` | `api:ShadcnApp`; ctor confirmed: `ShadcnApp({Widget? home, ThemeData theme, ThemeData? darkTheme, ThemeMode themeMode, AdaptiveScaling? scaling, Iterable<LocalizationsDelegate>? localizationsDelegates, …})` | Drop-in for the three params used today (`theme`, `darkTheme`, `themeMode`, `home`). |
| 2 | `Scaffold` ×6 | `Scaffold` (shadcn's own) | `skill:components/layout/scaffold.md`; `api:Scaffold` | **Not a drop-in.** `body:` → `child:`; `appBar:` → `headers: [AppBar(...)]`; `floatingActionButton`/`bottomNavigationBar` do not exist — use `footers:` or `floatingFooter: true`. |
| 3 | `AppBar` ×2 — `settings_view.dart:21`, `month_editor_view.dart:20` | `AppBar`, passed in `Scaffold(headers: [...])` | `skill:components/layout/scaffold.md` (example 1 puts `AppBar` in `headers`); `api:AppBar`: `AppBar({List<Widget> leading, List<Widget> trailing, Widget? title, Widget? subtitle, Widget? header, Widget? child, double? height, bool useSafeArea, …})` | Answers the ticket's open question: **both**. The class is called `AppBar` and it is mounted through `headers`, not an `appBar:` slot. `actions:` → `trailing:`. |
| 4 | `FilledButton` ×2 — `main.dart:163`, `calendar_view.dart:184` ("Riprova") | `PrimaryButton` | `skill:components/control/button.md` (example 1); `api:PrimaryButton` | Same `onPressed` + `child` shape. |
| 5 | `TextButton` ×1 — `month_editor_view.dart:27` ("Salva") | `TextButton` (shadcn's own, same name) | `skill:components/control/button.md` (example 12); `api:TextButton` | Name collides with Material's; after the swap the import resolves to shadcn's. |
| 6 | `OutlinedButton` ×1 — `equal_row_segmented.dart:79` | `OutlineButton` (note: no "d") | `skill:components/control/button.md` (example 3); `api:OutlineButton` | Styled via `style: const ButtonStyle.outline().withForegroundColor(...).withBorder…`, not `OutlinedButton.styleFrom` — see row 17. |
| 7 | `IconButton` ×1 — `floating_bottom_bar.dart:80` | `IconButton.ghost(icon: …, density: ButtonDensity.icon)` | `skill:components/control/button.md` (example 8); `api:IconButton`, `api:ButtonDensity` | **`tooltip:` does not exist** on shadcn's `IconButton` (confirmed across all seven named ctors). Wrap in `Tooltip` (`api:Tooltip`, `skill:components/overlay/tooltip.md`) to keep the current behaviour. |
| 8 | `CircularProgressIndicator` ×2 — `main.dart:133`, `calendar_view.dart:82` | `CircularProgressIndicator` (shadcn's own) | `skill:components/other/circular_progress_indicator.md`; `api:CircularProgressIndicator` — `{double? value, double? size, Color? color, double? strokeWidth, bool onSurface, …}` | **Not `Spinner`.** The ticket offered `spinner.md` as an alternative; `Spinner` is documented as an abstract base and is absent from the package index, so it is not a usable class. Indeterminate = leave `value` null. |
| 9 | `SnackBar` + `ScaffoldMessenger` ×1 — `calendar_view.dart:58` | `showToast(context: …, builder: …, location: ToastLocation.bottomLeft, showDuration: …)` | `skill:components/feedback/toast.md`; `api:showToast` — `ToastOverlay showToast({required BuildContext context, required ToastBuilder builder, ToastLocation location, bool dismissible, Duration showDuration, VoidCallback? onClosed, …})` | Builder returns a widget (`SurfaceCard` in the doc example, `api:SurfaceCard`) and receives a `ToastOverlay` handle for programmatic close. `ScaffoldMessenger` has **no** shadcn counterpart and is not needed — `showToast` finds the `ToastLayer` `ShadcnApp` installs. |
| 10 | `FilterChip` ×1 — `calendar_view.dart:290` (13 instances: 6 shifts + 7 weekdays, **multi-select**) | `Toggle` | `api:Toggle` — `Toggle({required bool value, ValueChanged<bool>? onChanged, required Widget child, bool? enabled, ButtonStyle style = const ButtonStyle.ghost()})` | shadcn's `Chip` (`skill:components/utility/chip.md`, `api:Chip`) has **no selected state** — only `child/leading/trailing/onPressed/style` — so it cannot carry the Filter's on/off. `Toggle` is the only shipped selected/unselected control. The per-chip Shift Colour still comes from `pickedStyle` (row 19) fed into `style:`. |
| 11 | `MaterialBanner` ×1 — `month_editor_view.dart:43` (sticky save-failure) | `Alert` | `skill:components/feedback/alert.md`; `api:Alert` — `{Widget? leading, Widget? title, Widget? content, Widget? trailing, bool destructive}` | `destructive: true` replaces the hand-set `errorContainer` background. Non-dismissible by construction, which is what this banner wants. |
| 12 | `RefreshIndicator` ×1 — `calendar_view.dart:145` | `RefreshTrigger` | `skill:components/utility/refresh_trigger.md`; `api:RefreshTrigger` — `{FutureVoidCallback? onRefresh, required Widget child, Axis direction, bool reverse, double? minExtent, double? maxExtent, RefreshIndicatorBuilder? indicatorBuilder, …}` | **Gap:** there is no `notificationPredicate`. `RefreshTrigger` drives itself through `RefreshTriggerPhysics` rather than listening for `ScrollNotification`, so the current `depth == 1` workaround has no equivalent and probably no need — but this must be verified on the emulator (flag for 05/06, do not assume). |
| 13 | `MaterialPageRoute` ×1 — `shell_view.dart:93` | `ShadcnPageRoute(builder: …)` | `skill:components/other/page_route.md`; `skill:guides/interop.md` "What moved out" table; `api:ShadcnPageRoute` | `Navigator.of(context).push/pop` themselves are unchanged (see B). |
| 14 | `Icon` / `Icons.*` | `Icon` (from `package:flutter/widgets.dart`, re-exported) + `LucideIcons.*` | `skill:guides/icons.md`; `skill:guides/interop.md` ("`Icons.add` → `LucideIcons.plus`"); `api:LucideIcons` | **No change needed in practice:** the app's only icon call sites (`shell_view.dart:56,62,71`) already use `LucideIcons.calendarDays` / `.pencil` / `.settings`, today via `catui`'s re-export. After the swap they come from `shadcn_flutter`. |
| 15 | `CatSegmented<ThemeMode>` ×1 — `settings_view.dart:31` (`Map<T,String> segments`, `T selected`, `ValueChanged<T> onChanged`) | **candidates only — ticket 05 decides** | see below | |
| 16 | `Divider` (implied by shadcn `Scaffold` headers example) | `Divider` | `skill:components/layout/divider.md`; `api:Divider` | Not used in `lib/` today; listed because the `Scaffold(headers:)` idiom uses it. |
| 17 | `Theme.of(context).textTheme.*` ×8 (`titleLarge`, `labelMedium`, `labelSmall`, `titleMedium`) | text extensions: `.h1() .h2() .h3() .h4() .p() .lead() .large() .small() .muted() .bold() .semiBold()` | `skill:guides/typography.md` | shadcn's `ThemeData` has `typography`, **not** `textTheme`. Per-string scale assignment is left open by the map ("Typography mapping" in *Not yet specified") and is not settled here. |
| 18 | `Theme.of(context).colorScheme.{primary,outlineVariant,onSurfaceVariant,surfaceContainerHigh,errorContainer}` | `Theme.of(context).colorScheme.{primary,border,mutedForeground,card/muted,destructive}` | `skill:components/layout/scaffold.md` (`theme.colorScheme.border`, `.primary`, `.muted`, `.primaryForeground`); `skill:guides/typography.md` (`.mutedForeground`); `api:ColorScheme` | `Theme` and `Theme.of` exist in shadcn (`api:Theme`) — the call shape survives, the token names do not. Material's `surfaceContainerHigh` / `outlineVariant` / `onSurfaceVariant` have no same-named counterparts. |
| 19 | `AppTokens.radius` (catui) ×2 | `theme.radiusSm` / `theme.borderRadiusMd`, off `ThemeData.radius` | `skill:guides/layout.md` (`radiusXs = radius*4` … `radiusXxl = radius*24`, `theme.borderRadiusMd`) | catui's token goes away with catui. |
| 20 | `Colors.transparent` ×2 — `calendar_view.dart:293-294` | `Colors.transparent` (shadcn's own `Colors`) | `api:Colors`; used in `skill:components/control/button.md` example 17 (`Colors.red`, `Colors.purple`) | Survives by name; different class, same API surface for this use. Likely deleted outright, since `Toggle`'s ghost style already has no fill. |
| 21 | `StadiumBorder` ×2 — `floating_bottom_bar.dart:60,87` | **NO KNOWN EQUIVALENT** | checked: package index has no `StadiumBorder`, `RoundedRectangleBorder`, `ShapeBorder`-family export; `skill:components/control/button.md` offers only `ButtonShape.circle` / `ButtonShape.rectangle` | `StadiumBorder` is `package:flutter/painting.dart`, **not** Material — it is re-exported by `widgets.dart` and therefore keeps working unchanged. No replacement is needed; it is listed only so nobody hunts for one. Same for `RoundedRectangleBorder` / `ShapeDecoration` in `calendar_view.dart:427` and `theme.dart:20`. |
| 22 | `ThemeExtension<ShiftColors>` — `shift_colors.dart:16` | **NO KNOWN EQUIVALENT** | checked: package index has **no** `ThemeExtension`; the `Extension` matches are all Dart extension methods (`ColorExtension`, `BorderRadiusExtension`, …), not the Material class. `skill:guides/theming.md` shows `ThemeData(colorScheme:, radius:, scaling:)` with no extension slot | This is the one genuine Material dependency in `lib/`. **Already resolved by map standing decision 4**: the six hues become literal constants, so `ShiftColors` stops being a `ThemeExtension` and becomes a plain `const Map<ShiftType, Color>` — no ancestor needed. If decision 4 were reversed, this corner would force a `Material`/`Theme` ancestor. |

#### Row 15 — `CatSegmented` candidates (API shapes only; **ticket 05 picks**)

`CatSegmented<T>` today: `{Map<T,String> segments, T selected, ValueChanged<T> onChanged}` —
value-keyed, single-select, three ThemeMode options, drawn as labelled segments.

| Candidate | Exact API shape | Fit notes (no verdict) |
|---|---|---|
| `Tabs` (`skill:components/navigation/tabs.md`, `api:Tabs`) | `Tabs({required int index, required ValueChanged<int> onChanged, required List<TabChild> children, bool expand, EdgeInsetsGeometry? padding, TabsTheme? theme})`; items are `TabItem(child: Text('…'))` (`api:TabItem`, `api:TabChild` is a mixin) | **Index-based, not value-based** — caller must map `ThemeMode` ↔ `int`. `expand: true` gives equal shares. Reads as a tab header, not a segmented control. |
| `TabList` (`skill:components/navigation/tab_list.md`, `api:TabList`) | `TabList({required int index, ValueChanged<int>? onChanged, required List<TabChild> children, TabListTheme? theme})` | Same index-based shape as `Tabs`, documented as "a lower-level tab header; it doesn't manage content". No `expand`. |
| `MultipleChoice<T>` (`skill:components/other/multiple_choice.md`, `api:MultipleChoice`) | `MultipleChoice<T>({required Widget child, T? value, ValueChanged<T?>? onChanged, bool? enabled, bool? allowUnselect})` | The only **value-keyed** candidate — matches `CatSegmented`'s shape exactly. **Caveat 05 must weigh:** both the local doc and the dartdoc say to fill `child` with `ChoiceChip` / `ChoiceButton`, and **neither class is exported** (package index has only `Choice` (mixin), `ControlledMultipleChoice`, `MultipleChoice`, `MultipleChoiceController`, `MultipleChoiceKey`, `MultipleChoiceTheme`). An item widget would have to be written against the `Choice` mixin's statics `Choice.choose(context, item)` / `Choice.getValue(context)` (`api:Choice-mixin`). |
| `Chip` (`skill:components/utility/chip.md`, `api:Chip`) | `Chip({required Widget child, Widget? leading, Widget? trailing, VoidCallback? onPressed, AbstractButtonStyle? style, ChipTheme? theme})` | **Carries no selected state at all.** Selection would be hand-rolled by swapping `style` between `ButtonStyle.outline()` and `ButtonStyle.primary()`. |
| `Toggle` (`api:Toggle`) — *not in the ticket's list, added here* | `Toggle({required bool value, ValueChanged<bool>? onChanged, required Widget child, bool? enabled, ButtonStyle style = const ButtonStyle.ghost()})` | Per-item boolean; a single-select group is three `Toggle`s with mutual-exclusion logic in the caller. This is also row 10's pick, so choosing it here would make the Filter and the Settings switch one idiom. |

There is **no** `Segmented*` symbol anywhere in the package (index checked).

### The three custom widgets

| Widget | Fate | Why |
|---|---|---|
| `lib/shared/widgets/floating_bottom_bar.dart` (99 ln) | **Survives as a local widget; internals re-skin.** shadcn *does* ship `NavigationBar` (`skill:components/other/bar.md`, `api:NavigationBar` — `{List<Widget> children, NavigationBarAlignment alignment, Axis? direction, NavigationLabelType labelType, Key? selectedKey, ValueChanged<Key?>? onSelected, bool expanded, Color? backgroundColor, double? surfaceOpacity, double? surfaceBlur, …}`) with `NavigationItem` (`api:NavigationItem` — `{bool? selected, ValueChanged<bool>? onChanged, Widget? label, AbstractButtonStyle? selectedStyle, required Widget child, …}`). But `NavigationBar` spans its container; this widget's whole point is a *floating pill that hugs its buttons* (`MainAxisSize.min`, `StadiumBorder`, floated by the Shell's `Align`). Swaps: `Material(color:…, elevation: 4, shape: StadiumBorder())` → `Card(borderRadius:…, boxShadow:…, fillColor:…)` (`skill:components/layout/card.md`, `api:Card`) or `SurfaceCard`; `IconButton(tooltip:)` → `IconButton.ghost` + `Tooltip` (row 7); `scheme.surfaceContainerHigh`/`onSurfaceVariant` → shadcn tokens (row 18). `barClearance`/`barReserve` are pure `MediaQuery.viewPaddingOf` arithmetic and are untouched. `NavigationBar`/`NavigationItem` remain a live alternative if ticket 04 decides the bar should span. |
| `lib/shared/widgets/equal_row_segmented.dart` (100 ln) | **Survives as a local widget; internals re-skin.** Nothing shipped forces equal shares on a single row with per-segment colours: `Tabs(expand: true)` is index-keyed and gives no per-item colour, `MultipleChoice` has no shipped item widget, `Chip` has no selected state. Swaps: `OutlinedButton` → `OutlineButton` (row 6), `OutlinedButton.styleFrom(minimumSize:, side:, textStyle:, foregroundColor:)` → `ButtonStyle.outline()` composed with `.withForegroundColor(...)` / `.withBorderRadius(...)` (`skill:components/control/button.md` example 17) plus a `ConstrainedBox`/`.sized(height: 48)` for the tap target, `AppTokens.segmentGap` → a `SizedBox(width: …)` (`skill:guides/layout.md`), and it drops its `catui` import. `Row`/`Expanded`/`Semantics` are `widgets.dart` and are untouched. |
| `lib/shared/widgets/picked_style.dart` (39 ln) | **Survives, but is rewritten — this is the one that changes most.** It is pure theme plumbing: it returns `({BorderSide side, TextStyle? labelStyle})` built from `ThemeData.textTheme.titleMedium` and `colorScheme.{outlineVariant,onSurfaceVariant}`, none of which exist in shadcn's `ThemeData`. It must return whatever shapes its two (now different) consumers want — a `ButtonStyle`/`AbstractButtonStyle` for `Toggle` and `OutlineButton` rather than a `BorderSide` + `TextStyle`. The *idea* (no fill; hairline border in the thing's own colour; bold letter in that colour) is unaffected and stays the shared contract. Exact return type is a ticket 05 call. |

### B. How far does Material go?

`skill:guides/interop.md` is unambiguous: `shadcn_flutter` is built on
`package:flutter/widgets.dart` **alone** and depends on neither Material nor
Cupertino. A bare `ShadcnApp` "no longer installs `Theme`, `Material`,
`ScaffoldMessenger` or `CupertinoTheme`, and no longer registers the Material and
Cupertino localizations delegates. Material or Cupertino widgets placed under a
bare `ShadcnApp` will **assert at build time**."

**What still works under `ShadcnApp` (all from `widgets.dart`, which shadcn re-exports):**

| Primitive | Works? | Note |
|---|---|---|
| `MediaQuery` / `MediaQuery.viewPaddingOf` | ✅ | `widgets.dart`. `floating_bottom_bar.dart:15` unchanged. |
| `Navigator.of(context).push/pop` | ✅ | `widgets.dart`. Only the *route class* changes (row 13). |
| `SafeArea`, `PageView`, `IndexedStack`, `Stack`, `Align`, `Opacity`, `DecoratedBox`, `LayoutBuilder`, `SingleChildScrollView`, `ListView.builder`, `Wrap`, `FittedBox`, `Semantics`, `Icon`, `Text`, `SizedBox`, `Padding` | ✅ | all `widgets.dart`; none appear in the interop "what moved out" table. |
| `StadiumBorder`, `RoundedRectangleBorder`, `ShapeDecoration`, `BorderSide`, `TextStyle`, `Color` | ✅ | `painting.dart`, re-exported by `widgets.dart`. |
| `WidgetsBindingObserver` / `didChangeAppLifecycleState` (`calendar_view.dart:25,47`) | ✅ | `widgets.dart`. |
| `showDialog` | ❌ | Material. shadcn has no `showDialog` function; it ships `DialogRoute`, `showCommandDialog`, `showItemPickerDialog`, `showOverlay`, `AlertDialog` (`skill:components/overlay/dialog.md`, `skill:components/feedback/alert_dialog.md`). **Not used in `lib/` today.** |
| `showModalBottomSheet` | ❌ | Material. shadcn ships `openSheetOverlay`, `openDrawerOverlay`, `openRawDrawer`, `closeDrawer` (`skill:components/overlay/drawer.md`). **Not used in `lib/` today.** |
| `ScaffoldMessenger` | ❌ | Material, and no longer installed. Replaced by `showToast` (row 9) — the one call site is `calendar_view.dart:58`. |
| `ThemeExtension` | ❌ | Material. See row 22 — the only real corner, and decision 4 already removes it. |

**Which of those has a shadcn-native replacement that should be used instead:**
`ScaffoldMessenger`/`SnackBar` → `showToast`; `MaterialPageRoute` → `ShadcnPageRoute`;
`RefreshIndicator` → `RefreshTrigger`; `MaterialBanner` → `Alert`; `Icons.*` →
`LucideIcons.*`; `Theme.of(context).textTheme.*` → typography extensions.
`MediaQuery`, `Navigator`, `SafeArea`, `PageView`, `IndexedStack` have no shadcn
replacement and need none — they are framework, not Material.

**Is a 100% Material-free `lib/` reachable? — Yes.** Nothing in `lib/` requires a
`Material` or Material-`Theme` ancestor once the table above is applied. The escape
hatches (`MaterialShadcnApp`, `MaterialLayer`, `shadcn_flutter_material`) are **not
needed**, and the `shadcn_flutter_material` dependency should not be added at all.
Note the local `interop.md` names `MaterialShadcnApp`, but that class is **not in the
published `shadcn_flutter` index** — it lives in the separate
`shadcn_flutter_material` package, which is another reason to stay out of it.

The single corner that *would* have forced a `Theme` ancestor is
`ShiftColors extends ThemeExtension<ShiftColors>` (`shift_colors.dart:16`, read via
`Theme.of(context).extension<ShiftColors>()!` at line 35). Map standing decision 4
already freezes the six hues as constants, which dissolves it. **That decision is now
load-bearing for Material-freedom, not merely a tidy-up — 03 should treat it as a
hard requirement.**

Two secondary corners, neither Material:
- **Localizations.** `ShadcnApp` defaults to `supportedLocales: [Locale('en','US')]`
  and installs `ShadcnLocalizations` (`api:ShadcnLocalizations`). The app is Italian
  but does all its own date/label strings in `italian_dates.dart`, so nothing breaks;
  `kMaterialLocalizationsDelegates` is only needed if Material is kept, and it is not.
- **`ThemeMode`.** shadcn ships its **own** `ThemeMode` enum (`api:ThemeMode`), not a
  re-export, with the same three values `system` / `light` / `dark`. `ThemeCubit`
  (`theme_cubit.dart:12`) is `Cubit<ThemeMode>` and persists `mode.name` — the names
  are identical, so **the stored `shared_preferences` values stay valid across the
  migration**. Only the import line changes.

**`flutter_bloc`:** confirmed untouched. Grep over `lib/` shows `BlocProvider`,
`BlocProvider.value`, `BlocBuilder`, `context.read<…>()`, `Cubit<T>` and nothing else
from the package; none of them reference Material or `ThemeData`. The one
brush-point is the *type argument* `Cubit<ThemeMode>`, which is an import swap, not a
bloc change (see above). `skill:guides/state_management.md` exists and adds no
constraint. `CalendarCubit` and `MonthEditorCubit` carry no Flutter UI types at all.

### Residual Material

After the mapping above is applied, **nothing** from `package:flutter/material.dart`
remains in `lib/`. The list of things that *look* like residual Material and are not:

1. **`StadiumBorder`, `RoundedRectangleBorder`, `ShapeDecoration`, `BorderSide`** —
   `painting.dart`, re-exported by `widgets.dart`. Keep as-is. (row 21)
2. **`TextButton`, `IconButton`, `Divider`, `Chip`, `AppBar`, `Scaffold`,
   `CircularProgressIndicator`, `Colors`, `Theme`, `ThemeData`, `ThemeMode`** — names
   shared with Material, but shadcn ships its own of each. The import line is the
   whole change; the param lists are **not** identical (rows 2, 3, 8, 18).
3. **`MediaQuery`, `Navigator`, `SafeArea`, `PageView`, `IndexedStack`,
   `WidgetsBindingObserver`** — framework, never Material.

The genuinely residual items, all already scheduled:

1. **`ThemeExtension<ShiftColors>`** — the only true Material dependency. Removed by
   map decision 4 (ticket 03). Until 03 lands, `lib/` cannot be Material-free.
2. **`catui`** — supplies `catTheme`, `Flavor`, `catppuccin`, `AppTokens`,
   `CatSegmented` and today's `LucideIcons` re-export. Its teardown is its own
   workstream in the map ("`catui` teardown"), gated on 01 and 03.
3. **`ChipThemeData` in `theme.dart:19`** — a Material `ThemeData` field with no
   shadcn counterpart. It exists only to un-round catui's chips; it dies with
   `lib/shared/theme.dart` when `ThemeData` becomes shadcn's.
4. **No `shadcn_flutter_material` / `shadcn_flutter_cupertino` dependency is
   required.** Adding either would be a regression against this ticket's finding.

### Open items handed forward

- **Ticket 05** picks the `CatSegmented` replacement from the five shapes in row 15,
  and decides `picked_style.dart`'s new return type.
- **Ticket 05/06** must verify on the emulator that `RefreshTrigger` fires from inside
  the `PageView` without the `depth == 1` predicate (row 12).
- **Typography** per-string scale (row 17) stays where the map left it: unspecified.

## Comments

- 2026-09-22 — Row 9 overridden by [04 — Prototype the shell](04-prototype-shell-chrome.md): toast uses `ToastLocation.topCenter`, not `bottomLeft`, which sits under the floating bar.
