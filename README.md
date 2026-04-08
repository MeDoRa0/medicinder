# Medicinder 💊

A comprehensive Flutter-based medication management app designed to help users track their medications, dosages, and schedules with ease.

## Features

### 🕐 **Smart Medication Scheduling**
- **Specific Time Scheduling**: Set exact times for medication doses
- **Meal-Based Scheduling**: Schedule medications relative to meals (before/after breakfast, lunch, dinner)
- **Flexible Timing**: Customizable time offsets for meal-based medications
- **Duration Tracking**: Set treatment duration in days with automatic completion

### 📱 **User-Friendly Interface**
- **Bilingual Support**: Available in English and Arabic with full localization
- **Intuitive Design**: Clean, modern UI with easy navigation
- **Cross-Platform**: Works on Android, iOS, Windows, macOS, Linux, and Web
- **Responsive Layout**: Adapts to different screen sizes and orientations

### 💊 **Medication Management**
- **Multiple Medication Types**: Support for pills and syrups
- **Dosage Tracking**: Record specific dosages with appropriate units
- **Usage Instructions**: Store detailed usage information for each medication
- **Smart Completion**: Automatic detection when treatment courses are finished
- **Manual Control**: Users can delete medications at any time

### 🔔 **Advanced Notification System**
- **Persistent Notifications**: Notifications stay visible until user action
- **Action Buttons**: "Done" and "Remind Me Later" options
- **Background Processing**: Works even when the app is closed
- **Automatic Scheduling**: Notifications scheduled when medications are added
- **Smart Rescheduling**: 15-minute delay option for missed doses
- **High Priority**: Notifications can wake the device

### 💾 **Data Persistence**
- **Local Storage**: Hive database for offline access
- **Data Migration**: Automatic handling of model structure changes
- **Cross-Platform**: Consistent data across all platforms

## Screenshots

### 📱 Main Interface
<p align="center">
  <img src="assets/screenshots/home-eng.png" alt="Home Screen - English" width="200"/>
  <img src="assets/screenshots/home-ar.png" alt="Home Screen - Arabic" width="200"/>
</p>
<p align="center"><b>Left:</b> English | <b>Right:</b> Arabic (RTL)</p>

### 💊 Add Medication
<p align="center">
  <img src="assets/screenshots/add-medication-eng.png" alt="Add Medication - English" width="200"/>
  <img src="assets/screenshots/add-medication-ar.png" alt="Add Medication - Arabic" width="200"/>
</p>
<p align="center"><b>Left:</b> English | <b>Right:</b> Arabic (RTL)</p>

### ⚙️ Settings & Localization
<p align="center">
  <img src="assets/screenshots/settings-eng.png" alt="Settings - English" width="200"/>
  <img src="assets/screenshots/settings-ar.png" alt="Settings - Arabic" width="200"/>
</p>
<p align="center"><b>Left:</b> English | <b>Right:</b> Arabic (RTL)</p>

### 🔔 Notification System
<p align="center">
  <img src="assets/screenshots/notification.png" alt="Notification" width="200"/>
</p>
<p align="center">Smart notification system with action buttons for dose tracking</p>

### 📝 Additional Screenshots
<p align="center">
  <img src="assets/screenshots/add_medication-eng2.png" alt="Add Medication Alternative" width="200"/>
</p>
<p align="center">Alternative view of medication addition form</p>

> **Note**: The app supports both English and Arabic languages with full RTL (Right-to-Left) layout support for Arabic users.

## Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/MeDoRa0/medicinder.git
   cd medicinder
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code** (for Hive models)
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Architecture

This project follows Clean Architecture principles with the following structure:

```
lib/
├── core/           # Core functionality, DI, and services
│   ├── di/        # Dependency injection setup
│   └── services/  # Notification and background services
├── data/          # Data layer (models, repositories, data sources)
├── domain/        # Business logic (entities, use cases, repositories)
├── presentation/  # UI layer (pages, widgets, state management)
└── l10n/         # Localization files
```

### Key Technologies
- **Flutter**: Cross-platform UI framework
- **Cubit (flutter_bloc)**: State management
- **Hive**: Local data persistence
- **Awesome Notifications**: Local notification scheduling and actions
- **GetIt**: Dependency injection
- **Clean Architecture**: Scalable code structure

### Dependencies

#### Core Dependencies
- `flutter_bloc: ^9.1.1` - State management
- `hive: ^2.2.3` - Local database
- `awesome_notifications: ^0.10.1` - Advanced notifications
- `get_it: ^8.0.3` - Dependency injection
- `timezone: ^0.10.1` - Timezone handling
- `uuid: ^4.5.1` - Unique ID generation
- `firebase_core` - Firebase bootstrap
- `firebase_auth` - Account-scoped cloud sync sign-in
- `cloud_firestore` - Cloud data mirror for sync
- `connectivity_plus` - Connectivity-driven sync triggers

### Firebase Sync Setup

Cloud sync requires platform Firebase configuration that is intentionally not
committed to this repository.

1. Create a Firebase project with Authentication and Firestore enabled.
2. Add the platform apps for Android and iOS.
3. Place `google-services.json` in `android/app/`.
4. Place `GoogleService-Info.plist` in `ios/Runner/`.
5. Run `flutter pub get`.

If those files are missing, the app should continue local-only medication
tracking and keep cloud sync disabled.

### Authentication Integration Rules

- Keep a guest or local-only path available when Firebase is unavailable or the
  user does not want to sign in.
- Restore the previous auth or guest session before deciding whether to show an
  auth gate or the main app.
- Keep Firestore data scoped under `users/{userId}` and never allow guest mode to
  read or write cloud-backed medication data.
- Render Apple Sign-In only on supported Apple platforms; Google Sign-In and other
  providers should stay behind a provider-extensible auth abstraction.
- Persist only the minimum local session metadata needed for restore. Do not store
  raw provider tokens outside the platform SDK or Firebase-managed session.

### Phase 1 Auth Entry Gate

- On first launch, the app restores a minimal local entry marker before routing.
- If no resolved entry marker exists, the app shows an auth entry gate before
  the existing meal-time setup or home flow.
- In Phase 1, `Continue as Guest` is the only enabled option. Google remains
  visible but disabled on supported platforms, and Apple is visible but disabled
  on iOS only.
- Guest mode remains device-local in this phase: no provider-auth completion,
  no guest-to-account merge, and no cloud attachment of guest-local medication
  data.

#### Development Dependencies
- `build_runner: ^2.5.3` - Code generation
- `hive_generator: ^2.0.1` - Hive model generation
- `flutter_launcher_icons: ^0.13.1` - App icon generation

## Features in Detail

### Notification System
The app uses Awesome Notifications for a robust notification experience:
- **Persistent notifications** that don't auto-dismiss
- **Action buttons** for quick dose tracking
- **Automatic scheduling** based on medication timing
- **Smart rescheduling** for missed doses

### Data Management
- **Hive database** for fast, local storage
- **Automatic data migration** for model changes
- **Cross-platform consistency** across all devices
- **Offline-first** approach for reliability

### Localization
- **English and Arabic** support
- **RTL layout** support for Arabic
- **Dynamic language switching** without app restart
- **Comprehensive translations** for all UI elements

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Guidelines
- Follow Clean Architecture principles
- Use Cubit for state management
- Add proper error handling
- Include localization for new strings
- Test on multiple platforms

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**Mohamed Hossam** - [MeDoRa0](https://github.com/MeDoRa0)

## Acknowledgments

- Flutter team for the amazing framework
- The open-source community for inspiration and tools
- All contributors and testers
- Awesome Notifications team for the robust notification system

---

⭐ **Star this repository if you find it helpful!**
