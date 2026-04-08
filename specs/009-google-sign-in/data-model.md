# Data Model: Google Sign-In

**Feature**: 009-google-sign-in  
**Date**: 2026-04-08

## Entities

### 1. AppEntrySession

**Purpose**: Canonical app-entry state that the launch router uses before
deciding whether to show the entry gate, initial settings, or the main app.

**Fields**:
- `status`: `restoring`, `unresolved`, `guest`, `authenticated`, or `failure`
- `entryMode`: `none`, `guest`, `google`, or `apple`
- `isResolved`: whether the app may bypass the gate
- `restoredFromStorage`: whether the current state came from a restorable source
- `failureCode`: optional non-sensitive code for gate feedback and diagnostics
- `failureMessage`: optional UI-mappable failure detail

**Validation rules**:
- `status = authenticated` requires `entryMode = google` in Phase 2
- `status = guest` requires `entryMode = guest` and `isResolved = true`
- `status = unresolved` requires `entryMode = none` and `isResolved = false`
- `status = failure` must still route the user back to a usable entry gate

**State transitions**:
- `restoring` -> `authenticated` when a valid Google-backed cloud session is
  restored
- `restoring` -> `guest` when no authenticated session exists and a valid guest
  marker is present
- `restoring` -> `unresolved` when neither an authenticated session nor a guest
  marker exists
- `restoring` -> `failure` when restored auth state is unsupported or invalid
- `unresolved` -> `authenticated` when Google sign-in plus workspace bootstrap
  completes successfully
- `unresolved` -> `guest` when the user chooses guest access
- `authenticated` -> `unresolved` when the user signs out
- `failure` -> `unresolved` when the user retries from the gate

### 2. AuthSession

**Purpose**: Cloud-auth/session state used by sync orchestration and by
authenticated app-entry restoration.

**Fields**:
- `userId`: authenticated Firebase user identifier, absent when signed out
- `providerId`: provider key such as `google.com`
- `isSignedIn`: whether a provider-authenticated user currently exists
- `workspaceReady`: whether the user-scoped Firestore workspace is initialized
- `status`: `signedOut`, `signingIn`, `signedIn`, `workspaceInitializing`,
  `ready`, `accessDenied`, or `failed`
- `failureCode`: optional non-sensitive auth or bootstrap error code
- `failureMessage`: optional non-sensitive message for UI and diagnostics

**Validation rules**:
- `status = ready` requires `userId != null`, `isSignedIn = true`, and
  `workspaceReady = true`
- `status = signedOut` requires `userId = null` and `workspaceReady = false`
- `status = failed` must not be treated as a restorable authenticated
  app-entry session

**State transitions**:
- `signedOut` -> `signingIn` when a Google attempt begins
- `signingIn` -> `workspaceInitializing` when Google approval returns a user
- `workspaceInitializing` -> `ready` when Firestore bootstrap completes
- `signingIn` or `workspaceInitializing` -> `failed` when provider or workspace
  initialization fails
- `ready` -> `signedOut` when sign-out completes

### 3. PersistedEntryState

**Purpose**: Minimal local record that preserves guest-mode resolution across
app restarts.

**Fields**:
- `resolvedMode`: optional string value persisted in `SharedPreferences`

**Validation rules**:
- Absence of `resolvedMode` means no guest resolution exists
- In Phase 2, the only locally persisted value remains `guest`
- Authenticated Google restoration must not depend on a locally stored
  `resolvedMode = google`

**Persistence rules**:
- Written only after successful guest selection
- Cleared on sign-out, local reset, or explicit entry-state reset
- Must never store tokens, credentials, or Firestore document payloads

### 4. CloudUserWorkspace

**Purpose**: User-scoped Firestore workspace created or updated when a Google
user signs in successfully.

**Fields**:
- `userId`: owning authenticated user identifier
- `workspaceReady`: whether the cloud workspace is initialized for sync
- `providerIds`: provider identifiers associated with the Firebase user
- `status`: user record status such as `active`
- `createdAt`: first successful bootstrap timestamp
- `updatedAt`: latest bootstrap or refresh timestamp

**Validation rules**:
- Stored under `users/{userId}` and `users/{userId}/profile/summary`
- `userId` in the document path and body must match
- Guest users never create or read this workspace

### 5. GoogleSignInAttemptState

**Purpose**: Observable gate interaction state for a live Google sign-in attempt.

**Fields**:
- `phase`: `idle`, `inProgress`, `cancelled`, `failed`, or `succeeded`
- `feedbackCode`: optional UI-mappable code such as cancellation or bootstrap
  failure
- `retryAllowed`: whether the user may immediately try again

**Validation rules**:
- `phase = inProgress` disables additional entry actions
- `phase = cancelled` or `failed` must keep the gate usable
- `phase = succeeded` hands control to authenticated launch routing rather than
  lingering on the gate

## Relationships

- `AuthSession.ready(providerId = google.com)` produces
  `AppEntrySession.authenticated(entryMode: google)`
- `PersistedEntryState` may produce `AppEntrySession.guest` only when no live
  authenticated session exists
- `CloudUserWorkspace` is bootstrapped from a successful Google-authenticated
  `AuthSession`
- `GoogleSignInAttemptState` drives UI feedback while the underlying
  `AuthSession` is being established

## State Flow

```text
App Start
  -> restore AuthSession from FirebaseAuth
     -> ready/google -> AppEntrySession.authenticated -> settings/home
     -> signedOut -> read PersistedEntryState
        -> guest -> AppEntrySession.guest -> settings/home
        -> none -> AppEntrySession.unresolved -> entryGate

Entry Gate Google Tap
  -> GoogleSignInAttemptState.inProgress
  -> AuthSession.signingIn
  -> AuthSession.workspaceInitializing
  -> if workspace ready -> AppEntrySession.authenticated
  -> if cancelled/failed -> AppEntrySession.unresolved or failure -> entryGate
```

## Cloud Schema Impact

No new top-level collection is required. Phase 2 reuses the existing
user-scoped workspace pattern:

- `users/{userId}`
- `users/{userId}/profile/summary`

Medication documents and Hive medication schemas remain unchanged in this phase.
