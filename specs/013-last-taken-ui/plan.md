# Implementation Plan: Last Taken Medicine - UI Implementation

**Branch**: `013-last-taken-ui` | **Date**: 2026-04-16 | **Spec**: [specs/013-last-taken-ui/spec.md](spec.md)
**Input**: Feature specification from `/specs/013-last-taken-ui/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

The Last Taken Medicine feature requires a UI to display medications taken in the last 24 hours. The UI will feature a vertical list, ordered by most recent, and will dynamically wrap text for long medication names. Relative time strings (e.g., "2 hours ago") will be used for display. An empty state will be shown if no medications were taken.

## Technical Context

**Language/Version**: Dart ^3.8.1, Flutter stable
**Primary Dependencies**: `flutter`, `flutter_bloc`, `intl`
**Storage**: N/A (UI layer, data handled by Cubit via Hive)
**Testing**: `flutter_test`, `bloc_test`, Mocktail
**Target Platform**: iOS, Android
**Project Type**: mobile-app
**Performance Goals**: 60 fps, render <1 sec
**Constraints**: Offline-capable natively, RTL support required
**Scale/Scope**: New feature page, ~4 UI components

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Plan-Driven Delivery**: Following `spec.md` strictly to build UI components and connect them to the `LastTakenMedicinesCubit` matching phase 3 objectives.
- **II. Flutter Clean Architecture Boundaries**: The new UI will reside exclusively in the `presentation` layer. No direct database or platform calls will be made from widgets.
- **III. Testable by Default**: Widget tests will be implemented for `LastTakenMedicinesView`, empty states, UI rendering, and Bloc interactions.
- **IV. Offline-First Reliability**: UI respects offline-first by only tracking Cubit state, ignoring network connectivity.
- **V. Authentication and Cloud Data Boundaries**: Feature relies on already partitioned data layer, skipping direct Firebase logic.
- **VI. Localization, Accessibility, and Observability**: New texts ("No medications taken today", "X hours ago") will be managed via `intl` arb files, supporting English and Arabic, and RTL correctly.

## Project Structure

### Documentation (this feature)

```text
specs/013-last-taken-ui/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── presentation/
│   └── last_taken/
│       ├── bloc/
│       │   ├── last_taken_medicines_cubit.dart (Assumed built in Phase 2)
│       │   └── last_taken_medicines_state.dart
│       ├── pages/
│       │   └── last_taken_medicines_page.dart
│       └── widgets/
│           ├── last_taken_medicines_list.dart
│           ├── taken_medicine_card.dart
│           └── empty_medication_state.dart
├── l10n/
│   ├── app_en.arb
│   └── app_ar.arb

test/
└── presentation/
    └── last_taken/
        ├── last_taken_medicines_page_test.dart
        └── widgets/
            └── taken_medicine_card_test.dart
```

**Structure Decision**: A dedicated feature folder `lib/presentation/last_taken/` will separate this feature from other domains, aligning with standard layer-first feature structuring.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |
