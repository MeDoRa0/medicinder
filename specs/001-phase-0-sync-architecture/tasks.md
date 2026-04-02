# Tasks: Phase 0 Cloud Sync Implementation Foundation

**Input**: Design documents from `C:\Users\medo2\Desktop\programming\medicinder\specs\001-phase-0-sync-architecture\`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/sync-boundaries.md`, `quickstart.md`

**Tests**: Tests are REQUIRED for this feature because sync, auth gating, offline replay, localization, and notification regeneration are non-trivial and constitution-gated.

**Organization**: Tasks are grouped by user story so each story can be implemented and verified independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel if dependencies are already complete and the task edits different files
- **[Story]**: Maps a task to `US1`, `US2`, or `US3`
- Every task below includes exact file paths

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add the packages, folders, and generated-file support required before sync implementation begins.

- [X] T001 Update Firebase and connectivity dependencies in `pubspec.yaml`
- [X] T002 Run package resolution and refresh locked versions in `pubspec.lock`
- [X] T003 [P] Create sync feature directories in `lib/core/services/auth/`, `lib/data/datasources/auth/`, `lib/data/models/sync/`, `lib/domain/entities/sync/`, `lib/domain/usecases/sync/`, `lib/presentation/cubit/sync/`, and `lib/presentation/widgets/sync/`
- [X] T004 [P] Document Firebase platform setup prerequisites and missing-config behavior in `specs/001-phase-0-sync-architecture/quickstart.md`, `README.md`, and `lib/main.dart`
- [X] T005 [P] Extend test folder structure for sync, auth, widget, integration, and localization coverage in `test/core/services/sync/`, `test/domain/usecases/sync/`, `test/presentation/cubit/sync/`, `test/widget/`, `test/integration/`, and `test/localization/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the shared auth, sync metadata, queue, DI, and logging foundation that all user stories depend on.

**CRITICAL**: No user story work should start until this phase is complete.

- [X] T006 Create sync-specific enums and value objects in `lib/domain/entities/sync/sync_types.dart`
- [X] T007 Create `UserSyncProfile` entity in `lib/domain/entities/sync/user_sync_profile.dart`
- [X] T008 [P] Create `PendingChange` entity in `lib/domain/entities/sync/pending_change.dart`
- [X] T009 [P] Create `ConflictMetadata` entity in `lib/domain/entities/sync/conflict_metadata.dart`
- [X] T010 [P] Create `SyncStatusViewState` entity or enum wrapper in `lib/domain/entities/sync/sync_status_view_state.dart`
- [X] T011 Update `Medication` sync metadata support in `lib/domain/entities/medication.dart` and `lib/domain/entities/sync_metadata.dart`
- [X] T012 Create Hive-backed sync models in `lib/data/models/sync/user_sync_profile_model.dart`, `lib/data/models/sync/pending_change_model.dart`, and `lib/data/models/sync/conflict_metadata_model.dart`
- [X] T013 Generate Hive adapters for new sync models in `lib/data/models/sync/user_sync_profile_model.g.dart`, `lib/data/models/sync/pending_change_model.g.dart`, and `lib/data/models/sync/conflict_metadata_model.g.dart`
- [X] T014 Create auth data source contract and Firebase-backed implementation in `lib/data/datasources/auth/auth_remote_data_source.dart`
- [X] T015 [P] Create local sync state data source in `lib/data/datasources/sync_state_local_data_source.dart`
- [X] T016 [P] Extend queue storage capabilities in `lib/data/datasources/sync_queue_local_data_source.dart` to support `PendingChange`, status updates, retries, and lookup by user
- [X] T017 Replace disabled-only remote sync abstraction with Firestore-ready contract in `lib/data/datasources/medication_remote_data_source.dart`
- [X] T018 Create sync repository contract extensions in `lib/domain/repositories/sync_repository.dart`
- [X] T019 Create auth repository contract in `lib/domain/repositories/auth_repository.dart`
- [X] T020 Create Firebase/auth and sync failure types in `lib/core/error/failures.dart`
- [X] T021 [P] Create sync diagnostics helper in `lib/core/services/sync/sync_diagnostics.dart`
- [X] T022 Update dependency injection, Hive box registration, and service wiring in `lib/core/di/injector.dart`
- [X] T023 Update startup bootstrap and deferred initialization flow in `lib/main.dart` to initialize Firebase safely without blocking the first frame

**Checkpoint**: Foundation ready. Auth state, local sync metadata, DI, and remote contracts exist so user story work can proceed with low ambiguity.

---

## Phase 3: User Story 1 - Approve Sync Direction (Priority: P1) MVP

**Goal**: Deliver the user-visible cloud sync direction by adding account-gated sync status, startup behavior, and settings/home surfaces that make the chosen product behavior concrete.

**Independent Test**: A reviewer can sign out, sign in, trigger a sync attempt, and see the four required states (`Not signed in`, `Syncing`, `Up to date`, `Sync failed`) without breaking local-only medication usage.

### Tests for User Story 1

- [X] T024 [P] [US1] Add auth repository unit tests in `test/domain/usecases/sync/auth_session_usecases_test.dart`
- [X] T025 [P] [US1] Add sync status cubit tests for all four states in `test/presentation/cubit/sync/sync_status_cubit_test.dart`
- [X] T026 [P] [US1] Add widget tests for signed-out and signed-in sync states in `test/widget/sync_status_banner_test.dart`
- [ ] T027 [P] [US1] Add localization tests for English/Arabic sync copy in `test/localization/sync_localizations_test.dart`
- [X] T028 [P] [US1] Add accessibility-focused widget tests for sync status semantics and retry affordances in `test/widget/sync_accessibility_test.dart`

### Implementation for User Story 1

- [X] T029 [P] [US1] Create auth session entity and repository implementation in `lib/domain/entities/sync/auth_session.dart` and `lib/data/repositories/auth_repository_impl.dart`
- [X] T030 [P] [US1] Create sign-in, sign-out, and watch-session use cases in `lib/domain/usecases/sync/sign_in_for_sync.dart`, `lib/domain/usecases/sync/sign_out_from_sync.dart`, and `lib/domain/usecases/sync/watch_auth_session.dart`
- [X] T031 [US1] Create `SyncStatusCubit` and state classes in `lib/presentation/cubit/sync/sync_status_cubit.dart` and `lib/presentation/cubit/sync/sync_status_state.dart`
- [X] T032 [P] [US1] Create sync status UI widgets in `lib/presentation/widgets/sync/sync_status_banner.dart` and `lib/presentation/widgets/sync/sync_account_tile.dart`
- [X] T033 [US1] Add accessibility semantics and clear retry labels to `lib/presentation/widgets/sync/sync_status_banner.dart` and `lib/presentation/widgets/sync/sync_account_tile.dart`
- [X] T034 [US1] Integrate sync account and status controls into `lib/presentation/pages/settings_page.dart`
- [X] T035 [US1] Surface read-only sync status on the main experience in `lib/presentation/pages/home_page.dart`
- [X] T036 [US1] Wire startup auth observation and initial sync status transitions in `lib/main.dart` and `lib/core/di/injector.dart`
- [X] T037 [US1] Add localized strings for sign-in and sync states in `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb`
- [X] T038 [US1] Regenerate localization outputs in `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, and `lib/l10n/app_localizations_ar.dart`

**Checkpoint**: User Story 1 is complete when the app clearly communicates cloud sync direction and account gating while preserving local-only use.

---

## Phase 4: User Story 2 - Define Data and Sync Rules (Priority: P2)

**Goal**: Implement the concrete sync rules for account-scoped data, queue replay, reconnect behavior, conflict resolution, and notification-regeneration triggers.

**Independent Test**: A reviewer can create or edit medication data offline, restore connectivity, observe automatic background replay, verify last-write-wins conflict handling, and confirm reminder data stays device-local except for synchronized schedule/settings inputs.

### Tests for User Story 2

- [ ] T039 [P] [US2] Extend conflict resolution tests in `test/core/services/sync/conflict_resolver_test.dart`
- [ ] T040 [P] [US2] Extend sync service replay and pull tests in `test/core/services/sync/sync_service_test.dart`
- [ ] T041 [P] [US2] Add queue persistence tests in `test/core/services/sync/sync_queue_local_data_source_test.dart`
- [ ] T042 [P] [US2] Add sync repository/use-case tests for reconnect-triggered sync in `test/domain/usecases/sync/synchronize_now_test.dart`
- [ ] T043 [P] [US2] Add integration-style offline-to-online replay coverage in `test/integration/sync_reconnect_flow_test.dart`
- [ ] T044 [P] [US2] Add performance validation tests for reconnect dispatch and sync status latency in `test/core/services/sync/sync_performance_test.dart` and `test/integration/sync_reconnect_flow_test.dart`

### Implementation for User Story 2

- [ ] T045 [P] [US2] Extend medication remote mapping and Firestore serialization in `lib/data/datasources/medication_remote_data_source.dart` and `lib/data/models/medication_model.dart`
- [ ] T046 [P] [US2] Create schedule and reminder sync entities in `lib/domain/entities/sync/schedule_configuration.dart` and `lib/domain/entities/sync/reminder_settings.dart`
- [ ] T047 [P] [US2] Create Hive/Firestore models for schedule and reminder sync records in `lib/data/models/sync/schedule_configuration_model.dart` and `lib/data/models/sync/reminder_settings_model.dart`
- [ ] T048 [P] [US2] Generate adapters for schedule and reminder sync models in `lib/data/models/sync/schedule_configuration_model.g.dart` and `lib/data/models/sync/reminder_settings_model.g.dart`
- [ ] T049 [US2] Create local sync state repository implementation in `lib/data/repositories/sync_repository_impl.dart`
- [ ] T050 [US2] Expand `MedicationConflictResolver` to record `ConflictMetadata` and enforce `updatedAt` last-write-wins in `lib/core/services/sync/conflict_resolver.dart`
- [ ] T051 [US2] Refactor `SyncService` to support auth-gated push/pull, queue replay, partial failure handling, reconnect-driven execution, and measurable timing hooks in `lib/core/services/sync/sync_service.dart`
- [ ] T052 [US2] Create sync use cases in `lib/domain/usecases/sync/synchronize_now.dart`, `lib/domain/usecases/sync/handle_connectivity_restored.dart`, and `lib/domain/usecases/sync/handle_auth_changed.dart`
- [ ] T053 [US2] Update repository implementations to enqueue and sync medication mutations in `lib/data/repositories/medication_repository_impl.dart`
- [ ] T054 [US2] Create connectivity monitoring service in `lib/core/services/sync/connectivity_sync_trigger.dart`
- [ ] T055 [US2] Add timing instrumentation and non-sensitive sync metrics in `lib/core/services/sync/sync_diagnostics.dart`
- [ ] T056 [US2] Integrate notification regeneration after synced schedule/setting changes in `lib/core/services/notification_handler.dart` and `lib/core/services/awesome_notification_service.dart`
- [ ] T057 [US2] Register all new sync repositories, services, boxes, and use cases in `lib/core/di/injector.dart`

**Checkpoint**: User Story 2 is complete when sync rules are enforced consistently and can be tested independently from the rest of the roadmap.

---

## Phase 5: User Story 3 - Prepare Downstream Planning (Priority: P3)

**Goal**: Leave the feature implementation ready for the next phases by documenting boundaries, validating diagnostics, and tightening developer-facing contracts.

**Independent Test**: A reviewer can read the updated developer docs, run the prescribed checks, and trace implementation boundaries and diagnostics without asking for missing design context.

### Tests for User Story 3

- [ ] T058 [P] [US3] Add diagnostic logging tests around sync outcomes in `test/core/services/sync/sync_diagnostics_test.dart`
- [ ] T059 [P] [US3] Add widget coverage for sync failure recovery affordances in `test/widget/sync_failure_recovery_test.dart`

### Implementation for User Story 3

- [ ] T060 [P] [US3] Update the internal sync contract to reflect implemented interfaces in `specs/001-phase-0-sync-architecture/contracts/sync-boundaries.md`
- [ ] T061 [P] [US3] Update implementation notes, Firebase setup guidance, performance checks, and operator checklist in `specs/001-phase-0-sync-architecture/quickstart.md`
- [ ] T062 [US3] Document concrete Firestore collections, auth assumptions, retry diagnostics, and implementation scope in `specs/001-phase-0-sync-architecture/research.md` and `specs/001-phase-0-sync-architecture/plan.md`
- [ ] T063 [US3] Add developer-facing sync section and validation commands in `README.md`
- [ ] T064 [US3] Refresh agent guidance with the now-implemented sync stack in `AGENTS.md`

**Checkpoint**: User Story 3 is complete when implementation artifacts, diagnostics, and repo documentation are aligned and ready for cheaper-model execution in later iterations.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Finish validation, cleanup, and cross-story safeguards that affect the full feature.

- [ ] T065 [P] Run formatter and analyzer for the touched sync feature files with `dart format lib test specs` and `flutter analyze`
- [ ] T066 [P] Run focused sync and widget test suites with `flutter test test/core/services/sync/`, `flutter test test/presentation/cubit/sync/`, and `flutter test test/widget/`
- [ ] T067 [P] Run integration and localization validation with `flutter test test/integration/`, `flutter test test/localization/`, and `flutter gen-l10n`
- [ ] T068 Validate offline recovery, account gating, sync state UX, and accessibility affordances manually in `specs/001-phase-0-sync-architecture/quickstart.md`
- [ ] T069 Validate English/Arabic copy, RTL rendering, non-sensitive diagnostics, and performance budgets in `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`, and `lib/core/services/sync/sync_diagnostics.dart`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup** has no dependencies and starts immediately.
- **Phase 2: Foundational** depends on Phase 1 and blocks all user stories.
- **Phase 3: US1** depends on Phase 2.
- **Phase 4: US2** depends on Phase 2 and should start after US1 UI/account direction is in place, because US2 publishes state into those surfaces.
- **Phase 5: US3** depends on US1 and US2 because it documents the implemented boundaries and diagnostics.
- **Phase 6: Polish** depends on all desired user stories being complete.

### User Story Dependencies

- **US1 (P1)**: No dependency on other user stories once the foundation is complete.
- **US2 (P2)**: Depends on the shared foundation and benefits from US1 sync status surfaces, but its service-layer tests can begin as soon as Phase 2 is done.
- **US3 (P3)**: Depends on completed implementation decisions from US1 and US2.

### Within Each User Story

- Write or extend tests first where possible, then implement entities/models, then repositories/services, then Cubits/UI, then wiring and documentation.
- Prefer finishing one task completely before moving to the next task that depends on it.
- Do not merge user-facing sync copy before the corresponding cubit/state wiring exists.

### Parallel Opportunities

- `T003`, `T004`, and `T005` can run in parallel after `T001`.
- `T007` through `T010`, `T015` through `T017`, and `T020` through `T021` can run in parallel once setup is done.
- In US1, tests `T024` through `T028` can run in parallel, and UI widgets `T032` can run in parallel with use cases `T030` after `T029`.
- In US2, tests `T039` through `T044` can run in parallel, and model tasks `T046` through `T048` can run in parallel with remote mapping `T045`.
- In US3, `T060`, `T061`, and `T063` can run in parallel after implementation settles.
- Validation tasks `T061`, `T062`, and `T063` can run in parallel at the end.

---

## Parallel Example: User Story 1

```text
Task: "T024 Add auth repository unit tests in test/domain/usecases/sync/auth_session_usecases_test.dart"
Task: "T025 Add sync status cubit tests for all four states in test/presentation/cubit/sync/sync_status_cubit_test.dart"
Task: "T026 Add widget tests for signed-out and signed-in sync states in test/widget/sync_status_banner_test.dart"
Task: "T027 Add localization tests for English/Arabic sync copy in test/localization/sync_localizations_test.dart"

Task: "T029 Create sign-in, sign-out, and watch-session use cases in lib/domain/usecases/sync/sign_in_for_sync.dart, lib/domain/usecases/sync/sign_out_from_sync.dart, and lib/domain/usecases/sync/watch_auth_session.dart"
Task: "T031 Create sync status UI widgets in lib/presentation/widgets/sync/sync_status_banner.dart and lib/presentation/widgets/sync/sync_account_tile.dart"
```

## Parallel Example: User Story 2

```text
Task: "T037 Extend conflict resolution tests in test/core/services/sync/conflict_resolver_test.dart"
Task: "T038 Extend sync service replay and pull tests in test/core/services/sync/sync_service_test.dart"
Task: "T039 Add queue persistence tests in test/core/services/sync/sync_queue_local_data_source_test.dart"
Task: "T040 Add sync repository/use-case tests for reconnect-triggered sync in test/domain/usecases/sync/synchronize_now_test.dart"

Task: "T042 Extend medication remote mapping and Firestore serialization in lib/data/datasources/medication_remote_data_source.dart and lib/data/models/medication_model.dart"
Task: "T043 Create schedule and reminder sync entities in lib/domain/entities/sync/schedule_configuration.dart and lib/domain/entities/sync/reminder_settings.dart"
Task: "T044 Create Hive/Firestore models for schedule and reminder sync records in lib/data/models/sync/schedule_configuration_model.dart and lib/data/models/sync/reminder_settings_model.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 and Phase 2.
2. Complete Phase 3 for user-visible sync direction, auth gating, and localization.
3. Stop and validate that local-only use still works while sync states render correctly.

### Incremental Delivery

1. Build the foundation once.
2. Deliver US1 as the first visible increment.
3. Deliver US2 to make the sync rules operational.
4. Deliver US3 to lock in documentation, diagnostics, and handoff quality.
5. Finish with the Polish phase and validation commands.

### Cheaper-Model Execution Notes

1. Execute tasks strictly in task-ID order unless a task is marked `[P]` and all its dependencies are already complete.
2. Do not combine multiple unchecked tasks into one edit unless they touch the same file group and same phase.
3. After each task, run the smallest relevant test from the task description before moving on.
4. When a task mentions generated files, update the source file first, then run the generator, then verify the generated output was refreshed.
5. If a task edits a file that already exists, extend the current implementation instead of replacing it.

---

## Notes

- All tasks follow the required checklist format.
- Total tasks: 69
- User story task counts:
  - `US1`: 15 tasks
  - `US2`: 19 tasks
  - `US3`: 7 tasks
- The recommended MVP scope is **Phase 1 + Phase 2 + User Story 1**.
- The highest-risk files are `lib/core/services/sync/sync_service.dart`, `lib/core/di/injector.dart`, `lib/main.dart`, and the localization files.
