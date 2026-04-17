---
description: "Task list for Last Taken Medicine - Phase 4 Integration"
---

# Tasks: Last Taken Medicine - Phase 4 Integration

**Input**: Design documents from `/specs/014-last-taken-integration/`
**Prerequisites**: plan.md, spec.md, research.md, quickstart.md

**Tests**: Required. Integration connects major components and needs widget/integration test coverage per Constitution III.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Mobile project**: `lib/`, `test/`, `integration_test/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Localization initialization for integration points

- [X] T001 Update English localization strings for Bottom Navigation Bar label in `lib/l10n/app_en.arb`
- [X] T002 Update Arabic localization strings for Bottom Navigation Bar label in `lib/l10n/app_ar.arb`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

*(No blocking foundational boilerplate needed beyond existing Hive/Bloc infrastructure)*

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Navigate to Last Taken Medicines (Priority: P1) MVP

**Goal**: Access the Last Taken Medicines from a top-level Home Screen Bottom Navigation Bar, rendering immediately with async background fetches.

**Independent Test**: App launches, a new item is visible in the Bottom Navigation Bar on Home Screen. Tapping it seamlessly switches tabs and triggers a data load without throwing dependency or router exceptions.

### Tests for User Story 1

> **NOTE**: Write these tests FIRST, ensure they FAIL before implementation

- [X] T003 [P] [US1] Widget Test: Verify `BottomNavigationBar` presence and interaction on Home Screen in `test/presentation/pages/home_page_test.dart`
- [X] T004 [P] [US1] Integration Test: Verify tab switching, hardware back-button return to tab 0, and initialization flow without runtime exceptions in `integration_test/last_taken_navigation_test.dart`

### Implementation for User Story 1

- [X] T005 [P] [US1] Trigger medicine fetch asynchronously within `initState` in `lib/presentation/last_taken/pages/last_taken_medicines_page.dart`
- [X] T006 [US1] Add `BottomNavigationBar` handling `MedicationList` (tab 0) and local injection of `LastTakenMedicinesPage` (tab 1) wrapped in `BlocProvider` relying on `GetIt` in `lib/presentation/pages/home_page.dart`
- [X] T006b [US1] Implement hardware back-button interception (e.g., using `PopScope`) on `HomePage` to return to tab 0 before exiting the app.

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently. You have MVP.

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [X] T007 Code cleanup and verifying zero lint warnings across modified presentation layer files
- [X] T008 Validate localization and accessibility for the newly added Bottom Navigation Bar icons
- [X] T009 Run quickstart.md validation to ensure end-to-end functionality

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Starts immediately
- **Foundational (Phase 2)**: Starts/finishes immediately (N/A)
- **User Stories (Phase 3+)**: Depends on localization from Setup.
- **Polish (Final Phase)**: Depends on US1 completion.

### User Story Dependencies

- **User Story 1 (P1)**: Only story in this phase.

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Localization keys before UI routing logic
- `initState` logic before bottom navigation integration

### Parallel Opportunities

- All Setup tasks (T001, T002) can run in parallel
- Widget and Integration tests (T003, T004) can be scaffolded in parallel
- Adding the fetch logic in `last_taken_medicines_page.dart` (T005) can be done concurrently before resolving the `home_page.dart` wrapper (T006).

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (Localization Keys)
2. Complete Phase 3: User Story 1
3. **STOP and VALIDATE**: Test User Story 1 via `flutter test` independently
4. Deploy/demo if ready
