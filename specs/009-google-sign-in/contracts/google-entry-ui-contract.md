# Contract: Google Entry UI

**Feature**: 009-google-sign-in  
**Date**: 2026-04-08

## Purpose

Define the required behavior of the first-launch entry gate once Google becomes
live in Phase 2.

## Entry Options

| Option | Visibility | Enabled State | Behavior |
|--------|------------|---------------|----------|
| Google | Visible on platforms supported by the Phase 2 auth flow | Enabled when the gate is idle and the platform supports live Google sign-in | Starts Google sign-in and shows an in-progress state. |
| Apple | Visible on iOS only | Disabled in Phase 2 | Remains a placeholder and must not start live auth. |
| Guest | Visible on all runners | Enabled when the gate is idle | Continues as guest using the existing local-only flow. |

## Gate State Contract

| Gate Condition | Required UI Result |
|----------------|--------------------|
| `AppEntrySession.restoring` | Show a single loading state before route resolution. |
| `AppEntrySession.unresolved` | Show the entry gate with Google and guest actions available, plus Apple placeholder on iOS. |
| Google sign-in in progress | Disable all entry actions and show a visible progress indicator. |
| Google sign-in cancelled | Return to the idle gate without an authenticated session. |
| Google sign-in failed | Keep the gate visible, show a localized retryable error, and preserve guest availability. |
| `AppEntrySession.authenticated(google)` | Leave the gate and continue to launch routing. |
| `AppEntrySession.failure` after restoration | Show the gate and a non-sensitive localized message. |

## Interaction Rules

1. The Google button MUST be the only live provider-auth entry point in this
   phase.
2. The gate MUST prevent double-submission while a Google attempt is active.
3. A cancelled or failed Google attempt MUST NOT create a restorable
   authenticated state.
4. Guest access MUST remain selectable whenever no authenticated session has
   been established.
5. Sign-out MUST return the user to this gate rather than creating an automatic
   guest session.

## Localization and Accessibility

- New Google loading, failure, cancellation, and signed-out guidance strings
  MUST be added to both `app_en.arb` and `app_ar.arb`.
- Google loading and failure feedback MUST be available to screen readers via
  semantics/live-region-compatible presentation.
- The gate layout MUST remain RTL-safe and preserve current English/Arabic
  readability.
- Error text MUST not expose tokens, raw provider payloads, or exception dumps.

## Non-Mobile Runner Behavior

- Desktop and web runners must remain buildable.
- If live Google provider auth is not supported on a runner in this phase, the
  UI must not invoke provider sign-in there.
- Unsupported runners may continue presenting local-only entry behavior so long
  as they do not appear to complete Google authentication.
