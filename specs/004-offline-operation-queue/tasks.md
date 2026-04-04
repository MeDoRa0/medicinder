---
description: "Task list for Offline Operation Queue"
---

# Tasks: Offline Operation Queue

**Input**: Design documents from `/specs/004-offline-operation-queue/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, quickstart.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Mobile**: `lib/` directory inside a single Flutter project.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Read through `specs/004-offline-operation-queue/data-model.md` and `specs/004-offline-operation-queue/research.md` to internalize the shift from `SyncOperation` to `PendingChange`.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T002 Ensure `PendingChange` entity supports all `Payload` serialization in `lib/domain/entities/sync/pending_change.dart` and `lib/data/models/sync/pending_change_model.dart`.

**Checkpoint**: Foundation ready - user story implementation can now begin.

---

## Phase 3: User Story 1 - Capture Changes Made While Offline (Priority: P1) 🎯 MVP

**Goal**: Every medication change made while offline is durably recorded so that nothing is lost.

**Independent Test**: Turn off network connectivity, create/update/delete a medication, restart the app, and verify via logs/state that a `PendingChange` with the full payload exists in Hive.

### Tests for User Story 1 ⚠️

- [ ] T016 [P] [US1] Unit test verifying `_enqueueOperation` correctly formats and stores JSON payload in `test/data/repositories/medication_repository_impl_test.dart`.

### Implementation for User Story 1

- [ ] T003 [US1] Update `_enqueueOperation` logic in `lib/data/repositories/medication_repository_impl.dart` to accept and enqueue a `PendingChange` object containing the `medication.toMap()` (or equivalent JSON map) payload.
- [ ] T004 [US1] Refactor `addMedication` and `updateMedication` in `lib/data/repositories/medication_repository_impl.dart` to use the new `_enqueueOperation` with the full snapshot payload.
- [ ] T005 [US1] Refactor `deleteMedication` in `lib/data/repositories/medication_repository_impl.dart` to enqueue the `delete` operation via `PendingChange` without a payload.

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently. Queued items are correctly formatted as `PendingChange` elements.

---

## Phase 4: User Story 2 - Replay Queued Operations on Reconnection (Priority: P2)

**Goal**: Queued offline operations are automatically replayed and synchronized when connectivity returns.

**Independent Test**: Add changes while offline, restore connectivity, verify operations push successfully to the cloud and are removed from the queue.

### Tests for User Story 2 ⚠️

- [ ] T017 [P] [US2] Unit test for extracting `PendingChange`s and batching correctly to 20 ops in `test/core/services/sync/sync_service_test.dart`.

### Implementation for User Story 2

- [ ] T006 [P] [US2] Update `SyncQueueLocalDataSource.getEffectivePendingChanges` in `lib/data/datasources/sync_queue_local_data_source.dart` to return ONLY natively stored `PendingChange`s instead of computing legacy operations.
- [ ] T007 [US2] Update `SyncService._pushChange` in `lib/core/services/sync/sync_service.dart` to reconstruct the `Medication` object from the `change.payload` (for create/update) to push to the cloud context.
- [ ] T008 [US2] Refactor `SyncService.syncNow` in `lib/core/services/sync/sync_service.dart` to partition `changes` into batches of 20 and handle incremental state updates.

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently.

---

## Phase 5: User Story 4 - Preserve Operation Order and Consistency (Priority: P2)

**Goal**: Offline operations are replayed in the exact order performed, but coalesce consecutive updates to the same record.

**Independent Test**: Make multiple updates to the same record while offline. Sync, and verify only one consolidated update hits the cloud.

### Tests for User Story 4 ⚠️

- [ ] T018 [P] [US4] Unit test verifying sequence coalescing correctly drops overriden updates in `test/data/datasources/sync_queue_local_data_source_test.dart`.

### Implementation for User Story 4

- [ ] T009 [US4] Implement a `_coalescePendingChanges` method in `lib/data/datasources/sync_queue_local_data_source.dart` which merges consecutive `update` operations on the same `entityId`.
- [ ] T010 [US4] Wire `_coalescePendingChanges` into `SyncQueueLocalDataSource.getEffectivePendingChanges` so `SyncService` receives optimized payloads.

**Checkpoint**: Ordering and coalescing apply to User Story 2 replay loop correctly.

---

## Phase 6: User Story 3 - Retry Failed Operations Automatically (Priority: P3)

**Goal**: Operations that fail during replay are retried automatically using exponential backoff up to a permanent failure state.

**Independent Test**: Simulate a cloud write failure. Confirm the item's `attemptCount` increments and is skipped on immediate subsequent syncs until the backoff timeout expires.

### Tests for User Story 3 ⚠️

- [ ] T019 [P] [US3] Unit test verifying arithmetic for exponential backoff filter drops unready entries in `test/data/datasources/sync_queue_local_data_source_test.dart`.

### Implementation for User Story 3

- [ ] T011 [US3] Add exponential backoff filtering in `SyncQueueLocalDataSource.getEffectivePendingChanges` in `lib/data/datasources/sync_queue_local_data_source.dart`. (e.g. Reject changes where `now < lastAttemptAt + (2^attemptCount) seconds`, max limit 5 attempts).
- [ ] T012 [US3] Add exposing logic for permanently failed operations (where `attemptCount >= 5`) in `lib/data/datasources/sync_queue_local_data_source.dart` and `lib/data/datasources/sync_state_local_data_source.dart`.
- [ ] T013 [US3] Update `SyncStatusCubit` in `lib/presentation/cubit/sync/sync_status_cubit.dart` to query and expose the count of failed operations for UI badge rendering.
- [ ] T020 [US3] Add English/Arabic localization strings for sync failure definitions in `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb`.

**Checkpoint**: All user stories should now be independently functional.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T014 Remove deprecated `SyncOperation` and `SyncOperationModel` files and references across the codebase to finalize the queue migration.
- [ ] T015 Run validation and ensure Hive box schema updates don't break existing data if legacy mapping is removed.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories**: All depend on Foundational phase completion
  - Sequential priority order: P1 (US1) → P2 (US2, US4) → P3 (US3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2)
- **User Story 2 (P2)**: Integrates heavily with User Story 1 (needs the stored payloads to replay).
- **User Story 4 (P2)**: Modifies User Story 2's data fetching pipeline.
- **User Story 3 (P3)**: Builds upon the finalized fetching pipeline and statuses.

### Parallel Opportunities

- The UI adjustments (T013) can be performed in parallel to the backoff logic (T011).
- The parsing and batching mechanisms in `SyncService` (T007, T008) can be developed alongside the fetching logic (T006).

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 & 2.
2. Complete Phase 3: User Story 1.
3. Validate that operations are durably written to disk as `PendingChange` with a full JSON payload.

### Incremental Delivery

1. Start by getting the local creation of changes working (US1).
2. Wire the `SyncService` to parse them and push them off the device (US2).
3. Apply logic filtering directly before the `SyncService` receives the queued items: coalesce them (US4), then time-gate them via exponential backoff (US3).
4. Remove all deprecated structs.
