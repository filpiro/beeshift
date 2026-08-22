# 07 — A way back to the Calendar

**What to build:** Settings is a room with no door. The only way out today is tapping the Settings button a second time while it is already lit, which nobody discovers, so the app reads as a one-way trip. The Bottom Bar gains a third button, Calendario, and the way back stops being a secret.

The bar carries three buttons, left to right: Calendario, Modifica, Impostazioni. The two destinations flank the one action. Calendario is drawn active while the Calendar is showing, exactly as Impostazioni is drawn active while Settings is, and returning to the Calendar leaves it on the month it was on with the Filter it had — that is what the Shell's stack has always promised and this ticket does not spend it.

Both destination buttons become a plain "go there". Tapping the one that is already active does nothing at all: the old toggle, where Impostazioni pressed twice walked back to the Calendar, goes away. One button per destination, one meaning per button.

The Month Editor does not change. It is still pushed full-screen over the bar, still left by its own back arrow or by Salva. It is a task with unsaved work in it, and a Calendar button there would be an escape hatch that says neither save nor discard.

The same bar is also sitting too low. It is spaced from the raw bottom edge of the screen, which on a phone with a gesture bar or a home indicator means the system's furniture is sharing the gap. The bar clears whatever the system reserves at the bottom, and then keeps a larger gap than it does today above that — on a phone with no bottom furniture the bar still ends up further from the glass than it is now. The Calendar's grid reserves the taller amount too, so the last row of day tiles stays fully visible above the bar on either kind of phone. Nothing about the bar's shape, its pill, or its elevation changes.

`CONTEXT.md`'s **Bottom Bar** entry describes two buttons and names the Settings toggle as the way back. Both are false after this. The **Shell** entry stays as it is, and ADR 0004 is untouched — this is a third button in the same bar, not a router.

**Blocked by:** None — can start immediately.

**Status:** done

- [x] The Bottom Bar shows three buttons in the order Calendario, Modifica, Impostazioni, each with its own Italian screen-reader name
- [x] Calendario is drawn active while the Calendar is showing, Impostazioni while Settings is, and never both
- [x] From Settings, Calendario returns to the Calendar on the same month with the same Filter
- [x] Tapping a destination button that is already active does nothing — the Impostazioni self-toggle is gone
- [x] Modifica is unchanged: still disabled while the Calendar has no grids, still opens the editor full-screen over the bar
- [x] The bar clears the system's bottom inset and keeps a larger gap above it than it does today
- [x] The Calendar's last row of day tiles is fully visible above the bar on a phone with a bottom inset and on one without
- [x] The Shell's tests cover the three buttons, the return from Settings, the inert active button, and the bar's clearance over a faked bottom inset
- [x] `CONTEXT.md`'s Bottom Bar entry matches what the bar now is

## Comments

The third button is a list entry in the existing `FloatingBottomBar`, exactly as that widget's own doc predicted — no new API, no router, ADR 0004 untouched. Both destinations now just assign the index; the self-toggle is gone.

The clearance is one number read once. `barClearance(context)` is `viewPadding.bottom + barBottomMargin` (16 → 24), and `barReserve(context)` — now a function, not a const 80 — is that plus the bar's height and gap. The Calendar's `SafeArea` gives up its bottom edge so the inset is not taken off twice; had it kept it, the grid would read `padding` while the bar read `viewPadding`, and the two would part company the moment anything consumed the inset.

Tapping the active destination is a no-op `setState`, so the button still ripples. Left live rather than nulled: a disabled Calendario on the Calendar would grey out the button that says where you are.

`flutter analyze` clean, 100/100 tests pass.
