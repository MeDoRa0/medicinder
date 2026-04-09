# Research: Apple Sign-In for iOS

## Decision 1: Extend the existing auth pipeline with a dedicated Apple provider data source

- **Decision**: Add an Apple-specific provider data source under
  `lib/data/datasources/auth/` and route `providerId: 'apple.com'` through the
  existing `AuthRemoteDataSource` / `AuthRepository` / `AuthSession` pipeline
  instead of introducing a second app-entry session stack.
- **Rationale**: Google sign-in already established a provider-extensible path
  for authenticated cloud access. Reusing that path keeps sync, launch routing,
  and sign-out behavior aligned and preserves clean architecture boundaries.
- **Alternatives considered**:
  - Put Apple provider logic directly in `AuthEntryCubit`: rejected because it
    would move provider SDK details into `presentation`.
  - Create a separate Apple-only repository: rejected because it would duplicate
    authenticated session ownership and restoration rules.

## Decision 2: Keep Firebase-managed restoration as the only authenticated restore source

- **Decision**: `RestoreAppEntrySession` should keep checking the current
  authenticated cloud session before consulting the guest marker in
  `SharedPreferences`, and Phase 3 should map `providerId: 'apple.com'` to
  `AppEntryMode.apple` without adding a local `"apple"` persistence marker.
- **Rationale**: Firebase Authentication already persists authenticated sessions
  securely. Adding a second local Apple marker would duplicate state and violate
  the constitution's minimum-persistence rule.
- **Alternatives considered**:
  - Persist `"apple"` in `SharedPreferences`: rejected because it adds drift
    without improving restore accuracy.
  - Restore Apple only from local app-entry state: rejected because it would
    ignore Firebase as the source of truth for authenticated sessions.

## Decision 3: Model Apple availability explicitly for the entry gate

- **Decision**: Treat Apple availability as a first-class gate state. The Apple
  option is hidden on non-iOS runners, visible and enabled on iOS when Apple
  sign-in is available, and visible but disabled with a localized unavailable
  message when the current iOS device cannot use Apple sign-in.
- **Rationale**: The clarified spec requires a different UX for unsupported
  platforms versus unavailable iOS devices. Making availability explicit avoids
  burying platform-specific checks in the widget tree and gives tests a stable
  state model to validate.
- **Alternatives considered**:
  - Hide Apple everywhere it cannot be used: rejected because unavailable iOS
    devices need explicit explanation, not silent removal.
  - Allow tapping Apple and fail only after the attempt starts: rejected because
    it creates avoidable dead-end interactions.

## Decision 4: Treat provider approval, Firebase credential exchange, and workspace bootstrap as one success boundary

- **Decision**: An Apple sign-in attempt is only successful after Apple approval,
  Firebase credential exchange, and `users/{userId}` workspace/profile bootstrap
  all complete successfully. If any step fails, the gate returns to an
  unresolved state with retryable, non-sensitive feedback.
- **Rationale**: The app treats authenticated entry as access to a usable
  user-scoped workspace, not merely possession of provider approval. This
  matches the existing Google behavior and prevents partial signed-in states.
- **Alternatives considered**:
  - Enter the app immediately after Apple approval and bootstrap later: rejected
    because it creates partial authenticated state and harder-to-test routing.
  - Save the authenticated session even when workspace bootstrap fails: rejected
    because it risks invalid cloud scoping and unclear recovery behavior.

## Decision 5: Use stable Apple-backed identity as the canonical returning-user key

- **Decision**: Returning Apple users should be recognized by the stable
  Apple-backed identity carried through the authenticated Firebase user, while
  email and name remain optional profile attributes when available.
- **Rationale**: Apple may provide reduced profile data on later approvals. The
  feature must not depend on email or name to restore access or prevent
  duplicate identities.
- **Alternatives considered**:
  - Require email for restoration: rejected because Apple may not resend it.
  - Require full profile details from the first sign-in: rejected because it
    makes successful restoration brittle and inconsistent with the clarified
    spec.

## Decision 6: Block cross-provider conflicts instead of auto-linking

- **Decision**: If the Apple attempt conflicts with an existing non-Apple
  account, map the result to a dedicated blocked/conflict state, keep the user
  on the entry gate, and show a clear message directing the user to the
  original sign-in method. Do not auto-link accounts or create a second app
  identity.
- **Rationale**: Cross-provider linking is explicitly out of scope. Blocking the
  attempt is safer than guessing user intent or risking duplicate cloud records.
- **Alternatives considered**:
  - Automatically link the Apple credential to the existing account: rejected
    because linking rules are not specified in this phase.
  - Create a second account for the same person: rejected because it would
    violate the clarified duplicate-account boundary.

## Decision 7: Keep diagnostics non-sensitive and center tests on availability and state transitions

- **Decision**: Log only coarse Apple auth events such as availability result,
  attempt started/cancelled/failed/conflict-blocked, workspace bootstrap
  failure class, restore outcome, and sign-out. Validation should emphasize
  provider data source mapping, restore/use-case behavior, Cubit transitions,
  widget-level gate states, and localized feedback.
- **Rationale**: This satisfies the constitution's observability requirement
  without exposing tokens or raw Apple payloads, and it targets the highest
  regression risks in this phase: provider availability, route correctness, and
  conflict handling.
- **Alternatives considered**:
  - Log raw provider payloads or tokens: rejected because it increases privacy
    and security risk.
  - Rely only on manual device validation: rejected because Apple-entry
    regressions would be too easy to reintroduce.
