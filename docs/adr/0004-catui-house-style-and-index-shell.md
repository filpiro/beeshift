# `catui` as the house style, and a Shell that is an index

> **Superseded in part** by [ADR-0006](0006-shadcn-flutter-replaces-catui.md): the house-style half ("The look") no longer holds. The navigation half stands.

Beeshift takes its theme, design tokens and icon set from `catui`, a git dependency shared with Clockodile, and adopts that app's folder layout with them. Navigation between the Shell's two destinations is an `int` index over an `IndexedStack`. There is no router.

## Considered Options

### The look

**Stock Material 3 on a seed colour** — rejected. It is what the app has, and it costs nothing to keep, but every styling decision then gets made here and made again in Clockodile, differently. Two apps by one developer that disagree about what a button's corner is are two apps that both look accidental.

**Copy Clockodile's theme file into beeshift** — rejected. It is one file today, and one file is genuinely cheap to duplicate. It is also the wrong unit: the tokens, the intent-hover style and the segmented group are already three files there, the copy diverges the first time either app fixes something, and the divergence is invisible because nothing imports anything.

**Depend on `catui`** — chosen. It already exists, already re-exports the palette and the icons so both apps stay version-locked to the same glyphs, and already draws the line between house style and app: the accent is stated by the app, everything else by the package. Beeshift states yellow, Clockodile states green.

The cost, accepted: `catui` is pinned to `main`, so both apps track a moving reference, and it is desktop-shaped in places — hover styles, an icon size chosen against a hover disc. Neither is wrong on a phone; the hover states are simply never entered, and the bar states its own button size. A SHA pin in both pubspecs is the fix if the moving reference ever bites.

**Extend `catui` with the two widgets beeshift lacks** — rejected for now. The floating bar and a six-across choice group have exactly one consumer, and an API designed for one consumer is a guess. They live in beeshift's shared widgets with a note saying where they go when a second app wants them.

### The navigation

**`go_router`** — rejected. It buys deep links, URL state and typed routes; the app has two destinations, no URLs, no incoming links, and one pushed screen that a plain `Navigator.push` already handles. The Month Editor's contract — built from a snapshot of the Calendar's visible month, discarded on back — is one constructor call today and becomes route arguments and a redirect under a router.

**Both destinations as pushed routes, the bar as pure actions** — rejected. Nothing would ever be "current", so the active-pill state the bar exists to show would have nothing to show, and returning to the Calendar from Settings would rebuild it and lose the month and the Filter.

**The Month Editor as a third destination in the Shell** — rejected, and this is the one worth recording. An `IndexedStack` keeps its children alive, so an editor built from a snapshot of the visible month would drift stale the moment the Calendar's carousel paged to the other month; keeping it fresh means either a listener wiring two cubits together or rebuilding the subtree on every tab entry. Both are machinery bought to make a screen behave like the pushed route it already is. Worse, it makes "tap Calendar" a one-finger discard of unsaved taps, where today the discard is a back press the user aimed at.

**An index over an `IndexedStack`, the editor pushed** — chosen. Switching destinations is `setState`, both keep their state for free, and the editor keeps the lifecycle it has: pushed, snapshot, own back button, Save pops, Calendar reloads on return.

## Consequences

The Shell mounts only under the loaded-repository branch, so no bar is drawn over the connect-error screen or the opening spinner. The Edit button is disabled while the Calendar has no grids; the Settings button is not, which is what makes the theme choice usable on a dead network.

A third destination is a list entry in the bar plus a child in the stack. If a fourth arrives, or if the app ever wants a link into a specific month, this decision is cheap to revisit — the router question reopens with `MaterialApp.router` and the same two screens, and nothing here has to be unpicked first.
