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

- [X] T016 [P] [US1] Unit test verifying `_enqueueOperation` correctly formats and stores JSON payload in `test/data/repositories/medication_repository_impl_test.dart`.
- [X] T017 [P] [US2] Unit test for extracting `PendingChange`s and batching correctly to 20 ops in `test/core/services/sync/sync_service_test.dart`.
- [X] T018 [P] [US4] Unit test verifying sequence coalescing correctly drops overriden updates in `test/data/datasources/sync_queue_local_data_source_test.dart`.
- [X] T019 [P] [US3] Unit test verifying arithmetic for exponential backoff filter drops unready entries in `test/data/datasources/sync_queue_local_data_source_test.dart`.

### Implementation for User Story 3

- [X] T011 [US3] Add exponential backoff filtering in `SyncQueueLocalDataSource.getEffectivePendingChanges` in `lib/data/datasources/sync_queue_local_data_source.dart`. (e.g. Reject changes where `now < lastAttemptAt + (2^attemptCount) seconds`, max limit 5 attempts).
- [X] T012 [US3] Add exposing logic for permanently failed operations (where `attemptCount >= 5`) in `lib/data/datasources/sync_queue_local_data_source.dart` and `lib/data/datasources/sync_state_local_data_source.dart`.
- [X] T013 [US3] Update `SyncStatusCubit` in `lib/presentation/cubit/sync/sync_status_cubit.dart` to query and expose the count of failed operations for UI badge rendering.
- [X] T020 [US3] Add English/Arabic localization strings for sync failure definitions in `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb`.

**Checkpoint**: All user stories should now be independently functional.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [X] T014 Remove deprecated `SyncOperation` and `SyncOperationModel` files and references across the codebase to finalize the queue migration.
- [X] T015 Run validation and ensure Hive box schema updates don't break existing data if legacy mapping is removed.

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
