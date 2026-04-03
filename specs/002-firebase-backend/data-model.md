# Data Model: Firebase Backend Integration

## 1. Cloud User Workspace

- **Purpose**: Root cloud container for one authenticated Medicinder user.
- **Identifier**: `userId`
- **Relationships**:
  - Owns zero or one `User Profile Record`
  - Owns many `Medication Record`
  - Owns many `Medication Schedule Record`
  - Owns many `Notification Preference Record`
- **Validation rules**:
  - Must exist only for an authenticated user
  - Must be created automatically on first successful sign-in if missing
  - Must not expose another user's records
- **Lifecycle**:
  - `missing` -> `initialized` when the authenticated user signs in for the first time
  - `initialized` -> `accessible` while the authenticated session is valid
  - `accessible` -> `inaccessible` when signed out or access is denied

## 2. User Profile Record

- **Purpose**: Minimal cloud-backed identity profile associated with the current authenticated user.
- **Fields**:
  - `userId`: stable unique identifier
  - `providerIds`: supported sign-in methods linked to the account
  - `createdAt`: first cloud workspace creation time
  - `updatedAt`: most recent profile update time
  - `status`: active or inaccessible
- **Validation rules**:
  - `userId` must match the owning workspace
  - `providerIds` must contain at least one provider for a signed-in profile

## 3. Medication Record

- **Purpose**: Cloud-backed medication entry scoped to one user.
- **Fields**:
  - `medicationId`: stable unique identifier
  - `userId`: owner identifier
  - `name`
  - `usage`
  - `dosage`
  - `type`
  - `timingType`
  - `doses`
  - `startDate`
  - `repeatForever`
  - `totalDays`
  - `deletedAt`
  - `updatedAt`
- **Validation rules**:
  - `medicationId` must remain stable across local and cloud copies
  - `userId` must match the owning workspace
  - `updatedAt` must be written on every create or update

## 4. Medication Schedule Record

- **Purpose**: Cloud-backed schedule information used to restore reminder intent later.
- **Fields**:
  - `scheduleId`: stable unique identifier
  - `userId`: owner identifier
  - `medicationId`: related medication
  - `timingRules`
  - `startDate`
  - `repeatPattern`
  - `updatedAt`
- **Validation rules**:
  - Must belong to an existing user workspace
  - Must reference a medication owned by the same user

## 5. Notification Preference Record

- **Purpose**: Cloud-backed reminder configuration preserved for future synchronization and recovery flows.
- **Fields**:
  - `preferenceId`: stable unique identifier
  - `userId`: owner identifier
  - `medicationId` or `scheduleId`: related subject
  - `notificationEnabled`
  - `reminderSettings`
  - `updatedAt`
- **Validation rules**:
  - Must remain user-scoped
  - Stores configuration only; device-specific delivery state is out of scope for Phase 2

## 6. Auth Session

- **Purpose**: Current app-level representation of cloud access state.
- **Fields**:
  - `userId`
  - `isSignedIn`
  - `providerId`
  - `workspaceReady`
- **Validation rules**:
  - Signed-out sessions must not allow cloud repository operations
  - Signed-in sessions must map to a single user workspace

## State Transitions

### Auth Session

- `signedOut` -> `signingIn`
- `signingIn` -> `signedIn`
- `signedIn` -> `workspaceInitializing`
- `workspaceInitializing` -> `workspaceReady`
- `workspaceReady` -> `signedOut`
- `signingIn` or `workspaceInitializing` -> `failed`

### Cloud-backed Record

- `absent` -> `created`
- `created` -> `updated`
- `updated` -> `deleted`
- `created` or `updated` -> `accessDenied` when the user context is invalid

## Notes

- Phase 2 models are intentionally shaped to support later synchronization work without implementing sync orchestration yet.
- Where the current codebase already contains similar entities, implementation should extend or adapt them without breaking clean architecture boundaries.
