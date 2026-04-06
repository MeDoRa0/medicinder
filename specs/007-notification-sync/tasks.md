# Tasks: Notification Synchronization

**Input**: Design documents from `/specs/007-notification-sync/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

**Tests**: Required by Constitution Principle III (Testable by Default). Unit test tasks are included for `NotificationSyncService`.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Mobile (Flutter)**: `lib/` for source, `test/` for tests at repository root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: No new dependencies or Hive boxes needed. This phase creates the new entity, extends existing data structures, and verifies a prerequisite method. ALL user stories depend on these.

- [x] T001 [P] Create `NotificationRegenerationSummary` entity in `lib/domain/entities/sync/notification_regen_summary.dart`

> **T001 — Full context for implementation**:
>
> Create a new file `lib/domain/entities/sync/notification_regen_summary.dart`.
> This is a **pure value object** (not persisted to Hive, not persisted to Firestore). It is used only for structured logging.
>
> **Fields** (all required, no nullable fields):
> | Field | Type | Description |
> |---|---|---|
> | `medicationsProcessed` | `int` | Count of medications for which regeneration was attempted |
> | `notificationsScheduled` | `int` | Count of new notifications successfully scheduled |
> | `notificationsCancelled` | `int` | Count of stale notifications cancelled |
> | `failures` | `int` | Count of medications that failed regeneration |
> | `permissionDenied` | `bool` | Whether notification permission was denied at time of regeneration |
> | `durationMs` | `int` | Wall-clock time of the regeneration cycle in milliseconds |
>
> **Implementation pattern**: Use an immutable Dart class with a `const` constructor. Follow the same style as other entities in `lib/domain/entities/sync/` (e.g., `conflict_metadata.dart`). Add a `@override String toString()` for debug logging. All int fields must be >= 0.
>
> ```dart
> class NotificationRegenerationSummary {
>   final int medicationsProcessed;
>   final int notificationsScheduled;
>   final int notificationsCancelled;
>   final int failures;
>   final bool permissionDenied;
>   final int durationMs;
>
>   const NotificationRegenerationSummary({
>     required this.medicationsProcessed,
>     required this.notificationsScheduled,
>     required this.notificationsCancelled,
>     required this.failures,
>     required this.permissionDenied,
>     required this.durationMs,
>   });
>
>   @override
>   String toString() => 'NotificationRegenerationSummary('
>       'processed=$medicationsProcessed, '
>       'scheduled=$notificationsScheduled, '
>       'cancelled=$notificationsCancelled, '
>       'failures=$failures, '
>       'permissionDenied=$permissionDenied, '
>       'durationMs=$durationMs)';
> }
> ```

- [x] T002 [P] Add `changedMedicationIds` field to `SyncResult` in `lib/domain/repositories/sync_repository.dart`

- [x] T003 [P] Verify `getMedicationById` exists in `MedicationRepository` (CONFIRMED: no-op — method already exists) in `lib/domain/repositories/medication_repository.dart`

> **T003 — Full context for implementation**:
>
> **VERIFIED**: `getMedicationById(String id, {bool includeDeleted = false})` already exists at line 6-9 of `lib/domain/repositories/medication_repository.dart`. It is also implemented in `lib/data/repositories/medication_repository_impl.dart` (line 34) and `lib/data/datasources/medication_local_data_source.dart` (line 29).
>
> **Action**: Skip this task — no code changes needed. T004 can call `getMedicationById(id, includeDeleted: true)` directly.
>
> **Note**: The method accepts an `includeDeleted` parameter (default `false`). T004 MUST pass `includeDeleted: true` to detect soft-deleted medications (where `isDeleted == true` but the record still exists in Hive).

> **T002 — Full context for implementation**:
>
> Open `lib/domain/repositories/sync_repository.dart`. The `SyncResult` class currently has these fields: `success`, `pushedCount`, `pulledCount`, `failedCount`, `failureClass`, `message`, `userId`.
>
> **Add ONE new field**: `changedMedicationIds` of type `List<String>` with default value `const []`.
>
> **Changes required**:
> 1. Add field declaration: `final List<String> changedMedicationIds;`
> 2. Add to constructor with default: `this.changedMedicationIds = const [],`
>
> **DO NOT** change any existing fields or the `SyncRepository` abstract class.
>
> **Expected result** (the full updated class):
> ```dart
> class SyncResult {
>   final bool success;
>   final int pushedCount;
>   final int pulledCount;
>   final int failedCount;
>   final String? failureClass;
>   final String? message;
>   final String? userId;
>   final List<String> changedMedicationIds;
>
>   const SyncResult({
>     required this.success,
>     this.pushedCount = 0,
>     this.pulledCount = 0,
>     this.failedCount = 0,
>     this.failureClass,
>     this.message,
>     this.userId,
>     this.changedMedicationIds = const [],
>   });
>
>   // Backward compatibility with legacy fields
>   int get processedOperations => pushedCount;
>   int get failedOperations => failedCount;
>   int get pulledRecords => pulledCount;
> }
> ```

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core service and infrastructure changes that MUST be complete before any user story can be implemented. These modify shared services used by multiple stories.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T004 Add `logNotificationRegenEvent()` method to `SyncDiagnostics` in `lib/core/services/sync/sync_diagnostics.dart`

> **T004 — Full context for implementation**:
>
> Open `lib/core/services/sync/sync_diagnostics.dart`. The class currently has two log methods: `logStartupMode` and `logSyncEvent`.
>
> **Add ONE new import at the top**:
> ```dart
> import '../../../domain/entities/sync/notification_regen_summary.dart';
> ```
>
> **Add ONE new method** after the existing `logSyncEvent` method:
> ```dart
> void logNotificationRegenEvent(NotificationRegenerationSummary summary) {
>   log(
>     'SyncDiagnostics.notificationRegen '
>     'processed=${summary.medicationsProcessed} '
>     'scheduled=${summary.notificationsScheduled} '
>     'cancelled=${summary.notificationsCancelled} '
>     'failures=${summary.failures} '
>     'permissionDenied=${summary.permissionDenied} '
>     'durationMs=${summary.durationMs}',
>     name: 'sync',
>   );
> }
> ```
>
> **DO NOT** change any existing methods or the constructor.

- [x] T005 Create `NotificationSyncService` in `lib/core/services/sync/notification_sync_service.dart`

> **T005 — Full context for implementation**:
>
> Create a new file `lib/core/services/sync/notification_sync_service.dart`.
>
> This is the CORE service that orchestrates notification regeneration after sync. It is a stateless service with injected dependencies.
>
> **Dependencies** (constructor-injected):
> - `MedicationRepository` — from `lib/domain/repositories/medication_repository.dart`
> - `NotificationOptimizer` — from `lib/core/services/notification_optimizer.dart`
> - `SyncDiagnostics` — from `lib/core/services/sync/sync_diagnostics.dart`
>
> **Required imports**:
> ```dart
> import 'package:awesome_notifications/awesome_notifications.dart';
> import 'package:flutter/widgets.dart';
> import 'dart:developer';
> import '../../../domain/entities/sync/notification_regen_summary.dart';
> import '../../../domain/repositories/medication_repository.dart';
> import '../notification_optimizer.dart';
> import 'sync_diagnostics.dart';
> ```
>
> **Two public methods**:
>
> ### Method 1: `regenerateNotifications`
> ```dart
> Future<NotificationRegenerationSummary> regenerateNotifications({
>   required List<String> changedMedicationIds,
>   BuildContext? context,
> })
> ```
>
> **Algorithm** (step by step):
> 1. Record `startTime = DateTime.now()` for duration tracking
> 2. Initialize counters: `scheduled = 0`, `cancelled = 0`, `failures = 0`, `permissionDenied = false`
> 3. Check notification permission: `await AwesomeNotifications().isNotificationAllowed()`
>    - If denied: set `permissionDenied = true`, log warning via `log()`
> 4. For each `medicationId` in `changedMedicationIds`:
>    a. Wrap in try-catch (errors for one medication must NOT stop others — FR-012)
>    b. Load medication: `await _medicationRepository.getMedicationById(medicationId, includeDeleted: true)`
>       (**IMPORTANT**: pass `includeDeleted: true` so soft-deleted medications are found and their notifications can be explicitly cancelled)
>    c. If medication is `null` (purged from local storage):
>       - Call `await _notificationOptimizer.cancelMedicationNotifications(medicationId)`
>       - Add return value to `cancelled` counter
>       - `continue`
>    d. If `medication.isDeleted == true` (soft-deleted, still in Hive):
>       - Call `await _notificationOptimizer.cancelMedicationNotifications(medicationId)`
>       - Add return value to `cancelled` counter
>       - `continue`
>    e. If `medication.doses.isEmpty`:
>       - Log warning: "Skipping notification regeneration for medication $medicationId: no doses"
>       - Increment `failures`
>       - `continue` (do NOT cancel existing alarms — keep them as safety net per research.md §7)
>    f. Cancel existing alarms: `cancelled += await _notificationOptimizer.cancelMedicationNotifications(medicationId)`
>    g. If `permissionDenied == false`:
>       - Call `await _notificationOptimizer.scheduleNextDoseNotification(medication, context: context)`
>       - Increment `scheduled`
>    h. On catch: log error, increment `failures`
> 5. Calculate `durationMs = DateTime.now().difference(startTime).inMilliseconds`
> 6. Build `NotificationRegenerationSummary` with all counters
> 7. Call `_syncDiagnostics.logNotificationRegenEvent(summary)`
> 8. Return summary
>
> ### Method 2: `cancelAllMedicationNotifications`
> ```dart
> Future<void> cancelAllMedicationNotifications()
> ```
>
> **Algorithm**:
> 1. Call `await _notificationOptimizer.clearAllNotifications()`
> 2. Log: "All medication notifications cancelled (sign-out)"
>
> **VERIFIED**: `getMedicationById(String id, {bool includeDeleted = false})` already exists in `MedicationRepository` (confirmed in T003). Use it with `includeDeleted: true`.
>
> **FR-010 Note (notification permission)**: The permission check in this service satisfies FR-010 for diagnostic logging. The user-visible permission prompt is already handled at app startup by `AwesomeNotificationService`. This service logs the `permissionDenied` flag in the regeneration summary for observability — no additional UI is needed here.
>
> **FR-011 Note (context-based scheduling)**: `scheduleNextDoseNotification` currently only handles `dose.time != null` (specific-time doses). Context-based meal-relative doses (where `dose.context` is set but `dose.time` is null) are a pre-existing limitation of `NotificationOptimizer`, not introduced by this feature. Addressing this is out of scope for 007-notification-sync.
>
> **Full class skeleton**:
> ```dart
> class NotificationSyncService {
>   final MedicationRepository _medicationRepository;
>   final NotificationOptimizer _notificationOptimizer;
>   final SyncDiagnostics _syncDiagnostics;
>
>   NotificationSyncService({
>     required MedicationRepository medicationRepository,
>     required NotificationOptimizer notificationOptimizer,
>     required SyncDiagnostics syncDiagnostics,
>   })  : _medicationRepository = medicationRepository,
>         _notificationOptimizer = notificationOptimizer,
>         _syncDiagnostics = syncDiagnostics;
>
>   // ... implement methods above
> }
> ```

- [x] T006 Extend `_pullRemoteChanges` in `SyncService` to track changed medication IDs in `lib/core/services/sync/sync_service.dart`

> **T006 — Full context for implementation**:
>
> Open `lib/core/services/sync/sync_service.dart`.
>
> **Goal**: Make `_pullRemoteChanges` return a `List<String>` of changed medication IDs instead of just `int` count. Then update `syncNow` to collect those IDs and pass them into `SyncResult`.
>
> **Change 1**: Change the signature of `_pullRemoteChanges` from:
> ```dart
> Future<int> _pullRemoteChanges({required String userId}) async {
> ```
> to:
> ```dart
> Future<List<String>> _pullRemoteChanges({required String userId}) async {
> ```
>
> **Change 2**: Inside `_pullRemoteChanges`, create a `List<String> changedIds = [];` at the top. Each time a medication is written to local storage (both the "new medication" case at line ~257 and the "conflict resolved" case at line ~295), add `remoteMedication.id` to `changedIds`. At the end, return `changedIds` instead of `remoteMedications.length`.
>
> **Detailed diff** for `_pullRemoteChanges`:
> ```dart
> Future<List<String>> _pullRemoteChanges({required String userId}) async {
>   final remoteMedications = await _remoteDataSource.pullMedications(userId);
>   final localMedications = await _medicationRepository.getMedications(
>     includeDeleted: true,
>   );
>   final localById = {
>     for (final medication in localMedications) medication.id: medication,
>   };
>
>   final List<String> changedIds = [];
>
>   for (final remoteMedication in remoteMedications) {
>     final localMedication = localById[remoteMedication.id];
>     if (localMedication == null) {
>       await _medicationRepository.saveSyncedMedication(
>         remoteMedication.copyWith(userId: userId).markSynced(DateTime.now()),
>       );
>       changedIds.add(remoteMedication.id);
>       continue;
>     }
>
>     final mergedMedication = _conflictResolver.resolve(
>       local: localMedication,
>       remote: remoteMedication,
>     );
>
>     // Log conflict metadata
>     final winningSource =
>         mergedMedication.syncMetadata.updatedAt ==
>             remoteMedication.syncMetadata.updatedAt
>         ? 'remote'
>         : 'local';
>
>     await _syncState.saveConflict(
>       ConflictMetadata(
>         entityType: sync_types.SyncEntityType.medication,
>         entityId: remoteMedication.id,
>         userId: userId,
>         localUpdatedAt: localMedication.syncMetadata.updatedAt,
>         remoteUpdatedAt: remoteMedication.syncMetadata.updatedAt,
>         winningSource: winningSource,
>         resolvedAt: DateTime.now(),
>       ),
>     );
>
>     final resolvedMedication = mergedMedication.copyWith(
>       userId: userId,
>       syncMetadata: mergedMedication.syncMetadata.copyWith(
>         status: SyncStatus.synced,
>         lastSyncedAt: DateTime.now(),
>       ),
>     );
>
>     await _medicationRepository.saveSyncedMedication(resolvedMedication);
>     changedIds.add(remoteMedication.id);
>   }
>   return changedIds;
> }
> ```
>
> **Change 3**: In `syncNow`, update the variable and usage. Currently (around lines 83-130) the code does:
> ```dart
> var pulledCount = 0;
> ...
> pulledCount = await _pullRemoteChanges(userId: userId);
> ```
>
> Change to:
> ```dart
> var pulledCount = 0;
> List<String> changedMedicationIds = [];
> ...
> changedMedicationIds = await _pullRemoteChanges(userId: userId);
> pulledCount = changedMedicationIds.length;
> ```
>
> **Change 4**: In the `return SyncResult(...)` at the end of `syncNow` (around line 193), add:
> ```dart
> changedMedicationIds: changedMedicationIds,
> ```
>
> **Summary of changes**: 4 targeted edits in one file. No new imports needed. No other methods modified.

- [x] T007 Register `NotificationSyncService` in dependency injection in `lib/core/di/injector.dart`

> **T007 — Full context for implementation**:
>
> Open `lib/core/di/injector.dart`.
>
> **Add ONE new import** at the top (with the other sync service imports):
> ```dart
> import '../../core/services/sync/notification_sync_service.dart';
> ```
>
> **Add ONE new registration** in the `// Services` section (around line 224-228), AFTER `SyncDiagnostics` is registered and BEFORE the `// Cubit` section:
> ```dart
> sl.registerLazySingleton<NotificationSyncService>(
>   () => NotificationSyncService(
>     medicationRepository: sl(),
>     notificationOptimizer: NotificationOptimizer(),
>     syncDiagnostics: sl(),
>   ),
> );
> ```
>
> **ALSO update the `SyncStatusCubit` factory** (around line 242-252) to inject the new service. Add `notificationSyncService: sl(),` to the constructor call:
> ```dart
> sl.registerFactory(
>   () => SyncStatusCubit(
>     signInForSync: sl(),
>     signOutFromSync: sl(),
>     watchAuthSession: sl(),
>     syncRepository: sl(),
>     syncDiagnostics: sl(),
>     connectivitySignal: sl(),
>     syncQueue: sl(),
>     notificationSyncService: sl(),  // <-- ADD THIS
>   ),
> );
> ```
>
> **Note**: The cubit won't compile until T008 is completed (which adds the `notificationSyncService` parameter to `SyncStatusCubit`). That's expected — T007 and T008 form a logical unit.

**Checkpoint**: Foundation ready — all shared infrastructure is in place. User story implementation can begin.

---

## Phase 3: User Story 1 — Reminders Restored on New Device (Priority: P1) 🎯 MVP

**Goal**: After a user signs in on a new/reinstalled device, sync downloads medication records and automatically regenerates all upcoming local notification alarms.

**Independent Test**: Sign in on a fresh device, wait for sync to complete, and verify that scheduled notifications match the medication records retrieved from the cloud.

### Implementation for User Story 1

- [x] T008 [US1] Add `NotificationSyncService` dependency to `SyncStatusCubit` and invoke `regenerateNotifications` after every successful sync in `lib/presentation/cubit/sync/sync_status_cubit.dart`

> **T008 — Full context for implementation**:
>
> Open `lib/presentation/cubit/sync/sync_status_cubit.dart`.
>
> **Add ONE new import**:
> ```dart
> import '../../../core/services/sync/notification_sync_service.dart';
> ```
>
> **Change 1 — Add field and constructor parameter**:
>
> Add a new final field:
> ```dart
> final NotificationSyncService _notificationSyncService;
> ```
>
> Add to constructor (after `syncQueue` parameter):
> ```dart
> required NotificationSyncService notificationSyncService,
> ```
>
> Add to initializer list:
> ```dart
> _notificationSyncService = notificationSyncService,
> ```
>
> **Change 2 — Invoke regeneration after sync completes**:
>
> There are THREE places where `_syncRepository.syncNow(...)` or `_syncRepository.synchronize()` is called and then a `SyncResult` is received. After each successful sync result, add a notification regeneration call.
>
> **Location A: `_applySessionState` method** (around lines 280-300):
> After `final result = await _syncRepository.syncNow(trigger);` and before the `emit(...)` call, add:
> ```dart
> if (result.success && result.changedMedicationIds.isNotEmpty) {
>   await _notificationSyncService.regenerateNotifications(
>     changedMedicationIds: result.changedMedicationIds,
>   );
> }
> ```
>
> **Location B: `retry` method** (around lines 103-143):
> After `final result = await _syncRepository.synchronize();` and before the `emit(...)` call, add the same block:
> ```dart
> if (result.success && result.changedMedicationIds.isNotEmpty) {
>   await _notificationSyncService.regenerateNotifications(
>     changedMedicationIds: result.changedMedicationIds,
>   );
> }
> ```
>
> **Location C: `handleConnectivityRestored` method** (around lines 145-192):
> After `final result = await _syncRepository.syncNow(...)` and before the `emit(...)` call, add the same block:
> ```dart
> if (result.success && result.changedMedicationIds.isNotEmpty) {
>   await _notificationSyncService.regenerateNotifications(
>     changedMedicationIds: result.changedMedicationIds,
>   );
> }
> ```
>
> **IMPORTANT**: The regeneration call must be inside the existing `try` block (before `emit`) so that if it fails, the sync result is still emitted (the `catch` block handles it). The regeneration itself already handles per-medication errors internally, so it should not throw in normal scenarios.

**Checkpoint**: At this point, User Story 1 is functional — new device sign-in triggers sync → sync returns changed IDs → cubit calls regenerateNotifications → alarms are scheduled.

---

## Phase 4: Unit Tests (Constitution Principle III — Testable by Default)

**Purpose**: Automated tests for `NotificationSyncService` core logic. Constitution mandates tests for non-trivial features.

- [x] T009 [P] Create unit tests for `NotificationSyncService.regenerateNotifications()` in `test/core/services/sync/notification_sync_service_test.dart`

> **T009 — Full context for implementation**:
>
> Create a new test file `test/core/services/sync/notification_sync_service_test.dart`.
>
> **Dependencies to mock**:
> - `MedicationRepository` — mock with `Mockito` or manual mock
> - `NotificationOptimizer` — mock (it's a singleton, so create a testable wrapper or use `@GenerateMocks`)
> - `SyncDiagnostics` — mock or use real instance with null `SyncStateLocalDataSource`
>
> **Test cases (4 minimum)**:
>
> **Test 1: Happy path — regenerates notifications for changed medications**
> ```dart
> // Arrange: mock getMedicationById to return a medication with future doses
> // Act: call regenerateNotifications(changedMedicationIds: ['med-1'])
> // Assert:
> //   - cancelMedicationNotifications called with 'med-1'
> //   - scheduleNextDoseNotification called with the medication
> //   - summary.medicationsProcessed == 1
> //   - summary.notificationsScheduled == 1
> //   - summary.failures == 0
> ```
>
> **Test 2: Deleted medication — cancels notifications without rescheduling**
> ```dart
> // Arrange: mock getMedicationById to return a medication with isDeleted=true
> // Act: call regenerateNotifications(changedMedicationIds: ['med-deleted'])
> // Assert:
> //   - cancelMedicationNotifications called
> //   - scheduleNextDoseNotification NOT called
> //   - summary.notificationsCancelled > 0
> ```
>
> **Test 3: Null medication (purged) — cancels notifications**
> ```dart
> // Arrange: mock getMedicationById to return null
> // Act: call regenerateNotifications(changedMedicationIds: ['med-purged'])
> // Assert:
> //   - cancelMedicationNotifications called
> //   - scheduleNextDoseNotification NOT called
> ```
>
> **Test 4: Partial failure — one medication fails, others continue (FR-012)**
> ```dart
> // Arrange: mock getMedicationById to throw for 'med-2' but succeed for 'med-1' and 'med-3'
> // Act: call regenerateNotifications(changedMedicationIds: ['med-1', 'med-2', 'med-3'])
> // Assert:
> //   - summary.medicationsProcessed == 3 (or 2 successful + 1 failure)
> //   - summary.failures == 1
> //   - summary.notificationsScheduled == 2
> //   - All three medications were attempted (med-2 failure didn't stop med-3)
> ```
>
> **Test 5: Empty doses — increments failures, keeps existing alarms**
> ```dart
> // Arrange: mock getMedicationById to return medication with doses = []
> // Act: call regenerateNotifications(changedMedicationIds: ['med-empty'])
> // Assert:
> //   - cancelMedicationNotifications NOT called (safety net)
> //   - scheduleNextDoseNotification NOT called
> //   - summary.failures == 1
> ```
>
> **Setup pattern**:
> ```dart
> import 'package:flutter_test/flutter_test.dart';
> // Import mocks or create manual mocks for MedicationRepository, NotificationOptimizer, SyncDiagnostics
>
> void main() {
>   late NotificationSyncService service;
>   late MockMedicationRepository mockRepo;
>   late MockNotificationOptimizer mockOptimizer;
>   late SyncDiagnostics diagnostics;
>
>   setUp(() {
>     mockRepo = MockMedicationRepository();
>     mockOptimizer = MockNotificationOptimizer();
>     diagnostics = const SyncDiagnostics();
>     service = NotificationSyncService(
>       medicationRepository: mockRepo,
>       notificationOptimizer: mockOptimizer,
>       syncDiagnostics: diagnostics,
>     );
>   });
>
>   // ... test cases
> }
> ```
>
> **Note on NotificationOptimizer mocking**: Since `NotificationOptimizer` is a singleton using `factory NotificationOptimizer() => _instance`, you may need to either:
> - Extract an interface and inject it, OR
> - Create a thin wrapper/subclass for testing, OR
> - Use `NotificationSyncService` constructor to accept the optimizer instance (already designed this way)

---

## Phase 5: User Story 2 — Schedule Changes Propagated Across Devices (Priority: P1)

**Goal**: When a schedule is changed on Device A and Device B syncs, Device B cancels stale alarms and reschedules notifications with the new times.

**Independent Test**: Modify a dose time on one device, trigger sync on the second, confirm the second device's local alarms now fire at the new time.

### Implementation for User Story 2

- [x] T010 [US2] Verify that `_pullRemoteChanges` correctly detects schedule-changed medications (no code change expected — validation only) in `lib/core/services/sync/sync_service.dart`

> **T010 — Full context for implementation**:
>
> This is a **verification task**, not a coding task. The implementor must read `lib/core/services/sync/sync_service.dart` and confirm that after T006:
>
> 1. **Every** medication that is written locally during `_pullRemoteChanges` (both new and conflict-resolved) has its ID added to `changedIds`.
> 2. The IDs flow through `SyncResult.changedMedicationIds` to the cubit.
> 3. The cubit (after T008) calls `regenerateNotifications` with those IDs.
>
> **If verification passes**: No code change needed. US2 is already handled by the foundational changes (T006 + T008) because:
> - Schedule changes on Device A → pushed to cloud
> - Device B pulls → `_pullRemoteChanges` detects the updated medication → adds ID to `changedIds`
> - Cubit calls `regenerateNotifications` → `NotificationSyncService` cancels old alarms + schedules new
>
> **If verification fails** (e.g., some edge case is missed): Document what's missing and fix it.
>
> The implementor should write a brief confirmation comment (e.g., `// US2: Schedule change propagation verified — covered by _pullRemoteChanges + regenerateNotifications flow`) at the top of `_pullRemoteChanges` or in a commit message.

**Checkpoint**: User Story 2 is functional — schedule changes on Device A propagate through sync and trigger notification regeneration on Device B.

---

## Phase 6: User Story 3 — Medication Deletion Clears Reminders (Priority: P2)

**Goal**: When a medication is deleted on one device, after syncing, all other devices cancel every outstanding notification for that medication.

**Independent Test**: Delete a medication on one device, sync the second, verify no leftover alarms fire.

### Implementation for User Story 3

- [x] T011 [US3] Verify that `NotificationSyncService.regenerateNotifications` handles deleted medications (no code change expected — validation only) in `lib/core/services/sync/notification_sync_service.dart`

> **T011 — Full context for implementation**:
>
> This is a **verification task**. The implementor must confirm that the `regenerateNotifications` method (implemented in T005) correctly handles deleted medications:
>
> 1. When `getMedicationById(id, includeDeleted: true)` returns a medication with `isDeleted == true`, the service calls `cancelMedicationNotifications(id)` and does NOT schedule new alarms.
> 2. When `getMedicationById(id, includeDeleted: true)` returns `null` (medication purged from local storage), the service calls `cancelMedicationNotifications(id)` and does NOT schedule new alarms.
>
> **If verification passes**: No code change needed. US3 is already handled.
>
> **If verification fails**: Add the missing branch in the `regenerateNotifications` loop.
>
> The existing sync engine already tracks deleted medication IDs in `changedMedicationIds` (they are pulled from the cloud and processed through `_pullRemoteChanges`). The delete operation in `_pushChange` calls `_medicationRepository.purgeMedication` which removes the local record, so `getMedicationById` will return `null`.

**Checkpoint**: User Story 3 is functional — medication deletions clear notifications on synced devices.

---

## Phase 7: User Story 4 — Offline Schedule Changes Queue and Replay (Priority: P2)

**Goal**: Schedule changes made offline are applied immediately to local notifications and queued for cloud sync when connectivity returns.

**Independent Test**: Disable network, edit a schedule, verify local alarms update immediately, re-enable network, confirm cloud record updates.

### Implementation for User Story 4

- [x] T012 [US4] Verify that offline schedule edits already trigger local notification updates (no code change expected — validation only) in `lib/presentation/` screens

> **T012 — Full context for implementation**:
>
> This is a **verification task**. FR-006 states: "The system MUST apply schedule changes to local notifications immediately when the user modifies a schedule, regardless of connectivity."
>
> The current app flow for schedule editing is:
> 1. User edits medication → `MedicationCubit.updateMedication()` is called
> 2. The medication is saved to local Hive storage via `MedicationRepository`
> 3. The change is enqueued as a `PendingChange` for cloud sync
> 4. Notification rescheduling should happen at edit time
>
> **Check these specific files** for `scheduleNextDoseNotification` or `NotificationOptimizer` calls:
> - `lib/presentation/screens/` — the add/edit medication screens
> - `lib/presentation/cubit/medication_cubit.dart` — the `updateMedication` method
> - `lib/core/services/notification_handler.dart` — the notification action handler
>
> **If it already exists**: No code change needed. Document confirmation.
>
> **If it does NOT exist**: Add a call to `NotificationOptimizer().scheduleNextDoseNotification(medication)` in the medication update flow. The most appropriate location is in the edit medication screen's save callback, right after calling `MedicationCubit.updateMedication()`. This should happen BEFORE and INDEPENDENTLY of any sync operation.
>
> **For FR-007** (offline queue replay): This is already handled by the existing offline operations queue (Phase 4). When connectivity returns, `PendingChange` records are pushed to the cloud by `SyncService._pushChange()`. No additional work needed.

**Checkpoint**: User Story 4 is functional — offline edits immediately update local alarms, and changes sync to cloud on reconnect.

---

## Phase 8: User Story 5 — Conflict Resolution for Concurrent Schedule Edits (Priority: P3)

**Goal**: When two devices edit the same medication schedule offline and both sync, the last-write-wins strategy resolves the conflict, and the losing device regenerates its notifications.

**Independent Test**: Edit the same medication on two offline devices, reconnect both, verify both converge on the same schedule and notification state.

### Implementation for User Story 5

- [x] T013 [US5] Verify that conflict-resolved medications trigger notification regeneration (no code change expected — validation only) in `lib/core/services/sync/sync_service.dart`

> **T013 — Full context for implementation**:
>
> This is a **verification task**. The conflict resolution flow is:
> 1. Both devices push their changes to the cloud (last-write-wins based on `updatedAt`)
> 2. When pulling, `_pullRemoteChanges` calls `_conflictResolver.resolve(local, remote)` and writes the resolved medication locally
> 3. After T006, the resolved medication's ID is added to `changedIds`
> 4. After T008, the cubit calls `regenerateNotifications` with those IDs
>
> **Check**: Confirm that after a conflict resolution in `_pullRemoteChanges`, `remoteMedication.id` is added to `changedIds` (this was implemented in T006). The existing `MedicationConflictResolver` in `lib/core/services/sync/conflict_resolver.dart` already implements last-write-wins.
>
> **If verification passes**: No code change needed. US5 is fully covered.
> **If verification fails**: Ensure all conflict-resolved medication IDs are collected.

**Checkpoint**: User Story 5 is functional — conflicts resolve via last-write-wins, and the losing device regenerates its notifications.

---

## Phase 9: Sign-Out Cleanup (Cross-Cutting Concern)

**Purpose**: Cancel all scheduled medication notifications on sign-out to prevent stale reminders (FR-014).

- [x] T014 Add sign-out notification cleanup to `SyncStatusCubit.signOut()` in `lib/presentation/cubit/sync/sync_status_cubit.dart`

> **T014 — Full context for implementation**:
>
> Open `lib/presentation/cubit/sync/sync_status_cubit.dart`.
>
> **Modify the `signOut` method** (currently around lines 90-101). Add a call to cancel all notifications BEFORE the `emit`:
>
> ```dart
> Future<void> signOut() async {
>   await _signOutFromSync();
>   _ignoreNextSignedInUserId = null;
>   // Cancel all scheduled medication notifications on sign-out (FR-014)
>   await _notificationSyncService.cancelAllMedicationNotifications();
>   emit(
>     state.copyWith(
>       viewState: SyncStatusViewState.signedOut,
>       busy: false,
>       clearUserId: true,
>       clearMessage: true,
>     ),
>   );
> }
> ```
>
> **Note**: This depends on the `_notificationSyncService` field already being added in T008.

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and verification.

- [x] T015 [P] Verify `flutter analyze` passes with zero errors after all changes

> **T015 — Full context for implementation**:
>
> Run `flutter analyze` from the project root. Fix any analyzer warnings or errors introduced by the changes in T001-T014.
>
> Common issues to watch for:
> - Missing imports in files that reference `NotificationSyncService` or `NotificationRegenerationSummary`
> - Unused imports if any were added
> - Type mismatches if `_pullRemoteChanges` return type change (T006) wasn't propagated correctly
> - Constructor parameter mismatch between `SyncStatusCubit` and its factory in `injector.dart`

- [x] T016 Run quickstart.md validation commands to verify the feature works end-to-end

> **T016 — Full context for implementation**:
>
> Follow the verification commands in `specs/007-notification-sync/quickstart.md`:
>
> ```bash
> # Run all tests (including the new notification sync tests from T009)
> flutter test
>
> # Run specific notification sync tests
> flutter test test/core/services/sync/notification_sync_service_test.dart
>
> # Check for analyzer warnings
> flutter analyze
> ```
>
> All tests must pass. No new analyzer warnings should be introduced.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — T001, T002, T003 can start immediately and in parallel
- **Foundational (Phase 2)**: T004 depends on T001. T005 depends on T001, T004. T006 depends on T002. T007 depends on T005.
- **User Story 1 (Phase 3)**: T008 depends on Phase 2 completion
- **Unit Tests (Phase 4)**: T009 depends on T005 (NotificationSyncService). Can run in parallel with US2-US5 verification.
- **User Stories 2-5 (Phase 5-8)**: All depend on Phase 2 completion
  - T010-T013 are verification tasks and can run in parallel after T008
- **Sign-Out (Phase 9)**: T014 depends on T008 (requires _notificationSyncService field)
- **Polish (Phase 10)**: T015-T016 depend on all prior tasks.

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Phase 2 — MVP story (T008)
- **User Story 2 (P1)**: Can start after Phase 2 — verification only (T010)
- **User Story 3 (P2)**: Can start after Phase 2 — verification only (T011)
- **User Story 4 (P2)**: Can start after Phase 2 — verification only (T012)
- **User Story 5 (P3)**: Can start after Phase 2 — verification only (T013)

### Within Each User Story

- Models before services
- Services before cubit integration
- Core implementation before verification

### Parallel Opportunities

- T001, T002, and T003 (Phase 1) can run in parallel — different files
- T004 and T006 can run in parallel (after their respective Phase 1 dependencies) — different files
- T009, T010, T011, T012, T013 (tests + verification tasks) can all run in parallel after T008
- T009 (unit tests) can start as soon as T005 is complete

---

## Parallel Example: Phase 1

```bash
# Launch all Phase 1 setup tasks together:
Task T001: "Create NotificationRegenerationSummary entity in lib/domain/entities/sync/notification_regen_summary.dart"
Task T002: "Add changedMedicationIds field to SyncResult in lib/domain/repositories/sync_repository.dart"
Task T003: "Verify getMedicationById exists (no-op)"
```

## Parallel Example: Verification Tasks

```bash
# After T008 is complete, launch tests + verification tasks:
Task T009: "Unit tests for NotificationSyncService"
Task T010: "Verify schedule change propagation in sync_service.dart"
Task T011: "Verify deleted medication handling in notification_sync_service.dart"
Task T012: "Verify offline schedule edits trigger local notifications"
Task T013: "Verify conflict-resolved medications trigger notification regeneration"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete T001 + T002 + T003 (Phase 1: Setup — parallel, T003 is a verified no-op)
2. Complete T004, T005, T006, T007 (Phase 2: Foundational — mostly sequential)
3. Complete T008 (Phase 3: US1 — cubit integration)
4. **STOP and VALIDATE**: Run `flutter analyze` to verify compilation
5. Complete T009 (unit tests — Constitution Principle III)
6. Complete T014 (sign-out cleanup)
7. Run T010-T013 (verification tasks — parallel)
8. Run T015-T016 (final validation)

### Key Implementation Notes

- **Total new files**: 3 (`notification_regen_summary.dart`, `notification_sync_service.dart`, `notification_sync_service_test.dart`)
- **Modified files**: 5 (`sync_repository.dart`, `sync_diagnostics.dart`, `sync_service.dart`, `sync_status_cubit.dart`, `injector.dart`)
- **Verified existing**: `getMedicationById` already exists in `medication_repository.dart` — no changes needed (T003 is a no-op)
- **No Hive schema changes**: No new boxes, no new adapters, no migrations
- **No new dependencies**: All packages already in `pubspec.yaml`
- **No Firestore changes**: Schedule template already synced as part of medication document

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
- Tasks T010-T013 are verification-only because the foundational changes (T005, T006, T008) already handle all user stories. The verification ensures no edge cases are missed.
- T009 provides unit test coverage for `NotificationSyncService` as required by Constitution Principle III.
- FR-010 (notification permission warning): The user-visible permission prompt is already handled at app startup by `AwesomeNotificationService`. This feature only adds diagnostic logging of the `permissionDenied` flag.
- FR-011 (context-based scheduling): Context-based meal-relative doses are a pre-existing limitation of `NotificationOptimizer`, not in scope for 007-notification-sync.
