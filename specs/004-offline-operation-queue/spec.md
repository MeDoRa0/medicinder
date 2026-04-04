# Feature Specification: Offline Operation Queue

**Feature Branch**: `004-offline-operation-queue`  
**Created**: 2026-04-04  
**Status**: Draft  
**Input**: User description: "Phase 4 - Offline Operation Queue: Ensure all operations performed while offline are safely stored and synchronized later. Record offline changes, queue pending synchronization tasks, and replay queued operations when connectivity returns."

## Clarifications

### Session 2026-04-04

- Q: When multiple updates to the same record are queued offline, should the system coalesce them into a single update or replay each individually? → A: Coalesce consecutive updates to the same record into a single operation before replay.
- Q: How should the system notify the user about permanently failed operations? → A: Show a non-intrusive badge/icon on the sync status screen; user taps to see failure details.
- Q: What retry backoff strategy should the system use for failed queue operations? → A: Exponential backoff (e.g., 1s, 2s, 4s, 8s, 16s) capped at a maximum delay.
- Q: Should the queue store a full snapshot of the record or only changed fields (delta) for updates? → A: Full snapshot of the complete record state at the time of each operation.
- Q: What batch size should the system use when processing large queues during replay? → A: 20 operations per batch.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Capture Changes Made While Offline (Priority: P1)

As a signed-in Medicinder user, I want every medication change I make while
offline to be durably recorded so that nothing I do is silently lost before
connectivity returns.

**Why this priority**: Durable capture of offline changes is the foundational
requirement. Without it, the queue has nothing to process and users risk silent
data loss during offline periods.

**Independent Test**: Can be fully tested by signing in, disabling connectivity,
performing create, update, and delete operations on medication records, and
confirming that each operation is durably recorded in a pending queue that
survives app restarts.

**Acceptance Scenarios**:

1. **Given** a signed-in user is offline, **When** the user creates a new
   medication record, **Then** the system durably stores a pending create
   operation in the offline queue that persists across app restarts.
2. **Given** a signed-in user is offline, **When** the user updates an existing
   medication record, **Then** the system durably stores a pending update
   operation in the offline queue containing the changed data.
3. **Given** a signed-in user is offline, **When** the user deletes a medication
   record, **Then** the system durably stores a pending delete operation in the
   offline queue referencing the deleted record.
4. **Given** a signed-in user makes multiple changes while offline, **When** the
   user closes and reopens the app, **Then** all previously queued operations are
   still present and intact.

---

### User Story 2 - Replay Queued Operations on Reconnection (Priority: P2)

As a signed-in Medicinder user, I want my queued offline operations to be
automatically replayed and synchronized when connectivity returns so that my
cloud backup catches up without any manual action.

**Why this priority**: Automatic replay completes the offline-to-online cycle.
Without it, queued operations accumulate indefinitely and the cloud copy
diverges from the local copy.

**Independent Test**: Can be fully tested by queuing several offline operations,
restoring connectivity, and confirming all queued operations are processed and
reflected in the cloud-backed records for the signed-in user.

**Acceptance Scenarios**:

1. **Given** a signed-in user has pending queued operations, **When**
   connectivity becomes available, **Then** the system replays queued operations
   in the order they were originally performed.
2. **Given** all queued operations replay successfully, **When** the replay
   completes, **Then** the system removes the successfully processed operations
   from the queue.
3. **Given** a signed-in user has queued operations spanning multiple record
   types (medications, schedules), **When** the replay runs, **Then** each
   operation is applied to the correct cloud-backed collection for the active
   user.

---

### User Story 3 - Retry Failed Operations Automatically (Priority: P3)

As a signed-in Medicinder user, I want operations that fail during replay to be
retried automatically so that transient network or server issues do not cause
permanent data loss.

**Why this priority**: Retry resilience ensures the queue handles real-world
connectivity instability gracefully, preventing partial sync states from becoming
permanent.

**Independent Test**: Can be fully tested by simulating a cloud write failure
during replay, confirming the failed operation remains in the queue with an
incremented retry count, and verifying that a subsequent replay attempt
re-processes the failed operation successfully.

**Acceptance Scenarios**:

1. **Given** a queued operation fails during replay due to a transient error,
   **When** the replay cycle ends, **Then** the failed operation remains in the
   queue with its retry count incremented rather than being discarded.
2. **Given** a previously failed queued operation is still in the queue, **When**
   the next replay cycle runs, **Then** the system re-attempts the failed
   operation.
3. **Given** a queued operation has exceeded the maximum retry limit, **When**
   the next replay cycle runs, **Then** the system marks the operation as
   permanently failed and surfaces the failure via a non-intrusive badge on the
   sync status screen, allowing the user to tap for details, without blocking
   other queued operations.

---

### User Story 4 - Preserve Operation Order and Consistency (Priority: P2)

As a signed-in Medicinder user, I want my offline operations to be replayed in
the exact order I performed them so that the final cloud state accurately
reflects my intended sequence of changes.

**Why this priority**: Order preservation prevents logical inconsistencies such
as updating a record that was supposed to be deleted, or deleting a record
before a preceding update is applied.

**Independent Test**: Can be fully tested by performing a sequence of dependent
operations offline (e.g., create then update then delete the same record),
restoring connectivity, and confirming the operations are replayed in the
original chronological order.

**Acceptance Scenarios**:

1. **Given** a signed-in user performs a create followed by an update on the same
   record while offline, **When** the operations are replayed, **Then** the
   create is processed before the update.
2. **Given** a signed-in user performs an update followed by a delete on the same
   record while offline, **When** the operations are replayed, **Then** the
   update is processed before the delete.

### Edge Cases

- The user performs multiple updates to the same record while offline; the
  system coalesces consecutive updates to the same record into a single
  operation before replay so that only the final state is sent to the cloud.
- Connectivity drops again mid-replay; successfully replayed operations are
  removed from the queue, while unprocessed and in-progress operations remain
  queued for the next cycle.
- The user signs out while queued operations exist; operations remain associated
  with the original user account and are not replayed until that user signs back
  in.
- The app is force-closed during a replay cycle; the queue persists on disk and
  resumes processing on the next app launch.
- A queued create operation targets a record that was already created in the
  cloud by another device; the system treats this as a conflict handled by the
  existing last-write-wins strategy from Phase 3.
- The queue grows very large during an extended offline period; the system
  processes operations in manageable batches to avoid excessive memory or time
  consumption.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST durably store every create, update, and delete
  operation performed on supported records by a signed-in user while the device
  is offline as a pending queue entry.
- **FR-002**: Each pending queue entry MUST include at minimum: operation type
  (create, update, or delete), the target record identifier, a full snapshot of
  the record state at the time of the operation (for create and update; record
  reference only for delete), and a timestamp indicating when the operation was
  performed.
- **FR-003**: The offline operation queue MUST persist across app restarts,
  meaning queued entries survive process termination and device reboots.
- **FR-004**: The system MUST preserve the chronological order in which
  operations were originally performed and MUST replay them in that same order.
- **FR-005**: The system MUST automatically trigger queue replay when
  connectivity becomes available and a signed-in user is active.
- **FR-006**: The system MUST integrate queue replay with the sync engine from
  Phase 3 so that queued operations are processed as part of the sync cycle
  rather than as an independent parallel process.
- **FR-007**: The system MUST remove successfully replayed operations from the
  queue after confirmation that the cloud write succeeded.
- **FR-008**: The system MUST retain failed operations in the queue, increment
  a retry counter for each failed attempt, and schedule the next retry using
  exponential backoff (e.g., base 2 seconds: 2s, 4s, 8s, 16s, …) capped at a
  maximum delay of 5 minutes.
- **FR-009**: The system MUST define a maximum retry limit per operation,
  after which the operation is marked as permanently failed.
- **FR-010**: Permanently failed operations MUST NOT block the processing of
  subsequent queued operations.
- **FR-011**: Permanently failed operations MUST be surfaced to the user via a
  non-intrusive badge or indicator on the sync status screen. The user MUST be
  able to tap the indicator to view failure details (operation type, target
  record, error reason).
- **FR-012**: The system MUST scope all queued operations to the authenticated
  user who performed them; queued operations for one user MUST NOT be replayed
  under a different user account.
- **FR-013**: The system MUST handle partial replay gracefully: if connectivity
  drops during replay, successfully processed operations are removed from the
  queue while remaining operations stay queued.
- **FR-014**: The system MUST process large queues in batches of 20 operations
  per batch to avoid excessive memory consumption or long blocking operations.
- **FR-015**: When a queued operation encounters a conflict with existing cloud
  data (e.g., creating a record that already exists), the system MUST delegate
  to the conflict resolution strategy established in Phase 3 (last-write-wins
  based on timestamps).
- **FR-016**: Before starting a replay cycle, the system MUST coalesce
  consecutive pending updates targeting the same record into a single update
  operation containing the final state, reducing redundant cloud writes.

### Key Entities

- **Pending Operation**: A single queued record representing one create, update,
  or delete action performed while offline. Contains the operation type, target
  record identifier, full record snapshot (for create/update) or record
  reference (for delete), originating user identifier, creation timestamp,
  retry count, next retry timestamp (computed via exponential backoff), and
  status.
- **Operation Queue**: The ordered, persistent collection of pending operations
  for a given user, stored locally and processed during sync cycles.
- **Replay Cycle**: A single pass through the operation queue that attempts to
  apply pending operations to cloud-backed records in chronological order.
- **Failed Operation**: A pending operation that has exceeded its maximum retry
  limit and is marked as permanently failed, requiring user attention or manual
  resolution.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In validation testing, 100% of create, update, and delete
  operations performed while offline are captured in the queue and survive app
  restart.
- **SC-002**: In validation testing, 100% of queued operations are replayed in
  their original chronological order during the next successful sync cycle.
- **SC-003**: In validation testing, 100% of successfully replayed operations
  are removed from the queue and reflected in the cloud-backed records for the
  correct user.
- **SC-004**: In validation testing, 100% of transiently failed operations
  remain in the queue with an incremented retry count and are re-attempted in
  the next replay cycle.
- **SC-005**: In validation testing, a queue of 100 or more pending operations
  completes replay within 60 seconds under typical connectivity conditions.
- **SC-006**: In validation testing, permanently failed operations do not
  prevent the successful replay of subsequent queued operations.

## Assumptions

- Phase 1 (Cloud Architecture), Phase 2 (Firebase Backend), and Phase 3 (Sync
  Engine) are implemented and operational before this phase begins.
- The sync engine from Phase 3 provides a well-defined integration point where
  the offline operation queue can feed pending changes into the sync cycle.
- Supported record types (medications, schedules) already have stable
  identifiers that are consistent between local and cloud copies.
- The last-write-wins conflict resolution strategy from Phase 3 applies when
  queued operations conflict with cloud state.
- The maximum retry limit will use a reasonable default (e.g., 5 attempts)
  without requiring user configuration.
- The default replay batch size is 20 operations per batch.
- Notification rescheduling after queue replay is out of scope for this phase
  and will be addressed in Phase 5.
- Signed-out users do not generate queued operations because cloud sync is only
  available for authenticated users.
