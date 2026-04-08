# medicinder Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-04-08

## Active Technologies
- Dart `^3.8.1` with Flutter stable + `firebase_core`, `firebase_auth`, `cloud_firestore`, `flutter_bloc`, `get_it`, `hive`, `hive_flutter`, `intl` (002-firebase-backend)
- Hive for local-first data; Firebase Authentication for identity; Firestore for user-scoped cloud-backed records (002-firebase-backend)
- Dart `^3.8.1` with Flutter stable + Flutter, `flutter_bloc`, `get_it`, `hive`, `hive_flutter`, `firebase_auth`, `cloud_firestore`, `intl` (003-sync-engine)
- Hive remains the local source of truth for medication records and sync state; Firestore stores user-scoped cloud medication copies; lightweight sync diagnostics stay in local state/logs only (003-sync-engine)
- [e.g., Python 3.11, Swift 5.9, Rust 1.75 or NEEDS CLARIFICATION] + [e.g., FastAPI, UIKit, LLVM or NEEDS CLARIFICATION] (004-offline-operation-queue)
- [if applicable, e.g., PostgreSQL, CoreData, files or N/A] (004-offline-operation-queue)
- Dart ^3.8.1 + Flutter stable, `flutter_bloc`, `get_it`, `hive`, `hive_flutter`, `awesome_notifications`, `firebase_auth`, `cloud_firestore`, `equatable`, `connectivity_plus` (007-notification-sync)
- Hive (local medications via `MedicationLocalDataSource`); Firestore (cloud medication records via `MedicationRemoteDataSource`). Notification state is ephemeral and device-local — never persisted to cloud. (007-notification-sync)
- Dart `^3.8.1` with Flutter stable + Flutter, `flutter_bloc`, `get_it`, `shared_preferences`, `firebase_auth`, `cloud_firestore`, `hive`, `hive_flutter`, `intl`, `flutter_localizations` (008-auth-entry-gate)
- `SharedPreferences` for minimal entry-resolution state; Hive remains the local medication source of truth; Firebase auth and Firestore remain untouched for disabled provider placeholders in this phase (008-auth-entry-gate)

- Dart `^3.8.1` with Flutter stable + Flutter, `flutter_bloc`, `hive`, `hive_flutter`, `awesome_notifications`, `intl`, `firebase_auth`, `cloud_firestore`, connectivity monitoring (001-phase-0-sync-architecture)

## Project Structure

```text
src/
tests/
```

## Commands

# Add commands for Dart `^3.8.1` with Flutter stable

## Code Style

Dart `^3.8.1` with Flutter stable: Follow standard conventions

## Recent Changes
- 008-auth-entry-gate: Added Dart `^3.8.1` with Flutter stable + Flutter, `flutter_bloc`, `get_it`, `shared_preferences`, `firebase_auth`, `cloud_firestore`, `hive`, `hive_flutter`, `intl`, `flutter_localizations`
- 007-notification-sync: Added Dart ^3.8.1 + Flutter stable, `flutter_bloc`, `get_it`, `hive`, `hive_flutter`, `awesome_notifications`, `firebase_auth`, `cloud_firestore`, `equatable`, `connectivity_plus`
- 004-offline-operation-queue: Added [e.g., Python 3.11, Swift 5.9, Rust 1.75 or NEEDS CLARIFICATION] + [e.g., FastAPI, UIKit, LLVM or NEEDS CLARIFICATION]


<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
