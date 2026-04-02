<!--
Sync Impact Report
- Version change: template -> 1.0.0
- Modified principles:
  - Principle 1 -> I. Plan-Driven Delivery
  - Principle 2 -> II. Flutter Clean Architecture Boundaries
  - Principle 3 -> III. Testable by Default
  - Principle 4 -> IV. Offline-First Reliability
  - Principle 5 -> V. Localization, Accessibility, and Observability
- Added sections:
  - Implementation Standards
  - Workflow and Quality Gates
- Removed sections:
  - None
- Templates requiring updates:
  - updated .specify/templates/plan-template.md
  - updated .specify/templates/spec-template.md
  - updated .specify/templates/tasks-template.md
  - pending .specify/templates/commands/*.md (directory not present in this repository)
- Follow-up TODOs:
  - None
-->

# Medicinder Constitution

## Core Principles

### I. Plan-Driven Delivery
Every feature implementation MUST follow the approved `plan.md` for that feature or
initiative. Any deviation in architecture, dependencies, storage, sync strategy, or
delivery order MUST be reflected in `plan.md` before implementation continues.
Features MUST trace work back to the active spec, plan, and tasks artifacts so
implementation remains reviewable and reproducible.

Rationale: this project uses Spec-Kit to control feature scope and reduce drift
between design and implementation.

### II. Flutter Clean Architecture Boundaries
All production code MUST preserve the existing Flutter clean architecture layering:
`presentation`, `domain`, `data`, and `core`. UI state MUST be managed through
Cubits or project-approved state primitives at the presentation layer. Domain logic
MUST remain platform-agnostic. Data sources, Firebase integrations, Hive access, and
notification platform details MUST stay outside the domain layer. New dependencies
MUST be introduced at the narrowest layer that can own them.

Rationale: strict boundaries keep the codebase testable, scalable, and easier to
change as offline sync and notification features evolve.

### III. Testable by Default
Every non-trivial feature or bug fix MUST add or update automated tests at the
lowest effective level. Domain rules require unit tests. Cubit behavior and critical
UI flows require widget or integration tests when behavior cannot be proven in unit
tests alone. Plans and tasks MUST name the intended test coverage before coding
starts. A change is incomplete if its critical paths cannot be verified repeatedly.

Rationale: medication scheduling, sync state, and notification behavior are too
sensitive to rely on manual validation alone.

### IV. Offline-First Reliability
Local operation MUST remain the primary mode of the app. Hive-backed local data,
queued operations, and notification scheduling MUST continue to function without
network access. Cloud sync, authentication, and remote storage MUST augment local
behavior rather than replace it. Conflict resolution, replay behavior, migration
steps, and failure recovery MUST be defined in planning artifacts before data model
or sync changes ship.

Rationale: Medicinder must remain dependable for medication reminders even when the
device is offline or connectivity is unstable.

### V. Localization, Accessibility, and Observability
User-facing changes MUST include English and Arabic localization updates when new
copy is introduced, and MUST preserve RTL behavior. Interaction flows MUST remain
usable with clear labels, accessible affordances, and predictable states. Critical
operations such as scheduling, syncing, and data migration MUST emit actionable logs
or diagnostics suitable for debugging without exposing sensitive data.

Rationale: the app serves bilingual users across platforms, and health-adjacent
flows require supportability when issues occur in production.

## Implementation Standards

- Flutter and Dart best practices are mandatory: keep widgets focused, prefer
  composition over monoliths, avoid duplicated business logic, and isolate side
  effects behind services or repositories.
- Repository and service interfaces MUST be explicit about failure modes, async
  behavior, and serialization boundaries.
- Generated files, adapters, and schema migrations MUST be regenerated and reviewed
  whenever models or storage formats change.
- New storage, sync, or notification code MUST document any initialization order,
  permission requirements, or platform-specific constraints in the relevant plan or
  quickstart artifact.
- Feature work MUST prefer incremental delivery that leaves the application runnable
  after each completed user story.

## Workflow and Quality Gates

- `spec.md`, `plan.md`, and `tasks.md` MUST exist and agree on scope before major
  implementation begins.
- The Constitution Check in each plan MUST confirm architecture boundaries, testing
  scope, offline-first behavior, localization impact, and operational diagnostics.
- Pull requests or review-ready changes MUST list the tests run and identify any
  intentionally deferred coverage or platform validation.
- If a change affects notifications, sync, persistence, or authentication, the
  implementer MUST validate regression risk across app start-up, background resume,
  and recovery from stale local state.
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
  offline-first, and architecture requirements when applicable.
- Reviews MUST reject changes that bypass the plan, violate layer boundaries, or
  weaken offline reliability without an approved amendment.

**Version**: 1.0.0 | **Ratified**: 2026-04-01 | **Last Amended**: 2026-04-01
