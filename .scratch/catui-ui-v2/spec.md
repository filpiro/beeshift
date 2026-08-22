# catui UI v2

Status: ready-for-agent

## Problem Statement

The app works and looks like nothing. It is stock Material 3 on the default seed colour, on a phone I use in the dark half the year, and it has no way to say so — no theme choice, no dark mode beyond whatever the system imposes on an app that never asked.

The one control it does have is a floating edit button in the corner. It is the only navigation the app has: one screen, one button, and no room for a second destination. Adding Settings under that arrangement means either a second floating button in the other corner or a hamburger over a two-item menu.

I also maintain a second Flutter app, Clockodile, which already solved the look: a shared package, `catui`, holding a catppuccin theme, design tokens and the atomic widgets built on them, plus a folder layout that says where a feature goes. Beeshift is eight files in a flat `lib/` and shares none of it. Every styling decision made here is one made twice, differently.

Three visual details in `docs/UI/base.md` have also been owed since the Month Editor shipped: its six choices are a stock `SegmentedButton` that cannot hold six letters in one row on a phone, the day numbers are small, and the rows are too tight to scan.

## Solution

Beeshift adopts `catui` as its house style, and Clockodile's folder layout with it, so the two apps stay one design decision rather than two.

The floating edit button is replaced by a **Bottom Bar**: a floating pill hugging two icon buttons, centred above the bottom edge. The first opens **Settings**, the second opens the Month Editor. The Settings button is a destination and lights up while Settings is showing; tapping it again returns to the Calendar. The edit button is an action — it pushes the Month Editor over everything, bar included, and never lights up.

Settings is one choice: Theme Mode — light, dark, or follow the system — drawn as `catui`'s separate-buttons group. It applies the instant it is tapped and survives a restart. The default is the system's.

The Month Editor keeps its shape exactly: pushed screen, own back button, Save in the app bar, discard by leaving. Only its paint changes — the six Shift Codes become one row of equal square buttons that fit a phone, the day headings grow, and the rows get room to breathe.

The Calendar and the Filter keep every behaviour they have. They inherit the palette and the corner radius, and nothing else about them moves.

## User Stories

1. As a shift worker, I want the app drawn in the catppuccin palette, so that it looks like a deliberate app rather than a Flutter default.
2. As a shift worker, I want a dark theme, so that checking tomorrow's Shift in bed does not blind me.
3. As a shift worker, I want the theme to follow my phone's setting out of the box, so that I never have to configure anything to get the right one.
4. As a shift worker, I want to override the system and force light or dark, so that I can keep the app readable when the system setting is wrong for where I am.
5. As a shift worker, I want the theme to change the moment I tap it, so that I can see which one I want rather than imagining it.
6. As a shift worker, I want my theme choice remembered after I close the app, so that I choose it once.
7. As a shift worker, I want my theme choice to stay on this phone, so that setting dark on the one I use at night does not darken the other.
8. As a shift worker, I want the theme choice to work even when the schedule cannot load, so that a dead network does not lock me out of a preference that has nothing to do with the network.
9. As a shift worker, I want a bar that is always on screen, so that the app's destinations are visible rather than remembered.
10. As a shift worker, I want that bar to float as a rounded pill above the bottom edge, so that it reads as a control sitting over the Calendar rather than a slab bolted to the frame.
11. As a shift worker, I want the bar to hug its buttons rather than span the screen, so that the Calendar keeps as much width as it can.
12. As a shift worker, I want the button for the screen I am on to be visibly active, so that I always know where I am.
13. As a shift worker, I want the active button drawn as a filled rounded pill with a coloured glyph, so that the state reads at a glance without a label.
14. As a shift worker, I want the inactive button muted, so that the active one is the only thing claiming attention.
15. As a shift worker, I want the bar reachable with a thumb, so that I can use the app one-handed.
16. As a shift worker, I want tapping the lit Settings button to take me back to the Calendar, so that I am never stuck on Settings looking for a way out.
17. As a shift worker, I want the Calendar to stay exactly where I left it — same month, same Filter — when I come back from Settings, so that a detour costs nothing.
18. As a shift worker, I want the grid to stop above the bar rather than under it, so that the last week of the month is never hidden behind a control.
19. As a shift worker, I want the edit button to open the Month Editor full-screen, so that entering a month is not done through a hole above a navigation bar.
20. As a shift worker, I want the Month Editor to keep its own back button, so that leaving it is the same gesture as leaving any other screen on the phone.
21. As a shift worker, I want the Month Editor to keep Save at the top, so that committing a month I have just tapped my way down is where it has always been.
22. As a shift worker, I want the Month Editor to still open on whichever month the Calendar was showing, pre-loaded with what is recorded, so that nothing about entering a schedule changes.
23. As a shift worker, I want the Calendar to refresh when I come back from a save, so that what I entered is on screen immediately.
24. As a shift worker, I want a failed save to keep me on the editor with my taps intact, so that I never believe a month was recorded when it was not.
25. As a shift worker, I want the six Shift Codes on one row, so that choosing a Shift Type is one tap with no scrolling sideways.
26. As a shift worker, I want each of the six choices the same width, so that I can hit the one I want without aiming.
27. As a shift worker, I want the selected Shift Type filled and the rest outlined, so that the day's answer is obvious while scrolling past it.
28. As a shift worker, I want the choices drawn as Shift Codes and spoken as their Italian names, so that the row fits and a screen reader still says `Notte`.
29. As a shift worker, I want the day heading bigger, so that I can find the 17th by scrolling rather than reading.
30. As a shift worker, I want space between the day rows, so that a month does not read as one dense block.
31. As a shift worker, I want the Month Editor to still refuse to un-record a day, so that a mis-tap cannot silently blank a Shift.
32. As a shift worker, I want the Filter to keep both groups always on screen with the same headings and the same taps, so that a restyle does not make me relearn it.
33. As a shift worker, I want the filter chips to match the app's corners and colours, so that they look like part of the app rather than the framework.
34. As a shift worker, I want today's tile still filled in the accent colour, so that the one thing the Calendar exists to answer is still answered at a glance.
35. As a shift worker, I want muted and filler days still dimmed the same way, so that the Filter reads exactly as it did.
36. As a shift worker, I want the month title, weekday initials, swipe between the two months and pull-to-refresh all untouched, so that the app I know is the app I get.
37. As a developer, I want the theme, tokens and icons to come from one shared package, so that a decision made in either app is not remade differently in the other.
38. As a developer, I want the folder layout to match Clockodile's, so that moving between the two projects costs no re-orientation.
39. As a developer, I want the tests to mirror the source layout, so that the file holding a screen's tests is where the screen is.
40. As a developer, I want the navigation to be an index and an `IndexedStack`, so that two destinations do not cost a router.
41. As a developer, I want the bar and the active-pill rule in one widget, so that a third destination is a list entry rather than a layout change.

## Implementation Decisions

**House style comes from `catui`, as a git dependency on `main`** — the same reference Clockodile uses, so the two apps track the same commit. `catui` re-exports `catppuccin_flutter` and `lucide_icons_flutter`; beeshift declares neither directly. Lucide replaces Material icons wherever the app draws one.

**`catui` is not modified.** The bottom bar and the dense one-row choice group do not exist in it and are built inside beeshift's shared widgets. One consumer is not an API. They are promoted upstream when a second app wants them, and the code says so.

**The accent is the flavor's yellow**, taken per flavor rather than fixed, so latte gets the dark yellow and mocha the light one and both keep `Flavor.base` as their foreground. Stated in beeshift's own theme file, not in the package — the same division Clockodile uses for its green. Secondary is left to `catui`.

**Two flavors, not four**: latte for light, mocha for dark. Frappé and macchiato are not offered; Theme Mode is the only theme axis in Settings.

**The chip theme is applied on the consumer side.** `catTheme` has no `chipTheme`, and the Filter's chips are the only chips in either app. Beeshift's theme file copies the package theme with a chip theme matching `AppTokens.radius`, rather than pushing a beeshift-shaped decision into the shared package.

**Navigation is an index over an `IndexedStack`, no router.** Two destinations, no deep links, no URLs; Clockodile does the same. The Month Editor is not one of the destinations — it is pushed on the root navigator, so it covers the bar.

**The Shell owns the index and the bar.** `main.dart` keeps only the repository `FutureBuilder` and the three states it already draws. The Shell mounts under the loaded-repository branch, so no bar exists over the connect-error screen or the opening spinner.

**The Edit button is disabled while the Calendar has no grids** — first load in flight, or first load failed. Editing a schedule that could not be read is meaningless. The Settings button stays live throughout, which is the point of putting the theme choice behind a control that does not depend on the database.

**The Month Editor's lifecycle is unchanged**: pushed with a `MonthEditorCubit` built from the Calendar's `visibleMonth` and its snapshot of that month's Shifts, back discards, `save()` pops on success and the Calendar reloads on return. This was reconsidered as a shell tab and rejected — an `IndexedStack` keeps children alive, so a long-lived editor drifts stale against the carousel, and "tap Calendar" becomes a one-finger discard of unsaved work.

**Theme Mode is a `ThemeCubit` over `shared_preferences`.** Device-local, which is the correct scope for a display preference; the Turso replica holds one `shifts` table and syncing a per-device preference through it would contradict that. The cubit starts at `ThemeMode.system` and emits the stored value once it reads back, so the first frame is never wrong for longer than a frame.

**The bar's geometry**: centred, floating above the safe-area bottom, fill from `surfaceContainerHigh`, stadium border, light shadow, two 48dp icon buttons, width hugging the pair. Active is a filled rounded pill in `secondaryContainer` behind a `primary` glyph; inactive is a bare `onSurfaceVariant` glyph. No labels. The Calendar's reserved bottom strip is the bar's height plus its margin, replacing the reserve the floating button had.

**Folder layout mirrors Clockodile**: `lib/features/<feature>/<feature>_view.dart` with its `cubit/` beside it, `lib/shared/theme.dart` and `lib/shared/widgets/`, `lib/data/` for the repository, and the tests mirroring it. The move lands first, alone, as a pure rename — so the styling diff that follows is readable.

**`docs/UI/base.md` is retired** once its Month Editor items land. Its first item asks for a floating edit button, which this work deletes.

**Glossary and decision record**: `CONTEXT.md` gains **Shell**, **Bottom Bar**, **Settings** and **Theme Mode**. An ADR records the two hard-to-reverse calls — `catui` as the house style, and shell navigation without a router.

## Testing Decisions

A good test here asserts what the user can see or do, through the same seam the app uses: a pumped widget over `FakeShiftsRepository`, never a call into a private widget or a check on a style object. Colours, radii and paddings are not asserted — they come from the theme, and a test that pins them only breaks when the theme improves.

**Existing seam, preferred**: the page-level widget tests already in the suite (`calendar_page_test`, `month_editor_page_test`) plus the cubit tests. They move with their sources and otherwise stand.

**One new seam**: a Shell-level widget test, pumping the Shell over `FakeShiftsRepository`. It covers the bar's two buttons, the active pill following the destination, Settings toggling back to the Calendar, the Calendar surviving the round trip, the Edit button pushing a full-screen Month Editor with no bar over it, and the Edit button being disabled before the first load lands. Settings gets no test file of its own — the theme picker is reachable and assertable through the Shell.

**No seam for preferences**: `SharedPreferences.setMockInitialValues` in `setUp`. A store interface with one implementation and one caller is an abstraction the app does not have a second use for.

**Prior art**: `test/calendar_page_test.dart`'s `pumpCalendar` helper is the pattern the Shell test copies — build the cubit over the fake, `load()`, pump inside a `MaterialApp`, clear recorded calls, then assert on behaviour.

**The theme cubit** is tested directly, like the other cubits: default is `system` with nothing stored, the stored value wins on construction, and setting a mode writes it.

## Out of Scope

- Any change to what the app stores, syncs, or reads. No schema change, no new table, no change to the sync triggers.
- Accent-colour choice in Settings. The accent is a constant; only Theme Mode is user-facing.
- Frappé and macchiato.
- Any behavioural change to the Filter — the groups, the OR/AND rule, the Empty-day rule and its lifetime are all as ticket 15 left them.
- Any behavioural change to the Calendar — the two-month carousel, today's highlight, muting, pull-to-refresh and the resume trigger all stand.
- Any behavioural change to the Month Editor — the snapshot, the discard-on-back, the one-batch save and the sticky failure banner all stand.
- A third destination in the bar. The widget takes a list, but nothing is added to it here.
- Localisation delegates. The app is Italian by construction and does not gain `flutter_localizations`.
- Promoting the bar or the dense choice group into `catui`.
- Desktop or web. The bar's geometry is a phone's.

## Further Notes

`catui` is desktop-shaped in places — hover styles, an 18dp icon size chosen against a 40dp hover disc. None of that is wrong on a phone, it is merely unused; the bar states its own 48dp buttons rather than inheriting the package's icon size.

The dependency is a git ref on `main`, so it is unpinned by construction. That is Clockodile's arrangement too, and both apps are single-developer. If it ever bites, the fix is a commit SHA in both pubspecs on the same day.
