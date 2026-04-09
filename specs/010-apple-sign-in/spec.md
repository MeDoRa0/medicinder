# Feature Specification: Apple Sign-In for iOS

**Feature Branch**: `010-apple-sign-in`  
**Created**: 2026-04-09  
**Status**: Draft  
**Input**: User description: "read authentication_plan.md and create a specifications for phase 3 Phase 3: Apple Sign-In for iOS only"

## Clarifications

### Session 2026-04-09

- Q: What should happen if Apple sign-in appears to belong to an existing non-Apple account? → A: Block Apple sign-in and show a clear message to use the original sign-in method.
- Q: What identity is sufficient to recognize a returning Apple user? → A: A stable Apple account identity alone is sufficient; email and name are optional if provided.
- Q: How should the app behave on iOS if Apple sign-in is unavailable on the device? → A: Show the Apple option disabled with a clear unavailable message.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Sign In With Apple on iOS (Priority: P1)

As an iOS user who chooses Apple from the existing entry gate, I want to
authenticate with my Apple account so I can enter the app as a registered user
instead of continuing as a guest.

**Why this priority**: This is the core value of phase 3. Without a complete
Apple sign-in path on supported iOS devices, the feature does not deliver its
intended authenticated entry option.

**Independent Test**: Start from the existing entry gate on an iOS device with
no resolved session, complete Apple sign-in with a valid account, and confirm
the user reaches the main app as an authenticated user with a restorable
session.

**Acceptance Scenarios**:

1. **Given** the user is on the entry gate on an iOS device with no active
   session, **When** the user chooses Apple sign-in and completes account
   approval successfully, **Then** the app signs the user in, associates the
   account to a single app user identity, saves the authenticated session, and
   routes the user to the main app.
2. **Given** the user signs in with an Apple account that has not previously
   been linked to an app user identity, **When** sign-in succeeds, **Then** the
   app creates the required user identity record before granting authenticated
   access.
3. **Given** the user signs in again with an Apple account that is already
   linked to an app user identity, **When** sign-in succeeds, **Then** the app
   restores access to that same user identity without creating a duplicate
   account, using the stable Apple account identity even if profile details are
   limited.
4. **Given** the user completes Apple account approval but the app cannot finish
   user identity setup, **When** the sign-in flow resolves, **Then** the app
   shows a clear error state, does not save an authenticated session, and keeps
   the user at the entry gate.

---

### User Story 2 - Recover From Cancellation Or Failure (Priority: P2)

As an iOS user attempting Apple sign-in, I want clear feedback when I cancel or
when sign-in fails so I can decide whether to retry, choose guest access, or
leave the gate without being stuck.

**Why this priority**: Authentication interruptions are common and must not
leave the user in a broken or ambiguous state.

**Independent Test**: From the entry gate on an iOS device, cancel the Apple
flow and separately simulate a failed sign-in attempt; verify the gate stays
usable, the user sees a clear non-sensitive error state, and the user can retry
or choose another path.

**Acceptance Scenarios**:

1. **Given** the user starts Apple sign-in from the entry gate on an iOS device,
   **When** the user cancels before completion, **Then** the app returns the
   user to the entry gate, shows no authenticated session, and keeps other
   available entry options usable.
2. **Given** the user starts Apple sign-in from the entry gate on an iOS device,
   **When** the attempt fails, **Then** the app shows a clear error state that
   explains the attempt was not completed without exposing sensitive data.
3. **Given** a prior Apple sign-in attempt was cancelled or failed, **When** the
   user retries Apple sign-in, **Then** the app starts a new sign-in attempt and
   does not require the user to restart the app first.
4. **Given** an Apple sign-in attempt conflicts with an existing non-Apple
   account, **When** the conflict is detected, **Then** the app blocks the
   Apple sign-in attempt, shows a clear message to use the original sign-in
   method, and does not create a new authenticated session.
5. **Given** the user is on the entry gate on an iOS device where Apple
   sign-in is unavailable, **When** the gate is shown, **Then** the Apple
   option remains visible but disabled and explains that Apple sign-in is
   unavailable on that device.

---

### User Story 3 - Restore Apple Session On Later Launches (Priority: P3)

As a returning Apple-authenticated user on iOS, I want the app to recognize my
existing authenticated session on later launches so I can go directly to the
main app without repeating the entry gate.

**Why this priority**: Persistent session restoration removes repeat friction
and makes Apple sign-in materially better than guest entry for returning users.

**Independent Test**: Sign in successfully with Apple on an iOS device, close
and reopen the app, and verify the app restores the session and routes directly
to the main app; then invalidate the session and verify the app falls back to
the entry gate.

**Acceptance Scenarios**:

1. **Given** the user previously completed Apple sign-in successfully, **When**
   the app starts again and the session can still be restored, **Then** the app
   skips the entry gate and routes the user directly to the main app as the same
   authenticated user.
2. **Given** the user previously completed Apple sign-in successfully, **When**
   the app starts again but the session can no longer be restored, **Then** the
   app clears the broken authenticated state and returns the user to the entry
   gate with Apple and guest options available on iOS.
3. **Given** the user is currently authenticated through Apple, **When** the
   user signs out, **Then** the app clears the authenticated session and returns
   the user to the entry gate instead of continuing as a guest automatically.

### Edge Cases

- What happens when the user loses connectivity or Apple account services become
  unavailable during sign-in? The app must treat the attempt as incomplete, keep
  the user out of the authenticated area, and present a retryable error state.
- How does the system handle user cancellation during provider approval? The app
  must return to the entry gate without saving an authenticated session.
- What happens if an Apple account is valid but the linked app user identity
  record is missing at first successful sign-in? The app must create the missing
  user identity record instead of creating duplicate identities for later
  attempts.
- What happens if Apple account approval succeeds but the app cannot create or
  restore the required user identity? The app must treat sign-in as failed, show
  a retryable error state, and keep the user at the entry gate.
- What happens when a returning Apple user signs in again and the provider
  shares less profile information than it did earlier? The app must still
  recognize the linked user identity using the stable Apple account identity and
  allow sign-in to complete.
- What happens if an Apple sign-in attempt appears to match an existing
  non-Apple account? The app must block the Apple sign-in attempt, avoid
  creating a duplicate identity, and direct the user to use the original
  sign-in method.
- What happens when a previously saved authenticated session exists but can no
  longer be restored on launch? The app must clear the unresolved authenticated
  state and show the entry gate again.
- What happens on Android and other unsupported runners? They must never show
  the Apple option or appear to complete Apple authentication.
- What happens on an iOS device where Apple sign-in is unavailable? The Apple
  option must remain visible but disabled, with a clear unavailable message,
  and must not start an authentication attempt.
- If the user previously continued as a guest, guest-to-account upgrade and
  local data merge behavior are out of scope for this phase and must remain
  unchanged.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST allow a user to begin Apple sign-in only from the
  existing first-launch entry gate on iOS in this phase, while Android and other
  existing runners remain local-only and compile-safe.
- **FR-002**: The system MUST show the Apple option only on supported iOS
  devices and MUST hide it on unsupported platforms.
- **FR-002a**: On an iOS device where Apple sign-in is unavailable, the system
  MUST keep the Apple option visible but disabled, MUST explain that Apple
  sign-in is unavailable on that device, and MUST prevent the user from
  starting an Apple sign-in attempt.
- **FR-003**: The system MUST show a visible in-progress state while Apple
  sign-in is underway so the user can distinguish an active attempt from an idle
  gate.
- **FR-004**: The system MUST complete authenticated entry only after Apple
  sign-in succeeds and the user is linked to a single app user identity.
- **FR-005**: The system MUST create the user's required app identity record when
  a successfully authenticated Apple account has not previously been linked to
  one.
- **FR-006**: The system MUST reuse the existing linked app user identity when a
  returning user signs in again with the same Apple account.
- **FR-007**: The system MUST allow a returning user to complete Apple sign-in
  even when the provider returns less profile detail than it did during an
  earlier successful approval, as long as the same stable Apple account
  identity is still recognized.
- **FR-007a**: The system MUST treat the stable Apple account identity as
  sufficient to recognize and restore a returning Apple user; email and name
  are optional profile attributes when provided and MUST NOT be required to
  restore access.
- **FR-008**: The system MUST save the minimum authenticated session state needed
  to restore direct access to the main app on later launches.
- **FR-009**: The system MUST restore a valid authenticated session on app launch
  before deciding whether to show the entry gate or the main app.
- **FR-009a**: If an Apple sign-in attempt conflicts with an existing
  non-Apple account, the system MUST block the Apple sign-in attempt, MUST NOT
  create a new app user identity or authenticated session, and MUST direct the
  user to use the original sign-in method.
- **FR-010**: The system MUST return the user to the entry gate when Apple
  sign-in is cancelled and MUST NOT save an authenticated session for a
  cancelled attempt.
- **FR-011**: The system MUST show a clear, observable error state when Apple
  sign-in fails and MUST NOT expose tokens, provider payloads, or other
  sensitive authentication details in user-visible messaging.
- **FR-012**: The system MUST allow the user to retry Apple sign-in after a
  failed or cancelled attempt without requiring an app restart.
- **FR-013**: The system MUST preserve guest or local-only access as an available
  alternative whenever no authenticated session has been established.
- **FR-014**: The system MUST treat medication and cloud-backed records accessed
  after Apple sign-in as belonging only to the authenticated user's identity and
  MUST NOT expose another user's data when restoring or re-establishing a
  session.
- **FR-015**: If a previously saved authenticated session cannot be restored, the
  system MUST clear the unresolved authenticated state and return the user to the
  entry gate instead of leaving the user in a partial signed-in state.
- **FR-016**: If Apple account approval succeeds but the app cannot create or
  restore the required app user identity, the system MUST treat the overall
  sign-in attempt as failed, show a clear retryable error state, and MUST NOT
  save an authenticated session.
- **FR-017**: When an authenticated user signs out, the system MUST clear the
  authenticated session and return the user to the entry gate without starting a
  guest session automatically.
- **FR-018**: This phase MUST be limited to Apple-authenticated entry, session
  restoration, and related user identity establishment from the first-launch
  entry gate on iOS; Google sign-in, in-app guest upgrade entry points,
  guest-to-account data merge behavior, and entry-gate implementation changes
  are out of scope.

### Key Entities *(include if feature involves data)*

- **Authenticated Session**: The restorable proof that a specific user has
  completed Apple sign-in and can be routed directly into the main app on later
  launches.
- **App User Identity**: The app-owned user record associated with one Apple
  account and used to scope the user's data and access.
- **Stable Apple Account Identity**: The persistent provider identity used to
  recognize the same Apple account across sign-in attempts, even when optional
  profile fields are absent or reduced.
- **Sign-In Attempt State**: The observable state of an Apple sign-in attempt,
  including idle, in progress, cancelled, failed, and successful completion.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In validation on supported iOS devices, 100% of users with a valid
  Apple account can complete sign-in from the entry gate and reach the main app
  in a single uninterrupted flow.
- **SC-002**: 100% of cancelled Apple sign-in attempts return the user to a
  usable entry gate without leaving a saved authenticated session behind.
- **SC-003**: 100% of failed Apple sign-in attempts present a clear retryable
  error state and keep the user out of authenticated content.
- **SC-004**: 100% of users with a restorable Apple-authenticated session bypass
  the entry gate on relaunch and are returned to the same app user identity.
- **SC-005**: In validation across supported and unsupported devices, the Apple
  option is shown on supported iOS devices and absent on unsupported platforms.

## Assumptions

- Phase 1 already provides the entry gate, guest entry, and launch-routing
  structure that phase 3 builds on.
- Phase 2 already defines Google sign-in behavior, and this phase does not change
  Google scope or guest behavior.
- In phase 3, live Apple sign-in is supported on iOS only, and only through the
  first-launch entry gate. Android and other existing runners remain local-only
  and must stay compile-safe.
- A successfully authenticated Apple account must map to exactly one app user
  identity for the purposes of this phase.
- A stable Apple account identity is available for every successful Apple
  sign-in and is the canonical basis for recognizing returning users.
- The app requires a user identity record for authenticated users so their
  personal data can be scoped correctly after sign-in.
- Guest-to-account upgrade, guest data merge, broader account linking, and
  non-iOS Apple entry points are not changed by this phase. Cross-provider
  account linking remains out of scope.
