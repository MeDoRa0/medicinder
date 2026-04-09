# Medicinder

Medicinder is a Flutter medication management app built with an offline-first architecture, local notifications, bilingual UX, and an optional Firebase-backed sync layer.

It is designed as a real production-style mobile codebase rather than a demo UI: the app includes local persistence, authentication entry flows, sync state handling, notification actions, and test coverage across data, domain, and presentation layers.

## Why This Project Stands Out

- Offline-first medication tracking with Hive as the local source of truth
- Optional cloud sync with Firebase Authentication and Firestore
- Google Sign-In and Apple Sign-In entry paths, plus guest mode
- Persistent medication reminders with actionable notifications
- English and Arabic localization with RTL support
- Clean Architecture structure with `data`, `domain`, `presentation`, and `core` layers
- Flutter Bloc and GetIt used for state management and dependency injection

## Product Highlights

- Create and manage medications with dosage, timing, and treatment duration
- Support exact-time scheduling and meal-based medication timing
- Track dose completion directly from notification actions
- Restore the user into the correct launch path through an app entry gate
- Continue working in local-only mode when Firebase is unavailable
- Surface sync status in the UI instead of hiding cloud state behind the scenes

## Screenshots

<p align="center">
  <img src="assets/screenshots/home-eng.png" alt="Home screen in English" width="180"/>
  <img src="assets/screenshots/home-ar.png" alt="Home screen in Arabic" width="180"/>
  <img src="assets/screenshots/add-medication-eng.png" alt="Add medication flow" width="180"/>
  <img src="assets/screenshots/notification.png" alt="Medication notification" width="180"/>
</p>

More images are available under `assets/screenshots/`.

## Tech Stack

- Flutter and Dart `^3.8.1`
- `flutter_bloc` for state management
- `get_it` for dependency injection
- `hive` and `hive_flutter` for local persistence
- `awesome_notifications` for reminders and notification actions
- `firebase_core`, `firebase_auth`, and `cloud_firestore` for cloud capabilities
- `google_sign_in` and `sign_in_with_apple` for provider sign-in
- `shared_preferences` for lightweight local session and setup state

## Architecture

The codebase follows a layered structure under `lib/`:

```text
lib/
  core/           shared services, DI, errors, sync utilities
  data/           models, datasources, repository implementations
  domain/         entities, repository contracts, use cases
  l10n/           ARB files and generated localizations
  presentation/   pages, widgets, cubits, app routing
```

That separation keeps the medication logic, auth/session handling, sync orchestration, and UI concerns testable in isolation.

## Getting Started

### Prerequisites

- Flutter SDK compatible with Dart `^3.8.1`
- A configured Flutter device or emulator
- Xcode for iOS/macOS work
- Android Studio or Android SDK tools for Android work

### Install and Run

```bash
git clone https://github.com/MeDoRa0/medicinder.git
cd medicinder
flutter pub get
flutter run
```

### Run Tests

```bash
flutter test
```

## Firebase Setup

Firebase is optional. If the platform config files are missing, the app should continue in local-only mode.

To enable authentication and sync:

1. Create a Firebase project.
2. Enable Firebase Authentication and Cloud Firestore.
3. Add platform apps for Android and iOS.
4. Place `google-services.json` in `android/app/`.
5. Place `GoogleService-Info.plist` in `ios/Runner/`.
6. Regenerate `lib/firebase_options.dart` if your Firebase project differs from the current generated config.

## Repository Notes

- Main application entry: `lib/main.dart`
- Launch routing and auth entry: `lib/presentation/pages/app_launch_router_page.dart`
- Local notifications: `lib/core/services/awesome_notification_service.dart`
- Sync services: `lib/core/services/sync/`
- Tests: `test/`

## Status

The repository currently includes:

- medication tracking and reminder flows
- bilingual UI support
- auth entry and session restore flows
- cloud sync foundation and status UI
- automated tests for sync, auth, and widget behavior

## Contact

GitHub: [@MeDoRa0](https://github.com/MeDoRa0)
