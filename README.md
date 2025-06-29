# Medicinder 💊

A comprehensive Flutter-based medication management app designed to help users track their medications, dosages, and schedules with ease.

## Features

### 🕐 **Smart Medication Scheduling**
- **Specific Time Scheduling**: Set exact times for medication doses
- **Meal-Based Scheduling**: Schedule medications relative to meals (before/after breakfast, lunch, dinner)
- **Flexible Timing**: Customizable time offsets for meal-based medications

### 📱 **User-Friendly Interface**
- **Bilingual Support**: Available in English and Arabic
- **Intuitive Design**: Clean, modern UI with easy navigation
- **Cross-Platform**: Works on Android, iOS, and desktop platforms

### 💊 **Medication Management**
- **Multiple Medication Types**: Support for pills and syrups
- **Dosage Tracking**: Record specific dosages with appropriate units
- **Usage Instructions**: Store detailed usage information for each medication
- **Duration Tracking**: Set treatment duration in days

### 🔔 **Smart Reminders**
- **Daily Dose Tracking**: Mark medications as taken
- **Visual Progress**: See your medication adherence at a glance
- **Persistent Storage**: Local data storage for offline access

## Screenshots

*[Screenshots will be added here]*

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
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

3. **Run the app**
   ```bash
   flutter run
   ```

## Architecture

This project follows Clean Architecture principles with the following structure:

```
lib/
├── core/           # Core functionality and DI
├── data/           # Data layer (models, repositories, data sources)
├── domain/         # Business logic (entities, use cases, repositories)
├── presentation/   # UI layer (pages, widgets, state management)
└── l10n/          # Localization files
```

### Key Technologies
- **Flutter**: Cross-platform UI framework
- **Cubit**: State management
- **Shared Preferences**: Local data persistence
- **Clean Architecture**: Scalable code structure

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**Mohamed Hossam** - [MeDoRa0](https://github.com/MeDoRa0)

## Acknowledgments

- Flutter team for the amazing framework
- The open-source community for inspiration and tools
- All contributors and testers

---

⭐ **Star this repository if you find it helpful!**
