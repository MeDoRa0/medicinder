# Contract: Auth Session Orchestration

**Feature**: 009-google-sign-in  
**Date**: 2026-04-08

## Purpose

Define the internal contract between app-entry restoration, provider-auth
execution, sync status observation, and sign-out so the application uses one
coherent authenticated session model.

## Participants

- `AuthEntryCubit`
- `RestoreAppEntrySession`
- `AuthRepository`
- `AuthRemoteDataSource`
- `SyncStatusCubit`
- `AppEntryRepository`
- Firestore workspace bootstrap under `users/{userId}`

## Contract Rules

1. `RestoreAppEntrySession` MUST resolve authenticated state before reading the
   guest marker.
2. `AuthRepository` MUST expose one authoritative current-session/read/watch
   contract for authenticated cloud access.
3. A Google sign-in attempt is successful only when provider approval and
   Firestore workspace bootstrap both complete successfully.
4. `SyncStatusCubit` MUST consume the same authenticated session stream and must
   not maintain a separate sign-in source.
5. Sign-out MUST clear the authenticated session first, then clear guest
   resolution state, then return routing to the entry gate.

## Repository and Data Source Shape

| Boundary | Required Behavior |
|----------|-------------------|
| `AuthRepository.getCurrentSession()` | Return the current Firebase-backed auth session, mapped into `AuthSession` with workspace readiness. |
| `AuthRepository.watchSession()` | Emit signed-out, signing-in, workspace-initializing, ready, access-denied, and failed states as auth changes occur. |
| `AuthRepository.signInForSync(providerId)` | Accept an explicit provider selection; Phase 2 must support `google.com`. |
| `AuthRepository.signOutFromSync()` | Sign out the Firebase user and end active cloud-backed access immediately. |
| `AppEntryRepository.readResolvedEntryMode()` | Return only guest-mode persistence; authenticated restoration must not depend on this result. |
| `AppEntryRepository.clearResolvedEntryMode()` | Remove guest-mode persistence during sign-out or explicit reset. |

## Launch Restoration Sequence

```text
MainApp startup
  -> AuthEntryCubit.restoreSession()
  -> RestoreAppEntrySession
     -> AuthRepository.getCurrentSession()
        -> ready/google => AppEntrySession.authenticated(google)
        -> signedOut => AppEntryRepository.readResolvedEntryMode()
           -> guest => AppEntrySession.guest
           -> none => AppEntrySession.unresolved
           -> unsupported => AppEntrySession.failure
  -> AppLaunchRouterPage routes to gate, settings, or home
```

## Google Sign-In Sequence

```text
AuthEntryGatePage Google tap
  -> AuthEntryCubit.beginGoogleSignIn()
  -> AuthRepository.signInForSync(providerId: "google.com")
  -> AuthRemoteDataSource starts provider flow
  -> FirebaseAuth credential exchange succeeds
  -> Firestore workspace/profile bootstrap succeeds
  -> AuthSession.ready(userId, providerId: "google.com")
  -> AppEntrySession.authenticated(entryMode: google)
  -> AppLaunchRouterPage routes forward
```

## Failure Mapping

| Failure Point | Required Result |
|---------------|-----------------|
| User cancels Google approval | Return to the entry gate without saving an authenticated session. |
| Google provider error | Emit a retryable failed session/result with non-sensitive feedback. |
| Firestore workspace bootstrap fails | Treat the overall sign-in attempt as failed and keep the user at the entry gate. |
| Unsupported restored provider session | Clear unresolved route state and show the gate again. |
| Explicit sign-out | Emit signed-out state, clear app-entry marker, cancel notifications, and restore the gate. |

## Settings Sync Tile Contract

- When an authenticated session exists, the settings sync tile may show status
  and allow sign-out.
- When no authenticated session exists, the settings sync tile may communicate
  local-only mode but MUST NOT initiate Google sign-in in Phase 2.
- The signed-out settings tile must remain consistent with the first-launch-gate
  scope boundary and avoid behaving like an in-app upgrade flow.
