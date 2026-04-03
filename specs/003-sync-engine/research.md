# Research: Sync Engine Implementation

## Decision 1: Automatic sync starts on app startup and connectivity restoration

- **Decision**: The Phase 3 engine will support automatic sync on signed-in app
  startup and on connectivity restoration, with manual retry remaining available
  and sign-in continuing to trigger an immediate sync entry point.
- **Rationale**: The clarified spec requires startup and reconnect behavior.
  Existing `SyncTrigger` values already model `appStartup`,
  `connectivityRestored`, `userSignIn`, and `manualRetry`, so the engine can
  adopt these triggers without inventing a new scheduling abstraction.
- **Alternatives considered**:
  - Manual-only sync: rejected because it conflicts with the approved startup and
    reconnect requirements.
  - Continuous background sync loop: rejected because it expands scope, increases
    battery/network complexity, and is not required for Phase 3.

## Decision 2: Conflict resolution stays last-write-wins with timestamped delete tombstones

- **Decision**: The engine will continue to use last-write-wins based on the
  record's last-changed timestamp, and deletion will win only when the deletion
  timestamp is newer than the competing update.
- **Rationale**: This matches the top-level roadmap, the Phase 3 spec, and the
  clarification outcome. It also fits the existing remote data shape, which
  persists `updatedAt` and `deletedAt` values for medication records.
- **Alternatives considered**:
  - Always prefer remote state: rejected because it would silently discard newer
    local changes.
  - Always prefer deletion: rejected because it would ignore the agreed
    timestamp-based conflict rule.
  - Manual conflict resolution UI: rejected because it belongs to a later,
    higher-complexity phase and is not required for this increment.

## Decision 3: The engine should consume queued local changes through an abstract boundary, not redesign the queue

- **Decision**: Phase 3 will consume queued local mutations through the existing
  local sync input boundary while treating durable queue ownership and queue
  redesign as Phase 4 work.
- **Rationale**: The repository already contains both legacy `SyncOperation`
  storage and newer `PendingChange` storage. The Phase 3 goal is the engine that
  uploads, pulls, merges, and reports outcomes; redesigning the durable queue now
  would blend Phase 3 and Phase 4 scope.
- **Alternatives considered**:
  - Fully migrate to `PendingChange` as part of Phase 3: rejected because it is a
    queue redesign and task decomposition concern better handled in Phase 4.
  - Keep only legacy `SyncOperation` handling in the design: rejected because the
    newer `PendingChange` shape already matches user-scoped retries and richer
    failure tracking better.

## Decision 4: Persist lifecycle state per active user and expose richer engine outcomes behind existing UI state

- **Decision**: The engine will maintain a user-scoped lifecycle snapshot that
  distinguishes idle, in progress, succeeded, and failed results, while the
  presentation layer continues mapping those results into localized sync status
  surfaces.
- **Rationale**: The spec requires accurate lifecycle outcomes, partial-failure
  reporting, and retry readiness. The current `SyncStatusViewState` is useful for
  UI, but the engine needs additional counts, timestamps, trigger source, and
  failure summaries to support tests and diagnostics cleanly.
- **Alternatives considered**:
  - Reuse only the UI-oriented view state enum as engine state: rejected because
    it is too lossy for partial-cycle and retry semantics.
  - Keep lifecycle state only in logs: rejected because the app must show correct
    failure and success outcomes.

## Decision 5: Diagnostics should log trigger, phase, counts, and failure class only

- **Decision**: Sync diagnostics will record trigger source, lifecycle phase,
  pushed and pulled record counts, retry counts, and coarse failure class, while
  excluding medication names, dosages, and serialized payload data.
- **Rationale**: The constitution requires actionable diagnostics for syncing
  without exposing sensitive user data. The existing `SyncDiagnostics` service
  already uses structured log lines and should be extended rather than replaced.
- **Alternatives considered**:
  - Log serialized record payloads for easier debugging: rejected due to privacy
    and supportability risk.
  - Emit no diagnostics: rejected because sync regressions become hard to
    troubleshoot across triggers and partial failures.

## Decision 6: Validation should focus on service logic first, then presentation reporting

- **Decision**: Testing will prioritize unit coverage for sync-service trigger,
  push, pull, merge, interruption, and retry behavior, followed by Cubit/widget
  validation that lifecycle outcomes surface correctly.
- **Rationale**: The core risk is correctness of reconciliation and lifecycle
  behavior. Presentation tests are still needed, but they are most useful after
  service semantics are fixed and repeatable.
- **Alternatives considered**:
  - Widget-heavy validation first: rejected because it would not sufficiently
    prove merge rules and interruption handling.
  - Integration-only validation: rejected because it would be slower to isolate
    failures and less aligned with the constitution's testable-by-default rule.
