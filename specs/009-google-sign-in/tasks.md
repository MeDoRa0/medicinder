# Tasks: Google Sign-In

**Input**: Design documents from `/specs/009-google-sign-in/`
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [quickstart.md](./quickstart.md), [contracts/](./contracts/)

**Tests**: Required. The constitution, plan, and feature scope require automated coverage for auth/session restoration, provider failure handling, sign-out behavior, localization/accessibility, unsupported-runner fallback, and user-scoped cloud state.

**Organization**: Tasks are grouped by user story and intentionally kept small, file-scoped, and explicit so a cheaper model can implement them with minimal inference.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel with other tasks in the same phase because it targets different files and has no dependency on incomplete work
- **[Story]**: User story label from `spec.md`
- Every task includes exact file paths

## Path Conventions

- **Flutter mobile app**: `lib/` for production code and `test/` for automated tests
- **Active startup entry point**: `lib/main.dart`
- **Do not rely on** `lib/presentation/main_app.dart` for this feature unless you intentionally switch the app to use it; the current startup flow is implemented in `lib/main.dart`
- **Existing Phase 1 auth-entry slice already exists** in `lib/presentation/pages/auth_entry_gate_page.dart`, `lib/presentation/pages/app_launch_router_page.dart`, `lib/presentation/cubit/auth/`, `lib/domain/usecases/auth/`, and `lib/data/repositories/app_entry_repository_impl.dart`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add the dependency and localized copy needed before any auth implementation starts.

- [X] T001 [P] Add the `google_sign_in` dependency to `pubspec.yaml`
- [X] T002 [P] Add Google loading, retryable failure, cancellation, and signed-out local-only copy to `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb`
- [X] T003 Regenerate localized outputs in `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, and `lib/l10n/app_localizations_ar.dart`

**Checkpoint**: Dependency and localized strings exist before code or tests reference them.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Create the shared provider-auth wiring and state contracts that all user stories build on.

**CRITICAL**: No user story work should begin until this phase is complete.

- [X] T004 [P] Create a Google provider adapter in `lib/data/datasources/auth/google_auth_provider_data_source.dart`
- [X] T005 [P] Extend the provider-aware auth contract in `lib/domain/repositories/auth_repository.dart`, `lib/data/repositories/auth_repository_impl.dart`, and `lib/domain/usecases/sync/sign_in_for_sync.dart`
- [X] T006 [P] Add the dedicated gate-facing use case in `lib/domain/usecases/auth/sign_in_with_google.dart`
- [X] T007 [P] Extend auth-entry presentation state for live provider attempts in `lib/presentation/cubit/auth/auth_entry_state.dart`
- [X] T008 [P] Make provider identity explicit in `lib/domain/entities/sync/auth_session.dart`
- [X] T009 Register the Google provider adapter and `SignInWithGoogle` use case in `lib/core/di/injector.dart`

**Implementation Notes**

- `T004`: Keep Google SDK details in `data`; do not import provider SDK classes into `domain` or `presentation`.
- `T005`: Preserve the existing auth repository as the single authenticated source of truth for both app-entry restore and sync status.
- `T006`: The gate should call `SignInWithGoogle`; do not make the gate depend directly on `SignInForSync`.
- `T008`: Preserve existing sync state semantics while making `google.com` a first-class provider identifier.
- `T009`: Keep existing Firebase bootstrap, Hive setup, and notification services intact.

**Checkpoint**: The repository has a provider-aware auth foundation ready for Google sign-in and session restoration.

---

## Phase 3: User Story 1 - Sign In With Google (Priority: P1) MVP

**Goal**: A user can start Google sign-in from the first-launch entry gate, complete it successfully, and enter the app as an authenticated user.

**Independent Test**: From a clean install with no resolved session, tap Google on the entry gate, complete the provider flow with a valid account, and confirm the app enters the settings/home path as an authenticated user without creating a duplicate workspace identity.

### Tests for User Story 1

- [X] T010 [P] [US1] Add `SignInWithGoogle` use case tests in `test/domain/usecases/auth/sign_in_with_google_test.dart`
- [ ] T011 [P] [US1] Add successful Google sign-in and workspace bootstrap tests in `test/data/datasources/auth/auth_remote_data_source_test.dart`
- [ ] T012 [P] [US1] Add tests for reusing an existing app user identity without duplicate workspace creation in `test/data/datasources/auth/auth_remote_data_source_test.dart`
- [X] T013 [P] [US1] Add auth-entry Cubit success and busy-state tests in `test/presentation/cubit/auth/auth_entry_cubit_test.dart`
- [X] T014 [P] [US1] Add widget tests for the enabled Google button, loading state, and forward routing in `test/widget/auth_entry_gate_test.dart` and `test/widget/app_launch_router_test.dart`
- [X] T015 [P] [US1] Add tests for unsupported-runner local-only fallback in `test/widget/auth_entry_gate_test.dart` and `test/data/datasources/auth/google_auth_provider_data_source_test.dart`

### Implementation for User Story 1

- [X] T016 [US1] Implement Google SDK interaction in `lib/data/datasources/auth/google_auth_provider_data_source.dart`
- [X] T017 [US1] Prevent live Google auth on unsupported runners and keep them local-only in `lib/data/datasources/auth/google_auth_provider_data_source.dart` and `lib/presentation/pages/auth_entry_gate_page.dart`
- [X] T018 [US1] Use Google credentials to sign in and bootstrap the Firestore workspace in `lib/data/datasources/auth/auth_remote_data_source.dart`
- [X] T019 [US1] Return authenticated Google app-entry sessions from `lib/domain/usecases/auth/sign_in_with_google.dart`
- [X] T020 [US1] Add the Google sign-in action to `lib/presentation/cubit/auth/auth_entry_cubit.dart`
- [X] T021 [US1] Enable the Google gate control and loading semantics in `lib/presentation/pages/auth_entry_gate_page.dart` and `lib/presentation/widgets/auth/auth_entry_option_button.dart`
- [X] T022 [US1] Keep authenticated launch routing in `lib/presentation/pages/app_launch_router_page.dart` so successful Google sign-in still respects meal-time setup before `HomePage`
- [ ] T023 [US1] Keep sync session readiness aligned with Google-authenticated users in `lib/presentation/cubit/sync/sync_status_cubit.dart`

**Implementation Notes**

- `T018`: A sign-in attempt is only successful after both provider approval and Firestore workspace/profile bootstrap succeed.
- `T019`: Map successful Google auth to `AppEntrySession.authenticated(entryMode: google)`; do not persist a local `"google"` marker in `SharedPreferences`.
- `T021`: Google becomes the only live provider button in this phase. Apple remains a disabled placeholder on iOS only.
- `T023`: Do not create a second authenticated session model for sync; reuse the existing `AuthSession` pipeline.

**Checkpoint**: A valid Google user can sign in from the gate and enter the app as an authenticated user.

---

## Phase 4: User Story 2 - Recover From Cancellation Or Failure (Priority: P2)

**Goal**: Cancelled or failed Google attempts return the user to a usable gate with clear, non-sensitive feedback and immediate retry support.

**Independent Test**: Start Google sign-in, cancel once and fail once, and confirm the gate remains visible, guest access remains available, no authenticated session is saved, and a retry can start without restarting the app.

### Tests for User Story 2

- [ ] T024 [P] [US2] Add Google cancellation and provider-failure tests in `test/data/datasources/auth/auth_remote_data_source_test.dart`
- [ ] T025 [P] [US2] Add Cubit retryable error and cancellation tests in `test/presentation/cubit/auth/auth_entry_cubit_test.dart`
- [ ] T026 [P] [US2] Add widget tests for localized Google failure feedback and guest fallback in `test/widget/auth_entry_gate_test.dart`

### Implementation for User Story 2

- [X] T027 [US2] Normalize cancellation versus failure mapping in `lib/data/datasources/auth/google_auth_provider_data_source.dart` and `lib/data/datasources/auth/auth_remote_data_source.dart`
- [X] T028 [US2] Keep auth-entry state retryable after cancelled or failed Google attempts in `lib/presentation/cubit/auth/auth_entry_state.dart` and `lib/presentation/cubit/auth/auth_entry_cubit.dart`
- [X] T029 [US2] Show non-sensitive localized Google failure and cancellation feedback in `lib/presentation/pages/auth_entry_gate_page.dart`
- [X] T030 [US2] Add coarse auth diagnostics for Google start, cancel, and fail outcomes in `lib/presentation/cubit/auth/auth_entry_cubit.dart` and `lib/data/datasources/auth/auth_remote_data_source.dart`

**Implementation Notes**

- `T027`: Cancellation must not be treated as success and must not save an authenticated session.
- `T028`: Retrying should start a fresh attempt without requiring app restart or process restart.
- `T029`: Use localization keys from Phase 1; do not surface raw exceptions, tokens, or provider payloads.
- `T030`: Keep logs coarse and supportable only. Never log OAuth tokens, raw credentials, or medication data.

**Checkpoint**: Failed or cancelled Google attempts leave the gate usable and safe.

---

## Phase 5: User Story 3 - Restore Authenticated Session On Later Launches (Priority: P3)

**Goal**: A returning Google-authenticated user bypasses the gate on relaunch, and signing out returns them to the gate instead of auto-continuing as guest.

**Independent Test**: Sign in with Google, relaunch to skip the gate, then sign out and confirm the app returns to the gate and the signed-out settings UI stays local-only without starting auth.

### Tests for User Story 3

- [X] T031 [P] [US3] Add restore-precedence tests for authenticated Google sessions versus guest markers in `test/domain/usecases/auth/app_entry_usecases_test.dart`
- [ ] T032 [P] [US3] Add sync-status sign-out and restored-session tests in `test/presentation/cubit/sync/sync_status_cubit_test.dart`
- [X] T033 [P] [US3] Add widget tests for authenticated relaunch skip-gate and post-sign-out gate return in `test/widget/app_launch_router_test.dart`

### Implementation for User Story 3

- [X] T034 [US3] Update `lib/domain/usecases/auth/restore_app_entry_session.dart` to consult `lib/domain/repositories/auth_repository.dart` before `lib/domain/repositories/app_entry_repository.dart`
- [X] T035 [US3] Return restored authenticated Google sessions from `lib/domain/entities/auth/app_entry_session.dart` and `lib/presentation/cubit/auth/auth_entry_cubit.dart`
- [X] T036 [US3] Clear app-entry resolution and authenticated sync state on sign-out in `lib/presentation/cubit/sync/sync_status_cubit.dart` and `lib/domain/usecases/auth/clear_app_entry_state.dart`
- [X] T037 [US3] Keep the signed-out settings surface local-only and non-entry-bearing in `lib/presentation/widgets/sync/sync_account_tile.dart` and `lib/presentation/cubit/sync/sync_status_state.dart`
- [X] T038 [US3] Ensure relaunch routing prefers restored authenticated sessions and returns to the gate after sign-out in `lib/presentation/pages/app_launch_router_page.dart` and `lib/main.dart`

**Implementation Notes**

- `T034`: Read the current Firebase-backed auth session first. Only if it is signed out should the restore flow consult the guest marker.
- `T035`: Restored authenticated state must map to Google only in this phase.
- `T036`: Sign-out must clear the app-entry resolved state and must not create an automatic guest session.
- `T037`: The signed-out settings tile may show local-only status text, but it must not trigger Google sign-in in this phase.

**Checkpoint**: Returning Google users skip the gate on relaunch, and sign-out reliably restores the gate.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, documentation alignment, and cleanup across all stories.

- [ ] T039 [P] Update the implementation and manual validation steps in `specs/009-google-sign-in/quickstart.md`
- [ ] T040 [P] Validate auth restoration and sync-state behavior after app background/resume in `specs/009-google-sign-in/quickstart.md` and `test/widget/app_launch_router_test.dart`
- [ ] T041 Run and fix focused auth/session tests in `test/domain/usecases/auth/sign_in_with_google_test.dart`, `test/domain/usecases/auth/app_entry_usecases_test.dart`, `test/data/datasources/auth/auth_remote_data_source_test.dart`, `test/data/datasources/auth/google_auth_provider_data_source_test.dart`, `test/presentation/cubit/auth/auth_entry_cubit_test.dart`, `test/presentation/cubit/sync/sync_status_cubit_test.dart`, `test/widget/auth_entry_gate_test.dart`, and `test/widget/app_launch_router_test.dart`
- [X] T042 Run analyzer cleanup for the auth feature touch points in `lib/core/di/injector.dart`, `lib/data/datasources/auth/google_auth_provider_data_source.dart`, `lib/data/datasources/auth/auth_remote_data_source.dart`, `lib/domain/usecases/auth/sign_in_with_google.dart`, `lib/domain/usecases/auth/restore_app_entry_session.dart`, `lib/presentation/cubit/auth/auth_entry_cubit.dart`, `lib/presentation/pages/auth_entry_gate_page.dart`, `lib/presentation/pages/app_launch_router_page.dart`, and `lib/presentation/widgets/sync/sync_account_tile.dart`
- [X] T043 [P] Validate localized copy, accessibility semantics, unsupported-runner behavior, and non-sensitive diagnostics in `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`, `lib/presentation/pages/auth_entry_gate_page.dart`, `lib/presentation\widgets\sync\sync_account_tile.dart`, and `lib\data\datasources\auth\google_auth_provider_data_source.dart`

**Checkpoint**: The feature is documented, testable, analyzer-clean, and aligned with the phase boundary.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup** has no dependencies and starts immediately.
- **Phase 2: Foundational** depends on Phase 1 and blocks all user stories.
- **Phase 3: US1** depends on Phase 2 and delivers the MVP Google sign-in path.
- **Phase 4: US2** depends on US1 because cancellation and failure handling build on the live Google sign-in flow.
- **Phase 5: US3** depends on US1 and is safest after US2 because restoration and sign-out should reuse the final failure-safe auth state model.
- **Phase 6: Polish** depends on all desired user stories being complete.

### User Story Dependencies

- **US1 (P1)**: No dependency on other stories after Phase 2.
- **US2 (P2)**: Depends on US1.
- **US3 (P3)**: Depends on US1 and should follow US2 for the simplest implementation order.

### Within Each User Story

- Write tests first and make sure they fail before implementation.
- Keep provider SDK code in `data`, state contracts in `domain`, and route/UI logic in `presentation`.
- Do not persist authenticated Google state in `SharedPreferences`.
- Do not add a second Google entry point outside the first-launch gate in this feature.
- Finish the story checkpoint before moving to the next priority.

### Parallel Opportunities

- `T001` and `T002` can run in parallel in Phase 1.
- `T004`, `T005`, `T006`, `T007`, and `T008` can run in parallel in Phase 2.
- `T010`, `T011`, `T012`, `T013`, `T014`, and `T015` can run in parallel for US1.
- `T024`, `T025`, and `T026` can run in parallel for US2.
- `T031`, `T032`, and `T033` can run in parallel for US3.
- `T039`, `T040`, and `T043` can run in parallel during polish once implementation is stable.

---

## Parallel Example: Foundational Phase

```text
Task: "T004 Create a Google provider adapter in lib/data/datasources/auth/google_auth_provider_data_source.dart"
Task: "T005 Extend the provider-aware auth contract in lib/domain/repositories/auth_repository.dart, lib/data/repositories/auth_repository_impl.dart, and lib/domain/usecases/sync/sign_in_for_sync.dart"
Task: "T006 Add the dedicated gate-facing use case in lib/domain/usecases/auth/sign_in_with_google.dart"
Task: "T007 Extend auth-entry presentation state for live provider attempts in lib/presentation/cubit/auth/auth_entry_state.dart"
Task: "T008 Make provider identity explicit in lib/domain/entities/sync/auth_session.dart"
```

## Parallel Example: User Story 1

```text
Task: "T010 Add SignInWithGoogle use case tests in test/domain/usecases/auth/sign_in_with_google_test.dart"
Task: "T011 Add successful Google sign-in and workspace bootstrap tests in test/data/datasources/auth/auth_remote_data_source_test.dart"
Task: "T012 Add tests for reusing an existing app user identity without duplicate workspace creation in test/data/datasources/auth/auth_remote_data_source_test.dart"
Task: "T013 Add auth-entry Cubit success and busy-state tests in test/presentation/cubit/auth/auth_entry_cubit_test.dart"
Task: "T015 Add tests for unsupported-runner local-only fallback in test/widget/auth_entry_gate_test.dart and test/data/datasources/auth/google_auth_provider_data_source_test.dart"
```

## Parallel Example: User Story 3

```text
Task: "T031 Add restore-precedence tests for authenticated Google sessions versus guest markers in test/domain/usecases/auth/app_entry_usecases_test.dart"
Task: "T032 Add sync-status sign-out and restored-session tests in test/presentation/cubit/sync/sync_status_cubit_test.dart"
Task: "T033 Add widget tests for authenticated relaunch skip-gate and post-sign-out gate return in test/widget/app_launch_router_test.dart"
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Complete Phase 1.
2. Complete Phase 2.
3. Complete Phase 3 (US1).
4. Run the US1 tests and validate one successful Google sign-in path before touching cancellation or restoration behavior.

### Incremental Delivery

1. Add the dependency, localized copy, and provider-aware auth foundation.
2. Deliver the successful Google sign-in path from the entry gate.
3. Add cancellation and failure handling without changing the success path.
4. Add authenticated relaunch and sign-out routing.
5. Finish with focused validation and cleanup.

### Small-Model Execution Guidance

1. Do not redesign the existing sync engine or medication sync logic.
2. Reuse the current `AuthRepository` and `AuthSession` pipeline instead of creating a second authenticated session source.
3. Keep `SharedPreferences` limited to guest persistence only.
4. Keep Google sign-in available only from `lib/presentation/pages/auth_entry_gate_page.dart` in this phase.
5. Do not make the signed-out settings tile an alternate sign-in surface.
6. Keep Firestore user bootstrap under `users/{userId}` and reuse the existing workspace initialization path.
7. On unsupported runners, keep the app compile-safe and local-only rather than attempting live Google auth.
8. If a task changes routing, re-run `test/widget/app_launch_router_test.dart` before moving on.

---

## Notes

- Total tasks: 43
- User story task counts:
  - **US1**: 14 tasks
  - **US2**: 7 tasks
  - **US3**: 8 tasks
- Parallel opportunities identified: setup, foundational contract work, all story test batches, and selected polish tasks
- Suggested MVP scope: Phase 1 + Phase 2 + Phase 3 only
- Format validation: every task uses the required checkbox, task ID, optional `[P]`, required `[US#]` for story phases, and exact file paths
