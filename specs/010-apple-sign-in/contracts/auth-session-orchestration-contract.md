# Contract: Auth Session Orchestration

**Feature**: 010-apple-sign-in  
**Date**: 2026-04-09

## Purpose

Define the internal contract between app-entry restoration, Apple availability
resolution, provider-auth execution, sync status observation, and sign-out so
the application uses one coherent authenticated session model.

## Participants

- `AuthEntryCubit`
- `RestoreAppEntrySession`
- `SignInWithApple`
- `AuthRepository`
- `AuthRemoteDataSource`
- `AppleAuthProviderDataSource`
- `SyncStatusCubit`
- `AppEntryRepository`
- Firestore workspace bootstrap under `users/{userId}`

## Contract Rules

1. `RestoreAppEntrySession` MUST resolve authenticated state before reading the
   guest marker.
2. `AuthRepository` MUST expose one authoritative current-session/read/watch
   contract for authenticated cloud access across Google and Apple providers.
3. An Apple sign-in attempt is successful only when Apple approval, Firebase
   credential exchange, and Firestore workspace bootstrap all complete
   successfully.
4. `AppleAuthProviderDataSource` MUST expose whether Apple sign-in is available
   on the current iOS device so the gate can render the Apple option as
   disabled instead of starting a failing attempt.
5. Cross-provider conflicts MUST block the Apple sign-in attempt, MUST NOT
   auto-link accounts, and MUST NOT create a duplicate app identity or session.
6. `SyncStatusCubit` MUST consume the same authenticated session stream and must
   not maintain a separate Apple sign-in source.
7. Sign-out MUST clear the authenticated session first, then clear guest
   resolution state, then return routing to the entry gate.

## Repository and Data Source Shape

| Boundary | Required Behavior |
|----------|-------------------|
| `AuthRepository.getCurrentSession()` | Return the current Firebase-backed auth session, mapped into `AuthSession` with workspace readiness and `providerId` that may be `apple.com`. |
| `AuthRepository.watchSession()` | Emit signed-out, signing-in, workspace-initializing, ready, access-denied, and failed states as auth changes occur. |
| `AuthRepository.signInForSync(providerId)` | Accept an explicit provider selection; Phase 3 must support `apple.com` without changing existing Google behavior. |
| `AppleAuthProviderDataSource.getAvailability()` | Return whether Apple sign-in is available on the current iOS device so the gate can decide between enabled, disabled, or hidden Apple presentation. |
| `AppleAuthProviderDataSource.signIn()` | Start Apple approval only when availability is enabled and map provider outcomes into success, cancelled, unavailable, conflict, or failure results with non-sensitive codes. |
| `AuthRepository.signOutFromSync()` | Sign out the Firebase user and end active cloud-backed access immediately. |
| `AppEntryRepository.readResolvedEntryMode()` | Return only guest-mode persistence; authenticated restoration must not depend on this result. |
| `AppEntryRepository.clearResolvedEntryMode()` | Remove guest-mode persistence during sign-out or explicit reset. |

## Launch Restoration Sequence

```text
MainApp startup
  -> AuthEntryCubit.restoreSession()
  -> RestoreAppEntrySession
     -> AuthRepository.getCurrentSession()
        -> ready/apple => AppEntrySession.authenticated(apple)
        -> ready/google => existing Google restore remains valid
        -> signedOut => AppEntryRepository.readResolvedEntryMode()
           -> guest => AppEntrySession.guest
           -> none => AppEntrySession.unresolved
           -> unsupported => AppEntrySession.failure
  -> AppLaunchRouterPage routes to gate, settings, or home
```

## Apple Sign-In Sequence

```text
AuthEntryGatePage shown on iOS
  -> AuthEntryCubit resolves Apple availability
  -> Apple visible/enabled only when AppleAuthProviderDataSource reports availability

AuthEntryGatePage Apple tap
  -> AuthEntryCubit.signInWithApple()
  -> AuthRepository.signInForSync(providerId: "apple.com")
  -> AppleAuthProviderDataSource starts Apple flow
  -> FirebaseAuth credential exchange succeeds
  -> Firestore workspace/profile bootstrap succeeds
  -> AuthSession.ready(userId, providerId: "apple.com")
  -> AppEntrySession.authenticated(entryMode: apple)
  -> AppLaunchRouterPage routes forward
```

## Failure Mapping

| Failure Point | Required Result |
|---------------|-----------------|
| Apple unavailable on current iOS device | Keep the gate visible, keep Apple disabled, and do not start an auth attempt. |
| User cancels Apple approval | Return to the entry gate without saving an authenticated session. |
| Apple provider or credential conflict with an existing non-Apple account | Emit a conflict-blocked result with a clear message to use the original sign-in method; do not auto-link. |
| Apple provider or credential exchange failure | Emit a retryable failed session/result with non-sensitive feedback. |
| Firestore workspace bootstrap fails | Treat the overall sign-in attempt as failed and keep the user at the entry gate. |
| Unsupported runner | Hide Apple from the gate entirely. |
| Explicit sign-out | Emit signed-out state, clear app-entry marker, cancel notifications, and restore the gate. |

## Settings Sync Tile Contract

- When an authenticated session exists, the settings sync tile may show status
  and allow sign-out.
- When no authenticated session exists, the settings sync tile may communicate
  local-only mode but MUST NOT initiate Apple sign-in in Phase 3.
- The signed-out settings tile must remain consistent with the first-launch-gate
  scope boundary and avoid behaving like an in-app upgrade flow.
