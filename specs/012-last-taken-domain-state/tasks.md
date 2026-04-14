# Tasks: Last Taken Medicine - Phase 2 (Domain & State Management)

**Input**: Design documents from `specs/012-last-taken-domain-state/`
**Prerequisites**: plan.md, spec.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [X] T001 Create project structure for the new cubit files per implementation plan in `lib/features/medication/presentation/cubit/` and test directories

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

- [X] T002 Define the `LastTakenMedicinesState` abstract/sealed class and its concrete states (`LastTakenMedicinesInitial`, `LastTakenMedicinesLoading`, `LastTakenMedicinesLoaded`, `LastTakenMedicinesError`) in `lib/features/medication/presentation/cubit/last_taken_medicines_state.dart`

---

## Phase 3: User Story 1 - Retrieve Recent Medications Successfully (Priority: P1)

**Goal**: Successfully fetch and prepare recently taken medications over a stream so that the UI can display them.

### Tests for User Story 1

- [X] T003 [P] [US1] Create unit tests for initial state and successful stream emission using `bloc_test` in `test/features/medication/presentation/cubit/last_taken_medicines_cubit_test.dart`

### Implementation for User Story 1

- [X] T004 [US1] Scafffold `LastTakenMedicinesCubit` in `lib/features/medication/presentation/cubit/last_taken_medicines_cubit.dart`
- [X] T005 [US1] Implement stream subscription to the repository inside the cubit to emit `LastTakenMedicinesLoading` and `LastTakenMedicinesLoaded` based on data

---

## Phase 4: User Story 2 - Handle Repository Errors Gracefully (Priority: P1)

**Goal**: Handle data retrieval errors gracefully without crashing.

### Tests for User Story 2

- [X] T006 [P] [US2] Create unit tests verifying error state emission when stream emits an error in `test/features/medication/presentation/cubit/last_taken_medicines_cubit_test.dart`

### Implementation for User Story 2

- [X] T007 [US2] Implement error catching, non-sensitive diagnostic logging, and emission of `LastTakenMedicinesError` via `onError` handler in the stream subscription in `lib/features/medication/presentation/cubit/last_taken_medicines_cubit.dart`
- [X] T008 [US2] Ensure Stream subscription is safely cancelled in the `close()` override of the Cubit

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [X] T009 Register `LastTakenMedicinesCubit` with GetIt/dependency injection where appropriate (e.g., generic DI setup file `lib/core/di/injection.dart` or similar router provider blocks)

---

## Dependencies & Execution Order

- **US1 (Retrieve)**: Depends on T002 State Definition.
- **US2 (Error Handling)**: Extends US1 implementation; logic can be added consecutively.
- **Tests**: Should be implemented immediately before their corresponding Cubit logic to support TDD.
