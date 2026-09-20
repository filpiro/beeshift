# 04 — Prototype the shell: floating bottom bar, app bar, page scaffold

Type: prototype
Status: open
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

<!-- filled on resolution -->
