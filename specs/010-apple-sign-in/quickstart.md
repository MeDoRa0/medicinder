# Quickstart: Apple Sign-In for iOS

**Feature**: 010-apple-sign-in  
**Date**: 2026-04-09

## Prerequisites

- Flutter stable SDK with Dart `^3.8.1`
- Existing Medicinder app builds successfully
- Firebase configuration is already present for iOS
- Apple Sign-In is enabled for the Firebase project used by the app
- Apple Sign-In capability is configured for the iOS app identifier in Apple
  Developer and Xcode
- iOS runner files are writable so Apple Sign-In entitlements/configuration can
  be added or updated

## Setup

Phase 3 adds one new runtime dependency for the live provider flow:

- `sign_in_with_apple`
- `crypto` for Apple nonce hashing before Firebase credential exchange

The iOS runner must also include the Apple Sign-In entitlement and mixed
localization support:

- `ios/Runner/Runner.entitlements` includes `com.apple.developer.applesignin`
- `ios/Runner.xcodeproj/project.pbxproj` sets `CODE_SIGN_ENTITLEMENTS`
- `ios/Runner/Info.plist` enables `CFBundleAllowMixedLocalizations`

The implementation should keep using the existing authentication and cloud
foundations already present in the project:

- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `shared_preferences`
- `flutter_bloc`
- `get_it`

No Hive adapter or medication schema change is required in this phase.

## Initialization Order

1. Initialize Flutter bindings, timezone data, Firebase bootstrap, and DI as
   the app already does in `main.dart`.
2. Register Apple-capable auth dependencies in `injector.dart` alongside the
   existing Google-capable auth and app-entry dependencies.
3. Start `AuthEntryCubit.restoreSession()` at app startup.
4. During restore, check the current authenticated cloud session before reading
   the guest marker from `SharedPreferences`.
5. On iOS, resolve Apple availability before enabling the Apple button on the
   gate.
6. Route authenticated or guest sessions into the existing meal-time setup
   decision and then to `HomePage`.
7. Route unresolved or failed restoration back to `AuthEntryGatePage`.
8. When the user starts Apple sign-in, exchange the Apple credential through
   Firebase Authentication, bootstrap the Firestore workspace, and only then
   treat the session as authenticated.
9. Keep `SyncStatusCubit` subscribed to the same auth session stream so settings
   and sync status reflect the authenticated Apple user automatically.
10. Keep the signed-out settings sync tile local-only. It may describe local
    mode, but it must not expose a second Apple sign-in entry point.

## Planned File Touchpoints

```text
pubspec.yaml
ios/Runner/Info.plist
ios/Runner.xcodeproj/project.pbxproj
ios/Runner/Runner.entitlements
lib/core/di/injector.dart
lib/data/datasources/auth/apple_auth_provider_data_source.dart
lib/data/datasources/auth/auth_remote_data_source.dart
lib/data/repositories/auth_repository_impl.dart
lib/domain/entities/auth/app_entry_session.dart
lib/domain/repositories/auth_repository.dart
lib/domain/usecases/auth/restore_app_entry_session.dart
lib/domain/usecases/auth/sign_in_with_apple.dart
lib/domain/usecases/sync/sign_in_for_sync.dart
lib/presentation/cubit/auth/auth_entry_cubit.dart
lib/presentation/cubit/auth/auth_entry_state.dart
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

### iOS

- Apple sign-in is live only from the first-launch entry gate.
- A successful Apple sign-in must create or refresh the user-scoped Firestore
  workspace before the app treats the session as authenticated.
- If Apple sign-in is unavailable on the current iOS device, the Apple option
  must remain visible but disabled with a clear localized message.
- Sign-out must return the user to the entry gate.

### Android, Web, and Desktop Runners

- The project must remain compile-safe.
- These runners must hide the Apple option and must not invoke Apple provider
  flows in this phase.
- Existing Google and guest behavior remains unchanged outside the Apple scope.

## Verification Commands

```bash
flutter test test/data/datasources/auth/apple_auth_provider_data_source_test.dart
flutter test test/data/datasources/auth/auth_remote_data_source_test.dart
flutter test test/domain/usecases/auth/sign_in_with_apple_test.dart
flutter test test/domain/usecases/auth/app_entry_usecases_test.dart
flutter test test/domain/usecases/sync/auth_session_usecases_test.dart
flutter test test/presentation/cubit/auth/auth_entry_cubit_test.dart
flutter test test/presentation/cubit/sync/sync_status_cubit_test.dart
flutter test test/widget/auth_entry_gate_test.dart
flutter test test/widget/app_launch_router_test.dart
flutter test test/widget/sync_accessibility_test.dart
flutter analyze lib/core/di/injector.dart lib/data/datasources/auth/apple_auth_provider_data_source.dart lib/data/datasources/auth/auth_remote_data_source.dart lib/domain/usecases/auth/restore_app_entry_session.dart lib/domain/usecases/auth/sign_in_with_apple.dart lib/presentation/cubit/auth/auth_entry_cubit.dart lib/presentation/pages/auth_entry_gate_page.dart
```

## Manual Validation Flow

1. Clear local app data and launch the app on an iOS device that supports Apple
   sign-in.
2. Confirm the entry gate appears before settings or home and shows Google,
   Apple, and guest options.
3. Tap Apple and complete the provider flow with a valid Apple account.
4. Confirm the app reaches initial settings or home as an authenticated user.
5. Relaunch the app and confirm the authenticated Apple session bypasses the
   gate.
6. Background the app after successful Apple sign-in, resume it, and confirm
   the authenticated session and route remain correct without showing a partial
   loading or gate state.
7. Sign out from the settings sync controls and confirm the app returns to the
   entry gate instead of continuing as guest.
8. Confirm the signed-out settings sync tile remains local-only and does not
   expose an Apple sign-in or upgrade action.
9. Repeat the flow with a cancelled Apple attempt and confirm the gate remains
   usable with guest access still available.
10. Simulate a conflict with an existing non-Apple account and confirm the gate
   shows a clear message instructing the user to use the original sign-in
   method without creating a new session.
11. Validate on an iOS device where Apple sign-in is unavailable and confirm
    the Apple option remains visible but disabled.
12. Validate on Android or another unsupported runner and confirm the Apple
    option is hidden and the app remains compile-safe.
13. Background the app after Apple sign-in, resume it, and confirm the
    authenticated route remains stable without showing the gate or a stuck
    loading state.
14. Simulate a stale guest marker plus an unrestorable Apple-authenticated
    session and confirm authenticated restore does not silently fall back to the
    guest marker.
15. Simulate a stale or unrestorable authenticated session and confirm the app
    clears the broken state and returns to the entry gate with guest access
    still available.

## Phase 3 Boundary

- Apple sign-in is enabled only from the first-launch entry gate on iOS.
- Google sign-in behavior remains unchanged in this phase.
- Guest-to-account upgrade, guest-data merge, and cross-provider linking remain
  out of scope.
- Medication sync logic, offline queue behavior, and notification regeneration
  are not re-specified here except where they consume the authenticated session.
