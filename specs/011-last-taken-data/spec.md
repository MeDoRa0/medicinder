# Feature Specification: Last Taken Medicine Data Layer

**Feature Branch**: `011-last-taken-data`  
**Created**: 2026-04-12  
**Status**: Draft  
**Input**: User description: Phase 1 Data Layer implementation from last_taken_medicine_feature_plan.md

## Clarifications

### Session 2026-04-12
- Q: Hive Storage Structure for Intake Records → A: Intake records exist in a separate Hive box where each entry represents one dose taken.
- Q: Timezone Handling for the 24-Hour Window → A: Strict UTC Comparison: Intake timestamps are stored and compared using UTC time.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Retrieve Recent Medications (Priority: P1)

The system needs to retrieve medication intake records from the local repository (Hive) that occurred within the last 24 hours, sorted from most recent to oldest.

**Why this priority**: Required foundation for all other stages of the "Last Taken Medicine" feature. It isolates the data retrieval logic ensuring accuracy before UI integration.

**Independent Test**: Can be fully tested using automated unit tests validating that the separate History repository returns the correct filtered and sorted list of medication intakes when mocked data is supplied.

**Acceptance Scenarios**:

1. **Given** a local history repository containing medication intake records from both today and 3 days ago, **When** `getLastTakenMedicines()` is called, **Then** only the records from within the last 24 hours are returned.
2. **Given** multiple medication intake records within the last 24 hours, **When** `getLastTakenMedicines()` is called, **Then** the records are returned sorted by `takenAt` in descending order (most recent first).
3. **Given** no medications were taken in the last 24 hours, **When** `getLastTakenMedicines()` is called, **Then** an empty list is returned.

---

### Edge Cases

- **Timezone shifts / Time Changes**: Addressed. Using absolute UTC eliminates bugs caused by users traveling across time zones.
- **24-hour exact boundary**: The comparison will use `>=` (inclusive of the exact millisecond 24 hours ago).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST expose a `getLastTakenMedicines()` method in the Medication Repository interface.
- **FR-002**: System MUST implement `getLastTakenMedicines()` to query the Hive local database containing individual intake records (e.g., `MedicationHistory` or `IntakeLog`).
- **FR-003**: System MUST filter retrieved intake records to include only those where `takenAt >= now - 24 hours`.
- **FR-004**: System MUST sort the retrieved records by the `takenAt` timestamp in descending order (latest first).
- **FR-005**: All `takenAt` timestamps MUST be stored, generated, and compared using strictly UTC mathematically to prevent unexpected behaviors due to local daylight saving time or travel edge cases.
- **FR-006**: System MUST create and maintain a `MedicationHistory` Hive box/entity to store individual intake records when a dose is marked as taken.
- **FR-007**: System MUST emit actionable diagnostic logs (as per Constitution Section VI) when new intake records are written to the database.

### Key Entities 

- **Taken Medication Form/Record**: Represents an individual medication intake event, stored in a separate history/log box.
  - Required attributes: `medicineId`, `medicineName`, `dose`, `takenAt` (UTC DateTime).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Repository method `getLastTakenMedicines()` reliably returns accurate, filtered lists in under 50ms for typical local database sizes.
- **SC-002**: Unit tests achieve 100% coverage on the new repository filtering and sorting logic.

## Assumptions

- Phase 1 is strictly isolated to the Data Layer; NO UI or State Management changes are required.
- The `medicineColor` and `medicineIcon` fields proposed in the preliminary plan are safely omitted from Phase 1 data layer specifications and deferred unless prioritized later.
