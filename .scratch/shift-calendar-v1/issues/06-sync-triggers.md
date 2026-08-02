# 06 — Sync triggers

**What to build:** The app keeps itself current without being asked, and gives you a way to force it when you can't wait.

Two triggers, both of them pulls. Bring the app back to the foreground and it syncs, recomputes today, re-derives the Data Window, and re-queries — so a schedule you entered on your other device is simply there, and the "today" highlight has corrected itself overnight. Pull down on the Calendar and the same fetch happens on demand, for the case where you changed something on the other device thirty seconds ago.

Resume is the trigger, **not cold start**. Android rarely kills this app; a cold-start-only trigger would almost never fire, which is exactly how the highlight ends up pointing at yesterday and the carousel ends up showing a month that has already ended.

There is deliberately **no sync after a write**. Writes go straight to the primary, and read-your-writes means the writing device sees them immediately — a post-write sync would push nothing and pull nothing. The original design documents specify the opposite, so this needs a test standing guard over it, not just a comment.

Failure handling is the next-but-one ticket; here, success is the path being built.

**Blocked by:** 04, 05.

**Status:** ready-for-agent

- [ ] Returning the app to the foreground syncs, then re-queries
- [ ] Pull-to-refresh on the Calendar syncs, then re-queries
- [ ] "Today" is recomputed on resume — asserted by resuming with a later injected "now" and seeing the highlight move
- [ ] The Data Window is re-derived on resume — asserted by resuming with an injected "now" in the following month and seeing the carousel's two months roll forward
- [ ] Ordering is asserted: sync completes before the query runs, on both triggers
- [ ] A test asserts that no sync occurs after a write
- [ ] No periodic timer and no background sync exists anywhere
- [ ] The cold-start `sync()` left in `main.dart` by 02 is removed — see the comment below

## Comments

**There is a third trigger to delete when this ticket runs.** `_openRepository()`
in `lib/main.dart` still awaits `repository.sync()` before the first frame,
carried over from ticket 02 where it was the only way to prove Turso rows
reached the device. It is exactly the cold-start trigger this ticket rules out,
and it makes opening the app wait on the network, against the spec's "Reads
always come from a local copy, so opening the app is instant and never waits on
the network." Ticket 03's review flagged it; it was left in place because
removing it before the resume and pull-to-refresh triggers exist would leave the
app with no sync at all.
