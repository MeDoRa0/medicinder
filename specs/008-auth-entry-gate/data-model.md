# Data Model: Authentication Entry Gate

**Feature**: 008-auth-entry-gate  
**Date**: 2026-04-08

## Entities

### 1. AppEntrySession

**Purpose**: Canonical app-level entry state used by launch routing and later
provider phases.

**Fields**:
- `status`: `restoring`, `unresolved`, `guest`, `authenticated`, or `failure`
- `entryMode`: `guest`, `google`, `apple`, or `none`
- `isResolved`: whether the launch decision can bypass the gate
- `restoredFromStorage`: whether the current state came from persisted local data
- `failureCode`: optional non-sensitive restoration or validation failure code
- `failureMessage`: optional localized-or-mappable failure message for UI and logs

**Validation rules**:
- `status = guest` requires `entryMode = guest` and `isResolved = true`
- `status = unresolved` requires `entryMode = none` and `isResolved = false`
- `status = authenticated` is reserved for later phases and must not be produced
  by Phase 1 persistence
- `status = failure` must fall back to showing the entry gate with guest still
  available

**State transitions**:
- `restoring` -> `unresolved` when no persisted state exists
- `restoring` -> `guest` when a valid guest marker is restored
- `restoring` -> `failure` when persisted state is invalid or unsupported
- `unresolved` -> `guest` when the user chooses guest entry
- `guest` -> `unresolved` when sign-out or local state clear occurs

### 2. PersistedEntryState

**Purpose**: Minimal local storage record used to restore the app-entry session.

**Fields**:
- `resolvedMode`: optional string key persisted in `SharedPreferences`

**Validation rules**:
- Absence of `resolvedMode` means first-launch or cleared state
- In Phase 1, the only supported persisted value is `guest`
- Any non-guest persisted value must be treated as unsupported for restoration
  and must route back to the entry gate

**Persistence rules**:
- Written only after successful guest selection
- Cleared on sign-out, local reset, or explicit entry-state reset
- Must never contain provider tokens, Firebase credentials, or Firestore
  workspace identifiers

### 3. EntryOptionViewModel

**Purpose**: UI description of each entry option on the gate.

**Fields**:
- `optionId`: `google`, `apple`, or `guest`
- `visible`: whether the option is rendered on the current platform
- `enabled`: whether tapping should perform a real entry action
- `availabilityLabelKey`: localized supporting text such as "coming soon"
- `semanticsLabelKey`: localized accessibility label

**Validation rules**:
- `guest` is always visible and enabled
- `google` is visible on supported app platforms in Phase 1 but disabled
- `apple` is visible only on supported iOS devices in Phase 1 and disabled there
- Disabled options must still expose accessible labels that describe
  unavailability

### 4. LaunchRouteDecision

**Purpose**: Final destination chosen after entry restoration and local setup
checks complete.

**Fields**:
- `destination`: `entryGate`, `initialSettings`, or `home`
- `session`: resolved `AppEntrySession`
- `mealTimesConfigured`: whether breakfast, lunch, and dinner times exist

**Validation rules**:
- `destination = entryGate` when `session.isResolved = false`
- `destination = initialSettings` when `session.isResolved = true` and meal
  times are incomplete
- `destination = home` when `session.isResolved = true` and meal times are
  already configured

## Relationships

- `PersistedEntryState` restores `AppEntrySession`
- `AppEntrySession` plus local meal-time setup determines `LaunchRouteDecision`
- `EntryOptionViewModel` is derived from platform plus Phase 1 feature scope, not
  persisted storage

## State Flow

```text
App Start
  -> restore PersistedEntryState
  -> build AppEntrySession
  -> if unresolved or invalid -> entryGate
  -> if guest resolved -> check meal-time setup
     -> incomplete -> initialSettings
     -> complete -> home
```

## Cloud Schema Impact

None. Phase 1 does not change Firestore collections, Firebase auth session
storage, or Hive medication schemas.
