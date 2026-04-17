# Tasks: Last Taken Medicine — Phase 5 Testing

**Input**: Design documents from `/specs/015-last-taken-testing/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

**Tests**: This feature IS the test coverage phase. All tasks produce test files or fix
source-code bugs that tests depend on. No new production features are introduced.

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create directory structure for new test files

- [X] T001 Create `test/domain/entities/` directory for entity tests

---

## Phase 2: Foundational (Bug Fixes — Blocking Prerequisites)

**Purpose**: Fix two production bugs discovered during research. Tests in later phases depend on corrected behavior.

**CRITICAL**: No user story test work can begin until these fixes are applied.

- [X] T002 Fix 24-hour boundary filter: change `>=` to strict `>` by removing `|| record.takenAt.isAtSameMomentAs(threshold)` in `lib/data/repositories/medication_repository_impl.dart` (lines 250–253)
- [X] T003 [P] Fix card text truncation: add `maxLines: 1` and `overflow: TextOverflow.ellipsis` to medication name `Text` widget in `lib/presentation/last_taken/widgets/taken_medicine_card.dart` (lines 25–31)

**Checkpoint**: Production bugs fixed — test tasks can now proceed.

---

## Phase 3: User Story 1 — Verify Recent Medication Visibility (Priority: P1) MVP

**Goal**: Prove that seeded medication history records render with the correct name, dose, relative time, and ordering — and that the 24-hour boundary filter is strict.

**Independent Test**: Seed `MedicationHistory` records with known timestamps. Assert list content, ordering, boundary exclusion/inclusion, entity equality, and card truncation.

**FR Coverage**: FR-005, FR-007, FR-008, FR-009, FR-012 · SC-004, SC-006, SC-007

### Tests for User Story 1

- [X] T004 [P] [US1] Create `MedicationHistory` entity value equality tests (equal and not-equal) in `test/domain/entities/medication_history_test.dart`
- [X] T005 [P] [US1] Add 24-hour strict boundary tests to existing group: exact 24h record excluded, 23h59m record included in `test/data/repositories/medication_repository_impl_test.dart`
- [X] T006 [P] [US1] Update card truncation test to assert `TextOverflow.ellipsis` and `maxLines: 1` on medication name widget with 100+ character name in `test/presentation/last_taken/widgets/taken_medicine_card_test.dart`

**Checkpoint**: Entity equality proven, boundary filter verified, card truncation confirmed. US1 core coverage complete.

---

## Phase 4: User Story 2 — Empty State When No Medications Taken (Priority: P1)

**Goal**: Verify that an empty medication list triggers the empty-loaded state in the cubit (not an error or broken UI).

**Independent Test**: Emit an empty list from the mock repository stream. Assert cubit transitions to `Loaded(empty)`.

**FR Coverage**: FR-006 (empty variant) · SC-002

### Tests for User Story 2

- [X] T007 [US2] Add cubit unit test: emits `[Loading, Loaded(empty)]` when repository stream emits an empty list in `test/features/medication/presentation/cubit/last_taken_medicines_cubit_test.dart`

**Checkpoint**: Empty state cubit transition proven. Existing page widget tests already cover the empty-state UI rendering (FR-006).

---

## Phase 5: User Story 3 — Reactive List Update After Taking a Dose (Priority: P2)

**Goal**: Prove the cubit correctly manages stream subscription lifecycle — cancelling previous subscriptions on re-watch and cleaning up on close.

**Independent Test**: Create multiple `StreamController`s, call `watchRecentMedicines()` multiple times. Verify only the latest subscription is active. Verify `close()` cancels cleanly.

**FR Coverage**: FR-003, FR-004 · SC-002

> **NOTE**: US3 acceptance scenarios 1–2 (stream emits new data → Loaded; stream errors → Error) are already covered by existing FR-001 and FR-002 tests. The tasks below address the subscription lifecycle edge cases (FR-003, FR-004) that make the reactive mechanism robust.

### Tests for User Story 3

- [X] T008 [US3] Add cubit unit test: re-calling `watchRecentMedicines()` cancels previous subscription (two controllers, data on first ignored, data on second received) in `test/features/medication/presentation/cubit/last_taken_medicines_cubit_test.dart`
- [X] T009 [US3] Add cubit unit test: `close()` cancels active stream subscription cleanly (no state emitted after close) in `test/features/medication/presentation/cubit/last_taken_medicines_cubit_test.dart`
- [X] T010 [US3] Add cubit unit test: `close()` during loading state does not emit error (only Loading emitted, no Error follows) in `test/features/medication/presentation/cubit/last_taken_medicines_cubit_test.dart`

**Checkpoint**: Subscription lifecycle fully tested — re-watch, close, and close-during-loading all proven safe.

---

## Phase 6: User Story 4 — Loading and Error States (Priority: P2)

**Goal**: Confirm loading indicator and error message render for their respective cubit states.

**Independent Test**: Already fully covered by existing page widget tests (see research.md coverage inventory).

**FR Coverage**: FR-002, FR-006 · SC-003

> **NOTE**: No new tasks required. Existing tests in
> `test/presentation/last_taken/pages/last_taken_medicines_page_test.dart` already
> cover Loading, Loaded, Error, and Empty state variants with correct UI assertions.
> The **Initial** state renders identically to Loading (both display
> `CircularProgressIndicator`), so a separate Initial-specific test is redundant —
> coverage is subsumed by the existing Loading state test. Research confirmed zero
> actionable gaps for this story.

**Checkpoint**: US4 is complete via existing coverage.

---

## Phase 7: User Story 5 — Navigation to Last Taken Page (Priority: P3)

**Goal**: Verify that tapping the history icon on the Home Screen navigates to the Last Taken Medicines page with all dependencies wired.

**Independent Test**: Render `HomePage` with mocked `MedicationCubit` and `LastTakenMedicinesCubit`, tap `Icons.history`, assert `LastTakenMedicinesPage` appears.

**FR Coverage**: FR-010

### Tests for User Story 5

- [X] T011 [US5] Create navigation widget test: tapping history icon navigates to `LastTakenMedicinesPage` in `test/widget/home_page_navigation_test.dart`

**Checkpoint**: Navigation wiring proven end-to-end.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Full suite validation and compliance verification

- [X] T012 Run full test suite via `flutter test` and verify zero failures (FR-011, SC-001)
- [X] T013 Verify cubit test count meets SC-002 threshold (≥5 tests covering all listed scenarios)
- [X] T014 Verify test suite execution time is under 30 seconds (SC-005)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user story test tasks
- **US1 (Phase 3)**: Depends on Phase 2 bug fixes (boundary filter fix needed for T005)
- **US2 (Phase 4)**: Depends on Phase 2 — independent of US1
- **US3 (Phase 5)**: Depends on Phase 2 — independent of US1 and US2
- **US4 (Phase 6)**: No new tasks — fully covered by existing tests
- **US5 (Phase 7)**: Depends on Phase 2 — independent of US1–US4
- **Polish (Phase 8)**: Depends on all user story phases

### User Story Dependencies

- **US1 (P1)**: Independent — tests entity, repository boundary, card widget
- **US2 (P1)**: Independent — tests cubit with empty stream data
- **US3 (P2)**: Independent — tests cubit subscription lifecycle
- **US4 (P2)**: No tasks — existing tests complete
- **US5 (P3)**: Independent — tests navigation wiring

### Within Each User Story

- All US1 tasks (T004, T005, T006) are [P] — different files, no dependencies
- US2 has a single task (T007)
- US3 tasks (T008, T009, T010) are in the same file — execute sequentially
- US5 has a single task (T011)

### Parallel Opportunities

After Phase 2 completes, all user stories can run in parallel:

```text
                     ┌── US1: T004 ─┐
                     │   US1: T005 ─┤ (all [P], different files)
                     │   US1: T006 ─┘
Phase 1 → Phase 2 → ├── US2: T007
                     ├── US3: T008 → T009 → T010 (same file, sequential)
                     └── US5: T011
                                    └── Phase 8: T012 → T013 → T014
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (create directory)
2. Complete Phase 2: Bug fixes (boundary filter + card truncation)
3. Complete Phase 3: US1 tests (entity, boundary, truncation)
4. **STOP and VALIDATE**: Run `flutter test` — all US1 tests should pass
5. US1 delivers: entity equality, boundary correctness, card truncation proven

### Incremental Delivery

1. Setup + Bug Fixes → Foundation ready
2. Add US1 → Core visibility tests passing (MVP!)
3. Add US2 → Empty state cubit test passing
4. Add US3 → Subscription lifecycle fully tested
5. Add US5 → Navigation wiring proven
6. Polish → Full suite validated, thresholds met

### Suggested MVP Scope

**US1 only** — proves core feature correctness (boundary filter, entity equality, card truncation). Delivers 4 new test cases + 2 production bug fixes.

---

## FR → Task Traceability Matrix

| Requirement | Task(s) | Story | Status |
|-------------|---------|-------|--------|
| FR-001 | — | — | ✅ Existing |
| FR-002 | — | — | ✅ Existing |
| FR-003 | T008 | US3 | 🆕 New |
| FR-004 | T009 | US3 | 🆕 New |
| Edge case (spec L99) | T010 | US3 | 🆕 New (close-during-loading, no error) |
| FR-005 | T002 (fix), T005 (test) | US1 | 🆕 New |
| FR-006 | — | US4 | ✅ Existing (Initial subsumed by Loading — same UI) |
| FR-007 | — | — | ✅ Existing |
| FR-008 | — | — | ✅ Existing |
| FR-009 | T003 (fix), T006 (test) | US1 | 🔄 Update |
| FR-010 | T011 | US5 | 🆕 New |
| FR-011 | T012 | — | 🔧 Verify |
| FR-012 | T004 | US1 | 🆕 New |

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story
- All cubit tests follow existing `mocktail` + manual `StreamController` pattern (no `bloc_test`)
- Widget tests bypass `get_it` and inject mocks via `BlocProvider` directly
- All time-dependent tests use seeded `DateTime` values (SC-006)
- Mock `cubit.close()` in all page widget tests to prevent `StateError`
