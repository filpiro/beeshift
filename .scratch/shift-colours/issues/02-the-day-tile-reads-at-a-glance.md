# 02 — The day tile reads at a glance

**What to build:** A Calendar day tile you can read without looking twice: the Shift Code large and coloured on the left, the day number small in the top-right corner, and today marked by its own colour rather than by a slab of accent.

The Shift Code is the thing the user is actually looking for, so it gets the size and it gets the Shift Colour. The day number is how you find the right tile, not what you read off it, so it shrinks out of the way into the corner — the same size it is today, only moved. A day with no Shift draws no letter and stays as plain as it is now.

Today stops being a filled tile. It keeps a border instead, two pixels of its own Shift Colour, and both its number and its Shift Code are bold. Nothing else on the grid is bold. When today has no Shift entered, there is no Shift Colour to borrow, so the border falls back to the app's accent — today is still findable on an empty month.

Everything the tile already gets right is frozen: today is still marked only on the page that owns the day and never as a filler day, the shared corner radius is unchanged, filler and muted days are still dimmed to the same single opacity and never dimmed twice, and a six-row month on a short screen still shrinks rather than clips or overflows. No tile is tappable — the Month Editor is still the only way in.

**Blocked by:** 01

**Status:** done

- [x] The Shift Code is drawn on the left of the tile, larger than before, in its Shift Colour
- [x] The day number sits in the top-right corner at the size it already has
- [x] Today draws a two-pixel border in its own Shift Colour and no fill
- [x] Today with no Shift entered falls back to an accent border, and still shows no letter
- [x] Today's day number and Shift Code are bold; no other day is bold
- [x] Today is still marked only on the page that owns the day, never as a filler day
- [x] Filler and muted days keep the same single 0.35 dimming and are never dimmed twice
- [x] A six-row month on a short screen still fits above the Bottom Bar with nothing overflowing
- [x] A widget test covers today with a Shift, today without one, a plain day and a muted day
- [x] Analyze is clean and the whole suite passes with no behavioural assertion rewritten
