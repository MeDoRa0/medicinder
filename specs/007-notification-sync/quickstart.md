# Quickstart: Notification Synchronization

**Feature**: 007-notification-sync  
**Date**: 2026-04-06

## Prerequisites

- Flutter stable SDK with Dart ^3.8.1
- Phase 3 (Sync Engine — `003-sync-engine`) fully implemented and operational
- Phase 4 (Offline Operation Queue — `004-offline-operation-queue`) fully implemented and operational
- `awesome_notifications` ^0.11.0 configured with channel key
- Firebase configured (for cloud sync; not required for local notification scheduling)
- Android: alarm/notification permissions granted
- iOS: notification permissions granted via `AwesomeNotifications`

## Setup

No new dependencies required. All necessary packages are already in `pubspec.yaml`:

```yaml
# Already present:
awesome_notifications: ^0.11.0
flutter_bloc: ^9.1.1
get_it: ^9.2.0
hive: ^2.2.3
hive_flutter: ^1.1.0
```

No Hive schema migration is needed — no new boxes or adapters are required. The `NotificationRegenerationSummary` entity is a pure value object (not persisted).

## Initialization Order

The notification sync service must be registered in `injector.dart` **after** the following dependencies are available:

1. `MedicationRepository` (already registered)
2. `NotificationOptimizer` (singleton, already available via `NotificationOptimizer()`)
3. `SyncDiagnostics` (already registered)

```dart
// In initDependencies(), after existing service registrations:
sl.registerLazySingleton<NotificationSyncService>(
  () => NotificationSyncService(
    medicationRepository: sl(),
    notificationOptimizer: NotificationOptimizer(),
    syncDiagnostics: sl(),
  ),
);
```

## Platform-Specific Constraints

### Android
- `AwesomeNotifications().cancel(id)` only cancels scheduled (not-yet-fired) alarms. Already-displayed notifications are unaffected.
- The app schedules only the next upcoming dose per medication to stay within Android's alarm scheduling limits.
- Exact alarms require `SCHEDULE_EXACT_ALARM` permission (already configured).

### iOS
- Same `cancel()` semantics apply via the AwesomeNotifications cross-platform API.
- Notification permission must be granted; if denied, regeneration logs a warning and skips scheduling.

## Key Behaviors

| Scenario | Expected Behavior |
|----------|-------------------|
| New device sign-in + sync | All upcoming medication alarms regenerated from synced records |
| Schedule change on Device A, sync on Device B | Device B cancels stale alarm, schedules new one |
| Medication deleted on Device A, sync on Device B | Device B cancels all alarms for that medication |
| Offline schedule edit | Local alarms updated immediately; cloud updated on reconnect |
| Notification permission denied | Warning logged; stale alarms still cancelled; no new alarms scheduled |
| Partial sync failure | Successfully synced medications get notification updates; failed ones are skipped |
| User signs out | All scheduled medication notifications cancelled; optimizer cache cleared |

## Verification Commands

```bash
# Run all tests
flutter test

# Run specific notification sync tests (once implemented)
flutter test test/core/services/sync/notification_sync_service_test.dart

# Run sync-related tests
flutter test test/presentation/cubit/sync/

# Check for analyzer warnings
flutter analyze
```
