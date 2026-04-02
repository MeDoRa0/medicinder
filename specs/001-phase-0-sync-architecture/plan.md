# Implementation Plan: Phase 0 Cloud Sync Implementation Foundation

**Branch**: `001-phase-0-sync-architecture` | **Date**: 2026-04-01 | **Spec**: [spec.md](C:\Users\medo2\Desktop\programming\medicinder\specs\001-phase-0-sync-architecture\spec.md)
**Input**: Feature specification from `C:\Users\medo2\Desktop\programming\medicinder\specs\001-phase-0-sync-architecture\spec.md`

## Summary

Implement the first Medicinder cloud sync foundation increment around an
offline-first Flutter application where Hive remains the primary local store,
Firebase Authentication isolates user data, Cloud Firestore stores per-user cloud
copies, connectivity restoration triggers automatic background sync, and conflict
handling uses last-write-wins with `updatedAt`. This phase produces both working
foundation code and the artifacts needed for later sync phases: research
decisions, a sync-focused data model, internal contracts, and an updated
quickstart.

## Technical Context

**Language/Version**: Dart `^3.8.1` with Flutter stable  
**Primary Dependencies**: Flutter, `flutter_bloc`, `hive`, `hive_flutter`, `awesome_notifications`, `intl`, planned `firebase_auth`, planned `cloud_firestore`, planned connectivity monitoring  
**Storage**: Hive as primary local store; Firestore as per-user cloud mirror; `shared_preferences` remains for lightweight local preferences only  
**Testing**: `flutter_test`, `flutter analyze`, existing sync unit tests under `test/core/services/sync/`, planned widget/integration/localization coverage for sync UX and account flows  
**Target Platform**: Android and iOS primary; web/desktop runners must remain compile-safe  
**Project Type**: Flutter mobile application  
**Performance Goals**: Sync initialization must not block reminder availability on startup; reconnect-triggered sync dispatch target under 5 seconds; foreground sync state updates visible within 1 second; normal sync cycles should complete within 30 seconds for a typical user dataset  
**Constraints**: Offline-first behavior is mandatory; local notifications remain device-local; cloud sync requires sign-in but local-only use must continue unsigned; English/Arabic and RTL support required for new copy; logs must exclude sensitive medication details; clean architecture boundaries must be preserved  
**Scale/Scope**: Single app codebase; per-user isolated datasets with low hundreds of medication and schedule records; Phase 0 scope is the first implementation foundation for medications, schedules, reminder settings, sync metadata, queue replay, sync status UX, and supporting documentation

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- `Plan Alignment`: Pass. The plan follows the active top-level roadmap in [plan.md](C:\Users\medo2\Desktop\programming\medicinder\plan.md) and the approved feature spec while explicitly scoping this feature as the first implementation foundation increment.
- `Architecture Boundaries`: Pass. Planned responsibilities keep UI state in `presentation`, orchestration and policies in `domain/core`, and Hive/Firebase integrations in `data`.
- `Test Coverage`: Pass. Later phases will require unit tests for conflict resolution, queue replay, and sync policies, plus widget/integration tests for account and sync status flows.
- `Offline-First Reliability`: Pass. The plan explicitly keeps Hive as source of truth, requires automatic replay after reconnect, documents conflict strategy, and treats notification scheduling as local-only behavior rebuilt from synced schedule data.
- `Localization/Accessibility/Observability`: Pass. The plan includes bilingual sync status strings, RTL-safe UX states, and structured diagnostics that avoid sensitive payload logging.

## Project Structure

### Documentation (this feature)

```text
specs/001-phase-0-sync-architecture/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   `-- sync-boundaries.md
|-- spec.md
`-- checklists/
    `-- requirements.md
```

### Source Code (repository root)

```text
lib/
|-- core/
|-- data/
|-- domain/
|-- l10n/
|-- presentation/
`-- main.dart

test/
`-- core/
    `-- services/
        `-- sync/

android/
ios/
linux/
macos/
web/
windows/
```

**Structure Decision**: Use the existing Flutter clean-architecture layout already
present in `lib/`. Future sync orchestration and policies should be split across
`domain` and `core`, Firebase and Hive implementations should live in `data`, and
sync status/account flows should surface through `presentation`. Existing sync unit
tests under `test/core/services/sync/` are the starting point for expanded coverage.

## Phase 0 Research

- Document Firebase Authentication and Firestore as the cloud platform pair for
  account isolation and synchronized storage.
- Confirm last-write-wins using `updatedAt` as the default conflict policy for
  Phase 0 and defer manual conflict UX.
- Define reconnect-triggered automatic background sync and queue replay as the
  baseline recovery behavior.
- Set initial operational budgets for startup safety, reconnect dispatch, and
  sync completion.
- Define observability expectations for sync triggers, results, retries, and
  non-sensitive failure diagnostics.

## Phase 1 Implementation Foundation & Contracts

- Model sync-facing entities for user scope, medications, schedules, reminder
  settings, pending changes, conflict metadata, and user-visible sync states.
- Implement the first production-ready auth, queue, sync-status, and replay
  scaffolding required by the approved feature backlog.
- Define internal contracts between auth/session state, local repositories,
  cloud repositories, and the sync coordinator.
- Produce an implementation quickstart covering prerequisites, validation flows,
  and expected test targets for the next phase.
- Update agent context after the plan is written so downstream work inherits the
  chosen architecture and dependency direction.

## Post-Design Constitution Check

- `Plan Alignment`: Pass. The generated artifacts and implementation backlog remain
  within the approved sync foundation scope and map directly to the feature
  requirements.
- `Architecture Boundaries`: Pass. Contracts separate auth, local persistence,
  cloud persistence, and orchestration boundaries cleanly.
- `Test Coverage`: Pass. Research and quickstart identify unit, widget,
  integration, localization, and regression expectations before coding.
- `Offline-First Reliability`: Pass. Data model and contracts preserve local-first
  behavior, queued replay, and device-local notification scheduling.
- `Localization/Accessibility/Observability`: Pass. Sync status states, sign-in
  boundary messaging, RTL impact, and diagnostic signals are explicitly captured.

## Complexity Tracking

No constitution violations require justification for this planning phase.
