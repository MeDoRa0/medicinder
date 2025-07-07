// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Medicinder';

  @override
  String get homeTitle => 'My Medications';

  @override
  String get addMedication => 'Add Medication';

  @override
  String get editMedication => 'Edit Medication';

  @override
  String get medicineName => 'Medicine Name';

  @override
  String get usage => 'What it\'s used for';

  @override
  String get dosage => 'Dosage';

  @override
  String get days => 'For how many days?';

  @override
  String get timing => 'Timing:';

  @override
  String get specificTimes => 'Specific Times';

  @override
  String get beforeAfterMeals => 'Before/After Meals';

  @override
  String get save => 'Save';

  @override
  String get settings => 'Settings';

  @override
  String get setMealTimes => 'Set your meal times:';

  @override
  String get breakfast => 'Breakfast';

  @override
  String get lunch => 'Lunch';

  @override
  String get dinner => 'Dinner';

  @override
  String get language => 'Language:';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get welcome =>
      'Welcome!\n\nTo get started, please set your meal times. This helps us remind you to take your medication at the right moments.';

  @override
  String get noMedications => 'No medications added yet.';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get courseFinished => 'Course finished';

  @override
  String daysLeft(int days) {
    return 'Days left: $days';
  }

  @override
  String dosesPerDay(int count) {
    return 'Doses per day: $count';
  }

  @override
  String get deleteMedication => 'Delete Medication';

  @override
  String get deleteConfirm =>
      'Are you sure you want to delete this medication?';

  @override
  String get cancel => 'Cancel';

  @override
  String get type => 'Type:';

  @override
  String get usageLabel => 'To treat:';

  @override
  String get dosageLabel => 'Dosage:';

  @override
  String get pill => 'Pill';

  @override
  String get syrup => 'Syrup';

  @override
  String get addTime => 'Add Time';

  @override
  String get beforeBreakfast => 'Before Breakfast';

  @override
  String get afterBreakfast => 'After Breakfast';

  @override
  String get beforeLunch => 'Before Lunch';

  @override
  String get afterLunch => 'After Lunch';

  @override
  String get beforeDinner => 'Before Dinner';

  @override
  String get afterDinner => 'After Dinner';

  @override
  String get medicineType => 'Medicine Type:';

  @override
  String get mealTimesSaved => 'Meal times saved!';

  @override
  String get before => 'Before';

  @override
  String get after => 'After';

  @override
  String get dailyDosesCompleted =>
      'Today\'s doses completed. Course continues.';

  @override
  String get courseContinues => 'Course continues.';

  @override
  String get medicationNotFound => 'Medication not found';

  @override
  String get invalidData => 'Invalid medication data';

  @override
  String get invalidDoseIndex => 'Invalid dose selection';

  @override
  String get notificationPermissionDenied => 'Notification permission denied';

  @override
  String get notificationSchedulingFailed => 'Failed to schedule notification';

  @override
  String get dataMigrationFailed => 'Data migration failed';

  @override
  String get storageError => 'Storage error occurred';

  @override
  String get networkError => 'Network connection failed';

  @override
  String get validationError => 'Invalid data provided';

  @override
  String get permissionDenied => 'Permission denied';

  @override
  String get resourceNotFound => 'Resource not found';

  @override
  String get unknownError => 'An unexpected error occurred';

  @override
  String get retryNetwork => 'Check your connection and try again';

  @override
  String get retryStorage => 'Try again or restart the app';

  @override
  String get retryNotification => 'Try again or check notification settings';

  @override
  String get checkInput => 'Please check your input and try again';

  @override
  String get tryAgain => 'Please try again';
}
