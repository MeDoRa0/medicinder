# Contract: Apple Entry UI

**Feature**: 010-apple-sign-in  
**Date**: 2026-04-09

## Purpose

Define the required behavior of the first-launch entry gate once Apple becomes
live on iOS in Phase 3.

## Entry Options

| Option | Visibility | Enabled State | Behavior |
|--------|------------|---------------|----------|
| Google | Visible on platforms supported by the existing Google auth flow | Enabled when the gate is idle and the runner supports live Google sign-in | Existing Google sign-in behavior remains unchanged. |
| Apple | Visible on iOS only | Enabled when the gate is idle and Apple is available on the device; disabled with an unavailable message when the iOS device cannot use Apple; hidden on non-iOS | Starts Apple sign-in only when enabled. |
| Guest | Visible on all runners | Enabled when the gate is idle | Continues as guest using the existing local-only flow. |

## Gate State Contract

| Gate Condition | Required UI Result |
|----------------|--------------------|
| `AppEntrySession.restoring` | Show a single loading state before route resolution. |
| `AppEntrySession.unresolved` on non-iOS | Show the entry gate with Google and guest actions only. |
| `AppEntrySession.unresolved` on iOS with Apple available | Show the entry gate with Google, Apple, and guest actions available. |
| `AppEntrySession.unresolved` on iOS with Apple unavailable | Keep Apple visible but disabled, show localized unavailable guidance, and keep Google and guest usable. |
| Apple sign-in in progress | Disable all entry actions and show a visible progress indicator. |
| Apple sign-in cancelled | Return to the idle gate without an authenticated session. |
| Apple sign-in conflict blocked | Keep the gate visible, show a localized message directing the user to the original sign-in method, and do not create a new session. |
| Apple sign-in failed | Keep the gate visible, show a localized retryable error, and preserve guest availability. |
| `AppEntrySession.authenticated(apple)` | Leave the gate and continue to launch routing. |
| `AppEntrySession.failure` after restoration | Show the gate and a non-sensitive localized message. |

## Interaction Rules

1. The Apple button MUST be a live provider-auth entry point only on iOS in
   this phase.
2. The gate MUST prevent double-submission while an Apple attempt is active.
3. A cancelled, conflict-blocked, or failed Apple attempt MUST NOT create a
   restorable authenticated state.
4. Guest access MUST remain selectable whenever no authenticated session has
   been established.
5. Sign-out MUST return the user to this gate rather than creating an automatic
   guest session.
6. Google button behavior MUST remain unchanged by the Apple-specific work.

## Localization and Accessibility

- New Apple loading, failure, cancellation, conflict, and unavailable-device
  strings MUST be added to both `app_en.arb` and `app_ar.arb`.
- Apple availability, loading, and failure feedback MUST be available to screen
  readers via semantics/live-region-compatible presentation.
- The gate layout MUST remain RTL-safe and preserve current English/Arabic
  readability.
- Error text MUST not expose tokens, raw provider payloads, or exception dumps.

## Non-iOS Behavior

- Android, web, and desktop runners must remain buildable.
- Non-iOS runners must hide the Apple option entirely.
- Unsupported runners may continue presenting existing Google and guest entry
  behavior so long as they do not appear to complete Apple authentication.
