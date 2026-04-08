# Contract: Launch Routing for Authentication Entry Gate

## Purpose

Define the expected route selection behavior for app startup once entry-state
restoration and local setup checks are complete.

## Inputs

- App process starts or rebuilds the root app shell
- Persisted local entry state is restored from `SharedPreferences`
- Local meal-time setup presence is checked
- Entry state may be cleared by sign-out or app data reset

## Outputs

- A transient restoring state while the launch decision is in progress
- `entryGate` destination when no valid resolved entry state exists
- `initialSettings` destination when guest entry is resolved but meal times are
  not yet configured
- `home` destination when guest entry is resolved and meal times are configured

## Rules

1. Launch routing must not show `HomePage` before entry-state restoration
   completes.
2. If no persisted resolved entry state exists, the app must show the auth entry
   gate.
3. If a valid persisted guest entry state exists, the app must skip the gate and
   continue to the existing meal-time setup check before routing home.
4. If a persisted non-guest or otherwise unsupported entry value is restored in
   Phase 1, the app must treat the restore as unresolved and return to the entry
   gate.
5. Clearing entry state through sign-out, reset, or local data removal must make
   the next launch show the entry gate again.
6. Launch routing must remain offline-safe and must not require Firebase auth or
   Firestore access in Phase 1.

## Validation Scenarios

1. Given a fresh install with no stored entry state, when the app launches, then
   the entry gate is shown before settings or home.
2. Given a stored guest entry and missing meal times, when the app launches, then
   the app skips the gate and routes to the initial settings screen.
3. Given a stored guest entry and existing meal times, when the app launches,
   then the app routes directly to `HomePage`.
4. Given an unsupported restored entry value such as `google`, when the app
   launches in Phase 1, then the app falls back to the entry gate and keeps guest
   available.
5. Given that app data is cleared or sign-out removes the stored entry marker,
   when the app launches again, then the entry gate is shown.
