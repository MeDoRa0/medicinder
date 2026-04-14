# Feature Specification: Last Taken Medicine - Phase 2 (Domain & State Management)

**Feature Branch**: `012-last-taken-domain-state`  
**Created**: 2026-04-14  
**Status**: Draft  
**Input**: User description: "read last_taken_medicine_feature_plan.md and create a specifications for Phase 2 --- Domain & State Management only"

## Clarifications

### Session 2026-04-14
- Q: How should the LastTakenMedicinesCubit handle automatic UI updates when a new medication is marked as taken? → A: Option B - The Repository exposes a Stream that the Cubit listens to for automatic database changes.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Retrieve Recent Medications Successfully (Priority: P1)

As a user, I want the system to successfully fetch and prepare my recently taken medications so that the UI can display them.

**Why this priority**: Retrieving the medications successfully is the core responsibility of this state management component. Without this, the feature does not exist.

**Independent Test**: Can be tested via unit tests of the Cubit, verifying that `LastTakenMedicinesLoaded` is emitted with the correct list when the repository successfully returns medication records.

**Acceptance Scenarios**:

1. **Given** the initial state, **When** the cubit is asked to fetch recent medications and the repository returns a valid list of records, **Then** the state transitions to `LastTakenMedicinesLoading` and then to `LastTakenMedicinesLoaded` containing the medications list.
2. **Given** the initial state, **When** the cubit is asked to fetch recent medications and the repository returns an empty list, **Then** the state transitions to `LastTakenMedicinesLoading` and then to `LastTakenMedicinesLoaded` with an empty list.

---

### User Story 2 - Handle Repository Errors Gracefully (Priority: P1)

As a user, I want the system to handle any data retrieval errors gracefully so that the app doesn't crash and can inform me of the problem.

**Why this priority**: Error handling is critical for stability and providing a good user experience when things go wrong (e.g., local database corruption or read errors).

**Independent Test**: Can be verified via unit tests ensuring the Cubit emits `LastTakenMedicinesError` when the repository throws an exception.

**Acceptance Scenarios**:

1. **Given** the initial state, **When** the cubit is asked to fetch recent medications and the repository throws an error, **Then** the state transitions to `LastTakenMedicinesLoading` and then to `LastTakenMedicinesError` with a failure message.

### Edge Cases

- What happens if the repository call takes a long time? (The state should remain in `LastTakenMedicinesLoading`, the UI can show a loading indicator).
- What happens if the user marks another medication while the cubit is fetching? (The cubit should likely queue or be re-triggered to fetch again, ensuring the latest state is captured).
- If the feature touches platform-specific providers, what happens on unsupported platforms? (N/A for local Hive state management).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a `LastTakenMedicinesCubit` to manage the state of the recent medications view.
- **FR-002**: System MUST define the following distinct states: `LastTakenMedicinesInitial`, `LastTakenMedicinesLoading`, `LastTakenMedicinesLoaded`, and `LastTakenMedicinesError`.
- **FR-003**: The Cubit MUST subscribe to the `getLastTakenMedicinesStream()` method from the medication repository.
- **FR-004**: The Cubit MUST emit a loading state while initially waiting for the repository stream, and update automatically upon new stream events.
- **FR-005**: The Cubit MUST emit a loaded state containing the list of recently taken medications on successful retrieval.
- **FR-006**: The Cubit MUST emit an error state containing the error details if the repository retrieval fails.

### Key Entities

- **LastTakenMedicinesState**: The state object representing the current phase of fetching (Initial, Loading, Loaded with data, or Error with message).
- **MedicationHistory**: The underlying data retrieved from the repository, containing medication name, dose, and timestamp.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Unit tests for the `LastTakenMedicinesCubit` achieve 100% logic branch coverage (Loading, Success, Empty, Error).
- **SC-002**: Cubit execution time, excluding repository fetch latency, completes synchronous state transitions in under 10ms.
- **SC-003**: Zero unexpected unhandled exceptions originate from the Cubit during repository interactions in testing.

## Assumptions

- The repository layer (`getLastTakenMedicines()`) is already implemented and securely accessible to the Cubit (Phase 1 completion assumption).
- The underlying presentation layer (UI) will rely solely on these emitted states to render.
- The repository exposes a Stream that the Cubit listens to for automatic reactive updates.
