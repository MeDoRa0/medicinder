# Contract: Auth Session and Workspace Access

## Purpose

Define the expected behavior for Phase 2 authentication and authenticated cloud workspace readiness.

## Inputs

- User initiates sign-in with an available provider
- App resumes and checks the current authentication session
- User signs out

## Outputs

- Signed-out state with no cloud workspace access
- Signed-in state with one authenticated `userId`
- Workspace-ready state once the user's cloud workspace exists
- Recoverable failure state when authentication or workspace initialization fails

## Rules

1. All cloud-backed repository operations require a signed-in session.
2. The system must initialize a missing cloud workspace automatically after the first successful sign-in.
3. The authenticated session must resolve to exactly one user-scoped workspace.
4. Signing out must revoke cloud-backed access for the current session.
5. Failure states must preserve local-only functionality and provide user-facing feedback plus non-sensitive diagnostics.

## Validation Scenarios

1. Given a signed-out user, when the app checks session state, then cloud-backed actions remain unavailable.
2. Given a first-time sign-in, when authentication succeeds, then the workspace is created automatically and becomes ready for repository operations.
3. Given a returning signed-in user, when the app restores session state, then the existing workspace is reused.
4. Given an authentication or workspace initialization failure, when the user attempts cloud-backed access, then the app denies cloud operations without implying local data loss.
