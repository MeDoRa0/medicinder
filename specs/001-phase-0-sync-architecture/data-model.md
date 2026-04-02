# Data Model: Phase 0 Cloud Sync Architecture

## Overview

This model defines the records and state needed to add account-scoped cloud sync to
an offline-first Medicinder app while keeping Hive authoritative locally and using
Firestore as the synchronized cloud mirror.

## Entities

### UserSyncProfile

- Purpose: Binds cloud sync state to a signed-in user account.
- Primary key: `userId`
- Fields:
  - `userId`: stable authenticated identifier
  - `syncEnabled`: boolean
  - `lastSuccessfulSyncAt`: UTC timestamp, nullable
  - `lastAttemptedSyncAt`: UTC timestamp, nullable
  - `lastSyncErrorCode`: string, nullable
  - `statusViewState`: enum `notSignedIn | syncing | upToDate | syncFailed`
  - `createdAt`: UTC timestamp
  - `updatedAt`: UTC timestamp
- Validation:
  - `userId` is required for any cloud operation.
  - `syncEnabled` can only be true when authentication is active.
  - `statusViewState = notSignedIn` implies no active cloud session.

### MedicationRecord

- Purpose: Represents the medication data that must exist consistently across
  local and cloud copies.
- Primary key: `medicationId`
- Fields:
  - `medicationId`: UUID or equivalent stable identifier
  - `userId`: nullable locally before sign-in; required in cloud scope
  - `name`: non-empty string
  - `dosage`: string
  - `instructions`: string, nullable
  - `startDate`: date, nullable
  - `endDate`: date, nullable
  - `isArchived`: boolean
  - `syncState`: enum `localOnly | pendingUpload | synced | syncFailed`
  - `createdAt`: UTC timestamp
  - `updatedAt`: UTC timestamp
  - `deletedAt`: UTC timestamp, nullable tombstone marker
- Validation:
  - `updatedAt` must be refreshed on every local mutation.
  - Deleted records retain identifier and timestamps until replay is complete.

### ScheduleConfiguration

- Purpose: Defines the schedule data required to rebuild local reminders.
- Primary key: `scheduleId`
- Fields:
  - `scheduleId`: stable identifier
  - `medicationId`: foreign key to `MedicationRecord`
  - `timezoneId`: IANA timezone string
  - `timesPerDay`: integer or derived recurrence count
  - `scheduledTimes`: list of local-time values
  - `startDate`: date
  - `endDate`: date, nullable
  - `recurrenceRule`: serialized recurrence descriptor
  - `reminderEnabled`: boolean
  - `syncState`: enum `localOnly | pendingUpload | synced | syncFailed`
  - `createdAt`: UTC timestamp
  - `updatedAt`: UTC timestamp
- Validation:
  - At least one scheduled time is required when `reminderEnabled` is true.
  - `timezoneId` is required to rebuild local notifications correctly.

### ReminderSettings

- Purpose: Stores synchronized reminder preferences that affect how local
  notifications are regenerated on each device.
- Primary key: `settingsId`
- Fields:
  - `settingsId`: stable identifier
  - `scheduleId`: foreign key to `ScheduleConfiguration`
  - `userId`: authenticated owner id
  - `leadTimeMinutes`: integer, nullable
  - `soundEnabled`: boolean
  - `vibrationEnabled`: boolean
  - `snoozeEnabled`: boolean
  - `updatedAt`: UTC timestamp
  - `syncState`: enum `localOnly | pendingUpload | synced | syncFailed`
- Validation:
  - Settings must map to an existing `ScheduleConfiguration`.
  - Device-specific notification delivery tokens or platform alarm ids are never
    stored here.

### PendingChange

- Purpose: Records offline operations that must be replayed to the cloud.
- Primary key: `changeId`
- Fields:
  - `changeId`: stable identifier
  - `entityType`: enum `medication | schedule | reminderSettings | profile`
  - `entityId`: referenced entity identifier
  - `operation`: enum `create | update | delete`
  - `payload`: serialized changed fields or tombstone payload
  - `queuedAt`: UTC timestamp
  - `sourceUpdatedAt`: UTC timestamp
  - `attemptCount`: integer
  - `lastAttemptAt`: UTC timestamp, nullable
  - `status`: enum `pending | inFlight | failed`
  - `userId`: nullable until authenticated mapping is available
- Validation:
  - Queue items are durable across app restarts.
  - `sourceUpdatedAt` is required for deterministic replay and conflict handling.

### ConflictMetadata

- Purpose: Stores the inputs and outcome of a detected record conflict.
- Primary key: composite `entityType + entityId + resolvedAt`
- Fields:
  - `entityType`: enum
  - `entityId`: string
  - `localUpdatedAt`: UTC timestamp
  - `remoteUpdatedAt`: UTC timestamp
  - `winningSource`: enum `local | remote`
  - `resolutionStrategy`: constant `lastWriteWins`
  - `resolvedAt`: UTC timestamp
- Validation:
  - `winningSource` must match whichever timestamp is latest.
  - Records are diagnostic metadata, not a new source of truth.

### SyncStatusViewState

- Purpose: Defines the minimum user-visible sync states for Phase 0.
- Allowed values:
  - `notSignedIn`
  - `syncing`
  - `upToDate`
  - `syncFailed`
- Validation:
  - Copy for these states must be localizable in English and Arabic.
  - State changes must be observable without exposing sensitive record content.

## Relationships

- `UserSyncProfile 1 -> many MedicationRecord`
- `MedicationRecord 1 -> many ScheduleConfiguration`
- `ScheduleConfiguration 1 -> 1 ReminderSettings`
- `UserSyncProfile 1 -> many PendingChange`
- `MedicationRecord/ScheduleConfiguration/ReminderSettings 1 -> many ConflictMetadata`

## State Transitions

### Entity Sync State

- `localOnly -> pendingUpload`: local entity becomes eligible for sync after sign-in
  or after a new offline mutation.
- `pendingUpload -> synced`: replay succeeds and local/cloud copies converge.
- `pendingUpload -> syncFailed`: replay attempt fails.
- `syncFailed -> pendingUpload`: retry is scheduled automatically after reconnect or
  manual recovery trigger.
- `synced -> pendingUpload`: a later local mutation occurs.

### User-Visible Sync Status

- `notSignedIn -> syncing`: user signs in and initial sync begins.
- `syncing -> upToDate`: all pending replay and pull operations complete.
- `syncing -> syncFailed`: sync attempt fails.
- `syncFailed -> syncing`: retry begins.
- `upToDate -> syncing`: a new foreground or reconnect-triggered sync starts.

## Notes for Implementation

- Local notifications are rebuilt from `ScheduleConfiguration` and
  `ReminderSettings`; no cloud entity represents platform alarm instances.
- Firestore documents should be partitioned per `userId` to maintain account
  isolation.
- Tombstones are preferred over hard deletes during replay so delete operations can
  synchronize safely across devices.
