# Tasks: Firebase Backend Integration

**Input**: Design documents from `/specs/002-firebase-backend/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Automated tests are required for this feature because the plan, constitution, and quickstart call for repository/data-source and presentation-layer verification.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g. `US1`, `US2`, `US3`)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare Firebase-backed Phase 2 workspaces, configs, and planning artifacts for implementation.

- [X] T001 Verify Firebase dependencies and platform setup expectations in `pubspec.yaml`, `android/`, `ios/`, and `specs/002-firebase-backend/quickstart.md`
- [X] T002 Verify Firebase runtime configuration assumptions in `lib/main.dart`, `lib/core/di/injector.dart`, and `specs/002-firebase-backend/quickstart.md`
- [X] T003 [P] Review current sync/auth integration points in `lib/core/di/injector.dart`, `lib/data/repositories/auth_repository_impl.dart`, and `lib/presentation/cubit/sync/sync_status_cubit.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before any user story work can be implemented safely.

- [X] T004 Define provider-extensible auth and workspace-ready domain contracts in `lib/domain/entities/sync/auth_session.dart`, `lib/domain/repositories/auth_repository.dart`, and `lib/domain/usecases/sync/sign_in_for_sync.dart`
- [X] T005 [P] Add cloud workspace and profile models plus serialization support in `lib/domain/entities/sync/user_sync_profile.dart`, `lib/data/models/sync/user_sync_profile_model.dart`, and generated model files under `lib/data/models/sync/`
- [ ] T006 [P] Extend failure and diagnostics support for auth/cloud backend flows in `lib/core/error/failures.dart`, `lib/core/error/error_handler.dart`, and `lib/core/services/sync/sync_diagnostics.dart`
- [X] T007 Wire Firebase initialization and backend feature registration in `lib/main.dart` and `lib/core/di/injector.dart`
- [X] T008 Add localized strings for Phase 2 auth, workspace, and cloud failure states in `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`, and generated localization files under `lib/l10n/`

**Checkpoint**: Foundation ready for user-scoped auth, workspace creation, repository guards, and localized status messaging.

---

## Phase 3: User Story 1 - Access Personal Cloud Workspace (Priority: P1) MVP

**Goal**: Let a user sign in, restore session state, and gain access only to their own initialized cloud workspace.

**Independent Test**: Sign in from a signed-out app state, confirm the workspace is created automatically on first use, restore the session successfully, and verify sign-out removes cloud-backed access.

### Tests for User Story 1

- [X] T009 [P] [US1] Add auth session mapping and sign-in/sign-out use case coverage in `test/domain/usecases/sync/auth_session_usecases_test.dart`
- [ ] T010 [P] [US1] Add auth remote data source coverage for session restore and workspace bootstrap behavior in `test/data/datasources/auth/auth_remote_data_source_test.dart`
- [X] T011 [P] [US1] Add sync status cubit coverage for signed-out, signed-in, and workspace-ready states in `test/presentation/cubit/sync/sync_status_cubit_test.dart`
- [X] T012 [P] [US1] Add widget coverage for account access states in `test/widget/sync_status_banner_test.dart` and `test/widget/sync_accessibility_test.dart`
- [ ] T013 [P] [US1] Add regression coverage for app start-up session restore and background resume auth revalidation in `test/presentation/cubit/sync/sync_status_cubit_test.dart` and `test/core/services/sync/sync_service_test.dart`

### Implementation for User Story 1

- [X] T014 [US1] Implement provider-aware auth session state and workspace readiness in `lib/domain/entities/sync/auth_session.dart`
- [X] T015 [US1] Replace anonymous-only auth behavior with a provider-extensible session contract in `lib/data/datasources/auth/auth_remote_data_source.dart` and `lib/data/repositories/auth_repository_impl.dart`
- [X] T016 [US1] Implement automatic cloud workspace creation and profile bootstrap in `lib/data/datasources/auth/auth_remote_data_source.dart` and `lib/data/datasources/sync_state_local_data_source.dart`
- [X] T017 [US1] Update auth use cases and dependency injection for the new workspace-ready contract in `lib/domain/usecases/sync/sign_in_for_sync.dart`, `lib/domain/usecases/sync/watch_auth_session.dart`, `lib/domain/usecases/sync/sign_out_from_sync.dart`, and `lib/core/di/injector.dart`
- [X] T018 [US1] Surface signed-out, signing-in, workspace-initializing, ready, access-denied, and signed-out-after-sign-out states in `lib/presentation/cubit/sync/sync_status_cubit.dart`, `lib/presentation/cubit/sync/sync_status_state.dart`, and `lib/presentation/widgets/sync/sync_account_tile.dart`

**Checkpoint**: User Story 1 is complete when account access is isolated per user, first sign-in creates the workspace automatically, and signed-out users remain local-only.

---

## Phase 4: User Story 2 - Store Personal Health Data Securely (Priority: P2)

**Goal**: Persist in-scope cloud-backed records under the authenticated user workspace with stable identifiers and last-changed timestamps.

**Independent Test**: With a valid signed-in session, create and update supported cloud-backed records, verify they are stored only under the current user's workspace, and confirm repository calls fail fast without user context.

### Tests for User Story 2

- [ ] T019 [P] [US2] Add repository contract tests for user-scoped cloud CRUD guards in `test/data/repositories/medication_repository_impl_test.dart`
- [ ] T020 [P] [US2] Add Firestore remote data source tests for user-scoped medication write, read, and delete behavior in `test/data/datasources/medication_remote_data_source_test.dart`
- [ ] T021 [P] [US2] Add user profile workspace persistence tests in `test/data/datasources/auth/auth_remote_data_source_test.dart`
- [ ] T022 [P] [US2] Add schedule and notification setting remote data source tests in `test/data/datasources/medication_schedule_remote_data_source_test.dart` and `test/data/datasources/notification_settings_remote_data_source_test.dart`
- [ ] T023 [P] [US2] Add integration-style sync service coverage for authenticated repository readiness and stale local state recovery in `test/core/services/sync/sync_service_test.dart`

### Implementation for User Story 2

- [ ] T024 [P] [US2] Extend sync metadata and shared cloud record shape in `lib/domain/entities/sync_metadata.dart`, `lib/data/models/sync/conflict_metadata_model.dart`, and `lib/data/models/medication_model.dart`
- [ ] T025 [P] [US2] Add user profile and workspace cloud models in `lib/domain/entities/sync/user_sync_profile.dart` and `lib/data/models/sync/user_sync_profile_model.dart`
- [ ] T026 [P] [US2] Add medication schedule cloud models in `lib/domain/entities/sync/medication_schedule_record.dart` and `lib/data/models/sync/medication_schedule_record_model.dart`
- [ ] T027 [P] [US2] Add notification settings cloud models in `lib/domain/entities/sync/notification_preference_record.dart` and `lib/data/models/sync/notification_preference_record_model.dart`
- [ ] T028 [US2] Implement user-scoped Firestore collections and guards for medications in `lib/data/datasources/medication_remote_data_source.dart`
- [ ] T029 [US2] Implement user-scoped Firestore persistence for schedules in `lib/data/datasources/medication_schedule_remote_data_source.dart`
- [ ] T030 [US2] Implement user-scoped Firestore persistence for notification settings in `lib/data/datasources/notification_settings_remote_data_source.dart`
- [ ] T031 [US2] Implement repository-layer enforcement of authenticated cloud CRUD contracts in `lib/domain/repositories/medication_repository.dart`, `lib/data/repositories/medication_repository_impl.dart`, and `lib/domain/repositories/sync_repository.dart`
- [ ] T032 [US2] Preserve stable identifiers and last-changed timestamps during cloud writes and reads in `lib/data/datasources/medication_remote_data_source.dart`, `lib/data/datasources/medication_schedule_remote_data_source.dart`, `lib/data/datasources/notification_settings_remote_data_source.dart`, and related model mapping files under `lib/data/models/`

**Checkpoint**: User Story 2 is complete when signed-in users can persist supported cloud-backed records in their own workspace and unauthenticated or cross-user access is blocked.

---

## Phase 5: User Story 3 - Recover Gracefully From Backend Setup Problems (Priority: P3)

**Goal**: Show clear non-destructive failure states when authentication or cloud access cannot complete.

**Independent Test**: Simulate backend misconfiguration, denied access, and sign-in failure; verify the app keeps local workflows available and shows actionable cloud error messaging.

### Tests for User Story 3

- [ ] T033 [P] [US3] Add failure-path coverage for auth, access-denied, and partial cloud save diagnostics in `test/domain/usecases/sync/auth_session_usecases_test.dart` and `test/core/services/sync/sync_service_test.dart`
- [ ] T034 [P] [US3] Add widget coverage for localized auth/cloud failure messaging in `test/widget/sync_status_banner_test.dart` and `test/widget/sync_accessibility_test.dart`

### Implementation for User Story 3

- [ ] T035 [US3] Implement recoverable auth and workspace initialization failures in `lib/data/datasources/auth/auth_remote_data_source.dart` and `lib/data/repositories/auth_repository_impl.dart`
- [ ] T036 [US3] Implement recoverable cloud repository failure mapping for medications, schedules, and notification settings in `lib/data/datasources/medication_remote_data_source.dart`, `lib/data/datasources/medication_schedule_remote_data_source.dart`, `lib/data/datasources/notification_settings_remote_data_source.dart`, `lib/data/repositories/medication_repository_impl.dart`, and `lib/core/error/failures.dart`
- [ ] T037 [US3] Surface localized failure, access-denied, and sign-out reset messaging in `lib/presentation/cubit/sync/sync_status_cubit.dart`, `lib/presentation/widgets/sync/sync_status_banner.dart`, and `lib/presentation/widgets/sync/sync_account_tile.dart`
- [ ] T038 [US3] Emit non-sensitive diagnostics for auth and cloud backend failures in `lib/core/services/sync/sync_diagnostics.dart` and integration points under `lib/presentation/cubit/sync/`

**Checkpoint**: User Story 3 is complete when backend failures are visible, local medication tracking still works, and diagnostics support debugging without leaking sensitive data.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Finish cross-story verification, cleanup, and documentation.

- [ ] T039 [P] Regenerate generated files and verify localization/model outputs in `lib/l10n/` and generated Hive model files under `lib/data/models/`
- [ ] T040 Run Phase 2 quickstart validation plus startup, background resume, and stale local state regression checks from `specs/002-firebase-backend/quickstart.md` and record follow-up notes in `specs/002-firebase-backend/plan.md`
- [ ] T041 [P] Update Phase 2 documentation references and implementation notes in `specs/002-firebase-backend/quickstart.md`, `specs/002-firebase-backend/research.md`, and `AGENTS.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup**: Starts immediately
- **Phase 2: Foundational**: Depends on Setup and blocks all user stories
- **Phase 3: US1**: Depends on Foundational completion
- **Phase 4: US2**: Depends on Foundational completion and benefits from US1 auth/session changes
- **Phase 5: US3**: Depends on Foundational completion and should be completed after the relevant US1 and US2 failure points exist
- **Phase 6: Polish**: Depends on all targeted user stories being complete

### User Story Dependencies

- **US1 (P1)**: No dependency on other user stories after foundational work
- **US2 (P2)**: Requires the authenticated session and workspace contract from US1
- **US3 (P3)**: Requires auth and repository failure surfaces from US1 and US2

### Within Each User Story

- Tests should be written first and fail before implementation
- Domain contracts and models precede repository and data-source work
- Repository and data-source changes precede Cubit and widget integration
- Localized copy updates must land before final widget-state validation

### Parallel Opportunities

- `T005`, `T006`, and `T008` can run in parallel during foundational work
- `T009` through `T013` can run in parallel within US1 test preparation
- `T019` through `T023` can run in parallel within US2 test preparation
- `T024` through `T027` can run in parallel before repository integration in US2
- `T033` and `T034` can run in parallel within US3 test preparation
- `T039` and `T041` can run in parallel during polish

---

## Parallel Example: User Story 1

```text
T009 test/domain/usecases/sync/auth_session_usecases_test.dart
T010 test/data/datasources/auth/auth_remote_data_source_test.dart
T011 test/presentation/cubit/sync/sync_status_cubit_test.dart
T012 test/widget/sync_status_banner_test.dart and test/widget/sync_accessibility_test.dart
T013 test/presentation/cubit/sync/sync_status_cubit_test.dart and test/core/services/sync/sync_service_test.dart
```

## Parallel Example: User Story 2

```text
T019 test/data/repositories/medication_repository_impl_test.dart
T020 test/data/datasources/medication_remote_data_source_test.dart
T021 test/data/datasources/auth/auth_remote_data_source_test.dart
T022 test/data/datasources/medication_schedule_remote_data_source_test.dart and test/data/datasources/notification_settings_remote_data_source_test.dart
T023 test/core/services/sync/sync_service_test.dart
```

## Parallel Example: User Story 3

```text
T033 test/domain/usecases/sync/auth_session_usecases_test.dart and test/core/services/sync/sync_service_test.dart
T034 test/widget/sync_status_banner_test.dart and test/widget/sync_accessibility_test.dart
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. Validate sign-in, workspace creation, and sign-out behavior independently
5. Stop for review before expanding cloud CRUD scope

### Incremental Delivery

1. Setup + Foundational establish Firebase wiring, failures, localization, and workspace contracts
2. US1 delivers account-gated cloud access
3. US2 delivers secure user-scoped cloud persistence
4. US3 delivers graceful failure handling and diagnostics
5. Polish regenerates generated outputs and validates the quickstart flow

### Parallel Team Strategy

1. One developer handles foundational auth/session contracts while another prepares localization and diagnostics
2. After US1 stabilizes, data/repository work for US2 can proceed in parallel with presentation-failure work for US3
3. Polish and generated-file validation can run in parallel with final bug fixes

---

## Notes

- All tasks follow the required checklist format with IDs, optional `[P]` markers, story labels where required, and concrete file paths.
- User stories remain independently testable: US1 covers access, US2 covers secure storage, and US3 covers recoverable failure handling.
- Automatic bidirectional sync, offline queue replay, and notification rescheduling are intentionally excluded from this task list because they are out of scope for Phase 2.
