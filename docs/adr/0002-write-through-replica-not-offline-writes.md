# Write-through replica, not offline writes

`libsql_dart` offers two local-file modes: `LibsqlClient.replica` (writes forwarded synchronously to the Turso primary) and `LibsqlClient.offline` (writes land locally and are pushed on a later `sync()`). We chose `.replica` with `readYourWrites: true` and `syncIntervalSeconds` omitted.

Reads are ~99% of usage and are served from the local file in both modes, so the choice only concerns writes — which happen roughly once a month, plus a few corrections. Requiring connectivity for those is acceptable; the phone is online whenever shifts are being entered. In exchange, a successful write is immediately durable in the cloud, with no pending-write queue and no possibility of two devices diverging.

## Consequences

**Writes are not local.** Turso's docs are explicit: writes are sent to the remote primary and are *not* written to the local file first. Offline, a write simply fails. The UI surfaces the error and the user retries later — nothing is queued, nothing is half-written, nothing is lost.

**Do not call `sync()` after a write.** `readYourWrites: true` guarantees the writing replica sees its own write immediately without syncing, and the data is already on the primary. A post-write `sync()` would push nothing and pull nothing needed. Sync therefore has exactly **two** trigger points, both about pulling in the *other* device's changes:

1. `AppLifecycleState.resumed` — not cold start. Android rarely kills the app, so a cold-start-only trigger would almost never fire. Resume also recomputes "today" and the Data Window, which would otherwise go stale overnight or across a month boundary.
2. Pull-to-refresh on the Calendar screen

**No background sync.** `syncIntervalSeconds` is `int?`; omitting it leaves it null and no periodic timer is started.

**Reconsider if** true offline entry ever becomes a real scenario, or once Turso ships a stable official Dart sync client (see ADR-0001) — `.offline` and Turso Sync are the migration targets, and both bring conflict handling back into scope.
