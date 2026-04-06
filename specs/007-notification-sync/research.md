# Research: Notification Synchronization

**Feature**: 007-notification-sync  
**Date**: 2026-04-06

## Research Tasks

### 1. How to detect which medications changed during a sync cycle

**Decision**: Extend `SyncResult` with a `List<String> changedMedicationIds` field and accumulate IDs during `_pullRemoteChanges`.

**Rationale**: The `_pullRemoteChanges` method in `SyncService` already iterates over every pulled remote medication and writes it locally via `saveSyncedMedication`. By collecting each `remoteMedication.id` that is actually written (new or conflict-resolved), we naturally produce the exact set of IDs that need notification regeneration. The push side (`_pushChange`) does not need tracking because push operations originate locally — local notifications were already updated at edit time (FR-006). Only pulled (remote-originated) changes require notification regeneration on this device.

**Alternatives considered**:
- **Stream-based change detection** (watch Hive box for writes): Rejected — over-engineered for the use case, hard to distinguish sync-writes from user-writes, and introduces a reactive dependency the current architecture does not use.
- **Full diff after sync** (compare pre/post medication snapshots): Rejected — O(n²) comparison for all medications when only the pull operation affects a handful. Wasteful and fragile.

---

### 2. How to cancel only future scheduled notifications (not already-fired ones)

**Decision**: Use the existing `NotificationOptimizer.cancelMedicationNotifications(medicationId)` which cancels only *scheduled* notifications via `AwesomeNotifications().cancel(id)`. Already-displayed (fired) notifications are unaffected by `cancel()` — the AwesomeNotifications API only removes pending scheduled alarms.

**Rationale**: The `AwesomeNotifications().cancel(id)` API cancels a scheduled notification that has not yet fired. If the notification has already been displayed, `cancel()` is a no-op on the scheduling side (the displayed notification remains). This is exactly the behavior required by FR-009. No additional filtering is needed.

**Alternatives considered**:
- **Custom timestamp filtering** (only cancel notifications whose scheduled time is in the future): Rejected — unnecessary since `AwesomeNotifications().cancel()` already only affects scheduled (not-yet-fired) entries by design.
- **`cancelScheduledNotifications()` with explicit time filter**: Rejected — the cache-based approach in `NotificationOptimizer` already provides medication-scoped cancellation.

---

### 3. How to regenerate notifications from the schedule template

**Decision**: Reuse `NotificationOptimizer.scheduleNextDoseNotification(medication)` for each changed medication. This method already:
1. Finds the next upcoming (future, not-taken) dose
2. Cancels existing scheduled notifications for the medication
3. Schedules one alarm for the next dose

**Rationale**: The existing `scheduleNextDoseNotification` encapsulates the full cancel-then-reschedule cycle. It uses `cancelMedicationNotifications` first (clearing stale alarms) then schedules the next future dose. This satisfies FR-001 (regenerate), FR-002 (cancel before reschedule), and FR-004 (skip past doses). No new scheduling logic is needed.

**Alternatives considered**:
- **Schedule all future doses at once**: Rejected — the current app design schedules only the next upcoming dose to avoid platform scheduling limits (Android caps pending alarms). After a dose fires, the action handler schedules the next one.
- **New dedicated regeneration method**: Rejected — would duplicate `scheduleNextDoseNotification` logic. Reuse is simpler and less error-prone.

---

### 4. How to handle notification permission checks

**Decision**: Before regeneration, call `AwesomeNotifications().isNotificationAllowed()`. If denied, log a warning and skip scheduling (but still cancel stale notifications). The permission prompt is already handled by `AwesomeNotificationService` at app startup. A diagnostic warning is emitted so the sync diagnostics surface shows the issue.

**Rationale**: FR-010 requires detecting denied permissions and surfacing a warning. The AwesomeNotifications API provides `isNotificationAllowed()` for this check. Rather than blocking the entire regeneration cycle, the system should still clean up stale alarms but skip new scheduling, and record the permission denial in the summary event.

**Alternatives considered**:
- **Request permission inline during regeneration**: Rejected — permissions should be requested at app startup (already done), not during background sync operations.
- **Silently ignore denied permissions**: Rejected — violates FR-010 which requires a user-visible warning.

---

### 5. How to integrate with sign-out flow

**Decision**: In `SyncStatusCubit.signOut()`, call `NotificationOptimizer().clearAllNotifications()` after `_signOutFromSync()`. This cancels all scheduled medication notifications and clears the optimizer's cache, satisfying FR-014.

**Rationale**: `clearAllNotifications()` already exists in `NotificationOptimizer` and calls `AwesomeNotifications().cancelAll()` plus clears the internal cache. This is the most direct path to satisfying the sign-out requirement. The method is synchronous-safe (awaitable) and handles errors internally.

**Alternatives considered**:
- **Iterate and cancel per-medication**: Rejected — unnecessarily slow. `cancelAll()` is atomic and platform-optimized.
- **Add sign-out hook in SyncService**: Rejected — sign-out side effects belong in the presentation cubit where the user action originates, following the existing pattern.

---

### 6. How to emit structured regeneration summary events

**Decision**: Create a `NotificationRegenerationSummary` entity (domain layer) and add a `logNotificationRegenEvent()` method to `SyncDiagnostics`. The summary includes: medications processed count, notifications scheduled count, notifications cancelled count, failures count, permission denied flag, and duration.

**Rationale**: FR-013 requires a structured summary event visible in the existing sync diagnostics infrastructure. `SyncDiagnostics` already follows the pattern of structured `log()` calls with named parameters. Adding a notification-specific method maintains consistency.

**Alternatives considered**:
- **Emit via a stream/event bus**: Rejected — the project does not use an event bus. Structured logging via `SyncDiagnostics` is the established pattern.
- **Store in Hive for history**: Rejected — the spec says "visible in sync diagnostics," not persisted history. Logging is sufficient.

---

### 7. Handling corrupt or missing schedule data from cloud

**Decision**: If a pulled medication has no dose schedule data (empty doses list), retain existing local notifications and log a warning via `SyncDiagnostics`. Do not clear alarms for that medication. This is checked inside the regeneration loop — if `medication.doses.isEmpty`, skip regeneration and increment a failure counter in the summary.

**Rationale**: Edge case from the spec requires defensive handling. Clearing alarms for a medication with no schedule data would cause missed reminders. The safest approach is to leave existing alarms in place and surface the anomaly.

**Alternatives considered**:
- **Throw an exception and fail the regeneration**: Rejected — partial failures should not block other medications (FR-012).
- **Silently skip**: Rejected — the anomaly should be observable for debugging.

---

### 8. Partial sync failure handling for notifications

**Decision**: Notification regeneration processes each changed medication independently. If regeneration fails for one medication (e.g., scheduling API error), it catches the exception, increments the failure counter, and continues to the next medication. This satisfies FR-012.

**Rationale**: The existing `NotificationOptimizer` methods already have try-catch blocks that log errors and continue. The regeneration service wraps individual medication processing in its own try-catch to ensure independence.

**Alternatives considered**:
- **All-or-nothing regeneration**: Rejected — violates FR-012 which requires independent processing.
- **Retry failed medications**: Rejected — adds complexity with minimal benefit. The next sync cycle will retry naturally.
