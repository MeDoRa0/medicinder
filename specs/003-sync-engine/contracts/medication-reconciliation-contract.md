# Contract: Medication Reconciliation

## Purpose

Define how Phase 3 compares and reconciles local and cloud medication records for
the same signed-in user.

## In-Scope Entity

- Medication record only

## Identity Rules

1. Local and cloud copies are matched by the same stable medication identifier.
2. Every cloud record must remain scoped to exactly one authenticated `userId`.

## Comparison Inputs

- Local medication record, including sync metadata and delete state
- Remote medication record, including sync metadata and delete tombstone fields
- Last-changed timestamp for both sides

## Required Behaviors

1. If a local record exists and no remote copy exists, the local change is
   eligible for upload.
2. If a remote record exists and no local copy exists, the remote record is
   eligible for local application.
3. If both sides exist and one side has the newer last-changed timestamp, the
   newer side wins.
4. If one side deletes the record and the other side updates it, deletion wins
   only when the deletion timestamp is newer than the competing update timestamp.
5. A winning delete must leave the record absent or marked deleted consistently
   on both sides after a successful cycle.
6. Reconciliation must not create duplicate medication records for the same
   identifier.
7. A successfully reconciled record must be marked locally as synchronized with a
   current last-synced timestamp.

## Failure Handling

1. A record that cannot be uploaded or applied locally must remain retryable for
   a later cycle.
2. A failed record must not cause already synchronized records in the same cycle
   to become unsynchronized again.

## Validation Scenarios

1. Given a local medication is newer than its cloud copy, when sync runs, then
   the cloud copy is updated and the local record becomes synchronized.
2. Given a cloud medication is newer than its local copy, when sync runs, then
   the local copy is updated to the remote winner.
3. Given a delete-versus-update conflict, when the delete timestamp is newer,
   then deletion becomes the winning result on both sides.
4. Given duplicate creation risk for the same medication identifier, when sync
   reconciles records, then exactly one synchronized record remains for that
   identifier.
