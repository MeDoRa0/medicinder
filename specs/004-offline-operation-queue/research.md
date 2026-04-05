# Phase 0: Research & Technical Context
**Branch**: `004-offline-operation-queue`

## Needs Clarification Resolutions

Based on the codebase exploration and the Feature Specification, here are the technical decisions to fulfill the requirements:

### 1. Storing Full Snapshots in Operations
**Decision**: Transition from the existing `SyncOperation` entity to the newly introduced `PendingChange` entity for all new offline operations.
**Rationale**: `PendingChange` already has a `payload` field (`Map<String, dynamic>`) implemented in its Hive model (`PendingChangeModel`). The specification requires full snapshots of the record state at the time of the operation. The `SyncOperation` entity and model currently only store the `entityId` and `operationType`.
**Implementation Strategy**: Update `MedicationRepositoryImpl` to enqueue `PendingChange` objects instead of `SyncOperation` objects. The `payload` will be the JSON representation of the `Medication` (using the `.toMap()` or equivalent method if available, or manual serialization).

### 2. Coalescing Consecutive Updates
**Decision**: Implement coalescing logic inside `SyncQueueLocalDataSource` (e.g., in a new `coalescePendingChanges()` method) before returning the list of effective changes to the `SyncService` during a replay cycle.
**Rationale**: FR-016 requires coalescing consecutive pending updates for the same record to reduce redundant cloud writes. 
**Logic**: 
- Group operations by `entityId`.
- Traverse operations chronologically. If multiple `update` operations are found consecutively for the same entity, merge them by retaining the data of the last update but the earliest `queuedAt` timestamp (or as specified). If a `create` is followed by `update`s, it remains a `create` operation containing the final state. If a `delete` follows an `update`, it becomes just a `delete`.

### 3. Exponential Backoff for Retries
**Decision**: Implement exponential backoff in `SyncQueueLocalDataSource.getEffectivePendingChanges()`, filtering out `PendingChange` entries that are not yet ready for their next retry.
**Rationale**: FR-008 requires exponential backoff (e.g., base 2 seconds up to max 5 minutes). 
**Logic**: 
- `nextRetryAt = lastAttemptAt + (2 ^ min(attemptCount, maxExponent)) seconds`.
- Cap the delay at 5 minutes (300 seconds).
- Filter out operations where `nextRetryAt > DateTime.now()`.
- Wait, max limits: FR-009 states a max retry limit (assumed 5 attempts). Operations exceeding 5 attempts are marked as `failed` and skipped.

### 4. Replay Batching
**Decision**: Implement replay batching (size = 20) in `SyncService.synchronize()`.
**Rationale**: FR-014 requires processing large queues in batches of 20 operations to avoid excessive memory or blocking.
**Implementation**: Inside `SyncService.syncNow()`, loop through the changes returned from `getEffectivePendingChanges()` in chunks of 20. Ensure progress is saved incrementally so that partial failures (FR-013) handle remaining queued items properly.

### 5. Surfacing Permanently Failed Operations
**Decision**: Add logic to `SyncDiagnostics` or local data source to count permanently failed items, and emit this status in `SyncStatusCubit`.
**Rationale**: Failed operations shouldn't block subsequent ones (FR-010) but must be surfaced to the user via a badge (FR-011). `PendingChange` supports a `failed` status. The UI can read `PendingChange`s with `status == failed` to show the badge.

## Core Technologies
- **Language**: Dart ^3.8.1
- **Framework**: Flutter
- **Storage**: Hive (`sync_queue` box via `SyncQueueLocalDataSource`)
- **State Management**: `flutter_bloc` / `SyncStatusCubit`
