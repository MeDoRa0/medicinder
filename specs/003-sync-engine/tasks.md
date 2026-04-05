# Tasks: Sync Engine Implementation

**Input**: Design documents from `/specs/003-sync-engine/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Automated tests are required for this feature because the constitution, plan, and quickstart explicitly call for unit and widget verification of sync-engine behavior.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g. `US1`, `US2`, `US3`)
- Include exact file paths in descriptions

## Low-Context Execution Rules

- Execute tasks in order unless a task is marked `[P]` and its dependencies are already complete.
- Do not redesign the offline queue in this feature; use the existing queue boundary and adapt it only enough for the Phase 3 engine.
- Do not hand-edit generated files unless the task explicitly says to regenerate them.
- After each user story checkpoint, run only that story's tests before moving forward.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare the repo for Phase 3 engine work and create the shared files all stories will use.

- [ ] T001 Add `connectivity_plus` and any required supporting package entries for Phase 3 sync triggers in `pubspec.yaml`
- [ ] T002 [P] Create the new lifecycle entity skeleton in `lib/domain/entities/sync/sync_cycle_state.dart`
- [ ] T003 [P] Create the matching Hive model skeleton in `lib/data/models/sync/sync_cycle_state_model.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared engine infrastructure that MUST be complete before any user story work begins.

**CRITICAL**: No user story work should start until this phase is done.

- [ ] T004 Extend shared sync enums and result fields for lifecycle status and failure classification in `lib/domain/entities/sync/sync_types.dart` and `lib/domain/repositories/sync_repository.dart`
- [ ] T005 [P] Extend per-user sync profile persistence to hold lifecycle timestamps, failure codes, and last-cycle summary fields in `lib/domain/entities/sync/user_sync_profile.dart`, `lib/data/models/sync/user_sync_profile_model.dart`, and `lib/data/datasources/sync_state_local_data_source.dart`
- [ ] T006 [P] Extend conflict metadata persistence to store user-scoped winner details in `lib/domain/entities/sync/conflict_metadata.dart`, `lib/data/models/sync/conflict_metadata_model.dart`, and `lib/data/datasources/sync_state_local_data_source.dart`
- [ ] T007 Wire the new lifecycle model, Hive adapter registration, Hive box opening, and connectivity service registration in `lib/core/di/injector.dart`
- [ ] T008 Add localized copy for syncing, sync complete, and retry-safe failure messaging in `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`, and generated localization files under `lib/l10n/`

**Checkpoint**: Shared types, persistence, diagnostics inputs, localization keys, and dependency wiring exist for all later story work.

---

## Phase 3: User Story 1 - Synchronize Changes After Reconnection (Priority: P1) MVP

**Goal**: Start sync automatically at app startup and after connectivity returns, then upload local medication changes without duplicate cycles.

**Independent Test**: Sign in, make a medication change while disconnected, restore connectivity, and confirm exactly one sync cycle runs and uploads the local change. Restart the app while signed in and confirm startup sync runs once without creating duplicate work.

### Tests for User Story 1

- [ ] T009 [US1] Add startup-trigger, reconnect-trigger, and overlap-guard unit tests in `test/core/services/sync/sync_service_test.dart`
- [ ] T010 [P] [US1] Add startup-session and reconnect-dispatch Cubit tests in `test/presentation/cubit/sync/sync_status_cubit_test.dart`
- [ ] T011 [P] [US1] Add widget coverage for visible in-progress sync state during startup and reconnect flows in `test/widget/sync_status_banner_test.dart` and `test/widget/sync_accessibility_test.dart`

### Implementation for User Story 1

- [ ] T012 [US1] Implement a connectivity-restored stream wrapper in `lib/core/services/sync/connectivity_signal_service.dart`
- [ ] T013 [US1] Extend the queue boundary to return user-scoped `PendingChange` items and convert legacy `SyncOperation` entries only as fallback in `lib/data/datasources/sync_queue_local_data_source.dart`
- [ ] T014 [US1] Update the sync engine to reject overlapping cycles, accept `appStartup` and `connectivityRestored` triggers, and process queued uploads from the queue boundary in `lib/core/services/sync/sync_service.dart`
- [ ] T015 [US1] Register and inject the connectivity wrapper into the app-wide sync flow in `lib/core/di/injector.dart`
- [ ] T016 [US1] Subscribe to startup and connectivity-restored sync triggers in `lib/presentation/cubit/sync/sync_status_cubit.dart`
- [ ] T017 [US1] Mark successfully uploaded local medication records as synced and remove completed queue entries in `lib/core/services/sync/sync_service.dart`

**Checkpoint**: User Story 1 is complete when startup and reconnect each trigger at most one active cycle and local medication changes upload successfully for the active signed-in user.

---

## Phase 4: User Story 2 - Receive Newer Cloud Updates Safely (Priority: P2)

**Goal**: Pull newer remote medication records, merge them with local records, and resolve conflicts with timestamp-based winner selection.

**Independent Test**: Create a newer medication change in the cloud, run sync, and confirm the local device converges to the correct winner. Create a delete-versus-update conflict and confirm the newest timestamp wins without duplicate records.

### Tests for User Story 2

- [ ] T018 [US2] Add delete-tombstone and timestamp-winner coverage in `test/core/services/sync/conflict_resolver_test.dart`
- [ ] T019 [P] [US2] Add pull-merge, duplicate-prevention, and conflict-recording coverage in `test/core/services/sync/sync_service_test.dart`
- [ ] T020 [P] [US2] Add Firestore medication mapping tests for remote tombstones and user-scoped pull results in `test/data/datasources/medication_remote_data_source_test.dart`

### Implementation for User Story 2

- [ ] T021 [US2] Update timestamp-based winner selection and delete-versus-update handling in `lib/core/services/sync/conflict_resolver.dart`
- [ ] T022 [US2] Extend remote medication mapping to preserve delete tombstones, stable identifiers, and user-scoped incremental pull behavior in `lib/data/datasources/medication_remote_data_source.dart`
- [ ] T023 [US2] Update remote pull reconciliation to merge by medication id, apply the winning record locally, and avoid duplicate local records in `lib/core/services/sync/sync_service.dart`
- [ ] T024 [US2] Save resolved conflict details after merge decisions in `lib/core/services/sync/sync_service.dart` and `lib/data/datasources/sync_state_local_data_source.dart`
- [ ] T025 [US2] Mark remote-pulled and merged winners with synchronized metadata in `lib/core/services/sync/sync_service.dart` and `lib/domain/entities/sync_metadata.dart`

**Checkpoint**: User Story 2 is complete when remote medication changes pull down correctly, delete tombstones obey timestamp rules, and merged records remain deduplicated and marked synced.

---

## Phase 5: User Story 3 - Understand Sync Progress and Failures (Priority: P3)

**Goal**: Persist accurate lifecycle outcomes, expose them through the Cubit and widgets, and keep failed work retryable with actionable diagnostics.

**Independent Test**: Trigger a successful cycle, a partial failure, and a full failure. Confirm the app shows running, success, and failure states correctly, diagnostics contain only safe metadata, and failed work remains retryable.

### Tests for User Story 3

- [ ] T026 [US3] Add lifecycle-snapshot, partial-failure, and retryability coverage in `test/core/services/sync/sync_service_test.dart`
- [ ] T027 [P] [US3] Add lifecycle-to-view-state mapping tests in `test/presentation/cubit/sync/sync_status_cubit_test.dart`
- [ ] T028 [P] [US3] Add widget coverage for syncing, synced, failed, and retry UI states in `test/widget/sync_status_banner_test.dart` and `test/widget/sync_accessibility_test.dart`
- [ ] T029 [P] [US3] Add sign-out and account-switch race coverage during in-flight sync in `test/core/services/sync/sync_service_test.dart` and `test/presentation/cubit/sync/sync_status_cubit_test.dart`

### Implementation for User Story 3

- [ ] T030 [US3] Prevent stale sync results from being applied after sign-out or active-account change in `lib/core/services/sync/sync_service.dart` and `lib/presentation/cubit/sync/sync_status_cubit.dart`
- [ ] T031 [US3] Implement persisted lifecycle snapshots in `lib/domain/entities/sync/sync_cycle_state.dart`, `lib/data/models/sync/sync_cycle_state_model.dart`, and `lib/data/datasources/sync_state_local_data_source.dart`
- [ ] T032 [US3] Update sync result creation, lifecycle writes, partial-failure accounting, and retry-safe failure messages in `lib/core/services/sync/sync_service.dart` and `lib/domain/repositories/sync_repository.dart`
- [ ] T033 [US3] Extend sync diagnostics to log cycle start, cycle end, trigger source, counts, and coarse failure classes without payload data in `lib/core/services/sync/sync_diagnostics.dart`
- [ ] T034 [US3] Update presentation state mapping for persisted lifecycle snapshots and retry outcomes in `lib/presentation/cubit/sync/sync_status_state.dart` and `lib/presentation/cubit/sync/sync_status_cubit.dart`
- [ ] T035 [US3] Update visible sync status rendering for running, complete, and failed outcomes in `lib/presentation/widgets/sync/sync_status_banner.dart` and `lib/presentation/widgets/sync/sync_account_tile.dart`

**Checkpoint**: User Story 3 is complete when the app reports running, succeeded, and failed sync outcomes accurately, failed work remains retryable, and diagnostics stay non-sensitive.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Regenerate outputs, run the planned validation suite, and leave clear implementation notes for follow-up work.

- [ ] T036 [P] Regenerate localization and Hive adapter outputs with the repo generation commands for files under `lib/l10n/` and `lib/data/models/sync/*.g.dart`
- [ ] T037 Measure sync-cycle duration and verify the 30-second acceptance target in `test/core/services/sync/sync_service_test.dart` and `specs/003-sync-engine/quickstart.md`
- [ ] T038 Run the Phase 3 validation commands from `specs/003-sync-engine/quickstart.md` and record any follow-up notes in `specs/003-sync-engine/quickstart.md`
- [ ] T039 [P] Update final implementation notes and phase-scope reminders in `specs/003-sync-engine/plan.md`, `specs/003-sync-engine/research.md`, and `AGENTS.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup**: Starts immediately
- **Phase 2: Foundational**: Depends on Setup and blocks all user stories
- **Phase 3: US1**: Depends on Foundational completion
- **Phase 4: US2**: Depends on US1 because remote merge work assumes startup/reconnect upload flow already exists
- **Phase 5: US3**: Depends on US1 and US2 because lifecycle reporting must describe real engine outcomes
- **Phase 6: Polish**: Depends on all targeted user stories being complete

### User Story Dependencies

- **US1 (P1)**: No dependency on other user stories after Foundational work
- **US2 (P2)**: Depends on US1 upload trigger flow and shared queue boundary
- **US3 (P3)**: Depends on US1 and US2 because lifecycle reporting must include startup, reconnect, push, pull, merge, and failure outcomes

### Within Each User Story

- Tests should be written first and fail before implementation
- Shared types and persistence changes should land before service logic
- Service logic should land before Cubit and widget updates
- Complete the checkpoint for one story before starting the next unless a task is explicitly marked `[P]`

### Parallel Opportunities

- `T002` and `T003` can run in parallel during Setup
- `T005` and `T006` can run in parallel during Foundational work
- `T010` and `T011` can run in parallel after `T009`
- `T019` and `T020` can run in parallel after `T018`
- `T027`, `T028`, and `T029` can run in parallel after `T026`
- `T036` and `T039` can run in parallel during Polish

---

## Parallel Example: User Story 1

```text
T010 test/presentation/cubit/sync/sync_status_cubit_test.dart
T011 test/widget/sync_status_banner_test.dart and test/widget/sync_accessibility_test.dart
```

## Parallel Example: User Story 2

```text
T019 test/core/services/sync/sync_service_test.dart
T020 test/data/datasources/medication_remote_data_source_test.dart
```

## Parallel Example: User Story 3

```text
T027 test/presentation/cubit/sync/sync_status_cubit_test.dart
T028 test/widget/sync_status_banner_test.dart and test/widget/sync_accessibility_test.dart
T029 test/core/services/sync/sync_service_test.dart and test/presentation/cubit/sync/sync_status_cubit_test.dart
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. Run only the US1 tests and validate the checkpoint
5. Stop for review before adding pull/merge complexity

### Incremental Delivery

1. Setup + Foundational create the shared engine types, persistence, localization, and DI wiring
2. US1 delivers startup/reconnect upload behavior
3. US2 delivers remote pull, merge, and conflict handling
4. US3 delivers lifecycle reporting, retry-safe failures, and diagnostics
5. Polish regenerates outputs and runs the full validation suite

### Low-Cost Model Strategy

1. Give the implementer one task at a time, in order
2. Do not combine tasks from different phases in one prompt
3. After each completed task, re-run the tests named in that story before continuing
4. If a task introduces a new file, finish that file before editing dependent files

---

## Notes

- All tasks follow the required checklist format with IDs, optional `[P]` markers, story labels where required, and concrete file paths.
- This task list intentionally uses small, file-scoped steps so a cheaper model can execute it without inferring hidden architecture decisions.
- Phase 4 queue redesign and Phase 5 notification regeneration are intentionally excluded from these tasks.
