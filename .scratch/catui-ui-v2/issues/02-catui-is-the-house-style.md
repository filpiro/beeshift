# 02 — `catui` is the house style

**What to build:** The whole app repainted. Light and dark catppuccin themes with a yellow accent, following the phone's setting, with every screen inheriting the palette, the corner radius and the icon set. Nothing moves and nothing gains a control — the app is the app, in colour.

`catui` arrives as a git dependency on `main`, the same reference Clockodile uses. It re-exports the palette and the icons, so beeshift declares neither directly, and Material's icons are replaced by Lucide wherever the app draws one.

Beeshift's own theme file states one thing the package does not: the accent. Yellow, taken from the flavor rather than fixed, so latte gets the dark yellow and mocha the light one and both keep the flavor's base as their foreground. Secondary is left to `catui`. Latte is light, mocha is dark, and no other flavor is offered.

The one thing the package theme does not cover is the Filter's chips — the only chips in either app. The chip theme is stated here, on the consumer side, matching the shared corner radius rather than pushing a beeshift-shaped decision into a shared package.

Both themes are handed to the app at once and the mode follows the system. Choosing the mode is ticket 03; this ticket is the two themes existing and the system picking between them.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] `catui` is the only new dependency, referenced by git on `main`, and neither the palette nor the icon package is declared directly
- [ ] The app has a light theme and a dark theme, built from `catui`'s theme function on latte and mocha
- [ ] The accent is the flavor's yellow in both, read per flavor rather than hardcoded
- [ ] Turning the phone from light to dark and back repaints the app both ways
- [ ] The Filter's chips match the app's corner radius rather than the framework default
- [ ] No Material icon is left anywhere in the app
- [ ] No screen gains, loses or moves a control
- [ ] `flutter analyze` is clean and the whole suite passes
