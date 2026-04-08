# Implementation Plan: Authentication Entry Gate

**Branch**: `008-auth-entry-gate` | **Date**: 2026-04-08 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/008-auth-entry-gate/spec.md`

## Summary

Add a dedicated app-entry session layer and launch coordinator that restores a
minimal local guest-resolution state before routing, shows a full-screen entry
gate when no resolved state exists, keeps Google visible-but-disabled on all
platforms, shows Apple visible-but-disabled on iOS only, and then hands control
to the existing initial-settings or main-app flow without requiring real
provider authentication or guest-to-account merge behavior in Phase 1.

## Technical Context

**Language/Version**: Dart `^3.8.1` with Flutter stable  
**Primary Dependencies**: Flutter, `flutter_bloc`, `get_it`, `shared_preferences`, `firebase_auth`, `cloud_firestore`, `hive`, `hive_flutter`, `intl`, `flutter_localizations`  
**Storage**: `SharedPreferences` for minimal entry-resolution state; Hive remains the local medication source of truth; Firebase auth and Firestore remain untouched for disabled provider placeholders in this phase  
**Testing**: `flutter_test`, widget tests for launch routing and gate UI, unit tests for repository/use case/Cubit logic, `flutter analyze`  
**Target Platform**: Flutter application with Android and iOS as the primary user flows; other existing Flutter runners must remain compile-safe  
**Project Type**: Mobile app  
**Performance Goals**: Launch restoration and route decision should complete within 1 second on a typical development device; choosing guest should navigate forward in a single uninterrupted interaction; the app should show at most one transient loading state before the route is resolved  
**Constraints**: Phase 1 excludes real Google and Apple authentication; guest entry must remain fully offline-capable; only minimal local session metadata may be persisted; guest-local medication data must remain unattached to cloud-backed accounts until a later provider-auth phase defines upgrade or merge rules; Apple visibility must not break non-iOS runners; new copy must be localized in English and Arabic and remain RTL-safe; the new gate must coexist with the existing meal-time initial setup flow  
**Scale/Scope**: Single Flutter app codebase; one new launch-routing slice, one local entry-state persistence boundary, one full-screen auth choice page, and test coverage for first-launch, returning-guest, and disabled-provider behavior

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Plan-Driven Delivery**: PASS. The plan stays within the approved Phase 1 scope: launch gating, guest continuation, platform-specific provider visibility, disabled placeholders, and launch restoration only.
- **II. Flutter Clean Architecture Boundaries**: PASS. Launch-session entities, repository contracts, and use cases remain in `domain`; local persistence stays in `data`; routing Cubit/state and page widgets stay in `presentation`; DI wiring and diagnostics remain in `core`.
- **III. Testable by Default**: PASS. The plan requires unit coverage for entry-state persistence and launch decision logic, Cubit tests for restore and guest continuation, and widget tests for iOS/non-iOS gate behavior plus disabled-option interactions.
- **IV. Offline-First Reliability**: PASS. Guest entry and launch restoration are local-only, require no network, and do not change Hive-backed medication behavior or queued sync ownership.
- **V. Authentication and Cloud Data Boundaries**: PASS. Phase 1 introduces a provider-extensible app-entry abstraction without implementing provider SDK auth; only guest resolution is persisted locally; guest mode does not read or write Firestore or merge into cloud-backed state; unsupported restored provider states must fall back to the gate.
- **VI. Localization, Accessibility, and Observability**: PASS. The plan includes English/Arabic copy updates, RTL-safe layout, accessible disabled-button messaging, and non-sensitive logging for restore and route outcomes.

## Project Structure

### Documentation (this feature)

```text
specs/008-auth-entry-gate/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   |-- entry-gate-ui-contract.md
|   `-- launch-routing-contract.md
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
|-- data/
|   |-- datasources/
|   |   `-- auth/
|   `-- repositories/
|-- domain/
|   |-- entities/
|   |   `-- auth/
|   |-- repositories/
|   `-- usecases/
|       `-- auth/
|-- l10n/
|-- presentation/
|   |-- cubit/
|   |   `-- auth/
|   |-- pages/
|   `-- widgets/
`-- main.dart

test/
|-- data/
|   `-- datasources/
|       `-- auth/
|-- domain/
|   `-- usecases/
|       `-- auth/
|-- presentation/
|   `-- cubit/
|       `-- auth/
`-- widget/
```

**Structure Decision**: Keep the existing single Flutter app and add a focused
auth-entry slice across `presentation`, `domain`, `data`, and `core`. The
feature should not repurpose the existing sync-auth contracts directly because
those model cloud workspace readiness rather than guest-first launch routing.

## Phase 0: Research

See [research.md](./research.md) for resolved decisions covering:

- Separation of the new app-entry session abstraction from the existing sync auth session
- Minimal `SharedPreferences` storage for resolved guest entry
- Launch ordering between auth gate, existing meal-time setup, and `HomePage`
- Platform-safe Apple visibility and disabled-provider interaction behavior
- Diagnostics and test strategy for route restoration and guest continuation

## Phase 1: Design & Contracts

- Data model documented in [data-model.md](./data-model.md)
- Internal contracts documented in [contracts/launch-routing-contract.md](./contracts/launch-routing-contract.md) and [contracts/entry-gate-ui-contract.md](./contracts/entry-gate-ui-contract.md)
- Validation and setup flow documented in [quickstart.md](./quickstart.md)

## Post-Design Constitution Check

- **I. Plan-Driven Delivery**: PASS. The design artifacts remain limited to the Phase 1 gate and restore flow and do not absorb real provider authentication from later phases.
- **II. Flutter Clean Architecture Boundaries**: PASS. The contracts preserve layer ownership by keeping storage local, routing state in presentation, and future provider integration behind repository/use-case boundaries.
- **III. Testable by Default**: PASS. The design identifies repeatable unit and widget validation for restoration, guest persistence, disabled-provider taps, and launch routing after initial settings.
- **IV. Offline-First Reliability**: PASS. The launch decision works without connectivity, does not weaken Hive-backed local use, and keeps guest entry available when Firebase is unavailable.
- **V. Authentication and Cloud Data Boundaries**: PASS. The data model limits persisted state to resolved guest entry in Phase 1, leaves provider tokens and cloud sessions unmanaged here, does not define guest-to-account merge behavior in this phase, and explicitly routes unsupported restored provider states back to the gate.
- **VI. Localization, Accessibility, and Observability**: PASS. The contracts require localized copy, accessible disabled states, RTL-safe layout, and non-sensitive logs for restore outcomes and user actions.

## Complexity Tracking

No constitution violations or justified exceptions.
