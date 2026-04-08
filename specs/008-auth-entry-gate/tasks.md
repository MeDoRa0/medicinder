# Tasks: Authentication Entry Gate

**Input**: Design documents from `/specs/008-auth-entry-gate/`
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [quickstart.md](./quickstart.md), [contracts/](./contracts/)

**Tests**: Required. The constitution, plan, and spec all require automated coverage for launch routing, guest persistence, localization/accessibility, and auth-adjacent state transitions.

**Organization**: Tasks are grouped by user story so each story can be implemented and validated independently. The tasks are intentionally narrow and explicit so a smaller model can execute them without inferring architecture.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel with other tasks in the same phase because it targets different files and has no dependency on incomplete work
- **[Story]**: User story label from `spec.md`
- Every task includes exact file paths

## Path Conventions

- **Flutter mobile app**: `lib/` for production code and `test/` for automated tests
- **Active startup entry point**: `lib/main.dart`
- **Do not rely on** `lib/presentation/main_app.dart` for this feature unless you intentionally switch the app to use it; the current startup flow is implemented in `lib/main.dart`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add shared copy and generated localization outputs before implementation starts.

- [X] T001 Add auth entry gate strings and semantics copy to `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb`
- [X] T002 Regenerate localized outputs in `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, and `lib/l10n/app_localizations_ar.dart`

**Checkpoint**: Localized copy exists before UI and tests reference it.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Create the local app-entry architecture shared by all user stories.

**CRITICAL**: No user story work should start until this phase is complete.

- [X] T003 [P] Create app-entry domain entities in `lib/domain/entities/auth/app_entry_session.dart` and `lib/domain/entities/auth/launch_route_decision.dart`
- [X] T004 [P] Create the app-entry repository contract in `lib/domain/repositories/app_entry_repository.dart`
- [X] T005 [P] Implement `SharedPreferences` entry-state persistence in `lib/data/datasources/auth/app_entry_local_data_source.dart`
- [X] T006 Implement the repository adapter in `lib/data/repositories/app_entry_repository_impl.dart`
- [X] T007 [P] Add app-entry use cases in `lib/domain/usecases/auth/restore_app_entry_session.dart`, `lib/domain/usecases/auth/continue_as_guest.dart`, and `lib/domain/usecases/auth/clear_app_entry_state.dart`
- [X] T008 Create presentation state and Cubit in `lib/presentation/cubit/auth/auth_entry_state.dart` and `lib/presentation/cubit/auth/auth_entry_cubit.dart`
- [X] T009 Register the new datasource, repository, use cases, and Cubit dependencies in `lib/core/di/injector.dart`

**Implementation Notes**

- `T003`:
  `AppEntrySession` must model `restoring`, `unresolved`, `guest`, `authenticated`, and `failure`.
  `LaunchRouteDecision` must model `entryGate`, `initialSettings`, and `home`.
- `T005`:
  Persist only one supported resolved value in Phase 1: `guest`.
  Store and expose raw persisted entry-state values so later restore logic can
  decide whether a value is supported in the current phase.
- `T007`:
  `restore_app_entry_session.dart` should read the stored value and map it to `AppEntrySession`.
  `continue_as_guest.dart` should persist the `guest` marker and return a resolved guest session.
  `clear_app_entry_state.dart` should remove the stored marker entirely.
- `T008`:
  The Cubit should expose methods for initial restore, guest continuation, disabled provider taps, and clearing state.
  The Cubit should emit non-sensitive diagnostics only; do not log provider tokens or medication data.

**Checkpoint**: The repo has a complete local app-entry slice ready for UI and routing.

---

## Phase 3: User Story 1 - First Launch Choice Gate (Priority: P1) MVP

**Goal**: First-launch users see a full-screen entry gate before the existing initial-settings or home flow, with platform-correct option visibility.

**Independent Test**: On a clean install with no stored entry state, app launch shows the entry gate first; iOS shows Google, Apple, and guest; non-iOS shows Google and guest only.

### Tests for User Story 1

- [X] T010 [P] [US1] Add local persistence restore tests in `test/data/datasources/auth/app_entry_local_data_source_test.dart`
- [X] T011 [P] [US1] Add Cubit restore-state tests in `test/presentation/cubit/auth/auth_entry_cubit_test.dart`
- [X] T012 [P] [US1] Add first-launch widget tests for iOS vs non-iOS option visibility in `test/widget/auth_entry_gate_test.dart`
- [X] T033 [P] [US1] Add widget tests for Arabic localization, RTL layout, and disabled-option accessibility semantics in `test/widget/auth_entry_gate_test.dart`

### Implementation for User Story 1

- [X] T013 [P] [US1] Create the reusable gate option widget in `lib/presentation/widgets/auth/auth_entry_option_button.dart`
- [X] T014 [US1] Create the full-screen entry gate page in `lib/presentation/pages/auth_entry_gate_page.dart`
- [X] T015 [US1] Create a launch router page that waits for entry-state restoration before choosing gate, settings, or home in `lib/presentation/pages/app_launch_router_page.dart`
- [X] T016 [US1] Replace the direct startup `FutureBuilder<bool>` flow with the launch router in `lib/main.dart`
- [X] T017 [US1] Add disabled-provider diagnostics and accessible unavailable feedback in `lib/presentation/pages/auth_entry_gate_page.dart` and `lib/presentation/cubit/auth/auth_entry_cubit.dart`

**Implementation Notes**

- `T012` and `T014`:
  Use compile-safe platform checks such as `defaultTargetPlatform` plus `kIsWeb` handling.
  Do not use `dart:io` directly in the gate widget.
- `T014`:
  Google must be visible but disabled on all supported app platforms for this release.
  Apple must be visible but disabled only on supported iOS devices and hidden elsewhere.
  Guest must always be visible and enabled.
- `T015`:
  Route order must be `restore entry state -> entry gate when unresolved -> meal-time check -> settings/home`.
  Do not skip the existing meal-time setup logic after guest restore.
- `T016`:
  Keep locale loading, Firebase bootstrap, DI, notification setup, and existing `MultiBlocProvider` behavior intact.
  Only replace the launch destination selection.

**Checkpoint**: A first-launch user can open the app and see the correct entry gate before any existing main flow.

---

## Phase 4: User Story 2 - Guest Entry to Main App (Priority: P2)

**Goal**: Guest selection persists a resolved guest state and moves the user into the existing app flow without registration.

**Independent Test**: On a clean install, tap guest and verify navigation continues to `SettingsPage(isInitialSetup: true)` when meal times are missing or `HomePage` when they exist; relaunch skips the gate.

### Tests for User Story 2

- [X] T018 [P] [US2] Add use case tests for guest persistence and clear-state behavior in `test/domain/usecases/auth/app_entry_usecases_test.dart`
- [X] T019 [P] [US2] Add Cubit tests for guest continuation and disabled-provider no-op behavior in `test/presentation/cubit/auth/auth_entry_cubit_test.dart`
- [X] T020 [P] [US2] Add widget tests for guest tap navigation and non-persisting disabled provider taps in `test/widget/auth_entry_gate_test.dart`

### Implementation for User Story 2

- [X] T021 [US2] Connect the existing guest-persistence repository and use case flow to the user-story navigation path in `lib/presentation/cubit/auth/auth_entry_cubit.dart` and verify the persisted result is consumed by routing
- [X] T022 [US2] Wire the guest action into the Cubit in `lib/presentation/cubit/auth/auth_entry_cubit.dart`
- [X] T023 [US2] Route successful guest continuation from the gate into `SettingsPage` or `HomePage` in `lib/presentation/pages/auth_entry_gate_page.dart` and `lib/presentation/pages/app_launch_router_page.dart`

**Implementation Notes**

- `T020`:
  Verify that tapping Google or Apple in Phase 1 leaves the gate visible and stores nothing.
- `T021`:
  The only persisted resolved value in Phase 1 is `guest`.
- `T023`:
  Do not navigate directly from the datasource or repository.
  Navigation decisions stay in presentation and must still honor the meal-time setup requirement.

**Checkpoint**: Guest users can enter the app immediately, and the entry gate does not return on the next launch unless the stored state is cleared.

---

## Phase 5: User Story 3 - Returning User Launch Routing (Priority: P3)

**Goal**: Returning users with a valid resolved guest state bypass the gate, while invalid stored states or sign-out return them to the gate.

**Independent Test**: Save a guest state and relaunch to skip the gate; seed an unsupported stored value and verify fallback to the gate; clear state via sign-out and verify the gate returns.

### Tests for User Story 3

- [X] T024 [P] [US3] Add use case tests for restored guest state and unsupported stored mode fallback in `test/domain/usecases/auth/app_entry_usecases_test.dart`
- [X] T025 [P] [US3] Add Cubit tests for restore success, invalid restore fallback, and clear-state transitions in `test/presentation/cubit/auth/auth_entry_cubit_test.dart`
- [X] T026 [P] [US3] Add widget tests for restored guest skip-gate and invalid stored mode fallback in `test/widget/app_launch_router_test.dart`

### Implementation for User Story 3

- [X] T027 [US3] Implement Phase 1 restore validation for unsupported stored modes and route them back to the gate in `lib/data/repositories/app_entry_repository_impl.dart` and `lib/domain/usecases/auth/restore_app_entry_session.dart`
- [X] T028 [US3] Inject clear-entry-state behavior into cloud sign-out in `lib/presentation/cubit/sync/sync_status_cubit.dart` and `lib/core/di/injector.dart`
- [X] T029 [US3] Re-run launch routing after clear-state events and keep the gate visible again on the next startup in `lib/presentation/cubit/auth/auth_entry_cubit.dart`, `lib/presentation/pages/app_launch_router_page.dart`, and `lib/main.dart`

**Implementation Notes**

- `T027`:
  Restoring `guest` should bypass the gate.
  Restoring any other value should emit an unresolved or failure state and show the gate.
- `T028`:
  Reuse `clear_app_entry_state.dart`; do not duplicate storage-clearing logic in the sync Cubit.
  This task is the explicit implementation for the spec rule that sign-out clears the launch decision.
- `T029`:
  The app should not require a full process restart to reflect a cleared state inside the running session.
  The next rebuild/startup should show the gate again.

**Checkpoint**: Returning launch behavior is stable, invalid stored values are safe, and sign-out restores first-launch gating.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, generated-code cleanup, and documentation updates.

- [X] T030 [P] Update the feature validation notes in `specs/008-auth-entry-gate/quickstart.md` and any user-facing setup note in `README.md`
- [X] T031 Run focused auth-entry tests and fix failures in `test/data/datasources/auth/app_entry_local_data_source_test.dart`, `test/domain/usecases/auth/app_entry_usecases_test.dart`, `test/presentation/cubit/auth/auth_entry_cubit_test.dart`, `test/widget/auth_entry_gate_test.dart`, and `test/widget/app_launch_router_test.dart`
- [X] T032 Run full analyzer cleanup for the feature touch points in `lib/main.dart`, `lib/core/di/injector.dart`, `lib/presentation/pages/app_launch_router_page.dart`, `lib/presentation/pages/auth_entry_gate_page.dart`, and `lib/presentation/cubit/auth/auth_entry_cubit.dart`
- [X] T034 Document the Phase 1 auth boundary in `specs/008-auth-entry-gate/quickstart.md`: no guest-to-account merge, no cloud attachment of guest-local data, and no provider-auth completion in this feature
- [X] T035 Validate launch routing UX in `specs/008-auth-entry-gate/quickstart.md`: confirm route restoration completes within the expected launch window and only one transient loading state appears before destination resolution

**Checkpoint**: The feature is documented, testable, and analyzer-clean.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup** has no dependencies and starts immediately.
- **Phase 2: Foundational** depends on Phase 1 and blocks all user stories.
- **Phase 3: US1** depends on Phase 2 and delivers the MVP launch gate.
- **Phase 4: US2** depends on US1 because guest continuation requires the gate UI and launch router.
- **Phase 5: US3** depends on US2 because returning-user restore relies on the persisted guest flow already existing.
- **Phase 6: Polish** depends on all desired user stories being complete.

### User Story Dependencies

- **US1 (P1)**: No dependency on other stories after Phase 2.
- **US2 (P2)**: Depends on US1.
- **US3 (P3)**: Depends on US2.

### Within Each User Story

- Write tests first and make sure they fail before implementation.
- Implement widgets only after the underlying Cubit and use cases exist.
- Keep routing decisions in presentation, persistence in data, and state modeling in domain/presentation.
- Finish the story checkpoint before moving to the next priority.

### Parallel Opportunities

- `T003`, `T004`, `T005`, and `T007` can run in parallel after Phase 1.
- `T010`, `T011`, `T012`, and `T033` can run in parallel for US1.
- `T018`, `T019`, and `T020` can run in parallel for US2.
- `T024`, `T025`, and `T026` can run in parallel for US3.
- `T030`, `T031`, `T032`, `T034`, and `T035` can run in parallel during polish once implementation is complete.

---

## Parallel Example: Foundational Phase

```text
Task: "T003 Create app-entry domain entities in lib/domain/entities/auth/app_entry_session.dart and lib/domain/entities/auth/launch_route_decision.dart"
Task: "T004 Create the app-entry repository contract in lib/domain/repositories/app_entry_repository.dart"
Task: "T005 Implement SharedPreferences entry-state persistence in lib/data/datasources/auth/app_entry_local_data_source.dart"
Task: "T007 Add app-entry use cases in lib/domain/usecases/auth/restore_app_entry_session.dart, lib/domain/usecases/auth/continue_as_guest.dart, and lib/domain/usecases/auth/clear_app_entry_state.dart"
```

## Parallel Example: User Story 1

```text
Task: "T010 Add local persistence restore tests in test/data/datasources/auth/app_entry_local_data_source_test.dart"
Task: "T011 Add Cubit restore-state tests in test/presentation/cubit/auth/auth_entry_cubit_test.dart"
Task: "T012 Add first-launch widget tests for iOS vs non-iOS option visibility in test/widget/auth_entry_gate_test.dart"
```

## Parallel Example: User Story 3

```text
Task: "T024 Add use case tests for restored guest state and unsupported stored mode fallback in test/domain/usecases/auth/app_entry_usecases_test.dart"
Task: "T025 Add Cubit tests for restore success, invalid restore fallback, and clear-state transitions in test/presentation/cubit/auth/auth_entry_cubit_test.dart"
Task: "T026 Add widget tests for restored guest skip-gate and invalid stored mode fallback in test/widget/app_launch_router_test.dart"
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Complete Phase 1.
2. Complete Phase 2.
3. Complete Phase 3 (US1).
4. Run the US1 tests and confirm the first-launch gate works before any guest persistence work.

### Incremental Delivery

1. Add the shared app-entry architecture.
2. Deliver the first-launch gate.
3. Add guest continuation and persistence.
4. Add restored-session and clear-state behavior.
5. Finish with validation and analyzer cleanup.

### Small-Model Execution Guidance

1. Do not redesign the existing sync-auth layer in `lib/domain/entities/sync/` or `lib/data/datasources/auth/auth_remote_data_source.dart`.
2. Keep this feature local-first and phase-limited: no Google SDK flow, no Apple SDK flow, no Firestore schema changes, no Hive schema changes.
3. Prefer adding a new app-entry slice under `auth/` paths rather than overloading the current sync auth files.
4. Keep the existing meal-time setup logic intact and place the new gate before it.
5. If a task touches navigation, re-run the focused widget tests before moving on.

---

## Notes

- Total tasks: 35
- User story task counts:
  - **US1**: 9 tasks
  - **US2**: 6 tasks
  - **US3**: 6 tasks
- Suggested MVP scope: Phase 1 + Phase 2 + Phase 3 only
- Format validation: every task uses the required checkbox, task ID, optional `[P]`, required `[US#]` for story phases, and exact file paths
