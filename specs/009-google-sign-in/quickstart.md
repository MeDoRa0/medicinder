# Quickstart: Google Sign-In

**Feature**: 009-google-sign-in  
**Date**: 2026-04-08

## Prerequisites

- Flutter stable SDK with Dart `^3.8.1`
- Existing Medicinder app builds successfully
- Firebase configuration is already present for Android and iOS
- Google Sign-In is enabled for the Firebase project used by the app
- Android and iOS client configuration required by the Google provider flow is
  available in the local Firebase setup

## Setup

Phase 2 adds one new runtime dependency for the live provider flow:

```yaml
google_sign_in: ^6.2.1
```

The implementation should keep using the existing authentication and cloud
foundations already present in the project:

```yaml
firebase_core: ^3.9.0
firebase_auth: ^5.3.4
cloud_firestore: ^5.6.1
shared_preferences: ^2.0.0
flutter_bloc: ^9.1.1
get_it: ^9.2.0
```

No Hive adapter or medication schema change is required in this phase.

## Initialization Order

1. Initialize Flutter bindings, timezone data, Firebase bootstrap, and DI as
   the app already does in `main.dart`.
2. Register Google-capable auth dependencies in `injector.dart` alongside the
   existing Firebase auth and app-entry dependencies.
3. Start `AuthEntryCubit.restoreSession()` at app startup.
4. During restore, check the current authenticated cloud session before reading
   the guest marker from `SharedPreferences`.
5. Route authenticated or guest sessions into the existing meal-time setup
   decision and then to `HomePage`.
6. Route unresolved or failed restoration back to `AuthEntryGatePage`.
7. Keep `SyncStatusCubit` subscribed to the same auth session stream so settings
   and sync status reflect the authenticated Google user automatically.

## Planned File Touchpoints

```text
pubspec.yaml
lib/core/di/injector.dart
lib/data/datasources/auth/auth_remote_data_source.dart
lib/data/datasources/auth/app_entry_local_data_source.dart
lib/data/repositories/auth_repository_impl.dart
lib/data/repositories/app_entry_repository_impl.dart
lib/domain/entities/auth/app_entry_session.dart
lib/domain/entities/sync/auth_session.dart
lib/domain/repositories/auth_repository.dart
lib/domain/repositories/app_entry_repository.dart
lib/domain/usecases/auth/restore_app_entry_session.dart
lib/domain/usecases/auth/clear_app_entry_state.dart
lib/domain/usecases/sync/sign_in_for_sync.dart
lib/presentation/cubit/auth/auth_entry_cubit.dart
lib/presentation/cubit/auth/auth_entry_state.dart
lib/presentation/cubit/sync/sync_status_cubit.dart
lib/presentation/pages/auth_entry_gate_page.dart
lib/presentation/pages/app_launch_router_page.dart
lib/presentation/widgets/sync/sync_account_tile.dart
lib/l10n/app_en.arb
lib/l10n/app_ar.arb
test/data/datasources/auth/
test/domain/usecases/auth/
test/domain/usecases/sync/
test/presentation/cubit/auth/
test/presentation/cubit/sync/
test/widget/
```

## Platform Constraints

### Android and iOS

- Google sign-in is live from the first-launch entry gate.
- A successful Google sign-in must create or refresh the user-scoped Firestore
  workspace before the app treats the session as authenticated.
- Sign-out must return the user to the entry gate.

### Desktop and Web Runners

- The project must remain compile-safe.
- These runners must not invoke unsupported live Google provider flows in this
  phase.
- Local-only guest behavior may remain available for development and validation.

## Verification Commands

```bash
flutter test test/data/datasources/auth/auth_remote_data_source_test.dart
flutter test test/domain/usecases/auth/app_entry_usecases_test.dart
flutter test test/domain/usecases/sync/auth_session_usecases_test.dart
flutter test test/presentation/cubit/auth/auth_entry_cubit_test.dart
flutter test test/presentation/cubit/sync/sync_status_cubit_test.dart
flutter test test/widget/auth_entry_gate_test.dart
flutter test test/widget/app_launch_router_test.dart
flutter analyze lib/core/di/injector.dart lib/data/datasources/auth/auth_remote_data_source.dart lib/domain/usecases/auth/restore_app_entry_session.dart lib/presentation/cubit/auth/auth_entry_cubit.dart lib/presentation/pages/auth_entry_gate_page.dart lib/presentation/widgets/sync/sync_account_tile.dart
```

## Manual Validation Flow

1. Clear local app data and launch the app.
2. Confirm the entry gate appears before settings or home.
3. Tap Google and complete the provider flow with a valid account.
4. Confirm the app reaches initial settings or home as an authenticated user.
5. Relaunch the app and confirm the authenticated session bypasses the gate.
6. Background the app after successful Google sign-in, resume it, and confirm
   the authenticated session and route remain correct without showing a partial
   loading or gate state.
7. Sign out from the settings sync controls and confirm the app returns to the
   entry gate instead of continuing as guest.
8. Repeat the flow with a cancelled Google attempt and confirm the gate remains
   usable with guest access still available.
9. Simulate workspace bootstrap failure and confirm the gate shows a retryable
   error without creating an authenticated session.
10. On a desktop or web runner, confirm the app stays compile-safe and local-only
    and does not attempt to complete a live Google sign-in flow.

## Phase 2 Boundary

- Google sign-in is enabled only from the first-launch entry gate.
- Apple sign-in remains out of scope and stays a placeholder.
- Guest-to-account upgrade and guest-data merge remain out of scope.
- Medication sync logic, offline queue behavior, and notification regeneration
  are not re-specified here except where they consume the authenticated session.
