# Feature Specification: Google Sign-In

**Feature Branch**: `009-google-sign-in`  
**Created**: 2026-04-08  
**Status**: Draft  
**Input**: User description: "read authentication_plan.md and create a specification for phase 2 only"

## Clarifications

### Session 2026-04-08

- Q: Where should Google sign-in be available in phase 2? -> A: Only from the first-launch entry gate.
- Q: What should happen after a Google-authenticated user signs out? -> A: Clear the authenticated session and return to the entry gate.
- Q: What should happen if app user identity setup fails after Google approval? -> A: Show an error and keep the user at the entry gate.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Sign In With Google (Priority: P1)

As a user who chooses Google from the existing entry gate, I want to authenticate
with my Google account so I can enter the app as a registered user instead of
continuing as a guest.

**Why this priority**: This is the core value of phase 2. Without a complete
Google sign-in path, the feature does not deliver authenticated access.

**Independent Test**: Start from the existing entry gate with no resolved
session, complete Google sign-in with a valid account, and confirm the user
reaches the main app as an authenticated user with a restorable session.

**Acceptance Scenarios**:

1. **Given** the user is on the entry gate with no active session, **When** the
   user chooses Google sign-in and completes account approval successfully,
   **Then** the app signs the user in, associates the account to a single app
   user identity, saves the authenticated session, and routes the user to the
   main app.
2. **Given** the user signs in with a Google account that has not previously been
   linked to an app user identity, **When** sign-in succeeds, **Then** the app
   creates the required user identity record before granting authenticated access.
3. **Given** the user signs in again with a Google account that is already linked
   to an app user identity, **When** sign-in succeeds, **Then** the app restores
   access to that same user identity without creating a duplicate account.
4. **Given** the user completes Google account approval but the app cannot finish
   user identity setup, **When** the sign-in flow resolves, **Then** the app
   shows a clear error state, does not save an authenticated session, and keeps
   the user at the entry gate.

---

### User Story 2 - Recover From Cancellation Or Failure (Priority: P2)

As a user attempting Google sign-in, I want clear feedback when I cancel or when
sign-in fails so I can decide whether to retry, choose guest access, or leave
the gate without being stuck.

**Why this priority**: Authentication failures are common and must not leave the
user in a broken or ambiguous state.

**Independent Test**: From the entry gate, cancel the Google flow and separately
simulate a failed sign-in attempt; verify the gate stays usable, the user sees a
clear non-sensitive error state, and the user can retry or choose another path.

**Acceptance Scenarios**:

1. **Given** the user starts Google sign-in from the entry gate, **When** the
   user cancels before completion, **Then** the app returns the user to the entry
   gate, shows no authenticated session, and keeps other available entry options
   usable.
2. **Given** the user starts Google sign-in from the entry gate, **When** the
   attempt fails, **Then** the app shows a clear error state that explains the
   attempt was not completed without exposing sensitive data.
3. **Given** a prior Google sign-in attempt was cancelled or failed, **When** the
   user retries Google sign-in, **Then** the app starts a new sign-in attempt and
   does not require the user to restart the app first.

---

### User Story 3 - Restore Authenticated Session On Later Launches (Priority: P3)

As a returning Google-authenticated user, I want the app to recognize my existing
authenticated session on later launches so I can go directly to the main app
without repeating the entry gate.

**Why this priority**: Persistent session restoration removes repeat friction and
makes registered sign-in materially better than guest entry.

**Independent Test**: Sign in successfully with Google, close and reopen the app,
and verify the app restores the session and routes directly to the main app; then
invalidate the session and verify the app falls back to the entry gate.

**Acceptance Scenarios**:

1. **Given** the user previously completed Google sign-in successfully, **When**
   the app starts again and the session can still be restored, **Then** the app
   skips the entry gate and routes the user directly to the main app as the same
   authenticated user.
2. **Given** the user previously completed Google sign-in successfully, **When**
   the app starts again but the session can no longer be restored, **Then** the
   app clears the broken authenticated state and returns the user to the entry
   gate with Google and guest options available.
3. **Given** the user is currently authenticated through Google, **When** the
   user signs out, **Then** the app clears the authenticated session and returns
   the user to the entry gate instead of continuing as a guest automatically.

### Edge Cases

- What happens when the user loses connectivity or Google service availability
  during sign-in? The app must treat the attempt as incomplete, keep the user out
  of the authenticated area, and present a retryable error state.
- How does the system handle user cancellation during provider approval? The app
  must return to the entry gate without saving an authenticated session.
- What happens if a Google account is valid but the linked app user identity
  record is missing at first successful sign-in? The app must create the missing
  user identity record instead of creating duplicate identities for later attempts.
- What happens if Google account approval succeeds but the app cannot create or
  restore the required user identity? The app must treat sign-in as failed, show
  a retryable error state, and keep the user at the entry gate.
- What happens when a previously saved authenticated session exists but can no
  longer be restored on launch? The app must clear the unresolved authenticated
  state and show the entry gate again.
- What happens when an authenticated user signs out intentionally? The app must
  clear the authenticated session and show the entry gate again.
- What happens on existing Flutter runners that are outside the supported mobile
  Google sign-in flow for this phase? They must remain compile-safe and
  local-only, and must not appear to complete live Google authentication.
- If the user previously continued as a guest, guest-to-account upgrade and local
  data merge behavior are out of scope for this phase and must remain unchanged.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST allow a user to begin Google sign-in only from the
  existing first-launch entry gate on Android and iOS in this phase, while
  other existing Flutter runners remain local-only and compile-safe.
- **FR-002**: The system MUST show a visible in-progress state while Google
  sign-in is underway so the user can distinguish an active attempt from an idle
  gate.
- **FR-003**: The system MUST complete authenticated entry only after Google
  sign-in succeeds and the user is linked to a single app user identity.
- **FR-004**: The system MUST create the user's required app identity record when
  a successfully authenticated Google account has not previously been linked to
  one.
- **FR-005**: The system MUST reuse the existing linked app user identity when a
  returning user signs in again with the same Google account.
- **FR-006**: The system MUST save the minimum authenticated session state needed
  to restore direct access to the main app on later launches.
- **FR-007**: The system MUST restore a valid authenticated session on app launch
  before deciding whether to show the entry gate or the main app.
- **FR-008**: The system MUST return the user to the entry gate when Google
  sign-in is cancelled and MUST NOT save an authenticated session for a cancelled
  attempt.
- **FR-009**: The system MUST show a clear, observable error state when Google
  sign-in fails and MUST NOT expose tokens, provider payloads, or other sensitive
  authentication details in user-visible messaging.
- **FR-010**: The system MUST allow the user to retry Google sign-in after a
  failed or cancelled attempt without requiring an app restart.
- **FR-011**: The system MUST preserve guest or local-only access as an available
  alternative whenever no authenticated session has been established.
- **FR-012**: The system MUST treat medication and cloud-backed records accessed
  after Google sign-in as belonging only to the authenticated user's identity and
  MUST NOT expose another user's data when restoring or re-establishing a session.
- **FR-013**: If a previously saved authenticated session cannot be restored, the
  system MUST clear the unresolved authenticated state and return the user to the
  entry gate instead of leaving the user in a partial signed-in state.
- **FR-014**: If Google account approval succeeds but the app cannot create or
  restore the required app user identity, the system MUST treat the overall
  sign-in attempt as failed, show a clear retryable error state, and MUST NOT
  save an authenticated session.
- **FR-015**: When an authenticated user signs out, the system MUST clear the
  authenticated session and return the user to the entry gate without starting a
  guest session automatically.
- **FR-016**: This phase MUST be limited to Google-authenticated entry, session
  restoration, and related user identity establishment from the first-launch
  entry gate; Apple sign-in, in-app guest upgrade entry points, and
  guest-to-account data merge behavior are out of scope.

### Key Entities *(include if feature involves data)*

- **Authenticated Session**: The restorable proof that a specific user has
  completed Google sign-in and can be routed directly into the main app on later
  launches.
- **App User Identity**: The app-owned user record associated with one Google
  account and used to scope the user's data and access.
- **Sign-In Attempt State**: The observable state of a Google sign-in attempt,
  including idle, in progress, cancelled, failed, and successful completion.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In validation on supported Android and iOS devices, 100% of users
  with a valid Google account can complete sign-in from the entry gate and reach
  the main app in a single uninterrupted flow.
- **SC-002**: 100% of cancelled Google sign-in attempts return the user to a
  usable entry gate without leaving a saved authenticated session behind.
- **SC-003**: 100% of failed Google sign-in attempts present a clear retryable
  error state and keep the user out of authenticated content.
- **SC-004**: 100% of users with a restorable authenticated session bypass the
  entry gate on relaunch and are returned to the same app user identity.

## Assumptions

- Phase 1 already provides the entry gate, guest entry, and launch-routing
  structure that phase 2 builds on.
- In phase 2, live Google sign-in is supported on Android and iOS only, and
  only through the first-launch entry gate. Other existing Flutter runners
  remain local-only and must stay compile-safe.
- A successfully authenticated Google account must map to exactly one app user
  identity for the purposes of this phase.
- The app requires a user identity record for authenticated users so their
  personal data can be scoped correctly after sign-in.
- Guest-to-account upgrade, guest data merge, Apple sign-in, and broader account
  linking behavior are not changed by this phase.
