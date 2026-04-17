# Implementation Plan: Last Taken Medicine — Phase 5 Testing

**Branch**: `015-last-taken-testing` | **Date**: 2026-04-17 | **Spec**: [spec.md](file:///c:/Users/medo2/Desktop/programming/medicinder/specs/015-last-taken-testing/spec.md)
**Input**: Feature specification from `/specs/015-last-taken-testing/spec.md`

## Summary

Add comprehensive test coverage for the "Last Taken Medicine" feature across all layers:
cubit unit tests, repository boundary tests, widget tests, entity tests, and navigation
tests. Fix two source-code bugs discovered during research (24-hour boundary filter and
card text truncation). No new dependencies required — all tests follow the existing
`mocktail` + manual stream pattern.

## Technical Context

**Language/Version**: Dart ^3.8.1 with Flutter stable  
**Primary Dependencies**: `flutter_test`, `mocktail`, `flutter_bloc`, `equatable`, `hive`  
**Storage**: Hive (local), tested via in-memory fakes  
**Testing**: `flutter test` (no `bloc_test` — uses existing manual stream pattern)  
**Target Platform**: Android / iOS  
**Project Type**: Mobile app (Flutter)  
**Performance Goals**: Full test suite completes in < 30 seconds (SC-005)  
**Constraints**: All tests must be deterministic — no real system time (SC-006)  
**Scale/Scope**: ~15–20 new test cases across 7 test files

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Plan-Driven Delivery**: ✅ This plan traces directly to the approved `spec.md`
  (Feature 015). All work items map to FR-001 through FR-012 and SC-001 through SC-007.
  No scope deviation.
- **II. Flutter Clean Architecture Boundaries**: ✅ Tests are organized by layer:
  `test/data/` for repository, `test/features/` for cubit, `test/presentation/` and
  `test/widget/` for UI. No production architecture changes. Two source-code fixes
  stay within their respective layers (data, presentation).
- **III. Testable by Default**: ✅ This feature IS the test coverage. It fills gaps
  identified in the existing test suite: cubit subscription lifecycle, repository
  boundary conditions, entity equality, card truncation, and navigation wiring.
- **IV. Offline-First Reliability**: ✅ Not applicable — all tests use in-memory fakes.
  No network, no Firestore, no real Hive. Offline-first behavior is not changed.
- **V. Authentication and Cloud Data Boundaries**: ✅ Not applicable — no auth or
  cloud sync logic is touched. Repository tests use a `_FakeAuthRepository`.
- **VI. Localization, Accessibility, and Observability**: ✅ Widget tests use
  `AppLocalizations.localizationsDelegates` with `locale: Locale('en')`. No new
  user-facing strings are introduced. Existing localized strings are verified.

## Project Structure

### Documentation (this feature)

```text
specs/015-last-taken-testing/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (not created by /speckit.plan)
```

### Source Code (repository root)

```text
# Production fixes (2 files)
lib/data/repositories/medication_repository_impl.dart    # Fix 24h boundary filter
lib/presentation/last_taken/widgets/taken_medicine_card.dart  # Fix text truncation

# New test files
test/domain/entities/medication_history_test.dart        # [NEW] Entity equality

# Modified test files
test/features/medication/presentation/cubit/last_taken_medicines_cubit_test.dart  # Add 4 tests
test/data/repositories/medication_repository_impl_test.dart                       # Add 2 boundary tests
test/presentation/last_taken/widgets/taken_medicine_card_test.dart                # Update truncation test
test/widget/home_page_navigation_test.dart                                       # [NEW] Navigation test
```

**Structure Decision**: Follows existing clean architecture test layout. No new
directories needed. Entity test goes in `test/domain/entities/` (new directory).
Navigation test goes in `test/widget/` (existing directory used for integration-like
widget tests).

## Proposed Changes

### Bug Fix 1: Repository 24-Hour Boundary

#### [MODIFY] [medication_repository_impl.dart](file:///c:/Users/medo2/Desktop/programming/medicinder/lib/data/repositories/medication_repository_impl.dart)

**Lines 250–253**: Change the filter from `>=` (inclusive) to `>` (strict) to match
the spec requirement that exactly 24 hours ago is **excluded**.

```diff
       final filteredRecords = records.where((record) {
-        return record.takenAt.isAfter(threshold) ||
-            record.takenAt.isAtSameMomentAs(threshold);
+        return record.takenAt.isAfter(threshold);
       }).toList();
```

---

### Bug Fix 2: Card Text Truncation

#### [MODIFY] [taken_medicine_card.dart](file:///c:/Users/medo2/Desktop/programming/medicinder/lib/presentation/last_taken/widgets/taken_medicine_card.dart)

**Lines 25–31**: Add `maxLines: 1` and `overflow: TextOverflow.ellipsis` to the
medication name `Text` widget to enforce single-line truncation per FR-009.

```diff
                   child: Text(
                     history.medicineName,
                     style: Theme.of(context).textTheme.titleMedium?.copyWith(
                           fontWeight: FontWeight.bold,
                         ),
-                    // Wrapping is default for Text
+                    maxLines: 1,
+                    overflow: TextOverflow.ellipsis,
                   ),
```

---

### Cubit Tests (4 new tests)

#### [MODIFY] [last_taken_medicines_cubit_test.dart](file:///c:/Users/medo2/Desktop/programming/medicinder/test/features/medication/presentation/cubit/last_taken_medicines_cubit_test.dart)

Add the following tests to the existing file:

1. **`emits [Loading, Loaded(empty)] when stream emits empty list`** — Covers the
   empty list case for SC-002.

2. **`re-calling watchRecentMedicines() cancels previous subscription`** — Creates
   two `StreamController`s, calls `watchRecentMedicines()` twice, adds data to the
   first (should be ignored) and second (should be received). Verifies FR-003.

3. **`close() cancels stream subscription cleanly`** — Calls `watchRecentMedicines()`,
   then `close()`, then adds data to the stream. Verifies no state is emitted after
   close. Covers FR-004.

4. **`close() during loading state does not emit error`** — Calls
   `watchRecentMedicines()`, immediately calls `close()`, verifies only Loading is
   emitted and no Error follows. Covers the edge case from spec line 99.

---

### Repository Boundary Tests (2 new tests)

#### [MODIFY] [medication_repository_impl_test.dart](file:///c:/Users/medo2/Desktop/programming/medicinder/test/data/repositories/medication_repository_impl_test.dart)

Add to the existing `group`:

1. **`excludes record at exactly 24 hours ago (strict boundary)`** — Seeds a record
   at `now.subtract(Duration(hours: 24))`, asserts result is empty. Covers FR-005.

2. **`includes record at 23 hours 59 minutes ago (just inside boundary)`** — Seeds
   a record at `now.subtract(Duration(hours: 23, minutes: 59))`, asserts record is
   included. Covers FR-005.

---

### Card Widget Test Update

#### [MODIFY] [taken_medicine_card_test.dart](file:///c:/Users/medo2/Desktop/programming/medicinder/test/presentation/last_taken/widgets/taken_medicine_card_test.dart)

Update the existing long-text test to explicitly verify `TextOverflow.ellipsis` and
`maxLines: 1` on the medication name widget:

1. Find the `Text` widget containing the long name.
2. Assert `text.maxLines == 1`.
3. Assert `text.overflow == TextOverflow.ellipsis`.
4. Assert no layout overflow exception.

---

### Entity Value Equality Test

#### [NEW] [medication_history_test.dart](file:///c:/Users/medo2/Desktop/programming/medicinder/test/domain/entities/medication_history_test.dart)

1. **`two instances with same properties are equal`** — Create two `MedicationHistory`
   instances with identical fields, assert `==` and `hashCode` match.

2. **`two instances with different properties are not equal`** — Create two with
   different `medicineId`, assert `!=`.

Covers FR-012 and SC-007.

---

### Navigation Test

#### [NEW] [home_page_navigation_test.dart](file:///c:/Users/medo2/Desktop/programming/medicinder/test/widget/home_page_navigation_test.dart)

1. **`tapping history icon navigates to LastTakenMedicinesPage`** — Render `HomePage`
   with mocked `MedicationCubit`, register `LastTakenMedicinesCubit` in `GetIt`,
   tap the `Icons.history` icon button, pump and settle, assert
   `find.byType(LastTakenMedicinesPage)` finds one widget.

Covers FR-010.

---

## FR → Test Traceability Matrix

| Requirement | Test Location | Status |
|-------------|---------------|--------|
| FR-001 | cubit_test: "Loading, Loaded when stream emits" | ✅ Exists |
| FR-002 | cubit_test: "Loading, Error when stream throws" | ✅ Exists |
| FR-003 | cubit_test: "re-calling cancels previous" | 🆕 New |
| FR-004 | cubit_test: "close cancels subscription" | 🆕 New |
| FR-005 | repo_test: exact boundary tests | 🆕 New |
| FR-006 | page_test: 4 existing state tests | ✅ Exists |
| FR-007 | card_test: name, dose, time display | ✅ Exists |
| FR-008 | list_test: order verification | ✅ Exists |
| FR-009 | card_test: truncation assertion update | 🔄 Update |
| FR-010 | home_page_navigation_test: history icon | 🆕 New |
| FR-011 | `flutter test` zero failures | 🔧 Verify |
| FR-012 | medication_history_test: equality | 🆕 New |

## Complexity Tracking

> No constitution violations requiring justification.

| Item | Notes |
|------|-------|
| No new dependencies | Tests follow existing `mocktail` + manual stream pattern |
| 2 source-code bug fixes | Minimal, targeted changes (1 line each) |
| All tests deterministic | Seeded DateTime values, no real system time |
