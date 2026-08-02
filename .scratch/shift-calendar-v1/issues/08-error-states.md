# 08 — Error states

**What to build:** Honest behaviour when things fail, calibrated so that exactly one failure is impossible to miss and the rest stay out of the way.

The principle: **only a failed write is unmissable.** Everything else degrades to "you are looking at slightly older data", which for a single-user app with one other device is nearly harmless — and interrupting you about it is worse than the staleness.

Four behaviours:

- **Cannot connect to the database** — a full-screen error with a Retry action. There is no app without the database, so pretending otherwise helps nobody.
- **Save fails** — stay on the Month Editor. Selections preserved exactly as they were, a sticky inline banner, Save still enabled to retry. Deliberately **not** a transient toast: this is the one place where missing the message means believing a month was recorded when it wasn't. Writes reach the primary synchronously, so this is what being offline looks like.
- **Pull-to-refresh fails** — a transient message. You asked for something and didn't get it, so you get one line about it. The data already on screen stays there.
- **Resume sync fails** — silent. No UI at all. Firing an error every time you unlock your phone in a bad-signal spot is pure noise for something you never requested.

**Blocked by:** 06, 07 — both failure surfaces have to exist before they can fail properly.

**Status:** done

- [x] Connect failure shows a full-screen error with a working Retry
- [x] Save failure keeps the user on the editor with every selection intact and a non-dismissing error visible
- [x] Save can be retried directly after a failure, and succeeds once connectivity returns
- [x] Pull-to-refresh failure shows a transient message and leaves the existing data on screen
- [x] Resume sync failure produces no UI whatsoever and leaves existing data on screen
- [x] All four are asserted at the state seam with a fake repository that fails on demand
- [x] A failed sync never clears, empties, or corrupts already-loaded Calendar data
