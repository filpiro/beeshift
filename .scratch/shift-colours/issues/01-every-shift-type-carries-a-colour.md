# 01 — Every Shift Type carries a colour

**What to build:** A Shift Colour — one palette colour per Shift Type — reachable from any widget through the theme, in both flavors, and written down as domain vocabulary rather than as styling trivia.

The mapping is fixed and belongs to beeshift, not to `catui`: a shared house style has no opinion about what a night shift looks like. It is taken per flavor, the same way the app's yellow accent already is, so latte gets latte's hues and mocha gets mocha's without a second table.

The mapping: `7` Primo takes peach, `3` Secondo takes blue, `N` Notte takes mauve, `S` Smonto takes teal, `R` Riposo takes green, `F` Ferie takes pink. Yellow is not available — it is the app's accent — and red is not available either, because it is already the scheme's error colour and a Shift Type that reads as a failure is a Shift Type nobody trusts.

A Shift Type is the only thing that has a colour. A day with no Shift has none, and the app's own accent stands in wherever a colour is still needed.

Nothing on screen changes in this ticket. It exists so the next two have one place to read from instead of two tables that drift.

**Blocked by:** None — can start immediately

**Status:** done

- [x] Each of the six Shift Types resolves to a distinct palette colour, in latte and in mocha
- [x] The colours are read through the theme, the same way every other colour in the app is
- [x] The mapping lives in beeshift and nothing is pushed into `catui`
- [x] Neither the accent yellow nor the error red is used as a Shift Colour
- [x] `CONTEXT.md` gains a **Shift Colour** entry — the colour identifies the Shift Type, it is not decoration
- [x] An ADR records why the mapping lives in the app's theme rather than in the shared package
- [x] Analyze is clean and the whole suite still passes, with nothing on screen changed
