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
  String get pushed => 'Pushed';

  @override
  String get pulled => 'Pulled';

  @override
  String get failed => 'Failed';

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

  @override
  String get forever => 'Forever';

  @override
  String get courseCompleted => 'Course Completed';

  @override
  String get dose => 'Dose';

  @override
  String get required => 'Required';

  @override
  String get repeatForever => 'Repeat Forever';

  @override
  String get statistics => 'Statistics';

  @override
  String get medicationStatistics => 'Medication Statistics';

  @override
  String get timePeriod => 'Time Period';

  @override
  String get days7 => '7 days';

  @override
  String get days30 => '30 days';

  @override
  String get days90 => '90 days';

  @override
  String get mostTakenMedication => 'Most Taken Medication';

  @override
  String get medicationDistribution => 'Medication Distribution';

  @override
  String get allMedications => 'All Medications';

  @override
  String get noMedicationData => 'No medication data available';

  @override
  String get takeMedicationsForStats =>
      'Take some medications to see statistics here';

  @override
  String dosesTaken(int count, String percentage) {
    return '$count doses taken ($percentage%)';
  }

  @override
  String get doses => 'doses';

  @override
  String get other => 'Other';

  @override
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String get enterValidDays => 'Enter a valid number of days';

  @override
  String get pillUnit => 'pill';

  @override
  String get mlUnit => 'ml';

  @override
  String get exampleDays => 'e.g., 7';

  @override
  String get medicationReminders => 'Medication Reminders';

  @override
  String get remindersForMedicationDoses => 'Reminders for medication doses';

  @override
  String get notificationPermissionDeniedTitle =>
      'Notification Permission Denied';

  @override
  String get enableNotificationsMessage =>
      'To receive medication reminders, please enable notifications in your device settings.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get medicationReminder => 'Medication Reminder';

  @override
  String timeToTakeMedication(String medicationName) {
    return 'Time to take $medicationName';
  }

  @override
  String get done => 'Taken';

  @override
  String get remindMeLater => 'Snooze';

  @override
  String get retry => 'Retry';

  @override
  String get goBack => 'Go Back';

  @override
  String get dosageHintPill => 'e.g., 1 pill, 2 pills';

  @override
  String get dosageHintSyrup => 'e.g., 5ml, 10ml';

  @override
  String get am => 'AM';

  @override
  String get pm => 'PM';

  @override
  String get syncStatusTitle => 'Cloud Sync';

  @override
  String get syncSignedOut => 'Signed out';

  @override
  String get syncSigningIn => 'Signing in';

  @override
  String get syncWorkspaceInitializing => 'Preparing your cloud workspace';

  @override
  String get syncReady => 'Cloud workspace ready';

  @override
  String get syncAccessDenied => 'Cloud workspace access denied';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get syncEnableCloudSync => 'Enable Sync';

  @override
  String get syncDisableCloudSync => 'Sign Out';

  @override
  String get syncUnavailableLocalOnly =>
      'Local-only mode is active until you sign in.';

  @override
  String syncSignedInAs(String userId) {
    return 'Signed in as $userId';
  }

  @override
  String syncReadyAs(String userId) {
    return 'Cloud workspace ready for $userId';
  }

  @override
  String get syncRunning => 'Syncing...';

  @override
  String get syncSucceeded => 'Sync complete';

  @override
  String get syncPartialFailure => 'Sync completed with some errors';

  @override
  String get syncRetrySafeFailure => 'Sync failed. Tap to retry.';

  @override
  String syncLastSuccess(String timestamp) {
    return 'Last sync: $timestamp';
  }

  @override
  String syncLastFailure(String timestamp) {
    return 'Sync failed at $timestamp';
  }

  @override
  String syncFailedOperationsBadge(int count) {
    return '$count operation(s) failed to sync';
  }

  @override
  String get syncFailedOperationsDetails => 'Tap to view failed operations';

  @override
  String get syncPermanentlyFailedTitle => 'Failed Operations';

  @override
  String get syncNoFailedOperations => 'No permanently failed operations';

  @override
  String get authEntryTitle => 'Choose how to enter';

  @override
  String get authEntrySubtitle =>
      'Choose local-only guest access now or sign in with Google to restore your cloud-backed medication workspace.';

  @override
  String get authEntryGoogleTitle => 'Continue with Google';

  @override
  String get authEntryGoogleDescription =>
      'Sign in to restore your cloud-backed medications and sync session.';

  @override
  String get authEntryGoogleLoading => 'Signing in with Google...';

  @override
  String get authEntryGoogleEnabledSemanticsHint => 'Starts Google sign-in.';

  @override
  String get authEntryAppleTitle => 'Continue with Apple';

  @override
  String get authEntryAppleDescription =>
      'Sign in with Apple to restore your cloud-backed medications and sync session.';

  @override
  String get authEntryAppleLoading => 'Signing in with Apple...';

  @override
  String get authEntryAppleEnabledSemanticsHint => 'Starts Apple sign-in.';

  @override
  String get authEntryGuestTitle => 'Continue as Guest';

  @override
  String get authEntryGuestDescription =>
      'Keep your medication reminders on this device only for now.';

  @override
  String get authEntryComingSoon => 'Coming soon';

  @override
  String get authEntryDisabledSemanticsHint => 'Unavailable in this release.';

  @override
  String get authEntryGoogleUnavailableFeedback =>
      'Google sign-in is not available in this phase yet.';

  @override
  String get authEntryGoogleCancelledFeedback =>
      'Google sign-in was cancelled. You can try again or continue as a guest.';

  @override
  String get authEntryGoogleFailedFeedback =>
      'Google sign-in could not be completed. Please try again.';

  @override
  String get authEntryGoogleUnsupportedRunnerFeedback =>
      'Google sign-in is not available on this runner. You can continue locally as a guest.';

  @override
  String get authEntryAppleUnavailableFeedback =>
      'Apple sign-in is not available on this device right now.';

  @override
  String get authEntryAppleCancelledFeedback =>
      'Apple sign-in was cancelled. You can try again or continue as a guest.';

  @override
  String get authEntryAppleFailedFeedback =>
      'Apple sign-in could not be completed. Please try again.';

  @override
  String get authEntryAppleConflictFeedback =>
      'This account already exists with another sign-in method. Use the original sign-in option to continue.';

  @override
  String get authEntryUnsupportedRestoreFeedback =>
      'The previous sign-in mode is not supported yet. Please choose an option again.';

  @override
  String get authEntryGuestSemanticsLabel =>
      'Continue as guest. Available now.';

  @override
  String get authEntryRestoring => 'Restoring launch state';
}
