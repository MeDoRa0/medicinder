# Research: Authentication Entry Gate

## Decision 1: Introduce a dedicated app-entry session abstraction instead of reusing the existing sync auth session

- **Decision**: Phase 1 will add a new app-entry session and launch-routing
  abstraction that explicitly models unresolved, guest, authenticated,
  restoring, and failure-oriented states for app entry, while leaving the
  existing `AuthSession` and sync-auth repository focused on cloud workspace
  readiness.
- **Rationale**: The current sync-auth contracts represent Firebase-backed cloud
  access and anonymous sign-in for sync, not guest-first launch routing. Reusing
  them for the entry gate would couple a local-only first-launch feature to
  backend semantics and make future Google/Apple provider expansion harder.
- **Alternatives considered**:
  - Reuse `AuthSession` directly: rejected because it does not model unresolved
    guest state cleanly and is tied to cloud workspace initialization.
  - Keep launch logic only in `main.dart` with nested `FutureBuilder`s: rejected
    because it would not satisfy the constitution's requirement for a dedicated
    abstraction that models auth and guest states explicitly.

## Decision 2: Persist only a minimal local guest-resolution marker in `SharedPreferences`

- **Decision**: Store only the minimum local metadata needed to restore Phase 1
  launch routing, limited to a resolved guest entry marker, in
  `SharedPreferences`.
- **Rationale**: `SharedPreferences` is already used by the app for launch-time
  settings such as language and meal times, so it fits a tiny launch-state
  record without adding Hive schema overhead. The approved clarification says
  only guest entry is persisted in Phase 1.
- **Alternatives considered**:
  - Use Hive for entry state: rejected because the state is too small to justify
    a new box or adapter in this phase.
  - Persist provider placeholders or richer session payloads: rejected because
    Google/Apple authentication is out of scope and the constitution limits
    stored metadata to the minimum needed for restore.

## Decision 3: Route in this order: restore entry state, then gate, then existing meal-time setup, then home

- **Decision**: On app start, the app should first restore the app-entry session.
  If no resolved state exists, show the auth entry gate. If guest entry is
  already resolved, continue into the existing meal-time setup check and then
  route to `HomePage`.
- **Rationale**: The spec requires first-launch users to see the entry gate
  before reaching the main app, while the current app already enforces an
  initial settings step when meal times are missing. This ordering preserves
  both behaviors without dropping either feature.
- **Alternatives considered**:
  - Show the meal-time setup before the auth gate: rejected because a true first
    launch would not show the required entry choice screen.
  - Remove or defer the meal-time setup gate: rejected because it would change
    existing launch behavior outside the feature scope.

## Decision 4: Use compile-safe platform detection and non-persisting disabled provider interactions

- **Decision**: Apple visibility should be determined with Flutter platform
  detection that remains safe on all supported runners, and disabled provider
  taps should never persist state or navigate; they should only surface a clear
  localized "coming soon" response.
- **Rationale**: The repository supports Android, iOS, desktop, and web runners.
  The spec requires Apple to appear only on supported iOS devices and to stay
  hidden elsewhere. Disabled taps must leave launch state unresolved in Phase 1.
- **Alternatives considered**:
  - Use `dart:io` platform checks everywhere: rejected because that can create
    compile issues on non-mobile runners.
  - Show Apple on all Apple-family platforms: rejected because the approved spec
    narrows visibility to iOS devices for this release.
  - Ignore disabled taps silently: rejected because the spec calls for clearly
    communicating unavailability.

## Decision 5: Keep diagnostics lightweight and non-sensitive, focused on restore and route outcomes

- **Decision**: Emit only coarse diagnostics for entry restoration and routing,
  such as restore result, selected path, unsupported restored state fallback, and
  disabled-provider interactions, without logging medication content, tokens, or
  personal account data.
- **Rationale**: The constitution requires observable auth-adjacent flows without
  exposing sensitive data. Phase 1 needs enough logging to debug gate regressions
  without introducing a heavy analytics subsystem.
- **Alternatives considered**:
  - No dedicated diagnostics: rejected because launch-gate regressions become
    difficult to isolate.
  - Verbose logs with account identifiers or raw payloads: rejected because they
    would exceed the minimum support need and increase privacy risk.

## Decision 6: Validate behavior with domain, Cubit, and widget tests before later provider phases

- **Decision**: Phase 1 testing will prioritize unit tests for local entry-state
  persistence and route-decision use cases, Cubit tests for restore and guest
  continuation flows, and widget tests for platform-specific option visibility,
  disabled states, localization, and launch routing.
- **Rationale**: The main risk in this phase is incorrect launch behavior rather
  than provider SDK integration. These tests cover the most failure-prone logic
  while remaining fast and repeatable.
- **Alternatives considered**:
  - Manual testing only: rejected because launch gating is business-critical and
    easy to regress.
  - Integration testing provider auth now: rejected because provider sign-in is
    explicitly out of scope for Phase 1.
