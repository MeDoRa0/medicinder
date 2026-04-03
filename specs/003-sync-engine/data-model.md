# Data Model: Sync Engine Implementation

## Overview

Phase 3 introduces a concrete synchronization engine over the existing local
medication and cloud workspace data. The model below focuses on records and
state the engine must read, compare, update, and report.

## Entities

### 1. Sync Cycle

- **Purpose**: Represents one synchronization attempt for the active signed-in
  user.
- **Key fields**:
  - `cycleId`: Unique identifier for the attempt
  - `userId`: Active signed-in user
  - `trigger`: Startup, connectivity restoration, sign-in, or manual retry
  - `startedAt`: Cycle start timestamp
  - `completedAt`: Cycle completion timestamp when available
  - `status`: `idle`, `running`, `succeeded`, or `failed`
  - `pushedCount`: Number of local changes accepted by cloud storage
  - `pulledCount`: Number of cloud records applied locally
  - `failedCount`: Number of records or operations not completed successfully
  - `failureClass`: Coarse failure category when the cycle fails or is partial
- **Validation rules**:
  - Only one running cycle may exist per active user
  - `completedAt` must be absent while status is `running`
  - `userId` is required for all non-idle cycles

### 2. Sync Lifecycle Snapshot

- **Purpose**: The persisted, user-scoped view of the latest cycle outcome used
  by application state and UI mapping.
- **Key fields**:
  - `userId`
  - `engineStatus`: `idle`, `running`, `succeeded`, `failed`
  - `lastTrigger`
  - `lastStartedAt`
  - `lastCompletedAt`
  - `lastSuccessAt`
  - `lastFailureAt`
  - `message`: User-safe summary for failure or recovery state
  - `lastPushedCount`
  - `lastPulledCount`
  - `lastFailedCount`
- **Relationships**:
  - One snapshot belongs to one active user profile
  - The latest `Sync Cycle` writes into the snapshot

### 3. Sync Candidate Record

- **Purpose**: A medication record considered during reconciliation.
- **Key fields**:
  - `entityType`: Medication for Phase 3
  - `entityId`
  - `userId`
  - `localUpdatedAt`
  - `remoteUpdatedAt`
  - `localDeletedAt`
  - `remoteDeletedAt`
  - `winningSide`: local, remote, or unchanged
  - `resolutionReason`: newer local update, newer remote update, newer delete, or no change
- **Validation rules**:
  - `entityId` must be stable across local and cloud copies
  - At least one side must exist for the record to be evaluated

### 4. Pending Change

- **Purpose**: A queued local mutation the engine can attempt to upload.
- **Key fields**:
  - `changeId`
  - `entityType`
  - `entityId`
  - `operation`: create, update, or delete
  - `payload`: optional serialized content for create/update
  - `queuedAt`
  - `sourceUpdatedAt`
  - `attemptCount`
  - `lastAttemptAt`
  - `status`: pending, in-flight, or failed
  - `userId`
  - `errorMessage`
- **Relationships**:
  - Many pending changes may feed one sync cycle
- **Validation rules**:
  - `userId` must match the active cycle before upload
  - Delete changes may omit payload

### 5. Conflict Metadata

- **Purpose**: A durable record that a conflict was detected and how it was
  resolved.
- **Key fields**:
  - `entityType`
  - `entityId`
  - `userId`
  - `localUpdatedAt`
  - `remoteUpdatedAt`
  - `resolvedAt`
  - `winningSide`
  - `strategy`: last-write-wins
- **Validation rules**:
  - `resolvedAt` must be present
  - `winningSide` must reflect the applied record state

### 6. User Sync Profile

- **Purpose**: Existing user-scoped local state for cloud sync readiness and
  user-facing status.
- **Key fields**:
  - `userId`
  - `syncEnabled`
  - `statusViewState`
  - `updatedAt`
  - optional user-safe status message fields
- **Relationships**:
  - One profile can reference one current lifecycle snapshot for presentation

## State Transitions

### Sync Cycle

```text
idle -> running -> succeeded
idle -> running -> failed
failed -> running -> succeeded
failed -> running -> failed
succeeded -> running -> succeeded
succeeded -> running -> failed
```

Rules:

- Startup, reconnect, sign-in, or manual retry may move a user from `idle`,
  `succeeded`, or `failed` into `running`.
- A new cycle cannot start while another cycle for the same user is `running`.
- Interrupted cycles transition to `failed`, not `succeeded`.

### Pending Change

```text
pending -> in-flight -> removed on success
pending -> in-flight -> failed
failed -> in-flight -> removed on success
failed -> in-flight -> failed
```

Rules:

- Successful upload removes the change from local pending storage.
- Failed or interrupted uploads keep the change retryable for a later cycle.

## Relationships Summary

- One `User Sync Profile` maps to one current `Sync Lifecycle Snapshot`.
- One `Sync Cycle` reads many `Pending Change` entries and many local/cloud
  medication records.
- One `Sync Candidate Record` may produce zero or one `Conflict Metadata`
  records, depending on whether both sides changed.

## Out of Scope for Phase 3

- Queue redesign and durable replay policy changes beyond the engine boundary
- Notification rescheduling after synchronized data changes
- Additional synchronized entity types beyond medication records
