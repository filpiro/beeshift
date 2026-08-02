# 05 — Data Window carousel

**What to build:** Swipe horizontally to move between this month and next month, and stop there. Two pages, not infinite paging — the Data Window is the current month plus the following one, and there is nothing beyond it to page to.

Both pages are served by the load that already happened; the query range widens to cover both months' visible grids rather than firing a second fetch on swipe. Which page is showing becomes part of the Calendar's state, because the next tickets depend on it: the editor targets the visible month, and resume has to re-derive the window when the real-world month rolls over.

Note that the Data Window is a *viewing* rule only. Shifts outside it are retained and are never purged — they are simply not reachable in v1.

**Blocked by:** 03.

**Status:** ready-for-agent

- [ ] Swiping left and right moves between the current month and the next month
- [ ] Paging stops at both ends; there is no third page
- [ ] Today and current-week highlighting behave correctly on both pages, including when today's week straddles the boundary between them
- [ ] The visible month is exposed in state
- [ ] Both pages render from a single load, with no fetch triggered by swiping
- [ ] The derived window is asserted against an injected "now", including a December "now" where the next month falls in the following year
