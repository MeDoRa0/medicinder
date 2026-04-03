# Contract: Sync Engine Lifecycle

## Purpose

Define the expected behavior of the Phase 3 synchronization engine across
automatic triggers, lifecycle reporting, retry handling, and account scope.

## Inputs

- Active authentication session
- User-scoped local medication records
- User-scoped local pending changes
- User-scoped remote medication records
- Trigger source: `appStartup`, `connectivityRestored`, `userSignIn`, or `manualRetry`

## Preconditions

1. A valid signed-in session exists before cloud mutations or pulls begin.
2. Cloud-backed access is available for the authenticated user.
3. No other sync cycle is already running for the same active user.

## Required Behaviors

1. The engine must reject cloud synchronization when no signed-in user exists.
2. The engine must start automatically on app startup and connectivity
   restoration when a signed-in user has cloud-backed access available.
3. The engine must support manual retry without requiring a new app session.
4. The engine must upload local pending medication changes before finalizing the
   cycle result.
5. The engine must pull remote medication records and reconcile them against
   local records during the same cycle.
6. The engine must expose user-scoped lifecycle outcomes that distinguish idle,
   running, succeeded, and failed states.
7. The engine must prevent overlapping cycles for the same user.
8. A cycle that loses connectivity or encounters remote failure must finish as
   failed and keep retryable work available for a later cycle.
9. If some records succeed and others fail, the cycle may keep successful
   results, but it must still report an accurate failure outcome.
10. The engine must stop applying results for a user who is no longer the active
    signed-in account.

## Result Shape

- `success`: Whether the cycle completed without outstanding failures
- `userId`: Active user for the cycle
- `processedOperations`: Count of accepted pushed local changes
- `pulledRecords`: Count of remote records evaluated and applied locally
- `failedOperations`: Count of local changes or records that did not complete
- `message`: User-safe summary of the latest outcome

## Validation Scenarios

1. Given a signed-in user opens the app, when startup sync is dispatched, then
   the engine begins one cycle for that user and reports it as running.
2. Given connectivity returns after offline use, when reconnect handling runs,
   then the engine begins a retryable sync cycle without starting a duplicate
   concurrent cycle.
3. Given a cycle fails mid-run, when the cycle ends, then the engine reports a
   failure result and leaves unfinished work retryable.
4. Given the user signs out during an active cycle, when later results arrive,
   then those results do not overwrite the new active account state.
