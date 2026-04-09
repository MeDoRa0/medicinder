# Implementation Plan: Apple Sign-In for iOS

**Branch**: `010-apple-sign-in` | **Date**: 2026-04-09 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/010-apple-sign-in/spec.md`

## Summary

Enable real Apple sign-in from the first-launch entry gate on iOS by extending
the existing Firebase auth pipeline with an Apple-specific provider data source,
exchanging Apple credentials through Firebase Authentication, bootstrapping the
user-scoped Firestore workspace, and exposing a restorable authenticated session
that the launch router and sync slice can consume. Google behavior remains
unchanged, guest persistence stays local-only, unsupported platforms continue to
hide Apple entirely, and iOS devices that cannot use Apple sign-in must keep the
Apple option visible but disabled with clear feedback.

## Technical Context

**Language/Version**: Dart `^3.8.1` with Flutter stable  
**Primary Dependencies**: Flutter, `flutter_bloc`, `get_it`, `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`, `sign_in_with_apple`, `shared_preferences`, `intl`, `flutter_localizations`  
**Storage**: `SharedPreferences` keeps the guest-only resolved mode marker; Firebase Authentication manages authenticated session restoration; Firestore stores user-scoped workspace/profile metadata under `users/{userId}`; Hive medication and sync state remain unchanged  
**Testing**: `flutter_test`, unit tests for provider data source and use case logic, Cubit tests for auth and sync transitions, widget tests for gate/launch routing, `flutter analyze`  
**Target Platform**: Flutter mobile app with iOS 15+ as the supported live Apple sign-in target; Android, web, and desktop runners must remain compile-safe and local-only for Apple in this phase  
**Project Type**: Mobile app  
**Performance Goals**: Restoring a previously authenticated or guest session should resolve launch routing within 1 second on a typical development device; a successful Apple sign-in should reach the main flow within 10 seconds on a normal network; the gate should show at most one active loading state per provider attempt  
**Constraints**: Apple sign-in may start only from the first-launch entry gate on iOS; non-iOS runners must hide Apple entirely; iOS devices that cannot use Apple sign-in must show Apple as disabled with a localized unavailable message; guest-to-account upgrade and cross-provider account linking are out of scope; conflicts with existing non-Apple accounts must be blocked; stable Apple identity is sufficient for returning-user recognition; tokens and secrets must remain under Apple/Firebase SDK management; new copy must be localized in English and Arabic and remain RTL-safe; diagnostics must stay non-sensitive; signed-out settings UI must not become a second Apple entry point in this phase  
**Scale/Scope**: Single Flutter app codebase; one new provider data source, one Apple entry use case, one launch restoration update, one entry-gate/cubit expansion, one iOS runner capability/configuration update, and automated coverage for success, cancellation, unavailable-device, conflict, restoration, and sign-out behavior

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Plan-Driven Delivery**: PASS. The plan remains inside the approved Phase 3 scope: Apple-authenticated entry from the first-launch gate on iOS, cancellation/error handling, unavailable-device behavior, conflict blocking, session restoration, and sign-out routing only.
- **II. Flutter Clean Architecture Boundaries**: PASS. Apple provider SDK and Firebase credential exchange stay in `data`; repository contracts and auth/session entities stay in `domain`; Cubits, gate UI, and launch routing stay in `presentation`; dependency wiring, diagnostics, and platform configuration stay in `core` or iOS runner files.
- **III. Testable by Default**: PASS. The plan requires automated tests for Apple provider availability/result mapping, repository restoration logic, Apple sign-in result mapping, Cubit state transitions, launch routing decisions, and widget-level gate feedback states.
- **IV. Offline-First Reliability**: PASS. Guest mode remains fully available without network access; failed or unavailable Apple sign-in must not block local usage; Hive-backed medication data, offline queue behavior, and notification behavior remain untouched for guests.
- **V. Authentication and Cloud Data Boundaries**: PASS. Apple is the new live provider only on iOS; guest resolution remains local-only; session restoration completes before routing; authenticated writes stay user-scoped under `users/{userId}`; no tokens are persisted outside Apple/Firebase SDK storage; conflict cases do not auto-link accounts; sign-out clears active access before further cloud behavior.
- **VI. Localization, Accessibility, and Observability**: PASS. The plan includes English/Arabic copy updates, RTL-safe gate behavior, disabled/loading/error semantics, and non-sensitive diagnostics for Apple availability, attempt start, cancellation, failure, restore outcomes, and sign-out.

## Project Structure

### Documentation (this feature)

```text
specs/010-apple-sign-in/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   |-- apple-entry-ui-contract.md
|   `-- auth-session-orchestration-contract.md
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

ios/
|-- Runner/
|-- Runner.xcodeproj/
`-- Podfile

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
provider-extensible auth stack introduced for Google rather than creating a
separate Apple-auth subsystem. The implementation adds one Apple-specific data
source and one Apple entry use case, keeps session ownership inside the shared
auth repository, and limits platform-specific work to the iOS runner capability
and configuration files required for Apple Sign-In.

## Phase 0: Research

See [research.md](./research.md) for resolved decisions covering:

- Extending the shared auth/session pipeline with a dedicated Apple provider
  data source instead of branching the app-entry stack
- Keeping authenticated restoration sourced from Firebase-managed session state
  while leaving `SharedPreferences` limited to guest-mode persistence
- Representing Apple availability as a first-class gate state: hidden on
  non-iOS, visible and disabled on unavailable iOS devices, and enabled only
  when the current iOS device can actually start Apple Sign-In
- Treating Apple approval, Firebase credential exchange, and Firestore
  workspace/profile bootstrap as one success boundary
- Using stable Apple-backed identity as the canonical returning-user key while
  treating email and name as optional profile attributes
- Blocking cross-provider conflicts instead of auto-linking or creating
  duplicate accounts
- Keeping diagnostics non-sensitive and validating the flow with provider,
  repository, Cubit, widget, localization, and sign-out coverage

## Phase 1: Design & Contracts

- Data model documented in [data-model.md](./data-model.md)
- Internal contracts documented in [contracts/auth-session-orchestration-contract.md](./contracts/auth-session-orchestration-contract.md) and [contracts/apple-entry-ui-contract.md](./contracts/apple-entry-ui-contract.md)
- Validation and setup flow documented in [quickstart.md](./quickstart.md)

## Post-Design Constitution Check

- **I. Plan-Driven Delivery**: PASS. The design stays bounded to gate-only Apple sign-in on iOS, restoration, conflict blocking, unavailable-device behavior, and sign-out without adding guest upgrade or settings-based auth entry.
- **II. Flutter Clean Architecture Boundaries**: PASS. The contracts keep Apple provider and Firebase credential handling in `data`, preserve domain-level repository/use-case ownership, and keep route/UI state in Cubits and pages.
- **III. Testable by Default**: PASS. The design names repeatable provider, unit, Cubit, and widget coverage for successful sign-in, cancellation, unavailable-device state, conflict handling, workspace bootstrap failure, restoration precedence, and post-sign-out routing.
- **IV. Offline-First Reliability**: PASS. Guest users keep local-only functionality when Apple or network services are unavailable, and authenticated failures fall back to a usable gate instead of blocking the app.
- **V. Authentication and Cloud Data Boundaries**: PASS. Guest persistence remains local-only, authenticated sessions restore through Firebase-managed state, Firestore bootstrap stays under `users/{userId}`, unsupported platforms never expose Apple, and conflict cases do not create duplicate app identities.
- **VI. Localization, Accessibility, and Observability**: PASS. The contracts require localized English/Arabic copy, disabled/loading/error semantics, RTL-safe presentation, and non-sensitive diagnostics for Apple availability and auth outcomes.

## Complexity Tracking

No constitution violations or justified exceptions.
