# Implementation Plan: Sync Engine Implementation

**Branch**: `003-sync-engine` | **Date**: 2026-04-03 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/003-sync-engine/spec.md`

## Summary

Implement Phase 3 as the first production-ready synchronization engine for
Medicinder's existing local-first Flutter app. The engine should start on app
startup and connectivity restoration for signed-in users, upload supported local
medication changes, pull newer remote medication records, resolve conflicts with
last-write-wins based on last-changed timestamps, preserve delete tombstones when
deletion is the newest change, expose accurate sync lifecycle outcomes, and emit
non-sensitive diagnostics without expanding Phase 4 queue ownership or Phase 5
notification regeneration into this increment.

## Technical Context

**Language/Version**: Dart `^3.8.1` with Flutter stable  
**Primary Dependencies**: Flutter, `flutter_bloc`, `get_it`, `hive`, `hive_flutter`, `firebase_auth`, `cloud_firestore`, `connectivity_plus`, `intl`  
**Storage**: Hive remains the local source of truth for medication records and sync state; Firestore stores user-scoped cloud medication copies; lightweight sync diagnostics stay in local state/logs only  
**Testing**: `flutter_test`, `flutter analyze`, sync service unit tests under `test/core/services/sync/`, presentation Cubit tests under `test/presentation/cubit/sync/`, sync widget tests under `test/widget/`  
**Target Platform**: Flutter mobile application for Android and iOS; other Flutter runners must remain compile-safe  
**Project Type**: Mobile app  
**Performance Goals**: Automatic sync dispatch should begin within 2 seconds of app startup or connectivity restoration for a signed-in user; 95% of successful sync cycles should complete within 30 seconds for a typical acceptance-test dataset; sync status updates should reach presentation state within 1 second of phase changes  
**Constraints**: Preserve clean architecture boundaries; keep local use functional while signed out or offline; no continuous background sync loop; no notification rescheduling in this phase; no queue redesign beyond the engine boundary; new logs must avoid sensitive medication details; existing English/Arabic sync UI must remain RTL-safe  
**Scale/Scope**: Single Flutter app codebase; Phase 3 covers medication synchronization only, with low hundreds of medication records per user, lifecycle state tracking, trigger handling, merge behavior, and retry-ready failure handling

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Plan-Driven Delivery**: PASS. The plan stays within the approved Phase 3 spec and its clarifications, including startup plus reconnect triggers and delete-versus-update conflict handling.
- **II. Flutter Clean Architecture Boundaries**: PASS. Sync orchestration remains behind `domain` repository contracts and `core` services; Firestore and Hive details stay in `data`; presentation consumes derived state only.
- **III. Testable by Default**: PASS. The plan requires service-level tests for trigger handling, merge rules, partial failures, and retry behavior, plus Cubit/widget coverage for sync lifecycle reporting.
- **IV. Offline-First Reliability**: PASS. Hive remains authoritative locally, interrupted sync is recoverable, and the plan explicitly avoids replacing local behavior with cloud-only flows.
- **V. Localization, Accessibility, and Observability**: PASS. Existing bilingual sync surfaces remain in scope for lifecycle messaging, and the engine plan includes actionable diagnostics without exposing medication content.

## Project Structure

### Documentation (this feature)

```text
specs/003-sync-engine/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   |-- medication-reconciliation-contract.md
|   `-- sync-engine-contract.md
|-- spec.md
`-- checklists/
    `-- requirements.md
```

### Source Code (repository root)

```text
lib/
|-- core/
|   |-- di/
|   |-- error/
|   `-- services/
|       `-- sync/
|-- data/
|   |-- datasources/
|   |   |-- auth/
|   |   |-- medication_local_data_source.dart
|   |   |-- medication_remote_data_source.dart
|   |   |-- sync_queue_local_data_source.dart
|   |   `-- sync_state_local_data_source.dart
|   |-- models/
|   |   `-- sync/
|   `-- repositories/
|-- domain/
|   |-- entities/
|   |   `-- sync/
|   |-- repositories/
|   `-- usecases/
|       `-- sync/
|-- l10n/
|-- presentation/
|   |-- cubit/
|   |   `-- sync/
|   `-- widgets/
|       `-- sync/
`-- main.dart

test/
|-- core/
|   `-- services/
|       `-- sync/
|-- domain/
|   `-- usecases/
|       `-- sync/
|-- presentation/
|   `-- cubit/
|       `-- sync/
`-- widget/
```

**Structure Decision**: Use the existing single Flutter app with clean
architecture boundaries already present in `lib/`. Phase 3 centers on
`core/services/sync`, `domain/repositories/sync_repository.dart`,
`data/datasources/medication_remote_data_source.dart`,
`data/datasources/sync_state_local_data_source.dart`, and sync status consumers
in `presentation/cubit/sync` and `presentation/widgets/sync`.

## Phase 0: Research

See [research.md](research.md) for resolved decisions covering:

- Automatic sync triggers for app startup, connectivity restoration, sign-in, and manual retry semantics
- Conflict resolution rules, including delete tombstones as timestamped winners
- Lifecycle state persistence and presentation-safe failure reporting
- Boundary choice to keep durable queue redesign deferred to Phase 4 while still consuming queued local changes through an abstract local sync input
- Non-sensitive sync diagnostics and test strategy

## Phase 1: Design & Contracts

- Data model documented in [data-model.md](data-model.md)
- Internal contracts documented in [contracts/sync-engine-contract.md](contracts/sync-engine-contract.md) and [contracts/medication-reconciliation-contract.md](contracts/medication-reconciliation-contract.md)
- Validation flow documented in [quickstart.md](C:\Users\medo2\Desktop\programming\medicinder\specs\003-sync-engine\quickstart.md)

## Post-Design Constitution Check

- **I. Plan-Driven Delivery**: PASS. Research and design artifacts stay inside the approved Phase 3 scope and do not absorb Phase 4 queue redesign or Phase 5 notification regeneration.
- **II. Flutter Clean Architecture Boundaries**: PASS. Contracts preserve repository abstractions, keep Firestore/Hive code in `data`, and keep sync orchestration in a service boundary rather than in presentation.
- **III. Testable by Default**: PASS. The quickstart and contracts define repeatable unit and widget validation for trigger dispatch, conflict resolution, interruption handling, and lifecycle state updates.
- **IV. Offline-First Reliability**: PASS. The design keeps local medication data authoritative on device, treats connectivity loss as recoverable, and preserves pending work for later retries without requiring a queue redesign in this phase.
- **V. Localization, Accessibility, and Observability**: PASS. The design keeps lifecycle updates compatible with existing localized sync surfaces and formalizes diagnostics that do not expose medication payloads.

## Complexity Tracking

No constitution violations or justified exceptions.
