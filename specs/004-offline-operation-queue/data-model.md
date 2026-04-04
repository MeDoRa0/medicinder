# Data Model Adjustments for Offline Operations queue

This document outlines the data model interactions necessary to support the Offline Operation Queue, building on the existing Phase 3 Sync Engine models.

## Entities

### `PendingChange`
The core entity representing a queued offline operation. This entity already exists in `lib/domain/entities/sync/pending_change.dart`, but its utilization will be expanded.

**Fields**:
- `changeId` (String): Unique identifier.
- `entityType` (SyncEntityType): Target type (e.g., `medication`).
- `entityId` (String): Target record UUID.
- `operation` (SyncOperationType): `create`, `update`, `delete`.
- `payload` (Map<String, dynamic>?): Full snapshot of the record for `create` and `update` operations.
- `queuedAt` (DateTime): Original operation timestamp.
- `sourceUpdatedAt` (DateTime): Record updated at timestamp.
- `attemptCount` (int): Number of failed sync attempts.
- `lastAttemptAt` (DateTime?): Last retry timestamp.
- `status` (SyncOperationStatus): `pending`, `inFlight`, `failed`.
- `userId` (String?): Scoped user ID.
- `errorMessage` (String?): Reason for failure.

## Storage Models

### `PendingChangeModel`
The Hive representation of `PendingChange`. Located in `lib/data/models/sync/pending_change_model.dart` mapped to TypeId 4.

## Core Operations

1. **Enqueue Operation**
   `MedicationRepositoryImpl` instances of local modifications will construct a `PendingChange` with the serialized record as `payload` and call `SyncQueueLocalDataSource.enqueuePendingChange(change)`.

2. **Fetching Effective Changes (with Backoff)**
   `SyncQueueLocalDataSource.getEffectivePendingChanges` will:
   - Read all `pending` and `inFlight` changes for the current `userId`.
   - Filter out operations waiting for backoff: `now < (lastAttemptAt + (2^attemptCount) seconds)`.
   - Filter out operations with `attemptCount >= 5` (which should transition to `failed` state).
   - Coalesce consecutive updates for the same `entityId`.
   - Return the filtered, coalesced list to `SyncService`.

3. **Processing Batch**
   `SyncService` will process up to 20 operations per run. On success, `markPendingChangeSucceeded` removes it. On failure, `markPendingChangeFailed` increments `attemptCount` and sets `lastAttemptAt`. If `attemptCount` reached 5, the status becomes `failed` and it stays indefinitely for user resolution.
