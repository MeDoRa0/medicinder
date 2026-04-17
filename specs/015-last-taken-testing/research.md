# Research: Last Taken Medicine — Phase 5 Testing

**Feature Branch**: `015-last-taken-testing` | **Date**: 2026-04-17

## 1. Existing Test Coverage Inventory

### Cubit Tests (`test/features/medication/presentation/cubit/last_taken_medicines_cubit_test.dart`)

| Test | Status | Spec Requirement |
|------|--------|------------------|
| Initial state is `LastTakenMedicinesInitial` | ✅ Exists | SC-002 |
| Loading → Loaded when stream emits data | ✅ Exists | FR-001 |
| Loading → Error when stream throws | ✅ Exists | FR-002 |
| Re-calling `watchRecentMedicines()` cancels previous subscription | ❌ Missing | FR-003 |
| `close()` cancels active stream subscription | ❌ Missing | FR-004 |
| Loaded with empty list | ❌ Missing | SC-002 |
| `close()` during loading → no error emitted | ❌ Missing | Edge case |

### Repository Tests (`test/data/repositories/medication_repository_impl_test.dart`)

| Test | Status | Spec Requirement |
|------|--------|------------------|
| Returns empty list when no records | ✅ Exists | — |
| Filters out records older than 24 hours | ✅ Exists (but uses 25h, not boundary) | FR-005 partial |
| Sorts records most recent first | ✅ Exists | — |
| Exact 24h boundary: exactly 24h excluded | ❌ Missing | FR-005 |
| Exact 24h boundary: 23h59m included | ❌ Missing | FR-005 |

### Page Widget Tests (`test/presentation/last_taken/pages/last_taken_medicines_page_test.dart`)

| Test | Status | Spec Requirement |
|------|--------|------------------|
| Loading state → CircularProgressIndicator | ✅ Exists | FR-006 |
| Error state → error message | ✅ Exists | FR-006 |
| Loaded state → LastTakenMedicinesList | ✅ Exists | FR-006 |
| Empty loaded state → EmptyStateWidget | ✅ Exists | FR-006 |
| Initial state → loading indicator | ❌ Not explicit (covered by Loading test) | FR-006 |

### Widget Tests

| Test File | Tests | Gaps |
|-----------|-------|------|
| `taken_medicine_card_test.dart` | Name, dose, relative time ✅; Long text wrapping ✅ | Ellipsis truncation not verified (FR-009) |
| `last_taken_medicines_list_test.dart` | Order verification ✅ | Complete for FR-008 |
| `empty_state_widget_test.dart` | Icon + message ✅ | Complete |

### Missing Test Files

| Test | Spec Requirement |
|------|------------------|
| `MedicationHistory` value equality test | FR-012 |
| Navigation test (history icon → page) | FR-010 |

## 2. Source Code Bug: 24-Hour Boundary

- **Decision**: The repository's `getLastTakenMedicines()` at line 250–253 uses `isAfter(threshold) || isAtSameMomentAs(threshold)` which means exactly 24h = **included**.
- **Spec requires**: Strict `takenAt > now - 24h`, meaning exactly 24h = **excluded**.
- **Rationale**: The spec explicitly states "Strict `takenAt > now - 24h` (exactly 24h = excluded)". The current implementation uses `>=`.
- **Action**: Fix the repository to use only `isAfter(threshold)` (remove the `isAtSameMomentAs` check), then add boundary tests to prove the fix.

## 3. Source Code Gap: Card Truncation

- **Decision**: The `TakenMedicineCard` widget does NOT use `maxLines: 1` or `TextOverflow.ellipsis` on the medicine name `Text` widget (line 25–31 of `taken_medicine_card.dart`).
- **Spec requires**: FR-009 — "long medication names are truncated with ellipsis (`TextOverflow.ellipsis`, `maxLines: 1`)".
- **Rationale**: The current card uses default `Text` wrapping. The spec and clarifications explicitly require single-line truncation with ellipsis for consistent card height.
- **Action**: Modify `TakenMedicineCard` to add `maxLines: 1` and `overflow: TextOverflow.ellipsis` to the medication name text. Then add a widget test that verifies truncation behavior with a ~100+ character name.

## 4. Dependency: `bloc_test` Package

- **Decision**: Add `bloc_test` to `dev_dependencies`.
- **Rationale**: The spec assumes `bloc_test` is available (see Assumptions section). It is currently NOT in `pubspec.yaml`. While the existing cubit tests use manual `stream` + `emitsInOrder` patterns, `bloc_test` with `blocTest()` provides a more declarative and idiomatic approach. However, since the existing 3 cubit tests already work without it, the new tests can follow the same manual pattern to maintain consistency.
- **Alternatives considered**: Using `blocTest()` from `bloc_test`. Rejected because: (a) existing tests don't use it, so mixing patterns would be inconsistent; (b) the manual approach is already proven; (c) installing a new dependency just for convenience adds unnecessary coupling.
- **Final Decision**: Do NOT add `bloc_test`. Write new cubit tests using the existing manual `stream` + `emitsInOrder` pattern for consistency.

## 5. Page Test: `close()` Mock

- **Decision**: All page-level widget tests mock `cubit.close()` to return `Future<void>.value()`.
- **Rationale**: The existing page tests do NOT mock `close()`, which can cause `StateError` ("Cannot emit after close") during test teardown. The recent conversation history (conversation `be3b4c75`) confirms this was a recurring issue that was fixed. New tests must include `when(() => mockCubit.close()).thenAnswer((_) async {});` in setUp.
- **Alternatives considered**: Not mocking `close()`. Rejected because it causes flaky test failures.

## 6. Navigation Test Strategy

- **Decision**: Create a widget test that renders `HomePage` with mocked dependencies, taps the `Icons.history` icon button, and asserts `LastTakenMedicinesPage` appears via `find.byType`.
- **Rationale**: FR-010 requires verifying that the history icon navigates to the Last Taken page. This requires mocking `MedicationCubit`, `LastTakenMedicinesCubit` (via `GetIt`), and providing localization delegates.
- **Alternatives considered**: Integration test. Rejected because it requires full app bootstrap and is slower. Widget test is sufficient to prove navigation wiring.

## 7. Time Determinism

- **Decision**: All tests that compare time use seeded `DateTime` values computed relative to `DateTime.now()` at test start.
- **Rationale**: SC-006 requires "No test relies on real system time — all time-dependent tests use deterministic, seeded values." The existing tests already follow this pattern (e.g., `final now = DateTime.now(); ... now.subtract(...)`).
- **Alternatives considered**: Using `clock` package for injectable time. Rejected because the existing codebase doesn't use it and it would require refactoring production code.
