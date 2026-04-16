# Feature Specification: Last Taken Medicine - UI Implementation

**Feature Branch**: `013-last-taken-ui`  
**Created**: 2026-04-16  
**Status**: Draft  
**Input**: User description: "read @[last_taken_medicine_feature_plan.md] and create a specifications for Phase 3 --- UI Implementation only"

## Clarifications

### Session 2026-04-16
- Q: Time Display Format → A: Relative time (e.g., "2 hours ago", "Just now")
- Q: Text Overflow Handling → A: Wrap text to multiple lines

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Recently Taken Medications (Priority: P1)

As a user, I want to see a clear list of medications I have taken within the last 24 hours so that I can quickly verify my recent doses and avoid accidentally taking the same medication twice.

**Why this priority**: This is the core functionality of the UI phase for this feature. Without seeing recently taken medications, the feature provides no value to the user.

**Independent Test**: Can be fully tested by opening the application (or specific feature view) after taking a medication, and verifying the medication appears with the correct dose and timestamp at the top of the list.

**Acceptance Scenarios**:

1. **Given** the user has taken a medication in the last 24 hours, **When** they view the last taken medicine list, **Then** the medication name, dose, and the time it was taken should be visible.
2. **Given** the user has taken multiple medications at different times, **When** they view the list, **Then** the medications are sorted chronologically with the most recent at the top.
3. **Given** the user took a medication exactly 24 hours and 1 minute ago, **When** they view the list, **Then** that medication should not be visible.

---

### User Story 2 - Empty State (Priority: P2)

As a user who has not taken any medications in the last 24 hours, I want to see a clear message indicating my list is empty, so that I am confident no doses have been recently recorded.

**Why this priority**: Users need visual feedback so they don't mistake an empty list for a loading error or a broken feature.

**Independent Test**: Can be tested by clearing all recent medication records (or opening the app on a fresh day) and verifying the empty state UI appears instead of a blank screen or progress indicator.

**Acceptance Scenarios**:

1. **Given** the user has no medication records in the last 24 hours, **When** they view the last taken medicine list, **Then** they should see a text message like "No medications taken today".
2. **Given** the user is viewing the empty state, **When** they take a new medication, **Then** the empty state should disappear and the new medication should be shown in the list.

### Edge Cases

- How does the system handle if the user's device time changes or is manually adjusted? (Note: timezone travel is resolved by rendering relative time based on UTC).
- What happens if the user marks multiple medications as taken simultaneously?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display a vertical layout list of medication records that fall within the last 24 hours.
- **FR-002**: System MUST display the Medication Name, Dose amount, and Time Taken for each entry in the list.
- **FR-003**: System MUST sort the displayed list in descending order by time taken (most recent at the top).
- **FR-004**: System MUST display an "Empty State" UI message (e.g., "No medications taken today") when the list contains zero records.
- **FR-005**: System MUST automatically update and re-render the view if a new medication is marked as taken while the screen is visible to the user.
- **FR-006**: System MUST display the "Time Taken" as a relative time string (e.g., "2 hours ago", "Just now") to clearly indicate elapsed time since the intake.

### Key Entities

- **Medication Intake Record**: A view representation of a medication taken by the user, containing the medication identifier, name, dose, and the exact timestamp it was taken.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of tested users can quickly identify the last medication they took and its corresponding time without confusion.
- **SC-002**: The UI renders the list of taken medications within 1 second of loading the initial data.
- **SC-003**: UI dynamically increases card height and wraps text to multiple lines to accommodate long medication names and doses, showing no visual clipping on the minimum supported screen width.

## Assumptions

- Users have standard, modern mobile devices capable of typical list rendering performance.
- The underlying Data Layer and Domain/State Management implementations (Phases 1 & 2) accurately provide UTC-based data for the last 24 hours.
- Visual component design will align perfectly with existing Medicinder application components (list tiles, cards, text themes, empty state styling).
- Offline capability works natively without extra UI logic because the chosen data layer stores records locally by default.
