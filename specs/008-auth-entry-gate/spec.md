# Feature Specification: Authentication Entry Gate

**Feature Branch**: `008-auth-entry-gate`  
**Created**: 2026-04-08  
**Status**: Draft  
**Input**: User description: "read authintecatur_plan.md and create a specification for phase 1 only"

## Clarifications

### Session 2026-04-08

- Q: In phase 1, how should Google and Apple buttons behave before real provider authentication is implemented? -> A: Show them as disabled "coming soon" options.
- Q: What launch state should phase 1 persist? -> A: Persist only guest entry as a resolved state.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - First Launch Choice Gate (Priority: P1)

As a new user, I want the app to show a clear first-launch entry screen so I can
choose how to enter the app before I start using medication features.

**Why this priority**: The feature has no value unless first-time users are guided
into the app through an intentional entry choice instead of being dropped into the
main flow without context.

**Independent Test**: On a fresh install with no saved entry state, open the app
and confirm the choice screen appears before the main app and offers the supported
entry options for that device.

**Acceptance Scenarios**:

1. **Given** the app is opened for the first time and no prior entry state exists,
   **When** the launch check completes, **Then** the user sees a full-screen entry
   gate before the main app.
2. **Given** the app is opened for the first time on an iOS device, **When** the
   entry gate is shown, **Then** the user sees Google, Apple, and guest options,
   with guest available for immediate entry and the provider options clearly marked
   as unavailable in phase 1.
3. **Given** the app is opened for the first time on a non-iOS device, **When**
   the entry gate is shown, **Then** the user sees Google and guest options, with
   guest available for immediate entry, Google clearly marked as unavailable in
   phase 1, and Apple hidden.

---

### User Story 2 - Guest Entry to Main App (Priority: P2)

As a user who does not want to register yet, I want to continue as a guest so I
can use the app immediately without creating or restoring an account.

**Why this priority**: Guest access protects the product's offline-first value and
keeps the app usable even when users do not want cloud-backed sign-in.

**Independent Test**: On a fresh install, open the app, choose the guest option,
and verify that the user reaches the main app and is not shown the gate again on
the next launch unless the saved state is removed.

**Acceptance Scenarios**:

1. **Given** the user is on the entry gate, **When** the user chooses guest access,
   **Then** the user enters the main app without being required to register.
2. **Given** a user previously entered as a guest, **When** the app is opened again,
   **Then** the app routes directly to the main app without showing the entry gate.
3. **Given** a user previously tapped a disabled provider option in phase 1,
   **When** the app is opened again, **Then** the app still shows the entry gate
   because no resolved provider state was stored.

---

### User Story 3 - Returning User Launch Routing (Priority: P3)

As a returning user, I want the app to remember whether I already resolved the
entry choice so I do not have to repeat the first-launch gate on every start.

**Why this priority**: Remembering the resolved entry state removes friction from
repeat use and makes the launch flow feel intentional instead of repetitive.

**Independent Test**: Save a resolved entry state, relaunch the app, and verify the
gate is skipped; then remove the saved state or simulate sign-out and verify the
gate returns.

**Acceptance Scenarios**:

1. **Given** a previously resolved entry state exists and can be restored,
   **When** the app starts, **Then** the app skips the entry gate and routes the
   user directly to the main app.
2. **Given** the saved entry state has been cleared or a sign-out has occurred,
   **When** the app starts again, **Then** the app shows the entry gate before the
   main app.

---

### Edge Cases

- What happens when a returning user has a saved non-guest entry state but the app
  cannot restore it on launch? The app must return the user to the entry gate
  instead of leaving the launch flow unresolved.
- How does the system handle app data being cleared or reset? The app must treat
  the next launch as first-time use and show the entry gate again.
- If the device does not support Apple entry, the Apple option must remain hidden
  without leaving an empty or broken placeholder in the gate.
- If a user has no network access, guest entry must still remain available and the
  launch flow must still complete.
- If a user taps a disabled provider option in phase 1, the gate must remain on
  screen and clearly indicate that the provider path is not yet available.
- If a user closes the app after tapping a disabled provider option, the next launch
  must still show the entry gate because only guest entry is persisted in phase 1.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST evaluate launch state before showing the main app to
  determine whether the user needs the first-launch entry gate.
- **FR-002**: The system MUST show a full-screen entry gate when no previously
  resolved entry state is available.
- **FR-003**: The entry gate MUST present Google as a visible provider option on
  all supported platforms covered by this release.
- **FR-004**: In phase 1, the Google option MUST be visible but disabled and MUST
  clearly communicate that provider sign-in is not yet available.
- **FR-005**: The entry gate MUST present Apple as a visible option only on
  supported Apple devices and MUST hide it elsewhere.
- **FR-006**: In phase 1, the Apple option MUST be visible but disabled on
  supported Apple devices and MUST clearly communicate that provider sign-in is
  not yet available.
- **FR-007**: The entry gate MUST present a guest option that allows the user to
  continue into the main app without registration.
- **FR-008**: When the user chooses guest entry, the system MUST remember that
  resolved state for future launches until the user signs out or app data is
  cleared.
- **FR-009**: When a previously resolved entry state is restored successfully, the
  system MUST route the user directly to the main app without showing the entry
  gate again.
- **FR-010**: When a previously saved non-guest entry state cannot be restored at
  launch, the system MUST return the user to the entry gate and keep guest access
  available.
- **FR-011**: The system MUST persist only the minimum launch-state information
  needed to decide whether to show the entry gate or the main app, limited in
  phase 1 to a resolved guest-entry state.
- **FR-012**: The system MUST preserve access to local app usage for guest users
  and must not require account registration to reach the core medication flow.
- **FR-013**: Phase 1 scope MUST be limited to the entry gate, guest continuation,
  option visibility, disabled provider placeholders, and launch routing;
  completion of Google or Apple account authentication is out of scope for this
  specification.
- **FR-014**: Tapping a disabled Google or Apple option in phase 1 MUST NOT create
  a resolved entry state or cause future launches to skip the entry gate.

### Key Entities *(include if feature involves data)*

- **Entry State**: The saved launch decision that indicates whether the user should
  see the entry gate or go directly to the main app; in phase 1, only resolved
  guest entry is stored.
- **Entry Option**: A user-selectable path from the entry gate, such as Google,
  Apple, or guest.
- **Restored Session State**: The result of checking whether the app can resume a
  previously resolved entry path on launch.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of first-launch users with no saved entry state are shown the
  entry gate before reaching the main app.
- **SC-002**: 100% of users who choose guest entry can reach the main app in a
  single uninterrupted flow from the entry gate.
- **SC-003**: 100% of returning users with a restorable saved entry state bypass
  the entry gate on relaunch.
- **SC-004**: In validation across supported devices, the Apple option is shown on
  supported Apple devices and absent on non-Apple devices.

## Assumptions

- Phase 1 covers only the launch gate, guest continuation, and remembered routing;
  full third-party sign-in completion will be specified in later phases.
- Only guest entry produces a persisted resolved state in phase 1; disabled provider
  taps do not.
- A user who signs out is treated the same as a user whose resolved entry state has
  been cleared for the purpose of deciding whether to show the gate again.
- Guest-to-account upgrade or merge behavior is out of scope for phase 1. This
  feature does not migrate, merge, or attach guest-local medication data to a
  cloud-backed account; that behavior must be specified in a later authentication
  phase before provider sign-in is enabled.
- The app's core local medication experience remains available to guest users.
- The entry gate uses the app's existing visual language rather than introducing a
  separate onboarding product flow.
