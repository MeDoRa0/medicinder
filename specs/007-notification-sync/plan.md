# Implementation Plan: Notification Synchronization

**Branch**: `007-notification-sync` | **Date**: 2026-04-06 | **Spec**: `/specs/007-notification-sync/spec.md`
**Input**: Feature specification from `/specs/007-notification-sync/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command.

## Summary

Ensure medication schedules and reminder configurations remain synchronized across devices while keeping notifications reliable. After every sync cycle, the system performs a **targeted notification regeneration** — only medications whose schedule data changed are processed. A new `NotificationSyncService` (domain-layer interface + core-layer implementation) listens for sync-complete events carrying `changedMedicationIds`, cancels stale future alarms for those medications via `NotificationOptimizer`, regenerates alarms from the local medication records, and emits a structured summary event into the existing `SyncDiagnostics` infrastructure. Sign-out cancels all scheduled notifications and clears the notification cache.

## Technical Context

**Language/Version**: Dart ^3.8.1  
**Primary Dependencies**: Flutter stable, `flutter_bloc`, `get_it`, `hive`, `hive_flutter`, `awesome_notifications`, `firebase_auth`, `cloud_firestore`, `equatable`, `connectivity_plus`  
**Storage**: Hive (local medications via `MedicationLocalDataSource`); Firestore (cloud medication records via `MedicationRemoteDataSource`). Notification state is ephemeral and device-local — never persisted to cloud.  
**Testing**: `flutter_test` (unit + widget tests)  
**Target Platform**: iOS / Android  
**Project Type**: mobile-app  
**Performance Goals**: Targeted notification regeneration for up to 50 changed medications completes within 5 seconds after sync.  
**Constraints**: Offline-capable; notifications must continue to work without network; no cloud push notifications — all reminders are local `AwesomeNotifications` alarms.  
**Scale/Scope**: Single Flutter app, personal medication management, local notification scheduling.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Plan-Driven Delivery**: ✅ Pass. All changes (SyncResult extension, NotificationSyncService, sign-out cleanup, diagnostics integration) are documented in this plan before implementation.
- **II. Flutter Clean Architecture Boundaries**: ✅ Pass. The notification regeneration contract is defined as a domain-layer abstract class. The implementation lives in `core/services`. `NotificationOptimizer` (platform detail) is injected behind the service interface. The presentation layer only reacts to state changes via existing Cubits.
- **III. Testable by Default**: ✅ Pass. `NotificationSyncService` logic (filter changed IDs, skip past doses, emit summary) is unit-testable with mocked `NotificationOptimizer` and `MedicationRepository`. Cubit integration is widget-testable.
- **IV. Offline-First Reliability**: ✅ Pass. Notifications are always scheduled from local Hive data. Sync merely triggers regeneration for changed records. No network dependency for alarm scheduling.
- **V. Localization, Accessibility, and Observability**: ✅ Pass. Notification content already uses localized strings. A structured `NotificationRegenerationSummary` event is emitted into `SyncDiagnostics` after each regeneration cycle.

## Project Structure

### Documentation (this feature)

```text
specs/007-notification-sync/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (created by /speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── di/
│   │   └── injector.dart                          # Register new service + updated SyncService
│   └── services/
│       ├── notification_optimizer.dart             # Add cancelScheduledNotifications (future-only)
│       └── sync/
│           ├── sync_service.dart                   # Extend _pullRemoteChanges to track changedMedicationIds
│           ├── sync_diagnostics.dart               # Add logNotificationRegenEvent()
│           └── notification_sync_service.dart      # [NEW] Core implementation
├── domain/
│   ├── entities/
│   │   └── sync/
│   │       └── notification_regen_summary.dart     # [NEW] Summary event entity
│   └── repositories/
│       └── sync_repository.dart                    # Extend SyncResult with changedMedicationIds
└── presentation/
    └── cubit/
        └── sync/
            └── sync_status_cubit.dart              # Invoke notification regeneration after sync; cancel on sign-out
```

**Structure Decision**: The structure remains a single Flutter mobile application project. No new layers or packages. The notification sync logic is a new service in `core/services/sync/` with its domain-layer entity in `domain/entities/sync/`. This follows the established pattern from prior phases.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations. Complexity is managed using the existing Clean Architecture patterns and the established `NotificationOptimizer` batch scheduling infrastructure.
