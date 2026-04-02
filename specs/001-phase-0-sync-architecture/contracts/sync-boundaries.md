# Contract: Sync Boundaries

## Purpose

Define the internal interfaces that future implementation phases must preserve
between presentation, domain/core orchestration, local persistence, and cloud
services.

## Auth Session Contract

### Input

- Authentication state changes from Firebase Authentication

### Output

- `signedOut`
- `signedIn(userId)`

### Rules

- `signedOut` means cloud sync is disabled and UI state must show `Not signed in`.
- Local medication tracking remains available while signed out.
- A transition to `signedIn(userId)` allows sync orchestration to bind pending local
  data to that account scope.

## Local Repository Contract

### Responsibilities

- Read and write `MedicationRecord`, `ScheduleConfiguration`, `ReminderSettings`,
  `PendingChange`, and sync metadata in Hive.
- Update `updatedAt` on every mutation.
- Persist queued changes durably before cloud replay begins.

### Interface Shape

```text
watchMedications() -> Stream<List<MedicationRecord>>
saveMedication(record) -> Future<void>
saveSchedule(schedule) -> Future<void>
saveReminderSettings(settings) -> Future<void>
enqueueChange(change) -> Future<void>
listPendingChanges(userId?) -> Future<List<PendingChange>>
markChangeSucceeded(changeId) -> Future<void>
markChangeFailed(changeId, errorCode) -> Future<void>
setSyncStatus(state) -> Future<void>
```

## Cloud Repository Contract

### Responsibilities

- Read and write account-scoped cloud copies in Firestore.
- Never expose shared cross-user access.
- Preserve `updatedAt` metadata required for last-write-wins conflict handling.

### Interface Shape

```text
pullChanges(userId, sinceTimestamp?) -> Future<CloudDelta>
pushChanges(userId, changes) -> Future<PushResult>
upsertMedication(userId, record) -> Future<void>
upsertSchedule(userId, schedule) -> Future<void>
upsertReminderSettings(userId, settings) -> Future<void>
deleteEntity(userId, entityType, entityId, deletedAt) -> Future<void>
```

### Failure Expectations

- Authentication failures must stop cloud writes and surface `Sync failed`.
- Transient network failures must preserve pending changes locally for retry.
- Partial success must return enough detail to retry failed items without dropping
  successful ones.

## Sync Coordinator Contract

### Triggers

- App startup after auth is available
- Connectivity restored
- User sign-in
- Optional manual retry from a future error state

### Responsibilities

- Debounce duplicate triggers.
- Load pending local changes.
- Push local changes before pulling remote updates when both are pending.
- Apply last-write-wins using `updatedAt`.
- Update `SyncStatusViewState`.
- Request notification regeneration after schedule or reminder-setting changes.

### Interface Shape

```text
syncNow(trigger) -> Future<SyncReport>
handleConnectivityRestored() -> Future<void>
handleAuthChanged(sessionState) -> Future<void>
resolveConflict(localRecord, remoteRecord) -> ConflictResolution
```

## Notification Regeneration Contract

### Input

- Changed `ScheduleConfiguration` and `ReminderSettings`

### Output

- Local notification schedules recreated on the current device

### Rules

- Platform notification ids remain local-only.
- Regeneration must be idempotent for repeated sync passes.
- Failure to reschedule notifications must be observable in diagnostics and must
  not corrupt medication data.

## Observability Contract

### Required Signals

- Sync trigger source
- Start and finish timestamps
- Count of pushed and pulled records
- Retry count
- Failure class
- Conflict count and winning source summary

### Restrictions

- Logs must not contain medication names, dosage instructions, or other sensitive
  user-entered health details.
