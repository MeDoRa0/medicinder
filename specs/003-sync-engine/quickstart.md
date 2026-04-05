# Quickstart: Sync Engine Implementation

## Purpose

Validate the Phase 3 sync engine increment for startup triggers, reconnect
triggers, medication reconciliation, lifecycle reporting, and retry behavior.

## Prerequisites

1. Flutter SDK matching the repo toolchain is installed.
2. Dependencies are fetched with `flutter pub get`.
3. Firebase configuration used by the existing backend integration is available
   for the selected runtime environment.
4. A test account exists for cloud-backed validation.

## Suggested Implementation Sequence

1. Finalize the sync-engine lifecycle contract and medication reconciliation
   contract.
2. Extend `SyncRepository` and `SyncService` behavior to honor startup and
   reconnect triggers without overlapping cycles.
3. Persist lifecycle snapshots through sync state storage so presentation can
   surface accurate running, success, and failure outcomes.
4. Refine conflict resolution and remote pull behavior for timestamped updates
   and delete tombstones.
5. Add or update unit and widget tests before broad manual verification.

## Automated Validation Targets

Run analysis and the sync-focused tests first:

```powershell
flutter analyze
flutter test test/core/services/sync/conflict_resolver_test.dart
flutter test test/core/services/sync/sync_service_test.dart
flutter test test/presentation/cubit/sync/sync_status_cubit_test.dart
flutter test test/widget/sync_status_banner_test.dart
flutter test test/widget/sync_accessibility_test.dart
```

## Manual Validation Scenarios

### 1. Startup-triggered sync

1. Sign in with a cloud-enabled account.
2. Launch the app with unsynced local medication changes available.
3. Confirm the sync lifecycle moves into a running state shortly after startup.
4. Confirm the cycle ends in a success or failure state without duplicate cycles.

### 2. Reconnect-triggered sync

1. Sign in, then disable connectivity.
2. Make local medication changes.
3. Restore connectivity.
4. Confirm a sync cycle starts automatically and pushes the queued local changes.

### 3. Remote pull and merge

1. Prepare a newer medication record in the cloud for the signed-in user.
2. Start the app or trigger manual retry.
3. Confirm the local medication record converges to the expected winner.

### 4. Delete-versus-update conflict

1. Create a conflict where one side deletes a medication and the other side
   updates it.
2. Ensure the delete timestamp is newer than the competing update timestamp.
3. Run sync.
4. Confirm deletion wins and no duplicate local or remote copy remains.

### 5. Failure and retry handling

1. Cause a recoverable remote failure or interrupt connectivity mid-cycle.
2. Confirm the cycle reports failure rather than success.
3. Restore the backend or connectivity.
4. Trigger retry and confirm unfinished work can succeed later.

## Expected Observability

- Diagnostics identify the trigger source and lifecycle phase.
- Diagnostics include pushed, pulled, and failed counts.
- Diagnostics never log medication names, dosage content, or serialized payloads.

## Out of Scope Checks

- Do not treat queue redesign as part of this feature.
- Do not validate notification regeneration here; that belongs to Phase 5.
