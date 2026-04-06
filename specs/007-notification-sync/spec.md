# Feature Specification: Notification Synchronization

**Feature Branch**: `007-notification-sync`  
**Created**: 2026-04-06  
**Status**: Draft  
**Input**: User description: "Phase 5 – Notification Synchronization: Ensure medication schedules and reminder configurations remain synchronized across devices while keeping notifications reliable"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reminders Restored on New Device (Priority: P1)

A user signs in on a second device (or reinstalls the application). The sync engine downloads all medication records from the cloud, including their schedule configurations (dose times, meal contexts, snooze preferences). As soon as the sync completes, the local notification scheduler regenerates alarms for every upcoming dose so the user receives timely reminders without any manual setup.

**Why this priority**: Without this, a second device or reinstall renders the app silent — the user misses medications, defeating the application's core purpose.

**Independent Test**: Can be fully tested by signing in on a fresh device, waiting for sync, and verifying that scheduled notifications match the medication records retrieved from the cloud.

**Acceptance Scenarios**:

1. **Given** a user has 3 active medications with configured dose schedules in the cloud, **When** the user signs in on a new device and sync completes, **Then** local notifications are scheduled for every upcoming dose matching the cloud schedule data.
2. **Given** a user reinstalls the application, **When** the user signs in and sync finishes, **Then** the user receives the next medication reminder at the correct time without manual intervention.
3. **Given** a user has a medication with "repeat forever" enabled, **When** the device syncs, **Then** recurring daily alarms are regenerated based on the synced dose times.

---

### User Story 2 - Schedule Changes Propagated Across Devices (Priority: P1)

A user edits a medication schedule on Device A (e.g., changes a dose time from 08:00 to 09:00 or adds a new dose). When Device B performs a sync cycle, it receives the updated schedule, cancels stale local alarms, and reschedules notifications with the new times.

**Why this priority**: Schedule accuracy across devices is critical. Stale reminders cause confusion and missed or double-taken doses.

**Independent Test**: Can be fully tested by modifying a dose time on one device, triggering sync on the second device, and confirming the second device's local alarms now fire at the new time.

**Acceptance Scenarios**:

1. **Given** a medication dose is changed from 08:00 to 09:00 on Device A, **When** Device B syncs, **Then** Device B cancels the 08:00 alarm and schedules a new alarm at 09:00.
2. **Given** a new dose is added to an existing medication on Device A, **When** Device B syncs, **Then** Device B adds a notification for the new dose while preserving notifications for unchanged doses.
3. **Given** a dose is removed from a medication on Device A, **When** Device B syncs, **Then** Device B cancels the notification for the removed dose.

---

### User Story 3 - Medication Deletion Clears Reminders (Priority: P2)

A user deletes a medication on one device. After syncing, all other devices cancel every outstanding notification for that medication so the user is not reminded about a medication they no longer take.

**Why this priority**: Delivering reminders for deleted medications erodes user trust and creates confusion.

**Independent Test**: Can be tested by deleting a medication on one device, syncing the second, and verifying no leftover alarms fire.

**Acceptance Scenarios**:

1. **Given** a medication is marked as deleted on Device A, **When** Device B syncs and receives the deletion, **Then** Device B cancels all scheduled notifications for that medication.
2. **Given** a medication is deleted while offline, **When** the device reconnects and syncs, **Then** the deletion propagates and remote devices cancel their notifications.

---

### User Story 4 - Offline Schedule Changes Queue and Replay (Priority: P2)

A user modifies a medication schedule while offline (e.g., changes dose times or adds new doses). The changes are applied immediately to local storage and local notifications. When connectivity returns, the offline operations queue replays the changes to the cloud so other devices can pick them up.

**Why this priority**: The offline-first architecture demands that schedule changes never block on connectivity, and that no edits are lost.

**Independent Test**: Can be tested by disabling network, editing a schedule, verifying local alarms update immediately, re-enabling network, and confirming the cloud record updates.

**Acceptance Scenarios**:

1. **Given** the device is offline and the user changes a dose time, **When** the change is saved, **Then** local notifications are rescheduled immediately to reflect the new time.
2. **Given** schedule changes were made offline, **When** connectivity returns and the sync engine runs, **Then** the pending changes are uploaded to the cloud and the cloud record reflects the new schedule.

---

### User Story 5 - Conflict Resolution for Concurrent Schedule Edits (Priority: P3)

Two users (or the same user on two devices) edit the same medication schedule simultaneously while one or both are offline. When both sync, the system applies the last-write-wins strategy, and the losing device regenerates its local notifications to match the winning version.

**Why this priority**: Conflicts are rare in a personal medication app but must be handled gracefully to prevent inconsistent reminders.

**Independent Test**: Can be tested by editing the same medication schedule on two offline devices, reconnecting both, and verifying both converge on the same schedule and notification state.

**Acceptance Scenarios**:

1. **Given** Device A and Device B both edit the same dose time offline, **When** they both sync, **Then** the device with the later `updatedAt` timestamp wins, and the other device adopts the winning schedule and reschedules its notifications accordingly.
2. **Given** a conflict is resolved, **When** the losing device processes the resolution, **Then** all stale notifications are cancelled and new ones are scheduled matching the resolved schedule.

---

### Edge Cases

- What happens when a notification is already firing (alarm ringing) at the moment a sync updates the schedule? The regeneration process only cancels future *scheduled* notifications (not yet fired). Any already-displayed notification completes its display lifecycle naturally — the system does not attempt to dismiss or cancel active/displayed notifications.
- How does the system handle a medication whose schedule includes times in the past after a sync? Past dose times must be skipped during notification regeneration; only future doses receive alarms.
- What happens if the cloud record has no dose schedule data (corrupted or incomplete)? The system must retain existing local notifications and log a warning rather than clearing alarms.
- What happens if the device's local time zone differs from the time zone where the schedule was created? Schedule times must be interpreted as local device time; time-zone translation is out of scope for this phase.
- What happens if the notification permission is revoked on the device? The system must detect denied permissions and surface a user-visible prompt; no silent failure.
- What happens if a sync cycle partially fails (some medications synced, some not)? Successfully synced items must still have their notifications regenerated; partial sync does not block notification updates for the items that did sync.
- What happens when a user signs out? All scheduled medication notifications on that device MUST be cancelled and the notification cache cleared, preventing stale reminders from firing for a signed-out (or different) user.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST regenerate local medication notifications for each medication whose schedule data changed after every successful sync cycle. The sync engine MUST provide a list of changed medication IDs; only those medications have their notifications regenerated (targeted rebuild).
- **FR-002**: The system MUST cancel all existing notifications for a medication before scheduling new ones for that medication during the regeneration process, preventing duplicate alarms.
- **FR-003**: The system MUST persist medication schedule configuration (dose times, meal contexts, offset minutes, timing type) in the cloud as part of the medication record.
- **FR-004**: The system MUST skip dose times that have already passed when regenerating notifications, scheduling only future doses.
- **FR-005**: The system MUST cancel all notifications for a medication when that medication is marked as deleted (whether the deletion originates locally or from sync).
- **FR-006**: The system MUST apply schedule changes to local notifications immediately when the user modifies a schedule, regardless of connectivity.
- **FR-007**: The system MUST queue schedule changes made offline and upload them when connectivity returns, using the existing offline operations queue.
- **FR-008**: The system MUST resolve concurrent schedule edits using the application's established last-write-wins strategy based on the `updatedAt` timestamp.
- **FR-009**: The system MUST NOT cancel or dismiss a notification that has already been displayed (actively ringing or shown). During sync-triggered regeneration, the system MUST only cancel future *scheduled* (not-yet-fired) notifications; already-fired notifications complete their display lifecycle naturally.
- **FR-010**: The system MUST detect and warn the user when notification permissions are denied, preventing silent notification failures.
- **FR-011**: The system MUST support both specific-time and context-based (meal-relative) dose scheduling as defined by the existing timing type model.
- **FR-012**: The system MUST regenerate notifications even after partial sync failures — each successfully synced medication must have its notifications updated independently.
- **FR-013**: The system MUST emit a structured summary event after each notification regeneration cycle, including: count of medications processed, notifications scheduled, and any failures. This event MUST be visible in the existing sync diagnostics infrastructure (not a new UI).
- **FR-014**: The system MUST cancel all scheduled medication notifications and clear the local notification cache when a user signs out, preventing stale or misattributed reminders.

### Key Entities

- **Medication Schedule Configuration (Schedule Template)**: The persistent definition of when doses should occur, consisting of time-of-day entries (e.g., "08:00", "20:00"), meal contexts, offset minutes, and timing type. This template is attached to the Medication record and synced to the cloud. It is the canonical source of truth for generating local dose instances and notifications on any device. Dose instances (concrete `DateTime` + `taken` flag) are ephemeral, device-local, and generated from this template — they are NOT synced to the cloud.
- **Notification State**: The collection of locally scheduled alarms on a device. This is ephemeral and device-local — it is never stored in the cloud; it is always derived from the local medication records.
- **Sync Event (Schedule-Relevant)**: A signal emitted by the sync engine indicating that one or more medication records with schedule data changes have been written to local storage. This event triggers notification regeneration and MUST carry its `changedMedicationIds` (list of medication IDs whose schedule data was created, updated, or deleted during this sync cycle).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After signing in on a new device and completing sync, 100% of upcoming medication reminders fire at the correct times within 60 seconds of the intended schedule.
- **SC-002**: When a schedule is changed on one device, the second device reflects the updated notification schedule within 30 seconds of completing its next sync cycle.
- **SC-003**: Deleted medications produce zero notification alarms on any synced device after sync completes.
- **SC-004**: Schedule changes made while offline are applied to local notifications immediately (within 2 seconds of save) and uploaded to the cloud within 30 seconds of connectivity restoration.
- **SC-005**: In a conflict scenario, both devices converge on identical notification schedules within one sync cycle after both come online.
- **SC-006**: Users experience zero missed reminders caused by sync-related schedule inconsistencies across devices.
- **SC-007**: Targeted notification regeneration for up to 50 changed medications completes within 5 seconds after sync.

## Assumptions

- The existing sync engine (Phase 3) and offline operations queue (Phase 4) are fully implemented and operational before this phase begins.
- Medication records stored in the cloud contain the schedule template (time-of-day entries, meal contexts, offset minutes, timing type) as part of the medication data model. Concrete dose instances (with `DateTime` and `taken` flags) are ephemeral and device-local — they are NOT synced. No schema migration is needed for the template data.
- All notifications are scheduled locally using the device's existing notification service (`AwesomeNotifications`); no cloud-based push notifications are used for medication reminders.
- The `last-write-wins` conflict resolution strategy with `updatedAt` timestamps is already established and does not need to be re-implemented.
- Time-zone translation between devices is out of scope; schedule times are interpreted as device-local time.
- The existing `NotificationOptimizer` class provides the batch scheduling and cancellation infrastructure required for post-sync regeneration.
- This feature targets both Android and iOS platforms, leveraging the cross-platform notification API already in place.

## Clarifications

### Session 2026-04-06

- Q: How should post-sync notification regeneration be scoped — full rebuild of all medications or targeted rebuild of only changed ones? → A: Targeted rebuild — extend SyncResult (or sync event) with a list of changed medication IDs; only regenerate notifications for those medications.
- Q: How should the system protect in-progress notifications during sync regeneration? → A: Skip active notifications — only cancel future scheduled (not-yet-fired) notifications during regeneration; already-displayed notifications complete their lifecycle naturally.
- Q: What is the source of truth for regenerating notifications on a new device — dose instances or schedule template? → A: Schedule template — sync a schedule definition (time-of-day entries + meal context + timing type); the new device generates fresh dose instances and notifications from the template. Dose instances are ephemeral and device-local.
- Q: What level of observability should post-sync notification regeneration provide? → A: Structured logging + summary event — emit a structured event after each regeneration cycle (medications processed, notifications scheduled, failures) visible in sync diagnostics; no new UI panel.
- Q: Should sign-out cancel all local medication notifications? → A: Yes, cancel all — on sign-out, cancel every scheduled medication notification and clear the notification cache.
