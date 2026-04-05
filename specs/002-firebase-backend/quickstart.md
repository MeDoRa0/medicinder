# Quickstart: Firebase Backend Integration

## Goal

Validate Phase 2 Firebase backend integration locally without entering later sync-engine scope.

## Prerequisites

- Flutter SDK matching the project's stable channel
- Firebase project configured for the app
- Platform Firebase config files added for the target platform
- A Firestore database with rules that isolate data by authenticated user

## Setup

1. Install dependencies:
   ```powershell
   flutter pub get
   ```
2. Ensure Firebase is enabled for the target platform and the app can initialize `firebase_core`.
3. Start from a clean signed-out state in the app.

## Validation Flow

1. Launch the app and confirm signed-out users can still access local medication workflows.
2. Trigger sign-in and confirm a valid authenticated session is established.
3. Verify the user's cloud workspace is created automatically on first successful sign-in.
4. Create or update a supported cloud-backed record and confirm it is written under the signed-in user's workspace.
5. Sign out and confirm cloud-backed actions are no longer available.
6. Trigger an authentication or cloud failure path and confirm the app shows a clear message without implying local data loss.

## Suggested Automated Coverage

- Unit tests for auth session mapping and sign-in/sign-out repository behavior
- Unit tests for Firestore user-scoped CRUD guards and workspace initialization
- Widget or Cubit tests for signed-out, syncing/loading, ready, and failure presentation states

## Out of Scope Checks

- Do not validate automatic bidirectional synchronization in this phase
- Do not validate offline operation queue replay in this phase
- Do not validate notification rescheduling regeneration in this phase
