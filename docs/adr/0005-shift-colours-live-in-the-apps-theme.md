# Shift Colours live in beeshift's theme, not in `catui`

Each Shift Type carries one Shift Colour. The mapping is a `ThemeExtension` registered by beeshift's own theme, built per flavor, and read from context like every other colour.

## Considered Options

### Where the mapping lives

**In `catui`** — rejected. The house style is shared with Clockodile, and a shared package has no opinion about what a night shift looks like: `ShiftType` does not exist there, and an enum-keyed colour table would have to be either copied into the package or handed to it as a `Map`, which is the same table with an extra hop. ADR-0004 already draws this line — the app states its accent, the package states everything else.

**A `const` table in a beeshift file, outside the theme** — rejected. It would have to name a flavor, so it would need a second table for the other one, and the two would drift the first time a hue is adjusted. It would also be the only colour in the app not reached through `Theme.of(context)`, so a widget would import a constant to draw one thing and read the theme to draw the next.

**A `ThemeExtension` on beeshift's theme, built per flavor** — chosen. One `ShiftColors.forFlavor(flavor)` produces latte's and mocha's tables from the same six lines, the theme carries it, and a widget reads `ShiftColors.of(context)`. Theme switching lerps it for free.

### Which colours

Yellow is excluded: it is the app's accent, so a Shift Type wearing it would be indistinguishable from a selection or a today marker. Red is excluded: it is the scheme's `error`, and a Shift Type that reads as a failure is one nobody trusts. The remaining six are peach (Primo), blue (Secondo), mauve (Notte), teal (Smonto), green (Riposo) and pink (Ferie).

Mauve is also `catui`'s default primary, but beeshift overrides that with yellow, so there is no clash in this app.

## Consequences

A seventh Shift Type needs a seventh entry here as well as an enum value; the lookup asserts on a missing one rather than falling back, so the gap is loud in the first test that draws it.

If Clockodile ever wants the same idea, what moves into `catui` is the pattern, not this table — the colours are beeshift's domain, and the package would only ever host the plumbing.
