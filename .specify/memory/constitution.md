<!--
Sync Impact Report
- Version change: 1.0.0 -> 1.1.0
- Modified principles:
  - V. Localization, Accessibility, and Observability -> V. Authentication and Cloud Data Boundaries
- Added sections:
  - VI. Localization, Accessibility, and Observability
- Removed sections:
  - None
- Templates requiring updates:
  - ✅ updated .specify/templates/plan-template.md
  - ✅ updated .specify/templates/spec-template.md
  - ✅ updated .specify/templates/tasks-template.md
  - ⚠ pending .specify/templates/commands/*.md (directory not present in this repository)
  - ✅ updated README.md
- Follow-up TODOs:
  - None
-->

# Medicinder Constitution

## Core Principles

### I. Plan-Driven Delivery
Every feature implementation MUST follow the approved `plan.md` for that feature or
initiative. Any deviation in architecture, dependencies, storage, sync strategy,
authentication flow, or delivery order MUST be reflected in `plan.md` before
implementation continues. Features MUST trace work back to the active `spec.md`,
`plan.md`, and `tasks.md` artifacts so implementation remains reviewable and
reproducible.

Rationale: this project uses Spec-Kit to control feature scope and reduce drift
between design and implementation.

### II. Flutter Clean Architecture Boundaries
All production code MUST preserve the existing Flutter clean architecture layering:
`presentation`, `domain`, `data`, and `core`. UI state MUST be managed through
Cubits or project-approved state primitives at the presentation layer. Domain logic
MUST remain platform-agnostic. Data sources, Firebase integrations, provider SDKs,
Hive access, and notification platform details MUST stay outside the domain layer.
New dependencies MUST be introduced at the narrowest layer that can own them.

Rationale: strict boundaries keep the codebase testable, scalable, and easier to
change as offline sync, authentication, and notification features evolve.

### III. Testable by Default
Every non-trivial feature or bug fix MUST add or update automated tests at the
lowest effective level. Domain rules require unit tests. Cubit behavior and critical
UI flows require widget or integration tests when behavior cannot be proven in unit
tests alone. Plans and tasks MUST name the intended test coverage before coding
starts. A change is incomplete if its critical paths cannot be verified repeatedly.

Rationale: medication scheduling, auth gating, sync state, and notification behavior
are too sensitive to rely on manual validation alone.

### IV. Offline-First Reliability
Local operation MUST remain the primary mode of the app. Hive-backed local data,
queued operations, and notification scheduling MUST continue to function without
network access. Cloud sync, authentication, and remote storage MUST augment local
behavior rather than replace it. Conflict resolution, replay behavior, migration
steps, guest-to-account upgrade rules, and failure recovery MUST be defined in
planning artifacts before data model or sync changes ship.

Rationale: Medicinder must remain dependable for medication reminders even when the
device is offline or connectivity is unstable.

### V. Authentication and Cloud Data Boundaries
Authentication flows MUST preserve a local-only path through guest access or disabled
cloud sync when Firebase is unavailable or the user declines registration. Supported
sign-in providers MUST be implemented behind a provider-extensible contract so UI,
domain, and sync orchestration do not depend on provider-specific SDK details.
Session restoration MUST complete before the app chooses between the authentication
gate and the main app flow. Firestore data MUST remain partitioned by authenticated
`userId` under a user-scoped workspace such as `users/{userId}`, and guest users
MUST NOT read or write cloud-backed records. Platform-specific providers such as
Apple Sign-In MUST render only on supported platforms and MUST degrade gracefully
elsewhere. The app MUST persist only the minimum local session metadata needed to
restore guest or authenticated state; tokens and secrets MUST remain under the
platform SDKs and Firebase-managed session storage.

Rationale: account identity and cloud backup are valuable, but they must never
compromise offline use, user isolation, or modularity.

### VI. Localization, Accessibility, and Observability
User-facing changes MUST include English and Arabic localization updates when new
copy is introduced, and MUST preserve RTL behavior. Interaction flows MUST remain
usable with clear labels, accessible affordances, and predictable states. Critical
operations such as authentication, scheduling, syncing, and data migration MUST emit
actionable logs or diagnostics suitable for debugging without exposing sensitive
data.

Rationale: the app serves bilingual users across platforms, and health-adjacent
flows require supportability when issues occur in production.

## Implementation Standards

- Flutter and Dart best practices are mandatory: keep widgets focused, prefer
  composition over monoliths, avoid duplicated business logic, and isolate side
  effects behind services or repositories.
- Repository and service interfaces MUST be explicit about failure modes, async
  behavior, serialization boundaries, and whether behavior is local-only,
  guest-capable, or cloud-backed.
- Authentication state management MUST use a dedicated abstraction that models
  authenticated, guest, loading, and error states explicitly.
- Generated files, adapters, and schema migrations MUST be regenerated and reviewed
  whenever models or storage formats change.
- New storage, sync, notification, or authentication code MUST document any
  initialization order, provider prerequisites, permission requirements, or
  platform-specific constraints in the relevant plan or quickstart artifact.
- Firestore writes, reads, and security assumptions MUST align on the same user
  workspace contract before cloud-backed behavior ships.
- Feature work MUST prefer incremental delivery that leaves the application runnable
  after each completed user story.

## Workflow and Quality Gates

- `spec.md`, `plan.md`, and `tasks.md` MUST exist and agree on scope before major
  implementation begins.
- The Constitution Check in each plan MUST confirm architecture boundaries, testing
  scope, offline-first behavior, auth and cloud data boundaries, localization
  impact, accessibility impact, and operational diagnostics.
- Features that touch authentication or cloud sync MUST document supported
  providers, guest behavior, session restoration, sign-out behavior, user-scoped
  data ownership, and upgrade or merge rules before implementation starts.
- Pull requests or review-ready changes MUST list the tests run and identify any
  intentionally deferred coverage or platform validation.
- If a change affects notifications, sync, persistence, or authentication, the
  implementer MUST validate regression risk across app start-up, background resume,
  auth cancellation or failure, and recovery from stale local state.
- Manual testing MAY supplement automation, but it MUST not replace automated
  coverage for business-critical behavior.

## Governance

This constitution overrides conflicting local habits and generic templates. Changes
to it require:

- a documented rationale,
- updates to any affected templates or guidance files,
- a semantic version decision recorded in the Sync Impact Report, and
- compliance verification in the next affected plan or review cycle.

Versioning policy:

- MAJOR: removes or materially redefines a governing principle or mandatory gate.
- MINOR: adds a new principle, section, or materially stronger requirement.
- PATCH: clarifies wording without changing expected behavior.

Compliance review expectations:

- Every implementation plan MUST pass the constitution gates before design proceeds.
- Every task list MUST include work needed to satisfy testing, localization,
  accessibility, offline-first, auth-boundary, and architecture requirements when
  applicable.
- Reviews MUST reject changes that bypass the plan, violate layer boundaries,
  weaken offline reliability, or break account-scoped cloud isolation without an
  approved amendment.

**Version**: 1.1.0 | **Ratified**: 2026-04-01 | **Last Amended**: 2026-04-08
