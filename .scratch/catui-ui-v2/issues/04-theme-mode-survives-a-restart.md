# 04 — Theme Mode survives a restart

**What to build:** The Theme Mode chosen in Settings is still in force the next time the app opens. Choosing it is a once-ever act rather than a once-per-launch one.

The choice is stored on the device, not in the database. The replica holds one `shifts` table (ADR 0003) and it syncs; a display preference is not schedule data and must not travel to the other phone — setting dark on the one used at night has no business darkening the other.

With nothing stored, the mode is the system's, which is what a fresh install gets. The stored value is read back at startup and applied; until it lands, the app draws the system's, so the worst case is one frame of the wrong theme rather than a blocking read before the first paint.

**Blocked by:** 03

**Status:** done

- [x] Choosing dark, closing the app and reopening it gives a dark app
- [x] The same holds for light, and for system
- [x] A fresh install with nothing stored follows the phone's setting
- [x] Nothing about the theme choice reaches the database or the other device
- [x] Choosing a mode still applies instantly, with no confirmation step
- [x] The theme cubit is tested directly: the default with nothing stored, a stored value winning at construction, and setting a mode writing it
