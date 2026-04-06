# Data Model: Notification Synchronization

**Feature**: 007-notification-sync  
**Date**: 2026-04-06

## Entities

### 1. NotificationRegenerationSummary (NEW)

**Location**: `lib/domain/entities/sync/notification_regen_summary.dart`

A value object emitted after each post-sync notification regeneration cycle. Not persisted — used only for structured logging via `SyncDiagnostics`.

| Field | Type | Description |
|-------|------|-------------|
| `medicationsProcessed` | `int` | Count of medications for which regeneration was attempted |
| `notificationsScheduled` | `int` | Count of new notifications successfully scheduled |
| `notificationsCancelled` | `int` | Count of stale notifications cancelled |
| `failures` | `int` | Count of medications that failed regeneration |
| `permissionDenied` | `bool` | Whether notification permission was denied at time of regeneration |
| `durationMs` | `int` | Wall-clock time of the regeneration cycle in milliseconds |

**Validation rules**:
- All counts >= 0
- `durationMs` >= 0

**Relationships**: None — standalone value object for observability.

---

### 2. SyncResult (EXTENDED)

**Location**: `lib/domain/repositories/sync_repository.dart`

Existing class extended with one new field.

| Field | Type | Description | Status |
|-------|------|-------------|--------|
| `success` | `bool` | Whether the sync cycle succeeded | Existing |
| `pushedCount` | `int` | Number of changes pushed to cloud | Existing |
| `pulledCount` | `int` | Number of records pulled from cloud | Existing |
| `failedCount` | `int` | Number of failed operations | Existing |
| `failureClass` | `String?` | Failure category | Existing |
| `message` | `String?` | Human-readable message | Existing |
| `userId` | `String?` | User ID for the sync cycle | Existing |
| **`changedMedicationIds`** | **`List<String>`** | **IDs of medications created/updated/deleted during pull** | **NEW** |

**Validation rules**:
- `changedMedicationIds` defaults to empty list `const []`
- IDs are medication entity IDs (UUIDs)

---

### 3. Medication (UNCHANGED)

**Location**: `lib/domain/entities/medication.dart`

No schema changes. The schedule template is already part of the `Medication` entity via:
- `timingType` (`MedicationTimingType` enum: `specificTime`, `contextBased`)
- `doses` (`List<MedicationDose>` with `time`, `context`, `offsetMinutes`, `taken`, `takenDate`)
- `repeatForever` (`bool`)
- `startDate` (`DateTime`)
- `totalDays` (`int`)

These fields are already synced to cloud as part of the medication record. No migration needed.

---

### 4. MedicationDose (UNCHANGED)

**Location**: `lib/domain/entities/medication.dart`

No schema changes. The existing fields are sufficient:
- `time` (`DateTime?`) — used for specific-time scheduling
- `context` (`MealContext?`) — used for context-based scheduling
- `offsetMinutes` (`int?`) — minutes before/after meal
- `taken` (`bool`) — ephemeral, device-local
- `takenDate` (`DateTime?`) — ephemeral, device-local

`taken` and `takenDate` are ephemeral dose instance data. Per the spec, these are NOT synced — they are regenerated locally from the schedule template.

---

## Interfaces / Services

### 5. NotificationSyncService (NEW)

**Location**: `lib/core/services/sync/notification_sync_service.dart`

Not a data entity but a new service class that orchestrates notification regeneration.

**Depends on**:
- `NotificationOptimizer` — for cancelling/scheduling notifications
- `MedicationRepository` — for reading local medication records
- `SyncDiagnostics` — for emitting regeneration summary events

**Key method signatures**:

```dart
/// Regenerate notifications for the given medication IDs after a sync.
/// Returns a summary of what was done.
Future<NotificationRegenerationSummary> regenerateNotifications({
  required List<String> changedMedicationIds,
  BuildContext? context,
});

/// Cancel all medication notifications (used on sign-out).
Future<void> cancelAllMedicationNotifications();
```

**State transitions**: None — stateless service. All state is ephemeral (notification cache in `NotificationOptimizer`).

---

## Data Flow

```
Sync Cycle Completes
        │
        ▼
SyncService._pullRemoteChanges()
  → collects changedMedicationIds
  → returns them in SyncResult
        │
        ▼
SyncStatusCubit receives SyncResult
  → calls NotificationSyncService.regenerateNotifications(changedMedicationIds)
        │
        ▼
NotificationSyncService
  ├── checks notification permission
  ├── for each changedMedicationId:
  │     ├── loads Medication from MedicationRepository
  │     ├── if deleted → cancelMedicationNotifications(id)
  │     ├── if empty doses → skip, log warning
  │     └── else → scheduleNextDoseNotification(medication)
  └── emits NotificationRegenerationSummary via SyncDiagnostics
```

## Cloud Schema Impact

None. No Firestore schema changes required. The medication schedule template (dose times, meal contexts, offset minutes, timing type) is already part of the medication document in Firestore.
