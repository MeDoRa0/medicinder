# Implementation Plan: Google Sign-In

**Branch**: `009-google-sign-in` | **Date**: 2026-04-08 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/009-google-sign-in/spec.md`

## Summary

Enable real Google sign-in from the first-launch entry gate by extending the
existing Firebase auth pipeline to exchange Google credentials, bootstrap the
user-scoped Firestore workspace, and expose a restorable authenticated session
that the launch router and sync status slice can both consume. Guest persistence
stays local-only, sign-out returns the user to the entry gate, and signed-out
settings UI must stop acting as an in-app upgrade path in this phase.

## Technical Context

**Language/Version**: Dart `^3.8.1` with Flutter stable  
**Primary Dependencies**: Flutter, `flutter_bloc`, `get_it`, `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`, `shared_preferences`, `intl`, `flutter_localizations`  
**Storage**: `SharedPreferences` keeps the guest-only resolved mode marker; Firebase Authentication manages authenticated session restoration; Firestore stores user-scoped workspace/profile metadata under `users/{userId}`; Hive medication and sync state remain unchanged  
**Testing**: `flutter_test`, unit tests for repository and use case logic, Cubit tests for auth and sync state transitions, widget tests for gate/launch routing, `flutter analyze`  
**Target Platform**: Flutter mobile app with Android and iOS as the supported live Google sign-in targets; desktop and web runners must remain compile-safe and local-only for this phase  
**Project Type**: Mobile app  
**Performance Goals**: Restoring a previously authenticated or guest session should resolve launch routing within 1 second on a typical development device; a successful Google sign-in should reach the main flow within 10 seconds on a normal network; the gate should show at most one active loading state per sign-in attempt  
**Constraints**: Google sign-in may start only from the first-launch entry gate; guest-to-account upgrade is out of scope; sign-out must clear the authenticated session and return to the gate; tokens and secrets must remain under Google/Firebase SDK management; new copy must be localized in English and Arabic and remain RTL-safe; diagnostics must stay non-sensitive; signed-out settings UI must not initiate Google sign-in in this phase  
**Scale/Scope**: Single Flutter app codebase; one provider-enabled auth path, one launch restoration update, one settings sync-state adjustment, one Firestore workspace bootstrap path, and automated coverage for success, cancellation, restoration, and sign-out behavior

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Plan-Driven Delivery**: PASS. The plan remains inside the approved Phase 2 scope: Google-authenticated entry from the first-launch gate, cancellation/error handling, session restoration, workspace/profile bootstrap, and sign-out routing only.
- **II. Flutter Clean Architecture Boundaries**: PASS. Provider SDK and Firebase work stays in `data`; repository contracts and auth/session entities stay in `domain`; Cubits, gate UI, and launch routing stay in `presentation`; dependency wiring and diagnostics stay in `core`.
- **III. Testable by Default**: PASS. The plan requires automated tests for repository restoration logic, Google sign-in result mapping, Cubit state transitions, launch routing decisions, settings sync-tile signed-out behavior, and widget-level gate feedback states.
- **IV. Offline-First Reliability**: PASS. Guest mode remains fully available without network access; failed or unavailable Google sign-in must not block local usage; Hive-backed medication data and offline notification behavior remain untouched for guests.
- **V. Authentication and Cloud Data Boundaries**: PASS. Google is the only live provider in this phase; guest resolution remains local-only; session restoration completes before routing; authenticated writes stay user-scoped under `users/{userId}`; no tokens are persisted outside provider/Firebase SDK storage; sign-out clears active access before further cloud behavior.
- **VI. Localization, Accessibility, and Observability**: PASS. The plan includes English/Arabic copy updates, RTL-safe gate behavior, loading/error semantics, and non-sensitive diagnostics for sign-in, cancellation, restore outcomes, and sign-out.

## Project Structure

### Documentation (this feature)

```text
specs/009-google-sign-in/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   |-- auth-session-orchestration-contract.md
|   `-- google-entry-ui-contract.md
|-- spec.md
`-- checklists/
    `-- requirements.md
```

### Source Code (repository root)

```text
lib/
|-- core/
|   |-- di/
|   `-- services/
|       `-- sync/
|-- data/
|   |-- datasources/
|   |   `-- auth/
|   `-- repositories/
|-- domain/
|   |-- entities/
|   |   |-- auth/
|   |   `-- sync/
|   |-- repositories/
|   `-- usecases/
|       |-- auth/
|       `-- sync/
|-- l10n/
`-- presentation/
    |-- cubit/
    |   |-- auth/
    |   `-- sync/
    |-- pages/
    `-- widgets/
        |-- auth/
        `-- sync/

test/
|-- data/
|   `-- datasources/
|       `-- auth/
|-- domain/
|   |-- entities/
|   |   `-- auth/
|   `-- usecases/
|       |-- auth/
|       `-- sync/
|-- presentation/
|   `-- cubit/
|       |-- auth/
|       `-- sync/
`-- widget/
```

**Structure Decision**: Keep the existing single Flutter app and extend the
Phase 1 auth-entry slice instead of creating a separate Google-auth feature
stack. Reuse the existing auth/sync repository boundary as the single source of
truth for authenticated cloud sessions, while preserving guest-mode persistence
inside the app-entry repository.

## Phase 0: Research

See [research.md](./research.md) for resolved decisions covering:

- Unifying Google-authenticated cloud access with the existing `AuthRepository`
  and `AuthSession` pipeline instead of adding a parallel session source
- Restoring authenticated app-entry state from Firebase-managed sessions first,
  while keeping `SharedPreferences` limited to guest-mode persistence
- Restricting live Google sign-in initiation to the first-launch gate and making
  signed-out settings sync UI non-entry-bearing in this phase
- Treating Google approval plus Firestore workspace/profile bootstrap as one
  success boundary
- Keeping Android and iOS as the active Google sign-in platforms while leaving
  other Flutter runners compile-safe and local-only
- Logging only coarse auth diagnostics and validating the flow with repository,
  Cubit, and widget tests

## Phase 1: Design & Contracts

- Data model documented in [data-model.md](./data-model.md)
- Internal contracts documented in [contracts/auth-session-orchestration-contract.md](./contracts/auth-session-orchestration-contract.md) and [contracts/google-entry-ui-contract.md](./contracts/google-entry-ui-contract.md)
- Validation and setup flow documented in [quickstart.md](./quickstart.md)

## Post-Design Constitution Check

- **I. Plan-Driven Delivery**: PASS. The design artifacts stay bounded to gate-only Google sign-in, restoration, sign-out, and workspace bootstrap without adding guest upgrade or Apple flows.
- **II. Flutter Clean Architecture Boundaries**: PASS. The contracts keep provider/Firebase details in `data`, preserve domain-level repository/use-case ownership, and keep route/UI state in Cubits and pages.
- **III. Testable by Default**: PASS. The design names repeatable unit, Cubit, and widget coverage for successful sign-in, cancellation, workspace bootstrap failure, restoration precedence, and post-sign-out routing.
- **IV. Offline-First Reliability**: PASS. Guest users keep local-only functionality when network or Firebase auth is unavailable, and authenticated failures fall back to a usable gate instead of blocking the app.
- **V. Authentication and Cloud Data Boundaries**: PASS. Guest persistence remains local-only, authenticated sessions restore through Firebase-managed state, Firestore bootstrap stays under `users/{userId}`, and signed-out settings UI no longer acts as an unauthorized in-app upgrade surface.
- **VI. Localization, Accessibility, and Observability**: PASS. The contracts require localized English/Arabic copy, loading/error semantics, RTL-safe presentation, and non-sensitive auth diagnostics.

## Complexity Tracking

No constitution violations or justified exceptions.
