# Feature Specification: Last Taken Medicine — Phase 5 Testing

**Feature Branch**: `015-last-taken-testing`  
**Created**: 2026-04-17  
**Status**: Draft  
**Input**: User description: "Phase 5 Testing for Last Taken Medicine feature — comprehensive test coverage for all layers"

## Clarifications

### Session 2026-04-17

- Q: How should same-minute medications be ordered when multiple have identical `takenAt` timestamps? → A: Insertion order (first-added appears first).
- Q: What should happen when the repository stream is cancelled before data arrives? → A: Remain in Loading state, silently cancel subscription (no error emitted).
- Q: Should widget tests use `get_it` registration or bypass DI? → A: Bypass `get_it`, inject mocks via `BlocProvider` directly.
- Q: What is the 24-hour boundary rule — exclusive or inclusive of exact boundary? → A: Strict `takenAt > now - 24h` (exactly 24h = excluded).
- Q: Should long medication names truncate with ellipsis or wrap multi-line? → A: Truncate with ellipsis (`…`), single line, consistent card height.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Verify Recent Medication Visibility (Priority: P1)

A user opens the "Last Taken" page after having marked one or more medications as taken within the last 24 hours. The system displays each medication with the correct name, dose, and relative time. The list is ordered with the most recently taken medication at the top.

**Why this priority**: This is the core value of the feature. If the list does not accurately reflect recently taken medications, the feature has zero utility and could endanger patient safety by creating false confidence.

**Independent Test**: Can be fully tested by seeding medication history records with known timestamps and asserting the list content, ordering, and individual card data render correctly.

**Acceptance Scenarios**:

1. **Given** a user has taken "Aspirin 500 mg" 2 hours ago, **When** they open the Last Taken page, **Then** they see "Aspirin" with dose "500 mg" and a relative time label such as "2 h ago".
2. **Given** a user has taken three medications at different times within the last 24 hours, **When** they open the Last Taken page, **Then** the list displays all three medications sorted from most recent to oldest.
3. **Given** a user has taken a medication exactly 24 hours and 1 minute ago, **When** they open the Last Taken page, **Then** that medication does NOT appear in the list.

---

### User Story 2 - Empty State When No Medications Taken (Priority: P1)

A user opens the "Last Taken" page but has not taken any medications within the last 24 hours. The system displays a friendly empty state message instead of a blank or broken screen.

**Why this priority**: The empty state is part of the core experience. Without it, users see a confusing blank screen and cannot tell if the UI is working properly.

**Independent Test**: Can be tested by providing the page with zero history records and asserting the empty state widget with icon and localized message appears.

**Acceptance Scenarios**:

1. **Given** no medications have been taken in the last 24 hours, **When** the user opens the Last Taken page, **Then** the system displays an icon and the message "No medications taken today."
2. **Given** the user's only history records are older than 24 hours, **When** the user opens the Last Taken page, **Then** the system shows the empty state (not an empty list).

---

### User Story 3 - Reactive List Update After Taking a Dose (Priority: P2)

A user marks a medication as taken elsewhere in the app. When they return (or are already viewing) the Last Taken page, the newly taken medication appears in the list without requiring a manual refresh.

**Why this priority**: Real-time reactivity is critical for trust — if users take a medication and the page doesn't reflect it, they may double-dose. However, it is a secondary flow behind the initial list display.

**Independent Test**: Can be tested by emitting new data through the repository stream and asserting the cubit transitions from its current state to an updated loaded state containing the new record.

**Acceptance Scenarios**:

1. **Given** the Last Taken page is open with 1 medication, **When** the repository stream emits a new list containing 2 medications, **Then** the cubit transitions to a loaded state with 2 medications.
2. **Given** the cubit is watching the stream, **When** the stream emits an error, **Then** the cubit transitions to an error state.

---

### User Story 4 - Loading and Error States (Priority: P2)

While data is being fetched, the system shows a loading indicator. If an error occurs during fetch, the system displays a localized error message instead of crashing.

**Why this priority**: Loading and error states are essential for a polished user experience, but they represent transitional states rather than the primary feature value.

**Independent Test**: Can be tested by providing the cubit with a loading state or error state and asserting the correct UI widgets appear.

**Acceptance Scenarios**:

1. **Given** the cubit is in the loading state, **When** the page renders, **Then** a circular progress indicator is displayed.
2. **Given** the cubit is in the error state, **When** the page renders, **Then** an error message is displayed.

---

### User Story 5 - Navigation to Last Taken Page (Priority: P3)

A user taps the history icon button on the Home Screen app bar. The system navigates the user to the Last Taken Medicines page with all dependencies correctly wired.

**Why this priority**: Navigation is a peripheral concern — it confirms wiring rather than core logic.

**Independent Test**: Can be tested by tapping the history icon in a widget test and asserting the Last Taken page appears.

**Acceptance Scenarios**:

1. **Given** the user is on the Home Screen, **When** they tap the history icon button, **Then** the Last Taken Medicines page is displayed with data loaded.

---

### Edge Cases

- The 24-hour boundary uses strict comparison: `takenAt > now - 24h`. A record at exactly 24 hours ago is **excluded**. Tests must assert: record at 24h00m00s → excluded; record at 23h59m59s → included.
- When multiple medications share the same `takenAt` timestamp, they are displayed in insertion order (first-added appears first). Tests should seed records in a known insertion order and assert that order is preserved.
- If the repository stream is cancelled before data arrives (e.g., cubit closed during loading), the cubit remains in Loading state and silently cancels the subscription without emitting an error. Tests should verify no error state is emitted when `close()` is called during loading.
- When `watchRecentMedicines()` is called while an existing subscription is active, the cubit MUST cancel the previous subscription before creating the new one. Tests seed two `StreamController`s and verify only the latest emits state changes (FR-003).
- When `close()` is called while the stream subscription is live, the cubit MUST cancel the subscription cleanly without emitting further states. Tests verify no state is emitted after `close()` (FR-004).
- Long medication names are truncated with ellipsis (`TextOverflow.ellipsis`, `maxLines: 1`) to maintain consistent card height. Tests should use a very long name string (~100+ characters) and assert no overflow exception is thrown and that the `Text` widget uses ellipsis overflow.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST have unit tests for the cubit that verify it emits the correct state sequence (Initial → Loading → Loaded) when the repository stream provides data.
- **FR-002**: The system MUST have unit tests for the cubit that verify it emits an error state when the repository stream errors.
- **FR-003**: The system MUST have unit tests for the cubit that verify calling `watchRecentMedicines()` while a subscription is already active cancels the previous subscription before creating a new one.
- **FR-004**: The system MUST have unit tests for the cubit that verify `close()` cancels the active stream subscription cleanly.
- **FR-005**: The system MUST have repository-level unit tests that verify 24-hour filtering works at the boundary (exactly 24 hours = excluded, 23 hours 59 minutes = included).
- **FR-006**: The system MUST have widget tests for the page that verify each cubit state (Initial, Loading, Loaded, Error, Empty List) renders the correct UI component.
- **FR-007**: The system MUST have widget tests for the individual card widget that verify medication name, dose, and relative time are displayed correctly.
- **FR-008**: The system MUST have widget tests that confirm the list displays items in the provided order (no re-sorting at the UI layer).
- **FR-009**: The system MUST have widget tests that verify long medication names are truncated with ellipsis (`TextOverflow.ellipsis`, `maxLines: 1`) and do not cause layout overflow exceptions.
- **FR-010**: The system MUST have a navigation test that verifies tapping the history icon on the Home Screen navigates to the Last Taken page.
- **FR-011**: All tests MUST pass with a `flutter test` invocation with zero failures.
- **FR-012**: The system MUST have a data model test that verifies the `MedicationHistory` entity correctly implements value equality using its properties.

### Key Entities

- **MedicationHistory**: Represents a single medication intake record. Key attributes: medicineId, medicineName, dose, takenAt (timestamp).
- **LastTakenMedicinesState**: Represents the cubit state. Variants: Initial, Loading, Loaded (list of MedicationHistory), Error (message string).
- **MedicationRepository**: Provides `getLastTakenMedicines()` (one-shot) and `getLastTakenMedicinesStream()` (reactive) methods for medication history.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of existing Last Taken feature tests pass without regression after new tests are added.
- **SC-002**: The cubit has at least 5 unit tests covering: initial state, loading transition, loaded with data, loaded with empty list, error state, subscription cancellation on re-watch, and cleanup on close.
- **SC-003**: Every cubit state variant (Initial, Loading, Loaded, Error) is exercised by at least one page-level widget test.
- **SC-004**: The 24-hour boundary condition is explicitly tested at the repository level with a record at exactly 24 hours (excluded) and at 23 hours 59 minutes (included).
- **SC-005**: The complete test suite executes in under 30 seconds on a standard development machine.
- **SC-006**: No test relies on real system time — all time-dependent tests use deterministic, seeded values.
- **SC-007**: The data model entity has at least 1 test verifying value equality behavior.

## Assumptions

- Phases 1–4 (Data Layer, Domain & State Management, UI, and Feature Integration) are already fully implemented and functional.
- The existing test structure under `test/` follows the project's clean architecture convention (data, domain, presentation, widget, integration directories).
- The `mocktail` package is available in `dev_dependencies` for creating mock objects.
- Cubit tests follow the existing manual `StreamController` + `emitsInOrder` pattern for consistency with the current test suite. The `bloc_test` package is NOT required (see research.md §4 for decision rationale).
- No real database or external service calls are needed — all tests operate with in-memory fakes and mocks.
- The existing tests already cover some scenarios (basic repository filtering, basic page states, basic widget rendering). The gap analysis shows the cubit has zero tests and the repository boundary test is incomplete.
- The implementing agent will have access to the full codebase and existing test files as examples of the project's testing patterns.
- Widget tests MUST bypass `get_it` and inject mock cubits directly via `BlocProvider`. This avoids cross-test state pollution from shared `GetIt` singletons and isolates UI behavior from DI wiring.
