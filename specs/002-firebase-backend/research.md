# Phase 0 Research: Firebase Backend Integration

## Decision 1: Keep Firebase-specific logic in data and composition layers

- **Decision**: Place Firebase Authentication and Firestore integration in `lib/data/datasources/**` and wire them through `lib/core/di/injector.dart`, while exposing only domain-safe repository interfaces to the rest of the app.
- **Rationale**: This preserves the constitution's clean architecture boundary, keeps domain logic platform-agnostic, and makes testing easier with fake or disabled data sources.
- **Alternatives considered**:
  - Call Firebase SDKs directly from Cubits: rejected because it leaks platform dependencies into presentation.
  - Put Firebase-specific classes in the domain layer: rejected because it couples business logic to implementation details.

## Decision 2: Use a user-scoped Firestore workspace rooted at `users/{userId}`

- **Decision**: Store all Phase 2 cloud-backed records under a per-user Firestore workspace rooted at `users/{userId}`, with child collections for medications, schedules, and notification settings.
- **Rationale**: This matches the Phase 1/plan direction, makes user isolation explicit, and gives later sync phases a stable path structure.
- **Alternatives considered**:
  - Flat top-level collections keyed by `userId`: rejected because authorization and record grouping become harder to reason about.
  - A single document for all user data: rejected because record-level updates and later sync granularity would be constrained.

## Decision 3: Auto-create the cloud workspace after the first successful sign-in

- **Decision**: Initialize the user's cloud workspace automatically the first time a valid authenticated session is established.
- **Rationale**: This removes manual setup friction, avoids a broken first-run cloud experience, and gives repository calls a consistent assumption that the workspace exists or will be provisioned lazily.
- **Alternatives considered**:
  - Require an explicit setup flow: rejected because it increases user friction for little product value.
  - Depend on out-of-band provisioning: rejected because it adds operational complexity and blocks local validation.

## Decision 4: Support a provider-extensible authentication contract

- **Decision**: Design the auth contract so Phase 2 can support multiple sign-in methods, while allowing Google Sign-In and Apple ID to be introduced incrementally without changing higher-level repository consumers.
- **Rationale**: The current code already abstracts auth behind repository and remote data source interfaces; expanding provider support within that abstraction avoids later churn.
- **Alternatives considered**:
  - Hard-code a single sign-in method in repository interfaces: rejected because it would force another contract break when more providers are added.
  - Implement full multi-provider account management now: rejected because it would expand scope beyond Phase 2 backend readiness.

## Decision 5: Treat cloud failures as recoverable and non-destructive

- **Decision**: Authentication or Firestore failures must block cloud-backed operations, preserve local data, and surface user-facing error states plus non-sensitive diagnostics.
- **Rationale**: Medicinder is offline-first and medication data cannot appear lost simply because cloud access failed.
- **Alternatives considered**:
  - Fail silently and retry later: rejected because users would not understand why cloud-backed actions did not complete.
  - Block local medication workflows on cloud availability: rejected because it violates the constitution's offline-first principle.

## Decision 6: Validate at repository and presentation boundaries

- **Decision**: Add automated tests around auth session mapping, workspace initialization behavior, user-scoped repository operations, and sync/account presentation states.
- **Rationale**: These are the lowest effective levels for proving Phase 2 behavior without relying on full end-to-end backend environments.
- **Alternatives considered**:
  - Rely mostly on manual Firebase testing: rejected because critical auth and storage behavior needs repeatable verification.
  - Add only UI tests: rejected because repository/data-source contracts are the highest-risk change points in this phase.
