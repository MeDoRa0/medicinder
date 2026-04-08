# Technical Implementation Plan: Google Sign-In, Apple Sign-In, and Guest Access

## Overview
Add a first-launch authentication gate to the app so new users can choose one of three entry paths:

1. Sign in with Google
2. Sign in with Apple on iOS devices only
3. Continue without registration

The app should remember the user’s choice and avoid showing the entry screen again after the first successful launch, unless the user signs out or clears app data.

## Goals
- Provide a simple, low-friction entry screen on first app open.
- Support Google authentication for all supported platforms.
- Support Apple authentication only when the device is running iOS.
- Allow guest usage without forcing registration.
- Keep authentication state persistent across app launches.
- Keep the solution aligned with the app’s existing Flutter architecture.

## User Experience Rules
- On first launch, show a full-screen choice page before the main app.
- Show the Apple Sign-In button only on iOS.
- Keep guest access available for users who do not want to register.
- After the user chooses any path, route them to the main app.
- On later launches, skip the choice page if a valid session or guest flag already exists.

## Phase 1: App Entry Gate
### Scope
- Detect first launch.
- Show the authentication choice screen.
- Handle platform-specific visibility for Apple Sign-In.
- Support guest entry.

### Output
- A reusable onboarding/auth gate view.
- A small persistence layer for first-launch and session flags.
- Navigation logic that decides whether to show the auth gate or the home flow.

### Acceptance Criteria
- First-time users see Google, Apple, and guest options.
- Apple Sign-In is hidden on non-iOS devices.
- Guest access enters the app successfully.
- Returning users do not see the gate again unless logged out.

## Phase 2: Google Sign-In
### Scope
- Implement Google authentication.
- Connect the signed-in Google user to the app’s user model.
- Handle loading, success, cancellation, and error states.

### Output
- Google auth service or repository method.
- Auth state updates after successful sign-in.
- User profile creation or sync if the app needs backend user records.

### Acceptance Criteria
- User can sign in with Google.
- App stores the authenticated session.
- Failed sign-in shows a clear error state.

## Phase 3: Apple Sign-In for iOS
### Scope
- Implement Apple authentication for iOS only.
- Keep the button hidden on Android and other platforms.
- Handle Apple auth response, cancellation, and errors.

### Output
- iOS-only Apple auth flow.
- Platform checks before rendering the button.
- Auth state updates after successful sign-in.

### Acceptance Criteria
- Apple Sign-In appears only on iOS.
- iOS users can authenticate successfully.
- Non-iOS users never see the Apple option.

## Phase 4: Guest Mode
### Scope
- Allow the user to continue without registration.
- Mark the session as guest/local-only if needed.
- Define what guest users can access.

### Output
- Guest session persistence.
- A clear way to distinguish guest users from registered users.
- Optional upgrade path later for converting guest users to full accounts.

### Acceptance Criteria
- Guest users can open and use the app.
- Guest state persists across app restarts.
- Guest users can later sign in if the app supports upgrading.

## State Management and Persistence
- Use a dedicated auth state manager to track:
  - authenticated user
  - guest user
  - loading state
  - error state
- Persist only the minimum data needed for session restoration.
- Restore session on app start before deciding which screen to show.

## Navigation Flow
1. App starts.
2. Check stored auth/guest state.
3. If no session exists, show the auth choice screen.
4. If a session exists, route directly to the main app.
5. After sign-in or guest entry, save state and navigate forward.

## Validation
Before implementation of each phase, confirm:
- the spec is clear,
- the plan matches the app’s current architecture,
- acceptance criteria are testable,
- platform-specific behavior is documented.

## Notes
- Keep authentication UI consistent with the app’s current design system.
- Keep the implementation modular so Google, Apple, and guest flows can be changed independently.
- Reserve room for future account linking or social login expansion.

