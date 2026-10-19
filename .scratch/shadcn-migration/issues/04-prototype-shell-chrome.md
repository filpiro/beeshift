# 04 — Prototype the shell: floating bottom bar, app bar, page scaffold

Type: prototype
Status: resolved
Blocked by: 01, 02
Map: ../map.md

## Question

`lib/features/shell/shell_view.dart` hosts the pages and
`lib/shared/widgets/floating_bottom_bar.dart` is a hand-built floating nav bar that does
its own system-inset maths (`barClearance`, `barReserve`, `barBottomMargin`) and hands
the calendar a reserve so its last grid row clears the bar.

Prototype the shell under `ShadcnApp` and settle:

1. **Does the custom floating bar survive?** shadcn ships `components/other/bar.md`,
   `rail.md`, `sidebar.md`, `components/navigation/tab_list.md`. If one of them gives a
   floating bottom bar with the same clearance behaviour, the custom widget dies. If not,
   it stays as plain Flutter and only reads shadcn tokens for colour and radius.
   Favour keeping it — the inset maths is the hard part and it already works.
2. **App bar.** shadcn `Scaffold` takes `headers`/`footers` rather than Material's
   `appBar`. Show `Impostazioni` and the calendar's own bar in that shape.
3. **The `barReserve` contract.** The calendar deliberately keeps `SafeArea` off its
   bottom edge and reserves space itself. Confirm shadcn's `Scaffold` does not fight this,
   or say what replaces the contract.

Link the prototype. Resolve with a decision, not merged code.

## Answer

Resolved 2026-09-22 with the user, against the `shadcn_flutter` 0.0.54 source in the pub cache.
[Prototype](https://claude.ai/artifact/SzSfXu8B5xt3JmukuXAJ7p) — HTML mock, darkSlate + Amber.

1. **The custom floating bar survives** (user confirmed). No shipped widget is a floating pill.
   `NavigationBar` (`navigation/navigation_bar/bar.dart`) is a flat full-width `Container` —
   no shape, no elevation, no `SafeArea`. `NavigationRail`/`Sidebar` are side rails.
   Reskin only: `Material(surfaceContainerHigh, elevation: 4, StadiumBorder)` becomes a
   `Container` with `colorScheme.card`, a `colorScheme.border` outline, `StadiumBorder`
   (from `painting`, not Material) and a `BoxShadow`. `_BarButton` becomes
   `IconButton.ghost` wrapped in shadcn `Tooltip` (02, row 7); keep the `Key(label)` and the
   `semanticLabel`. Active glyph `primary` → the Amber accent; inactive
   `onSurfaceVariant` → `colorScheme.mutedForeground`. `barClearance`, `barReserve`,
   `barBottomMargin` are unchanged.
2. **App bar.** `Impostazioni` and the Month Editor become
   `Scaffold(headers: [AppBar(title: Text(...)), Divider()], child: ...)`. shadcn `AppBar`
   applies `SafeArea(top:)` itself when it is `headers[0]` (`scaffold.dart:760`).
   shadcn `Scaffold` does **not** strip the top padding from its child's `MediaQuery` the
   way Material does, so the body `SafeArea` **must become `SafeArea(top: false)`** or the
   status-bar gap doubles. The Calendar has no app bar today and gets none: `headers: []`,
   filter chips + month title + weekday row stay in the body `Column`.
3. **The `barReserve` contract holds.** shadcn `Scaffold` never reads or rewrites
   `viewPadding`; it only rewrites `MediaQuery.padding`, and only when
   `floatingHeader`/`floatingFooter` is true — neither is used. The Calendar keeps
   `SafeArea(bottom: false)` and `padding: barReserve(context)`. The bar stays in the
   Shell's `Stack`, **not** in `footers:` — a footer would add its height on top of
   `padding.bottom`, which already holds the system inset, so the inset counts twice.
   Each shadcn `Scaffold` builds its own `Overlay` + `ToastLayer`; the nested
   Shell → Calendar scaffolds are harmless.
4. **Toast moves to `ToastLocation.topCenter`** (user choice). 02's `bottomLeft` lands under
   the floating bar, and `Scaffold` gives no way to pad its `ToastLayer`. This overrides
   row 9 of 02.

Navigation shape unchanged: `IndexedStack` + `setState` (ADR 0004), `MaterialPageRoute` →
`ShadcnPageRoute` per 02.
