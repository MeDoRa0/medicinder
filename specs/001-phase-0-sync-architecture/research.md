# Research: Phase 0 Cloud Sync Architecture

## Decision 1: Use Firebase Authentication and Cloud Firestore for cloud sync

- Decision: Use Firebase Authentication for account identity and Cloud Firestore
  for per-user synchronized records.
- Rationale: The existing roadmap already selects Firebase, it fits Flutter well,
  and it gives account isolation plus structured cloud storage without introducing
  a custom backend in Phase 0.
- Alternatives considered: Supabase, custom REST backend, Firestore without
  authenticated user accounts.

## Decision 2: Keep Hive as the primary source of truth

- Decision: Hive remains the authoritative local database; Firestore stores a
  synchronized cloud mirror rather than becoming the runtime source of truth.
- Rationale: This satisfies the constitution's offline-first requirement, keeps
  reminders available without network access, and avoids coupling core flows to
  connectivity or remote latency.
- Alternatives considered: Firestore-first reads, hybrid online-first reads,
  replacing Hive entirely.

## Decision 3: Require sign-in for cloud sync, not for local-only use

- Decision: Users may continue using the app unsigned for local-only medication
  tracking, but cloud backup and sync start only after authentication.
- Rationale: This preserves the current product usability model while ensuring
  cloud data remains isolated per account.
- Alternatives considered: Mandatory sign-in before app use, anonymous sync,
  shared family/household accounts.

## Decision 4: Trigger sync automatically after reconnect

- Decision: Connectivity restoration should enqueue an automatic background sync
  without requiring manual user action.
- Rationale: This reduces recovery friction, matches offline-first expectations,
  and makes queued changes converge quickly after temporary outages.
- Alternatives considered: Manual sync only, sync on next launch only, confirm
  before syncing.

## Decision 5: Use last-write-wins with `updatedAt`

- Decision: If local and cloud copies of the same record both changed, resolve the
  conflict using last-write-wins based on trusted `updatedAt` metadata.
- Rationale: This is simple to explain, easy to test, and consistent with the
  product roadmap for early sync phases.
- Alternatives considered: Local-wins, cloud-wins, manual merge UX, field-level
  merge logic.

## Decision 6: Sync only schedule configuration and reminder settings

- Decision: Synchronize medication records, schedules, and reminder settings, but
  keep actual notification delivery state on-device.
- Rationale: Notification alarms are platform-local artifacts; syncing the source
  schedule data is enough to rebuild reminders safely on each device.
- Alternatives considered: Syncing delivery history, syncing raw notification
  platform identifiers, excluding reminder settings from sync.

## Decision 7: Use a persistent offline operation queue

- Decision: Represent offline creates, updates, and deletes as explicit queued
  change records stored locally until sync succeeds.
- Rationale: Queue-backed replay makes reconnect behavior auditable, testable, and
  resilient across app restarts.
- Alternatives considered: Best-effort immediate writes only, recomputing diffs
  solely from entity snapshots, transient in-memory queues.

## Decision 8: Adopt initial sync performance and observability budgets

- Decision: Use the following initial planning targets:
  - App startup must not block reminder availability while sync initializes.
  - Reconnect-triggered sync dispatch target: under 5 seconds.
  - Foreground sync status updates target: under 1 second.
  - Typical sync completion target: under 30 seconds for a low-hundreds record set.
  - Diagnostics must log trigger, direction, duration, record counts, retries,
    and failure class without recording medication names or instructions.
- Rationale: These targets are concrete enough for planning and testing while still
  realistic for a Flutter mobile app introducing cloud sync incrementally.
- Alternatives considered: No explicit operational budgets, more aggressive
  near-real-time guarantees, verbose payload logging for debugging.
