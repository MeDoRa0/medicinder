# Feature Specification: Sync Engine Implementation

**Feature Branch**: `003-sync-engine`  
**Created**: 2026-04-03  
**Status**: Draft  
**Input**: User description: "Create a specification for Phase 3 Sync Engine Implementation from plan.md, covering connectivity detection, upload and download synchronization, merge behavior, conflict resolution, and sync lifecycle management only."

## Clarifications

### Session 2026-04-03

- Q: How should sync resolve a delete-versus-update conflict? → A: Deletion wins if it has the newest last-changed timestamp.
- Q: When should the sync engine automatically start a sync cycle? → A: On connectivity return and app start.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Synchronize Changes After Reconnection (Priority: P1)

As a signed-in Medicinder user, I want my locally changed medication data to
sync automatically after connectivity returns so my cloud backup catches up
without requiring manual cleanup.

**Why this priority**: Automatic catch-up after reconnect is the core user value
of the sync engine and is required before broader multi-device reliability can
exist.

**Independent Test**: Can be fully tested by changing supported records while
disconnected, restoring connectivity, and confirming the same signed-in account
reaches a synchronized state without duplicate records.

**Acceptance Scenarios**:

1. **Given** a signed-in user has local record changes that are not yet backed up,
   **When** connectivity becomes available, **Then** the system starts a sync
   cycle and uploads the pending changes to that user's cloud-backed records.
2. **Given** a signed-in user opens the app with cloud-backed access available,
   **When** the app session starts, **Then** the system starts a sync cycle for
   that active account.
3. **Given** a signed-in user has no unsynced differences between local and cloud
   copies, **When** a sync cycle starts, **Then** the system completes the cycle
   without creating unnecessary record changes.

---

### User Story 2 - Receive Newer Cloud Updates Safely (Priority: P2)

As a signed-in Medicinder user, I want the app to bring down newer cloud changes
and merge them predictably so my local medication data stays aligned with the
latest accepted version of each record.

**Why this priority**: Downloading and merging cloud changes is essential to
keeping a user's records consistent across sessions and devices after upload
behavior exists.

**Independent Test**: Can be fully tested by preparing newer cloud-backed
changes for supported records, starting a sync cycle, and confirming the local
copy converges to the correct result without data duplication.

**Acceptance Scenarios**:

1. **Given** a signed-in user has newer supported records in the cloud than on
   the device, **When** a sync cycle runs, **Then** the system updates the local
   copy to match the winning record versions.
2. **Given** the same supported record changed both locally and in the cloud,
   **When** the sync cycle resolves the difference, **Then** the system applies
   the record version with the most recent last-changed timestamp as the winner.

---

### User Story 3 - Understand Sync Progress and Failures (Priority: P3)

As a signed-in Medicinder user, I want sync progress and failure states to be
managed consistently so I know whether my medication data is current or needs
attention.

**Why this priority**: Clear sync lifecycle behavior reduces user confusion and
supports safe recovery when cloud access is interrupted.

**Independent Test**: Can be fully tested by triggering successful and failed
sync cycles and confirming the system exposes distinct in-progress, success, and
failure outcomes for the active account.

**Acceptance Scenarios**:

1. **Given** a signed-in user starts a sync cycle, **When** the cycle is still
   running, **Then** the system reflects that synchronization is in progress and
   prevents overlapping cycles for the same account.
2. **Given** a sync cycle cannot complete because cloud access fails mid-cycle,
   **When** the cycle ends, **Then** the system records a failure outcome without
   falsely reporting that all records are up to date.

### Edge Cases

- Connectivity becomes available briefly and drops again before a sync cycle
  completes.
- Local and cloud copies both changed since the last successful sync and one side
  deleted a record while the other side updated it; the newest last-changed
  timestamp wins, including deletion.
- A sync cycle starts while another sync cycle for the same signed-in user is
  already in progress.
- The user signs out while a sync cycle is running.
- Some records synchronize successfully while others fail during the same cycle.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST support a synchronization cycle for a signed-in
  user that compares supported local records with that user's cloud-backed
  records.
- **FR-002**: The system MUST detect when connectivity becomes available after an
  offline period and MUST be able to start a sync cycle in response.
- **FR-002a**: The system MUST be able to start a sync cycle automatically when a
  signed-in user's app session starts and cloud-backed access is available.
- **FR-003**: The system MUST upload supported local record changes that are not
  yet reflected in the cloud for the signed-in user.
- **FR-004**: The system MUST download supported cloud record changes that are
  newer or otherwise different from the local copy for the signed-in user.
- **FR-005**: The system MUST merge local and cloud differences so that the local
  and cloud copies converge on one accepted version of each supported record by
  the end of a successful sync cycle.
- **FR-006**: When the same supported record changed both locally and in the
  cloud, the system MUST resolve the conflict using a last-write-wins rule based
  on the record's last-changed timestamp.
- **FR-006a**: When one side deletes a supported record and the other side
  updates it, the system MUST treat the deletion as the winning outcome only if
  the deletion has the most recent last-changed timestamp.
- **FR-007**: The system MUST avoid creating duplicate supported records while
  synchronizing local and cloud changes.
- **FR-008**: The system MUST keep synchronization scoped to the currently
  authenticated user's records and MUST stop applying cloud-backed changes for a
  user who is no longer the active signed-in account.
- **FR-009**: The system MUST maintain a sync lifecycle state that distinguishes
  at minimum between idle, in-progress, succeeded, and failed outcomes for the
  active signed-in account.
- **FR-010**: The system MUST prevent overlapping sync cycles for the same active
  signed-in account.
- **FR-011**: If a sync cycle cannot complete, the system MUST preserve enough
  failure information for the app to indicate that synchronization did not finish
  successfully.
- **FR-012**: The system MUST allow a later sync cycle to retry records that were
  not synchronized successfully in a previous failed cycle.
- **FR-013**: The system MUST treat connectivity loss during synchronization as a
  recoverable interruption and MUST not mark interrupted records as fully
  synchronized.
- **FR-014**: The system MUST support partial-cycle outcomes where successfully
  synchronized records remain synchronized even if other records in the same cycle
  fail, provided the failure state is exposed accurately.
- **FR-015**: The system MUST limit this feature to sync-engine behavior only;
  durable offline operation queuing, notification rescheduling, and remote
  reminder delivery are out of scope for this phase.

### Key Entities *(include if feature involves data)*

- **Sync Cycle**: A single attempt to compare, exchange, and reconcile supported
  records between the local app data and the active user's cloud-backed records.
- **Sync Candidate Record**: A supported medication-related record that may need
  upload, download, merge, or no action during a sync cycle.
- **Conflict Record State**: A record state where the local and cloud copies of
  the same supported record both changed and require winner selection.
- **Sync Lifecycle State**: The user-scoped outcome that indicates whether
  synchronization is idle, running, successful, or failed.
- **Sync Failure Detail**: The information needed to explain that a sync cycle or
  part of a cycle did not finish successfully and may need retry.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In validation testing, 100% of supported local changes made while
  disconnected are uploaded to the correct signed-in user's cloud-backed records
  during the next successful sync cycle.
- **SC-002**: In validation testing, 100% of newer supported cloud record changes
  are reflected locally after the next successful sync cycle for the same signed-
  in user.
- **SC-003**: In validation testing, 100% of conflicting supported record updates
  resolve to the version with the most recent last-changed timestamp and do not
  create duplicate records.
- **SC-004**: At least 95% of successful sync cycles for a typical signed-in user
  complete within 30 seconds for the supported record volume used in acceptance
  testing.
- **SC-005**: In validation testing, 100% of interrupted or failed sync cycles
  expose a failure outcome rather than reporting that all supported records are up
  to date.

## Assumptions

- Phase 1 and Phase 2 outputs already define the supported cloud-backed record
  scope, authenticated user isolation, and the last-changed timestamp needed for
  conflict resolution.
- This phase covers the engine that performs bidirectional reconciliation, not the
  durable offline operation queue that will be specified separately in Phase 4.
- Signed-out users continue using local-only medication tracking, but Phase 3
  synchronization behavior applies only after a user is authenticated for cloud-
  backed access.
- Supported medication-related records already have stable identities so local and
  cloud copies can be matched during synchronization.
- Notification scheduling remains a separate concern; this phase only ensures the
  underlying synchronized data becomes consistent.
