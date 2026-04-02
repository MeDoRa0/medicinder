# Quickstart: Phase 0 Cloud Sync Architecture

## Purpose

Use this guide to validate the Phase 0 design artifacts before implementation work
starts in later phases.

## Prerequisites

- Flutter SDK compatible with Dart `^3.8.1`
- Existing Medicinder repo checked out on branch `001-phase-0-sync-architecture`
- Firebase project planned for Authentication and Firestore
- Local Hive-based app flows working before any cloud integration begins
- Android `google-services.json` and iOS `GoogleService-Info.plist` available
  locally when cloud sync is being tested

## Read Order

1. Review [spec.md](C:\Users\medo2\Desktop\programming\medicinder\specs\001-phase-0-sync-architecture\spec.md).
2. Review [research.md](C:\Users\medo2\Desktop\programming\medicinder\specs\001-phase-0-sync-architecture\research.md).
3. Review [data-model.md](C:\Users\medo2\Desktop\programming\medicinder\specs\001-phase-0-sync-architecture\data-model.md).
4. Review [sync-boundaries.md](C:\Users\medo2\Desktop\programming\medicinder\specs\001-phase-0-sync-architecture\contracts\sync-boundaries.md).

## Implementation Readiness Checklist

- Confirm Hive remains the local source of truth.
- Confirm Firebase Authentication is required only for cloud sync.
- Confirm Firestore stores per-user mirrored data, not device notification state.
- Confirm reconnect triggers automatic background sync.
- Confirm conflicts resolve using last-write-wins on `updatedAt`.
- Confirm minimum user-visible states are `Not signed in`, `Syncing`, `Up to date`,
  and `Sync failed`.
- Confirm new sync copy will be localized in English and Arabic and must remain
  RTL-safe.

## Recommended Next Implementation Steps

1. Add Firebase dependencies and initialization scaffolding at the data layer.
2. Introduce auth/session abstractions that expose signed-in versus signed-out
   state without leaking Firebase directly into domain logic.
3. Define Hive-backed sync metadata storage for `PendingChange`, sync status, and
   conflict metadata.
4. Add Firestore mappers and repositories for medications, schedules, and reminder
   settings.
5. Implement the sync coordinator with reconnect triggers, queue replay, and
   last-write-wins conflict resolution.
6. Connect sync status into presentation-layer state and localized UI copy.
7. Regenerate local notifications from synchronized schedule data.

## Firebase Setup Notes

- Do not commit Firebase platform config files to the repository.
- If Firebase config is absent, the app should start in local-only mode and keep
  sync status at `Not signed in` or disabled.
- Firestore and Authentication should only be initialized after startup safety
  work is complete so reminder availability is not blocked.

## Verification Targets for Later Phases

- Unit tests:
  - conflict resolution based on `updatedAt`
  - queue replay ordering and retry behavior
  - auth-gated sync enablement
- Widget tests:
  - sync status rendering for all four user-visible states
  - signed-out versus signed-in cloud sync affordances
- Integration tests:
  - offline create/update/delete followed by reconnect replay
  - device-local notification regeneration after synced schedule changes
- Localization tests:
  - English and Arabic status strings
  - RTL-safe layout for sync and account states

## Commands

```powershell
flutter pub get
flutter analyze
flutter test test/core/services/sync/
```

## Exit Criteria

Phase 0 planning is complete when stakeholders approve the spec, plan, data model,
research decisions, and sync boundary contracts as the baseline for implementation.
