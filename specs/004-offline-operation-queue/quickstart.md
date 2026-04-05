# Offline Queue Quickstart

This document explains how to trigger offline queuing operations.

## Initializing the Offline Queue
The Offline Queue functionality relies on existing Sync initializations. The local queue box (`pending_changes`) is opened in `lib/core/di/injector.dart`.

## Triggering an Offline Operation
Any standard medication modification automatically enqueues a change. You can trigger this using the existing uses cases:

```dart
final addMedicationUseCase = sl<AddMedication>();

// If connectivity is down, this will durably store the medication in Hive
// and add a PendingChange operation to the queue.
await addMedicationUseCase(Medication(
  id: 'uuid', 
  name: 'Aspirin',
  userId: 'user_id',
  // ... other fields
));
```

## Replaying the Queue
Replay is automatically handled by the `SyncService` when connectivity is restored.

```dart
final syncService = sl<SyncRepository>();

// Manual trigger for testing
await syncService.synchronize();
```
