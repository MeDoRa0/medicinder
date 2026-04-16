# Tasks: Last Taken Medicine - UI Implementation

**Input**: Design documents from `/specs/013-last-taken-ui/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure. As this adds to an existing Flutter repo, setup tasks involve configuring localization schemas specifically for the UI.

- [X] T001 [P] Add string keys ("timeAgoMinutes", "timeAgoHours", "justNow", "noMedsToday") in `lib/l10n/app_en.arb`
- [X] T002 [P] Add string keys ("timeAgoMinutes", "timeAgoHours", "justNow", "noMedsToday") translating to Arabic in `lib/l10n/app_ar.arb`
- [X] T003 Execute `flutter gen-l10n` to generate localized context methods

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

- [X] T004 [P] Create relative time formatting extension on `DateTime` resolving localized strings via `BuildContext` in `lib/core/utils/time_extension.dart`
- [X] T005 [P] Create unit test for the relative time formatting extension in `test/core/utils/time_extension_test.dart`

**Checkpoint**: Foundation ready - user story implementation can now begin.

---

## Phase 3: User Story 1 - View Recently Taken Medications (Priority: P1) MVP

**Goal**: As a user, I want to see a clear list of medications I have taken within the last 24 hours so that I can quickly verify my recent doses and avoid accidentally taking the same medication twice.

**Independent Test**: Can be fully tested by mocking a loaded `LastTakenMedicinesState` featuring recent medications and verifying the UI displays cards sorted properly.

### Tests for User Story 1 (REQUIRED)
- [X] T006 [P] [US1] Create Widget test validating text wrapping and relative time rendering for `TakenMedicineCard` in `test/presentation/last_taken/widgets/taken_medicine_card_test.dart`
- [X] T007 [P] [US1] Create Widget test validating chronological ordering in `LastTakenMedicinesList` in `test/presentation/last_taken/widgets/last_taken_medicines_list_test.dart`
- [X] T008 [P] [US1] Create Widget test for `LastTakenMedicinesPage` simulating `LastTakenMedicinesLoaded`, `LastTakenMedicinesLoading`, and `LastTakenMedicinesError` states in `test/presentation/last_taken/pages/last_taken_medicines_page_test.dart`

### Implementation for User Story 1
- [X] T009 [P] [US1] Build `TakenMedicineCard` ensuring dynamic height and multi-line wrapping in `lib/presentation/last_taken/widgets/taken_medicine_card.dart`
- [X] T010 [US1] Build `LastTakenMedicinesList` to vertically list cards mapping items from a provided list in `lib/presentation/last_taken/widgets/last_taken_medicines_list.dart` (depends on T009)
- [X] T011 [US1] Build `LastTakenMedicinesPage` using `BlocBuilder<LastTakenMedicinesCubit, LastTakenMedicinesState>` to render the loaded list state, plus `LastTakenMedicinesLoading` and `LastTakenMedicinesError` fallback views in `lib/presentation/last_taken/pages/last_taken_medicines_page.dart`
- [X] T012 [US1] Expose a route/navigation entry point for `LastTakenMedicinesPage` wiring it into the existing `BottomNavigationBar` or Home screen drawer in `lib/core/router/app_router.dart`

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently.

---

## Phase 4: User Story 2 - Empty State (Priority: P2)

**Goal**: As a user who has not taken any medications in the last 24 hours, I want to see a clear message indicating my list is empty.

**Independent Test**: Can be fully tested by generating an empty list payload for the `LastTakenMedicinesState` and viewing the "no medications taken today" display.

### Tests for User Story 2 (REQUIRED)
- [X] T013 [P] [US2] Create Widget test validating empty message presentation in `test/presentation/last_taken/widgets/empty_medication_state_test.dart`
- [X] T014 [P] [US2] Append test mimicking empty `LastTakenMedicinesLoaded` array to verify `EmptyMedicationState` is rendered over the list view in `test/presentation/last_taken/pages/last_taken_medicines_page_test.dart`

### Implementation for User Story 2
- [X] T015 [P] [US2] Build `EmptyMedicationState` widget using localized text resource in `lib/presentation/last_taken/widgets/empty_medication_state.dart`
- [X] T016 [US2] Modify `LastTakenMedicinesPage` BlocBuilder tree to conditionally render `EmptyMedicationState` when item count is zero in `lib/presentation/last_taken/pages/last_taken_medicines_page.dart`

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently.

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [X] T017 [P] Perform localized UI tests ensuring RTL (Right-to-Left) formatting for Arabic texts remains functionally and visually flawless 
- [X] T018 Code cleanup, refactoring unneeded widgets or styling properties, and resolving any dart static analysis lint errors 
- [X] T019 [P] Create and run Flutter integration profiling test ensuring `LastTakenMedicinesPage` renders list under 1 second per SC-002 in `integration_test/last_taken_performance_test.dart` 

---

## Dependencies & Execution Order

### Phase Dependencies
- **Setup (Phase 1)**: Modifying arb files requires zero setup. Can start immediately.
- **Foundational (Phase 2)**: Depends on `flutter gen-l10n`. BLOCKS all UI user stories.
- **User Stories (Phase 3+)**: US1 and US2 can theoretically start widget tests in parallel once foundational extensions and translation keys are defined.
- **Polish (Final Phase)**: Depends on US1 and US2 being completd.

### User Story Dependencies
- **User Story 1 (P1)**: After Phase 2, this is fully decoupled block of UI components.
- **User Story 2 (P2)**: Component `EmptyMedicationState` requires nothing. The parent integration requires T011 to be finished.

### Parallel Opportunities
- T001 and T002 can be performed in parallel.
- US1 and US2 widget building (T009, T015) can be completed in parallel.
- All Widget Tests can theoretically be stubbed parallel.

## Implementation Strategy

1. Add localization tokens to ARB files and generate (Phase 1).
2. Apply Time extension handler resolving localization (Phase 2).
3. Create US1 tests & stub dummy layouts.
4. Implement UI view and components ensuring `flutter run` shows dynamic text wrapping working smoothly.
5. Create empty states and insert conditional Bloc wiring for US2.
6. Verify RTL UI and fix potential trailing margin errors for Phase N polish.
