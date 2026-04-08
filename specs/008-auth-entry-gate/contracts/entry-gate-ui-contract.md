# Contract: Authentication Entry Gate UI

## Purpose

Define the user-facing behavior of the first-launch entry gate in Phase 1.

## Inputs

- Current platform at runtime
- User taps on Google, Apple, or guest entry options
- Localized string resources for English and Arabic

## Outputs

- Visible Google option on all supported app platforms covered by this release
- Visible Apple option only on supported iOS devices
- Enabled guest option that continues into the app
- Clear disabled-state feedback for provider options that are not implemented yet

## Rules

1. The gate must render Google as visible but disabled in Phase 1 and label it
   as unavailable or coming soon.
2. The gate must render Apple only on supported iOS devices in Phase 1, and it
   must also be disabled with the same availability messaging.
3. The guest option must remain enabled regardless of connectivity state and must
   persist the resolved guest entry state when selected.
4. Tapping a disabled Google or Apple option must not navigate, must not persist
   a resolved state, and must keep the gate visible.
5. Disabled options must remain accessible through clear labels or hints that
   explain they are unavailable in this phase.
6. All new user-facing copy must exist in English and Arabic and preserve RTL
   layout behavior.

## Validation Scenarios

1. Given an iOS device, when the gate is shown, then Google, Apple, and guest
   options are present and only guest is actionable.
2. Given a non-iOS device, when the gate is shown, then Google and guest are
   present, Apple is hidden, and only guest is actionable.
3. Given the user taps Google or Apple in Phase 1, when the interaction
   completes, then the app remains on the gate and no resolved state is stored.
4. Given the user taps guest, when the interaction completes, then the guest
   entry state is stored and the app continues into the next launch destination.
5. Given Arabic localization is active, when the gate is shown, then all labels,
   disabled messaging, and layout remain readable and RTL-safe.
