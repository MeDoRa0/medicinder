# Quickstart: Authentication Entry Gate

**Feature**: 008-auth-entry-gate  
**Date**: 2026-04-08

## Prerequisites

- Flutter stable SDK with Dart `^3.8.1`
- Existing Medicinder app builds successfully
- `shared_preferences`, `flutter_bloc`, and `get_it` already available in
  `pubspec.yaml`
- Firebase configuration is optional for this phase because provider sign-in is
  not implemented yet

## Setup

No new package dependency is required for Phase 1. The implementation reuses:

```yaml
shared_preferences: ^2.0.0
flutter_bloc: ^9.1.1
get_it: ^9.2.0
firebase_auth: ^5.3.4
cloud_firestore: ^5.6.1
```

Phase 1 should add a local app-entry repository and launch Cubit without
changing Hive adapters or Firestore schema.

## Initialization Order

1. Initialize Flutter bindings, timezone data, Firebase bootstrap, and DI as the
   app already does in `main.dart`.
2. Restore locale state as today.
3. Restore the app-entry session from local storage before selecting the home
   route.
4. If the session is unresolved, render the auth entry gate.
5. If the session resolves to guest, check the existing meal-time setup state.
6. Route to `SettingsPage(isInitialSetup: true)` when meal times are missing, or
   `HomePage` when they already exist.

## Planned File Touchpoints

```text
lib/main.dart
lib/core/di/injector.dart
lib/data/datasources/auth/
lib/data/repositories/
lib/domain/entities/auth/
lib/domain/repositories/
lib/domain/usecases/auth/
lib/presentation/cubit/auth/
lib/presentation/pages/
lib/l10n/app_en.arb
lib/l10n/app_ar.arb
test/data/datasources/auth/
test/domain/usecases/auth/
test/presentation/cubit/auth/
test/widget/
```

## Platform Constraints

### iOS

- Apple entry is visible but disabled in Phase 1.
- No Apple provider SDK flow is triggered yet.

### Android and other non-iOS runners

- Apple entry is hidden.
- Google remains visible but disabled.
- The launch gate must remain compile-safe on desktop and web runners already
  present in the repository.

## Verification Commands

```bash
flutter test test/data/datasources/auth/app_entry_local_data_source_test.dart
flutter test test/domain/usecases/auth/app_entry_usecases_test.dart
flutter test test/presentation/cubit/auth/auth_entry_cubit_test.dart
flutter test test/widget/auth_entry_gate_test.dart
flutter test test/widget/app_launch_router_test.dart
flutter analyze lib/main.dart lib/core/di/injector.dart lib/presentation/pages/app_launch_router_page.dart lib/presentation/pages/auth_entry_gate_page.dart lib/presentation/cubit/auth/auth_entry_cubit.dart
```

## Manual Validation Flow

1. Clear app data or remove the stored entry marker and launch the app.
2. Confirm the auth entry gate appears before settings or home.
3. On iOS, confirm Apple is visible and disabled; on non-iOS, confirm it is
   hidden.
4. Tap Google or Apple and confirm the app remains on the gate.
5. Tap guest and confirm the app continues to initial settings when meal times
   are missing, or to home when they already exist.
6. Relaunch the app and confirm the gate is skipped after guest resolution.
7. If cloud sync is signed in, sign out from the settings screen and confirm the
   entry gate returns without requiring a full app restart.

## Phase 1 Boundary

- Guest mode stays device-local in this feature.
- Guest data does not attach to a cloud account.
- No guest-to-account merge flow exists yet.
- Google and Apple entry remain visible placeholders only; no provider-auth
  completion is implemented in this phase.

## Launch UX Validation Notes

- Launch routing should show one transient loading state while entry restore and
  meal-time routing complete.
- Restoring an existing guest marker should move to settings or home within the
  normal launch window for a local-only startup path.
- Unsupported stored modes such as `google` should return the user to the gate
  with guest still available.
