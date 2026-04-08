# Research: Google Sign-In

## Decision 1: Reuse the existing auth/sync session pipeline as the single authenticated source of truth

- **Decision**: Extend the current `AuthRemoteDataSource` / `AuthRepository` /
  `AuthSession` pipeline to support Google-based sign-in and workspace
  bootstrap, and let the app-entry restore flow consume that same authenticated
  session instead of introducing a second provider-session stack.
- **Rationale**: The repository already centralizes Firebase session watching,
  Firestore workspace bootstrap, local sync profile writes, and sign-out. Reusing
  it avoids divergent definitions of "signed in", keeps sync and launch routing
  aligned, and honors the constitution's provider-extensible contract rule.
- **Alternatives considered**:
  - Add a separate Google-only repository for the entry gate: rejected because it
    would duplicate session restoration and create conflicts with `SyncStatusCubit`.
  - Keep anonymous sync auth and add Google only for app entry: rejected because
    the app would then have two competing authenticated cloud identities.

## Decision 2: Restore authenticated entry from Firebase-managed session state before consulting guest persistence

- **Decision**: `RestoreAppEntrySession` should check the current authenticated
  cloud session first and return `AppEntrySession.authenticated(entryMode:
  google)` when a restorable Google-backed user exists; only if no authenticated
  session exists should it read the local guest marker from `SharedPreferences`.
- **Rationale**: Firebase Authentication already persists the signed-in user
  session securely. Requiring an extra local `"google"` marker would duplicate
  state and drift from the constitution's "minimum local session metadata" rule.
- **Alternatives considered**:
  - Persist `"google"` in `SharedPreferences`: rejected because it adds
    duplicate state without improving restoration accuracy.
  - Ignore authenticated restoration and rely only on guest persistence:
    rejected because it would violate the spec's returning-user requirement.

## Decision 3: Keep `SharedPreferences` limited to guest-mode persistence

- **Decision**: Continue storing only the guest resolved-mode marker locally and
  clear it on sign-out or explicit reset; authenticated session metadata remains
  under Google/Firebase SDK management.
- **Rationale**: Phase 1 already established a small local persistence boundary
  for guest routing. Keeping that boundary unchanged reduces migration risk and
  keeps local secrets/token storage out of scope.
- **Alternatives considered**:
  - Move authenticated state into the app-entry local data source: rejected
    because it would duplicate provider-managed session data.
  - Replace guest persistence with Firebase-only state: rejected because guest
    mode must still work without cloud access.

## Decision 4: Gate-only Google sign-in means signed-out settings UI must stop initiating auth

- **Decision**: Real Google sign-in starts only from the first-launch entry gate
  in this phase. When the user is signed out, the settings sync status tile may
  display local-only status but must not launch a Google sign-in flow or act as
  an in-app upgrade entry point.
- **Rationale**: The approved clarification explicitly limits Google sign-in
  availability to the first-launch gate. Leaving the existing signed-out "Enable
  Sync" action wired to provider auth would silently expand feature scope.
- **Alternatives considered**:
  - Keep the settings tile as a second Google sign-in surface: rejected because
    it violates the clarified scope.
  - Remove the sync tile entirely when signed out: rejected because signed-out
    status remains useful to communicate local-only mode.

## Decision 5: Treat Google approval and Firestore workspace/profile bootstrap as one success boundary

- **Decision**: A Google sign-in attempt is only successful after both provider
  approval and `users/{userId}` workspace/profile initialization succeed. If the
  provider succeeds but workspace bootstrap fails, the app returns a retryable
  error state and does not save an authenticated app-entry session.
- **Rationale**: The spec says authenticated entry requires linking the user to a
  single app user identity. The current auth pipeline already bootstraps the
  workspace; keeping that as part of the success boundary prevents partial
  signed-in states and user-scoping errors.
- **Alternatives considered**:
  - Let the user enter immediately after Google approval and finish workspace
    setup later: rejected because it creates partial authenticated state.
  - Save the session but block cloud features until bootstrap succeeds: rejected
    because the user experience becomes ambiguous and harder to test.

## Decision 6: Support live Google sign-in on Android and iOS, while keeping other runners compile-safe

- **Decision**: Implement live Google sign-in only for Android and iOS in this
  phase. Other Flutter runners must still build and route safely, but the app
  should not invoke Google provider SDK flows there.
- **Rationale**: The current product and Firebase setup are mobile-centric, and
  the app already treats iOS/Android as the primary auth-entry experience.
  Compile-safe fallback preserves development ergonomics without expanding the
  platform validation burden.
- **Alternatives considered**:
  - Enable Google sign-in on every Flutter runner immediately: rejected because
    it increases provider-configuration and QA scope beyond the approved feature.
  - Block non-mobile builds entirely: rejected because the repo already includes
    additional Flutter runners that should remain buildable.

## Decision 7: Keep diagnostics non-sensitive and focus testing on state transitions

- **Decision**: Log only coarse auth events such as restore outcome, Google
  attempt started/cancelled/failed, workspace bootstrap failure class, and
  sign-out. Validation should emphasize repository mapping, Cubit transitions,
  and widget-level gate routing/feedback.
- **Rationale**: This satisfies the constitution's observability requirement
  without exposing tokens or raw provider payloads, and it targets the highest
  regression risk in this phase: route and state correctness.
- **Alternatives considered**:
  - Add verbose provider payload logging: rejected because it increases privacy
    risk.
  - Rely only on manual testing: rejected because auth-entry regressions are too
    easy to reintroduce.
