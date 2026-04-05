# Contract: User-Scoped Cloud Repository

## Purpose

Define the repository expectations for CRUD access to Phase 2 cloud-backed records.

## Supported Record Types

- User profile records
- Medication records
- Medication schedule records
- Notification preference records

## Preconditions

1. A valid authenticated session exists.
2. The authenticated user's cloud workspace is ready.
3. Each create or update request carries a stable record identifier and a last-changed timestamp.

## Required Behaviors

1. Create, read, update, and delete operations must be scoped to the authenticated `userId`.
2. Requests without a valid authenticated user context must fail fast with a clear failure result.
3. A repository call must never read or mutate another user's records.
4. Stored records must preserve stable identifiers for later sync correlation.
5. Stored records must preserve a last-changed timestamp for later conflict resolution.
6. Partial failures must return a recoverable failure signal and must not imply local data loss.

## Record Storage Shape

- Workspace root: `users/{userId}`
- Child collections:
  - `profile`
  - `medications`
  - `schedules`
  - `notificationSettings`

## Validation Scenarios

1. Given a signed-in user, when they create a medication record, then the record is stored under their own workspace only.
2. Given a missing user context, when a repository operation is attempted, then the operation is rejected before cloud mutation occurs.
3. Given two different users, when each reads cloud-backed records, then each can access only their own records.
4. Given a record update, when the repository persists it, then the stable identifier and last-changed timestamp remain present.
