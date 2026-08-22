# 03 — The Filter and the Month Editor agree on colour

**What to build:** One idiom for "this Shift Type is picked", used by the Filter's chips and by the Month Editor's row of choices alike: no fill, a two-pixel border in the Shift Colour, and the Shift Code bold in the same colour.

Both places already draw the same six letters and mean roughly the same thing by them, and today they say "picked" in two different ways — a tinted chip in one, a filled button in the other. After this ticket the colour is the signal in both. Unselected stays quiet: the outline and the letter in the ordinary muted foreground, normal weight. The Shift Code is larger in both places than it is now — these are the letters the user reads off the real rota.

The Filter's second group has no Shift Type behind it, so its seven weekday letters take the app's accent instead: same shape, same border, same bold letter, yellow rather than a Shift Colour. The two groups keep their two headings, which are still the only thing telling Smonto's `S` from Sabato's `S`.

The Month Editor keeps its rules exactly: six choices on one line at equal widths, every tap sets the day, no tap ever clears it, and one Save still commits the month. The Filter keeps its rules exactly: multi-select, no check marks, OR-within and AND-across, and the Empty-day rule untouched.

The two stay separate widgets. They look alike and behave differently — one wraps and multi-selects, the other is a single-choice row — and a single widget covering both would carry both behaviours to serve neither.

Every letter still announces its full Italian name and its selected state out loud, which is what keeps the design honest now that colour is doing visible work.

**Blocked by:** 01

**Status:** done

- [x] A selected Shift chip draws no fill, a two-pixel Shift Colour border, and its Shift Code bold in that colour
- [x] A selected Month Editor choice draws exactly the same way
- [x] Unselected in both places is a quiet outline and a normal-weight muted letter
- [x] The Shift Code is larger than before in both places
- [x] The weekday chips take the app's accent in the same shape
- [x] Both filter groups keep their headings, stay multi-select, and still show no check marks
- [x] The OR-within, AND-across rule and the Empty-day rule are unchanged
- [x] The Month Editor still fits six choices on one line, still cannot clear a day, and still saves the month in one action
- [x] Every letter still announces its Italian name and its selected state
- [x] The Filter and the Month Editor remain separate widgets
- [x] Analyze is clean and the whole suite passes with no behavioural assertion rewritten
