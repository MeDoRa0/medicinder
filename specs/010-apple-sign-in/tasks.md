# Tasks: Apple Sign-In for iOS

**Input**: Design documents from `/specs/010-apple-sign-in/`
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [quickstart.md](./quickstart.md), [contracts/](./contracts/)

**Tests**: Required. The constitution, plan, and feature scope require automated coverage for auth/session restoration, provider failure handling, sign-out behavior, localization/accessibility, iOS availability gating, conflict blocking, and user-scoped cloud state.

**Organization**: Tasks are grouped by user story and intentionally kept small, explicit, and file-scoped so a cheaper model can implement them with minimal inference.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel with other tasks in the same phase because it targets different files and has no dependency on incomplete work
- **[Story]**: User story label from `spec.md`
- Every task includes exact file paths

## Path Conventions

- **Flutter mobile app**: `lib/` for production code and `test/` for automated tests
- **iOS runner files**: `ios/Runner/`, `ios/Runner.xcodeproj/`
- **Active startup entry flow**: `lib/main.dart`, `lib/presentation/pages/app_launch_router_page.dart`, and `lib/presentation/pages/auth_entry_gate_page.dart`
- **Existing shared auth pipeline** already lives in `lib/data/datasources/auth/auth_remote_data_source.dart`, `lib/data/repositories/auth_repository_impl.dart`, `lib/domain/repositories/auth_repository.dart`, and `lib/domain/entities/sync/auth_session.dart`
- **Do not create a second authenticated session source** outside the existing `AuthRepository` and `AuthSession` pipeline

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add the dependency and localized copy required before any Apple auth code or tests reference them.

- [X] T001 [P] Add the `sign_in_with_apple` dependency to `pubspec.yaml`
- [X] T002 [P] Replace Apple placeholder copy and add Apple loading, cancellation, failure, conflict, and unavailable-device strings in `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb`
- [X] T003 Regenerate localization outputs in `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, and `lib/l10n/app_localizations_ar.dart`

**Checkpoint**: Dependency and localized Apple strings exist before any new production or test code references them.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Create the shared Apple provider contracts and iOS capability scaffolding that all user stories depend on.

**CRITICAL**: No user story work should begin until this phase is complete.

- [X] T004 [P] Create `AppleAuthAvailability`, `AppleAuthProviderStatus`, and provider result value types in `lib/data/datasources/auth/apple_auth_provider_data_source.dart`
- [X] T005 [P] Create the gate-facing `SignInWithApple` use case scaffold in `lib/domain/usecases/auth/sign_in_with_apple.dart`
- [X] T006 [P] Extend `AuthEntryState` with Apple availability and Apple in-progress feedback slots in `lib/presentation/cubit/auth/auth_entry_state.dart`
- [X] T007 [P] Add Apple Sign-In capability scaffolding in `ios/Runner/Info.plist`, `ios/Runner/Runner.entitlements`, and `ios/Runner.xcodeproj/project.pbxproj`
- [X] T008 Keep `apple.com` as an allowed provider input in `lib/domain/repositories/auth_repository.dart` and `lib/domain/usecases/sync/sign_in_for_sync.dart`

**Implementation Notes**

- `T004`: Keep Apple SDK details in `data`; do not import Apple provider packages into `domain` or `presentation`.
- `T005`: Mirror the existing `SignInWithGoogle` pattern instead of inventing a second app-entry flow.
- `T006`: Keep Google state behavior intact while adding Apple-specific state fields.
- `T007`: Only add the minimum iOS capability/configuration required for Apple Sign-In; do not change unrelated runner settings.
- `T008`: The repository contract stays provider-driven; the Apple provider will still be implemented through the same `signInForSync(providerId: ...)` entry point.

**Checkpoint**: The repo has a clear Apple provider contract, Apple-aware entry state, and iOS capability scaffolding ready for implementation.

---

## Phase 3: User Story 1 - Sign In With Apple on iOS (Priority: P1) MVP

**Goal**: An iOS user can start Apple sign-in from the first-launch entry gate, complete it successfully, and enter the app as an authenticated user.

**Independent Test**: From a clean install on an iOS device with Apple Sign-In available, tap Apple on the entry gate, complete the provider flow with a valid Apple account, and confirm the app reaches the authenticated settings/home path without creating a duplicate cloud identity.

### Tests for User Story 1

- [X] T009 [P] [US1] Create Apple availability and successful credential result tests in `test/data/datasources/auth/apple_auth_provider_data_source_test.dart`
- [X] T010 [P] [US1] Create success mapping tests for `SignInWithApple` in `test/domain/usecases/auth/sign_in_with_apple_test.dart`
- [X] T011 [P] [US1] Create Apple credential exchange and workspace bootstrap success tests in `test/data/datasources/auth/auth_remote_data_source_test.dart`
- [X] T012 [P] [US1] Add stable-identity-only Apple restoration tests when email and name are absent in `test/data/datasources/auth/auth_remote_data_source_test.dart` and `test/domain/usecases/auth/sign_in_with_apple_test.dart`
- [X] T013 [P] [US1] Add Apple success and Apple-loading tests in `test/presentation/cubit/auth/auth_entry_cubit_test.dart`
- [X] T014 [P] [US1] Add enabled Apple button and authenticated Apple routing tests in `test/widget/auth_entry_gate_test.dart` and `test/widget/app_launch_router_test.dart`

### Implementation for User Story 1

- [X] T015 [US1] Implement real Apple availability checks and provider credential retrieval in `lib/data/datasources/auth/apple_auth_provider_data_source.dart`
- [X] T016 [US1] Route `providerId: 'apple.com'` through Apple credential exchange and workspace bootstrap in `lib/data/datasources/auth/auth_remote_data_source.dart`
- [X] T017 [US1] Preserve stable Apple identity as the restore key when optional profile fields are missing in `lib/data/datasources/auth/auth_remote_data_source.dart`
- [X] T018 [US1] Return `AppEntrySession.authenticated(entryMode: AppEntryMode.apple)` from `lib/domain/usecases/auth/sign_in_with_apple.dart`
- [X] T019 [US1] Register `AppleAuthProviderDataSource` and `SignInWithApple` in `lib/core/di/injector.dart`
- [X] T020 [US1] Add `loadAppleAvailability()` and `signInWithApple()` flows to `lib/presentation/cubit/auth/auth_entry_cubit.dart`
- [X] T021 [US1] Trigger Apple availability loading when the entry gate opens in `lib/presentation/pages/auth_entry_gate_page.dart`
- [X] T022 [US1] Replace the Apple placeholder button with live iOS Apple button behavior in `lib/presentation/pages/auth_entry_gate_page.dart`

**Implementation Notes**

- `T015`: The Apple data source must report availability separately from sign-in results so the gate can disable Apple on an unavailable iOS device without launching auth.
- `T016`: A sign-in attempt is only successful after Apple approval, Firebase credential exchange, and Firestore workspace/profile bootstrap all succeed.
- `T017`: Returning-user recognition must remain stable even when Apple does not resend email or name.
- `T018`: Do not persist a local `"apple"` marker in `SharedPreferences`; authenticated restoration must remain Firebase-managed.
- `T019`: Keep the existing Google registration untouched while adding Apple.
- `T022`: Non-iOS runners must still hide Apple entirely, while iOS devices with Apple unavailable must show Apple as disabled.

**Checkpoint**: A valid iOS Apple user can sign in from the gate and enter the app as an authenticated user.

---

## Phase 4: User Story 2 - Recover From Cancellation Or Failure (Priority: P2)

**Goal**: Cancelled, failed, unavailable, or conflict-blocked Apple attempts return the user to a usable gate with clear, non-sensitive feedback and immediate retry support.

**Independent Test**: On iOS, cancel one Apple attempt, simulate one provider/bootstrap failure, and simulate one conflict with an existing non-Apple account; confirm the gate remains visible, guest access remains available, no authenticated session is saved, and a retry can start without restarting the app.

### Tests for User Story 2

- [X] T023 [P] [US2] Add Apple cancelled, unavailable-device, and provider-failure tests in `test/data/datasources/auth/apple_auth_provider_data_source_test.dart`
- [X] T024 [P] [US2] Add conflict-blocked and workspace-bootstrap failure tests in `test/data/datasources/auth/auth_remote_data_source_test.dart`
- [X] T025 [P] [US2] Add retryable Apple failure and conflict-feedback tests in `test/presentation/cubit/auth/auth_entry_cubit_test.dart`
- [X] T026 [P] [US2] Add widget tests for disabled unavailable Apple state and localized Apple error feedback in `test/widget/auth_entry_gate_test.dart`

### Implementation for User Story 2

- [X] T027 [US2] Map Apple cancellation, unavailable-device, and provider failures to stable non-sensitive codes in `lib/data/datasources/auth/apple_auth_provider_data_source.dart`
- [X] T028 [US2] Block cross-provider conflicts and workspace-bootstrap failures in `lib/data/datasources/auth/auth_remote_data_source.dart`
- [X] T029 [US2] Keep Apple attempts retryable and return the gate to unresolved state in `lib/presentation/cubit/auth/auth_entry_cubit.dart`
- [X] T030 [US2] Show localized Apple cancellation, failure, conflict, and unavailable-device feedback in `lib/presentation/pages/auth_entry_gate_page.dart`
- [X] T031 [US2] Add coarse Apple diagnostics without tokens or raw payloads in `lib/data/datasources/auth/apple_auth_provider_data_source.dart`, `lib/data/datasources/auth/auth_remote_data_source.dart`, and `lib/presentation/cubit/auth/auth_entry_cubit.dart`

**Implementation Notes**

- `T025`: Use stable machine-readable codes that the UI can map to localized text; do not expose raw Apple/Firebase exceptions directly.
- `T026`: Conflict blocking must not auto-link accounts and must not create a new authenticated session or duplicate user workspace.
- `T027`: Retry should start a fresh Apple attempt without app restart.
- `T028`: Keep Google and guest controls usable when Apple fails or is unavailable.
- `T029`: Logs must remain supportable and non-sensitive only.

**Checkpoint**: Apple failure cases leave the gate usable, safe, and clear.

---

## Phase 5: User Story 3 - Restore Apple Session On Later Launches (Priority: P3)

**Goal**: A returning Apple-authenticated user bypasses the gate on relaunch, and signing out returns them to the gate instead of auto-continuing as guest.

**Independent Test**: Sign in with Apple on iOS, relaunch to skip the gate, then sign out and confirm the app returns to the gate and the signed-out settings UI stays local-only without starting Apple auth.

### Tests for User Story 3

- [X] T032 [P] [US3] Add restored Apple session precedence tests in `test/domain/usecases/auth/app_entry_usecases_test.dart`
- [X] T033 [P] [US3] Add unrestorable Apple session fallback tests in `test/domain/usecases/auth/app_entry_usecases_test.dart` and `test/widget/app_launch_router_test.dart`
- [X] T034 [P] [US3] Add Apple sign-out and restored-session sync tests in `test/presentation/cubit/sync/sync_status_cubit_test.dart`
- [X] T035 [P] [US3] Add widget tests for Apple relaunch skip-gate and post-sign-out gate return in `test/widget/app_launch_router_test.dart`

### Implementation for User Story 3

- [X] T036 [US3] Restore `apple.com` sessions as `AppEntryMode.apple` in `lib/domain/usecases/auth/restore_app_entry_session.dart`
- [X] T037 [US3] Clear broken Apple-authenticated restore state and return to the gate in `lib/domain/usecases/auth/restore_app_entry_session.dart` and `lib/presentation/pages/app_launch_router_page.dart`
- [X] T038 [US3] Keep restored Apple sessions routable through `lib/presentation/cubit/auth/auth_entry_cubit.dart` and `lib/presentation/pages/app_launch_router_page.dart`
- [X] T039 [US3] Ensure sign-out clears Apple entry resolution and returns to the gate in `lib/presentation/cubit/sync/sync_status_cubit.dart` and `lib/domain/usecases/auth/clear_app_entry_state.dart`
- [X] T040 [US3] Preserve the signed-out settings surface as local-only without adding an Apple upgrade entry point in `lib/presentation/widgets/sync/sync_account_tile.dart`

**Implementation Notes**

- `T036`: Read the current Firebase-backed auth session first. Only if it is signed out should restore fall back to the guest marker.
- `T037`: Unrestorable or invalid Apple-authenticated state must clear back to the gate instead of leaving the app partially signed in.
- `T038`: Do not change the existing meal-time/home routing rules; only add Apple as another authenticated entry mode.
- `T039`: Sign-out must clear app-entry resolution and must not create an automatic guest session.
- `T040`: The settings tile may describe local-only state, but it must not become a second Apple sign-in surface in this phase.

**Checkpoint**: Returning Apple users skip the gate on relaunch, and sign-out reliably restores the gate.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, documentation alignment, and cleanup across all stories.

- [X] T041 [P] Update Apple Sign-In validation steps and iOS setup notes in `specs/010-apple-sign-in/quickstart.md`
- [X] T042 [P] Validate Apple-authenticated background resume behavior in `specs/010-apple-sign-in/quickstart.md` and `test/widget/app_launch_router_test.dart`
- [X] T043 [P] Validate stale local state and unrestorable-session recovery in `specs/010-apple-sign-in/quickstart.md`, `test/domain/usecases/auth/app_entry_usecases_test.dart`, and `test/widget/app_launch_router_test.dart`
- [X] T044 Run and fix focused Apple auth tests in `test/data/datasources/auth/apple_auth_provider_data_source_test.dart`, `test/data/datasources/auth/auth_remote_data_source_test.dart`, `test/domain/usecases/auth/sign_in_with_apple_test.dart`, `test/domain/usecases/auth/app_entry_usecases_test.dart`, `test/presentation/cubit/auth/auth_entry_cubit_test.dart`, `test/presentation/cubit/sync/sync_status_cubit_test.dart`, `test/widget/auth_entry_gate_test.dart`, and `test/widget/app_launch_router_test.dart`
- [X] T045 Run analyzer cleanup for `lib/core/di/injector.dart`, `lib/data/datasources/auth/apple_auth_provider_data_source.dart`, `lib/data/datasources/auth/auth_remote_data_source.dart`, `lib/domain/usecases/auth/sign_in_with_apple.dart`, `lib/domain/usecases/auth/restore_app_entry_session.dart`, `lib/presentation/cubit/auth/auth_entry_cubit.dart`, `lib/presentation/pages/auth_entry_gate_page.dart`, and `lib/presentation/pages/app_launch_router_page.dart`
- [X] T046 [P] Validate English/Arabic copy, accessibility semantics, iOS unavailable-device state, and non-iOS hidden Apple behavior in `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`, `lib/presentation/pages/auth_entry_gate_page.dart`, and `test/widget/auth_entry_gate_test.dart`

**Checkpoint**: The feature is documented, testable, analyzer-clean, and aligned with the approved phase boundary.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup** has no dependencies and starts immediately.
- **Phase 2: Foundational** depends on Phase 1 and blocks all user stories.
- **Phase 3: US1** depends on Phase 2 and delivers the MVP Apple sign-in path.
- **Phase 4: US2** depends on US1 because cancellation, conflict, and failure handling build on the live Apple sign-in flow.
- **Phase 5: US3** depends on US1 and is safest after US2 because restoration and sign-out should reuse the final failure-safe Apple state model.
- **Phase 6: Polish** depends on all desired user stories being complete.

### User Story Dependencies

- **US1 (P1)**: No dependency on other stories after Phase 2.
- **US2 (P2)**: Depends on US1.
- **US3 (P3)**: Depends on US1 and should follow US2 for the simplest implementation order.

### Within Each User Story

- Write tests first and make sure they fail before implementation.
- Keep provider SDK code in `data`, state contracts in `domain`, and route/UI logic in `presentation`.
- Do not persist authenticated Apple state in `SharedPreferences`.
- Do not add a second Apple entry point outside `lib/presentation/pages/auth_entry_gate_page.dart`.
- Finish the story checkpoint before moving to the next priority.

### Parallel Opportunities

- `T001` and `T002` can run in parallel in Phase 1.
- `T004`, `T005`, `T006`, `T007`, and `T008` can run in parallel in Phase 2.
- `T009`, `T010`, `T011`, `T012`, `T013`, and `T014` can run in parallel for US1.
- `T023`, `T024`, `T025`, and `T026` can run in parallel for US2.
- `T032`, `T033`, `T034`, and `T035` can run in parallel for US3.
- `T041`, `T042`, `T043`, and `T046` can run in parallel during polish once implementation is stable.

---

## Parallel Example: Foundational Phase

```text
Task: "T004 Create AppleAuthAvailability, AppleAuthProviderStatus, and provider result value types in lib/data/datasources/auth/apple_auth_provider_data_source.dart"
Task: "T005 Create the gate-facing SignInWithApple use case scaffold in lib/domain/usecases/auth/sign_in_with_apple.dart"
Task: "T006 Extend AuthEntryState with Apple availability and Apple in-progress feedback slots in lib/presentation/cubit/auth/auth_entry_state.dart"
Task: "T007 Add Apple Sign-In capability scaffolding in ios/Runner/Info.plist, ios/Runner/Runner.entitlements, and ios/Runner.xcodeproj/project.pbxproj"
Task: "T008 Keep apple.com as an allowed provider input in lib/domain/repositories/auth_repository.dart and lib/domain/usecases/sync/sign_in_for_sync.dart"
```

## Parallel Example: User Story 1

```text
Task: "T009 Create Apple availability and successful credential result tests in test/data/datasources/auth/apple_auth_provider_data_source_test.dart"
Task: "T010 Create success mapping tests for SignInWithApple in test/domain/usecases/auth/sign_in_with_apple_test.dart"
Task: "T011 Create Apple credential exchange and workspace bootstrap success tests in test/data/datasources/auth/auth_remote_data_source_test.dart"
Task: "T012 Add stable-identity-only Apple restoration tests when email and name are absent in test/data/datasources/auth/auth_remote_data_source_test.dart and test/domain/usecases/auth/sign_in_with_apple_test.dart"
Task: "T013 Add Apple success and Apple-loading tests in test/presentation/cubit/auth/auth_entry_cubit_test.dart"
Task: "T014 Add enabled Apple button and authenticated Apple routing tests in test/widget/auth_entry_gate_test.dart and test/widget/app_launch_router_test.dart"
```

## Parallel Example: User Story 3

```text
Task: "T032 Add restored Apple session precedence tests in test/domain/usecases/auth/app_entry_usecases_test.dart"
Task: "T033 Add unrestorable Apple session fallback tests in test/domain/usecases/auth/app_entry_usecases_test.dart and test/widget/app_launch_router_test.dart"
Task: "T034 Add Apple sign-out and restored-session sync tests in test/presentation/cubit/sync/sync_status_cubit_test.dart"
Task: "T035 Add widget tests for Apple relaunch skip-gate and post-sign-out gate return in test/widget/app_launch_router_test.dart"
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Complete Phase 1.
2. Complete Phase 2.
3. Complete Phase 3 (US1).
4. Run the US1 tests and validate one successful Apple sign-in path on iOS before touching failure or restoration behavior.

### Incremental Delivery

1. Add the dependency, localized copy, Apple provider contract, and iOS capability scaffolding.
2. Deliver the successful Apple sign-in path from the entry gate.
3. Add cancellation, conflict, unavailable-device, and failure handling without changing the success path.
4. Add authenticated relaunch and sign-out routing.
5. Finish with focused validation and cleanup.

### Small-Model Execution Guidance

1. Do not redesign the existing sync engine or medication sync logic.
2. Reuse the current `AuthRepository` and `AuthSession` pipeline instead of creating a second authenticated session source.
3. Keep `SharedPreferences` limited to guest persistence only.
4. Keep Apple sign-in available only from `lib/presentation/pages/auth_entry_gate_page.dart` in this phase.
5. Do not make `lib/presentation/widgets/sync/sync_account_tile.dart` an alternate Apple sign-in surface.
6. Keep Firestore user bootstrap under `users/{userId}` and reuse the existing workspace initialization path in `lib/data/datasources/auth/auth_remote_data_source.dart`.
7. On non-iOS runners, hide Apple rather than attempting live Apple auth.
8. On iOS devices where Apple Sign-In is unavailable, keep Apple visible but disabled instead of hiding it.
9. If a task changes routing, re-run `test/widget/app_launch_router_test.dart` before moving on.
10. If a task changes gate behavior, re-run `test/widget/auth_entry_gate_test.dart` before moving on.

---

## Notes

- Total tasks: 46
- User story task counts:
  - **US1**: 14 tasks
  - **US2**: 9 tasks
  - **US3**: 9 tasks
- Parallel opportunities identified: setup, foundational Apple contract work, all story test batches, and selected polish tasks
- Suggested MVP scope: Phase 1 + Phase 2 + Phase 3 only
- Format validation: every task uses the required checkbox, task ID, optional `[P]`, required `[US#]` for story phases, and exact file paths
