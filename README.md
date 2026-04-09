# Medicinder

Medicinder is a Flutter medication reminder app with local-first storage, scheduled notifications, bilingual UI, and optional Firebase-backed account sync.

## What It Does

- Track medications, dosages, and treatment duration
- Schedule reminders at fixed times or around meals
- Show actionable local notifications for dose tracking
- Support English and Arabic, including RTL layouts
- Store data locally with Hive
- Optionally enable account-based sync with Firebase Auth and Firestore

## Tech Stack

- Flutter
- `flutter_bloc`
- `get_it`
- Hive / `hive_flutter`
- `awesome_notifications`
- Firebase Auth / Firestore
- `google_sign_in`
- `sign_in_with_apple`

## Project Structure

```text
lib/
  core/
  data/
  domain/
  presentation/
  l10n/
test/
assets/
```

## Getting Started

### Prerequisites

- Flutter SDK with Dart `^3.8.1`
- Android Studio, VS Code, or another Flutter-capable IDE

### Install Dependencies

```bash
flutter pub get
```

### Generate Hive Adapters

```bash
dart run build_runner build
```

### Run The App

```bash
flutter run
```

### Run Tests

```bash
flutter test
```

## Firebase Setup

Firebase is required only for authenticated cloud sync. The app should still run in local-only mode without Firebase platform credentials.

If you want sync enabled:

1. Create a Firebase project.
2. Enable Authentication and Firestore.
3. Add your Android and iOS apps.
4. Place `google-services.json` in `android/app/`.
5. Place `GoogleService-Info.plist` in `ios/Runner/`.
6. Run `flutter pub get`.

## Notes

- Apple Sign-In is available only on supported Apple platforms.
- Google Sign-In depends on platform support and Firebase configuration.
- Screenshots live under `assets/screenshots/`.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
