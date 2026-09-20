# 07 — What colour is a shift in Light mode?

Type: grilling
Status: open
Map: ../map.md

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

<!-- filled on resolution -->
