import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Medicinder'**
  String get appTitle;

  /// Title for the home page
  ///
  /// In en, this message translates to:
  /// **'My Medications'**
  String get homeTitle;

  /// Button text to add a new medication
  ///
  /// In en, this message translates to:
  /// **'Add Medication'**
  String get addMedication;

  /// Title for editing medication
  ///
  /// In en, this message translates to:
  /// **'Edit Medication'**
  String get editMedication;

  /// Label for medicine name field
  ///
  /// In en, this message translates to:
  /// **'Medicine Name'**
  String get medicineName;

  /// Label for medicine usage field
  ///
  /// In en, this message translates to:
  /// **'What it\'s used for'**
  String get usage;

  /// Label for dosage field
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosage;

  /// Question about medication duration
  ///
  /// In en, this message translates to:
  /// **'For how many days?'**
  String get days;

  /// Label for timing section
  ///
  /// In en, this message translates to:
  /// **'Timing:'**
  String get timing;

  /// Option for specific timing
  ///
  /// In en, this message translates to:
  /// **'Specific Times'**
  String get specificTimes;

  /// Option for meal-based timing
  ///
  /// In en, this message translates to:
  /// **'Before/After Meals'**
  String get beforeAfterMeals;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Settings page title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Label for meal times section
  ///
  /// In en, this message translates to:
  /// **'Set your meal times:'**
  String get setMealTimes;

  /// Breakfast meal label
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get breakfast;

  /// Lunch meal label
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get lunch;

  /// Dinner meal label
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get dinner;

  /// Language selection label
  ///
  /// In en, this message translates to:
  /// **'Language:'**
  String get language;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Arabic language option
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// Welcome message for initial setup
  ///
  /// In en, this message translates to:
  /// **'Welcome!\n\nTo get started, please set your meal times. This helps us remind you to take your medication at the right moments.'**
  String get welcome;

  /// Message when no medications exist
  ///
  /// In en, this message translates to:
  /// **'No medications added yet.'**
  String get noMedications;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Edit button text
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Status when medication course is complete
  ///
  /// In en, this message translates to:
  /// **'Course finished'**
  String get courseFinished;

  /// Days remaining in medication course
  ///
  /// In en, this message translates to:
  /// **'Days left: {days}'**
  String daysLeft(int days);

  /// Number of doses per day
  ///
  /// In en, this message translates to:
  /// **'Doses per day: {count}'**
  String dosesPerDay(int count);

  /// Title for delete medication dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Medication'**
  String get deleteMedication;

  /// Confirmation message for deleting medication
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this medication?'**
  String get deleteConfirm;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Label for medication type
  ///
  /// In en, this message translates to:
  /// **'Type:'**
  String get type;

  /// Label for medication usage display
  ///
  /// In en, this message translates to:
  /// **'To treat:'**
  String get usageLabel;

  /// Label for medication dosage display
  ///
  /// In en, this message translates to:
  /// **'Dosage:'**
  String get dosageLabel;

  /// Pill medication type
  ///
  /// In en, this message translates to:
  /// **'Pill'**
  String get pill;

  /// Syrup medication type
  ///
  /// In en, this message translates to:
  /// **'Syrup'**
  String get syrup;

  /// Button to add a dose time
  ///
  /// In en, this message translates to:
  /// **'Add Time'**
  String get addTime;

  /// Before breakfast meal context
  ///
  /// In en, this message translates to:
  /// **'Before Breakfast'**
  String get beforeBreakfast;

  /// After breakfast meal context
  ///
  /// In en, this message translates to:
  /// **'After Breakfast'**
  String get afterBreakfast;

  /// Before lunch meal context
  ///
  /// In en, this message translates to:
  /// **'Before Lunch'**
  String get beforeLunch;

  /// After lunch meal context
  ///
  /// In en, this message translates to:
  /// **'After Lunch'**
  String get afterLunch;

  /// Before dinner meal context
  ///
  /// In en, this message translates to:
  /// **'Before Dinner'**
  String get beforeDinner;

  /// After dinner meal context
  ///
  /// In en, this message translates to:
  /// **'After Dinner'**
  String get afterDinner;

  /// Label for medicine type section
  ///
  /// In en, this message translates to:
  /// **'Medicine Type:'**
  String get medicineType;

  /// Success message when meal times are saved
  ///
  /// In en, this message translates to:
  /// **'Meal times saved!'**
  String get mealTimesSaved;

  /// Before preposition
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get before;

  /// After preposition
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get after;

  /// Status message when daily doses are completed but course continues
  ///
  /// In en, this message translates to:
  /// **'Today\'s doses completed. Course continues.'**
  String get dailyDosesCompleted;

  /// Message shown when today's doses are complete but the course is not yet finished.
  ///
  /// In en, this message translates to:
  /// **'Course continues.'**
  String get courseContinues;

  /// Error message when medication is not found
  ///
  /// In en, this message translates to:
  /// **'Medication not found'**
  String get medicationNotFound;

  /// Error message for invalid medication data
  ///
  /// In en, this message translates to:
  /// **'Invalid medication data'**
  String get invalidData;

  /// Error message for invalid dose index
  ///
  /// In en, this message translates to:
  /// **'Invalid dose selection'**
  String get invalidDoseIndex;

  /// Error message when notification permission is denied
  ///
  /// In en, this message translates to:
  /// **'Notification permission denied'**
  String get notificationPermissionDenied;

  /// Error message when notification scheduling fails
  ///
  /// In en, this message translates to:
  /// **'Failed to schedule notification'**
  String get notificationSchedulingFailed;

  /// Error message when data migration fails
  ///
  /// In en, this message translates to:
  /// **'Data migration failed'**
  String get dataMigrationFailed;

  /// Error message for storage errors
  ///
  /// In en, this message translates to:
  /// **'Storage error occurred'**
  String get storageError;

  /// Error message for network errors
  ///
  /// In en, this message translates to:
  /// **'Network connection failed'**
  String get networkError;

  /// Error message for validation errors
  ///
  /// In en, this message translates to:
  /// **'Invalid data provided'**
  String get validationError;

  /// Error message when permission is denied
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;

  /// Error message when resource is not found
  ///
  /// In en, this message translates to:
  /// **'Resource not found'**
  String get resourceNotFound;

  /// Error message for unknown errors
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get unknownError;

  /// Label for number of pushed sync entities
  ///
  /// In en, this message translates to:
  /// **'Pushed'**
  String get pushed;

  /// Label for number of pulled sync entities
  ///
  /// In en, this message translates to:
  /// **'Pulled'**
  String get pulled;

  /// Label for number of failed sync entities
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// Suggested action for network errors
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again'**
  String get retryNetwork;

  /// Suggested action for storage errors
  ///
  /// In en, this message translates to:
  /// **'Try again or restart the app'**
  String get retryStorage;

  /// Suggested action for notification errors
  ///
  /// In en, this message translates to:
  /// **'Try again or check notification settings'**
  String get retryNotification;

  /// Suggested action for validation errors
  ///
  /// In en, this message translates to:
  /// **'Please check your input and try again'**
  String get checkInput;

  /// Generic retry message
  ///
  /// In en, this message translates to:
  /// **'Please try again'**
  String get tryAgain;

  /// Text for medications that repeat forever
  ///
  /// In en, this message translates to:
  /// **'Forever'**
  String get forever;

  /// Status message when medication course is fully completed
  ///
  /// In en, this message translates to:
  /// **'Course Completed'**
  String get courseCompleted;

  /// Label for a medication dose
  ///
  /// In en, this message translates to:
  /// **'Dose'**
  String get dose;

  /// Validation error message for required fields
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// Checkbox label for repeating medication forever
  ///
  /// In en, this message translates to:
  /// **'Repeat Forever'**
  String get repeatForever;

  /// Statistics page tooltip and title
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// Title for medication statistics page
  ///
  /// In en, this message translates to:
  /// **'Medication Statistics'**
  String get medicationStatistics;

  /// Label for time period selector
  ///
  /// In en, this message translates to:
  /// **'Time Period'**
  String get timePeriod;

  /// 7 days period button
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get days7;

  /// 30 days period button
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get days30;

  /// 90 days period button
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get days90;

  /// Label for most taken medication card
  ///
  /// In en, this message translates to:
  /// **'Most Taken Medication'**
  String get mostTakenMedication;

  /// Label for medication distribution chart
  ///
  /// In en, this message translates to:
  /// **'Medication Distribution'**
  String get medicationDistribution;

  /// Label for all medications list
  ///
  /// In en, this message translates to:
  /// **'All Medications'**
  String get allMedications;

  /// Message when no medication statistics data is available
  ///
  /// In en, this message translates to:
  /// **'No medication data available'**
  String get noMedicationData;

  /// Message prompting user to take medications to see statistics
  ///
  /// In en, this message translates to:
  /// **'Take some medications to see statistics here'**
  String get takeMedicationsForStats;

  /// Format for doses taken with percentage
  ///
  /// In en, this message translates to:
  /// **'{count} doses taken ({percentage}%)'**
  String dosesTaken(int count, String percentage);

  /// Word for doses (plural)
  ///
  /// In en, this message translates to:
  /// **'doses'**
  String get doses;

  /// Label for other medications in statistics
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// Error message prefix
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String error(String message);

  /// Validation error for invalid number of days
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number of days'**
  String get enterValidDays;

  /// Unit for pill medication
  ///
  /// In en, this message translates to:
  /// **'pill'**
  String get pillUnit;

  /// Unit for syrup medication
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get mlUnit;

  /// Example hint for days field
  ///
  /// In en, this message translates to:
  /// **'e.g., 7'**
  String get exampleDays;

  /// Notification channel name
  ///
  /// In en, this message translates to:
  /// **'Medication Reminders'**
  String get medicationReminders;

  /// Notification channel description
  ///
  /// In en, this message translates to:
  /// **'Reminders for medication doses'**
  String get remindersForMedicationDoses;

  /// Title for notification permission denied dialog
  ///
  /// In en, this message translates to:
  /// **'Notification Permission Denied'**
  String get notificationPermissionDeniedTitle;

  /// Message explaining how to enable notifications
  ///
  /// In en, this message translates to:
  /// **'To receive medication reminders, please enable notifications in your device settings.'**
  String get enableNotificationsMessage;

  /// Button to open device settings
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// Notification title
  ///
  /// In en, this message translates to:
  /// **'Medication Reminder'**
  String get medicationReminder;

  /// Notification body text
  ///
  /// In en, this message translates to:
  /// **'Time to take {medicationName}'**
  String timeToTakeMedication(String medicationName);

  /// Notification action: user took the medication
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get done;

  /// Notification action: remind again after a short delay
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get remindMeLater;

  /// Button label for retrying an action
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Button label for going back
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// Example hint for pill dosage field
  ///
  /// In en, this message translates to:
  /// **'e.g., 1 pill, 2 pills'**
  String get dosageHintPill;

  /// Example hint for syrup dosage field
  ///
  /// In en, this message translates to:
  /// **'e.g., 5ml, 10ml'**
  String get dosageHintSyrup;

  /// AM time period abbreviation
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get am;

  /// PM time period abbreviation
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get pm;

  /// Title for cloud sync status controls
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get syncStatusTitle;

  /// Cloud sync status when the user is signed out
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get syncSignedOut;

  /// Cloud sync status while authentication is in progress
  ///
  /// In en, this message translates to:
  /// **'Signing in'**
  String get syncSigningIn;

  /// Cloud sync status while the user workspace is being initialized
  ///
  /// In en, this message translates to:
  /// **'Preparing your cloud workspace'**
  String get syncWorkspaceInitializing;

  /// Cloud sync status when the authenticated workspace is ready
  ///
  /// In en, this message translates to:
  /// **'Cloud workspace ready'**
  String get syncReady;

  /// Cloud sync status when backend access is denied
  ///
  /// In en, this message translates to:
  /// **'Cloud workspace access denied'**
  String get syncAccessDenied;

  /// Cloud sync status when the latest sync attempt failed
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncFailed;

  /// Button label for enabling cloud sync
  ///
  /// In en, this message translates to:
  /// **'Enable Sync'**
  String get syncEnableCloudSync;

  /// Button label for signing out from cloud sync
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get syncDisableCloudSync;

  /// Message shown when cloud sync is unavailable because the user is signed out
  ///
  /// In en, this message translates to:
  /// **'Local-only mode is active until you sign in.'**
  String get syncUnavailableLocalOnly;

  /// Message shown when cloud sync is linked to a signed-in account
  ///
  /// In en, this message translates to:
  /// **'Signed in as {userId}'**
  String syncSignedInAs(String userId);

  /// Message shown when the authenticated cloud workspace is ready
  ///
  /// In en, this message translates to:
  /// **'Cloud workspace ready for {userId}'**
  String syncReadyAs(String userId);

  /// Cloud sync status while sync is in progress
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncRunning;

  /// Cloud sync status when the latest sync attempt succeeded
  ///
  /// In en, this message translates to:
  /// **'Sync complete'**
  String get syncSucceeded;

  /// Cloud sync status when sync completed but with partial failures
  ///
  /// In en, this message translates to:
  /// **'Sync completed with some errors'**
  String get syncPartialFailure;

  /// Actionable failure message for retryable sync errors
  ///
  /// In en, this message translates to:
  /// **'Sync failed. Tap to retry.'**
  String get syncRetrySafeFailure;

  /// Timestamp of the last successful sync
  ///
  /// In en, this message translates to:
  /// **'Last sync: {timestamp}'**
  String syncLastSuccess(String timestamp);

  /// Timestamp of the last failed sync
  ///
  /// In en, this message translates to:
  /// **'Sync failed at {timestamp}'**
  String syncLastFailure(String timestamp);

  /// Badge text showing count of permanently failed sync operations
  ///
  /// In en, this message translates to:
  /// **'{count} operation(s) failed to sync'**
  String syncFailedOperationsBadge(int count);

  /// Hint text prompting user to tap for failed operation details
  ///
  /// In en, this message translates to:
  /// **'Tap to view failed operations'**
  String get syncFailedOperationsDetails;

  /// Title for the permanently failed operations screen
  ///
  /// In en, this message translates to:
  /// **'Failed Operations'**
  String get syncPermanentlyFailedTitle;

  /// Message shown when there are no permanently failed operations
  ///
  /// In en, this message translates to:
  /// **'No permanently failed operations'**
  String get syncNoFailedOperations;

  /// Title for the authentication entry gate
  ///
  /// In en, this message translates to:
  /// **'Choose how to enter'**
  String get authEntryTitle;

  /// Subtitle for the authentication entry gate
  ///
  /// In en, this message translates to:
  /// **'Choose local-only guest access now or sign in with Google to restore your cloud-backed medication workspace.'**
  String get authEntrySubtitle;

  /// Label for the Google auth entry option
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authEntryGoogleTitle;

  /// Description for the live Google auth entry option
  ///
  /// In en, this message translates to:
  /// **'Sign in to restore your cloud-backed medications and sync session.'**
  String get authEntryGoogleDescription;

  /// Loading label shown while a Google sign-in attempt is active
  ///
  /// In en, this message translates to:
  /// **'Signing in with Google...'**
  String get authEntryGoogleLoading;

  /// Semantics hint for the enabled Google auth button
  ///
  /// In en, this message translates to:
  /// **'Starts Google sign-in.'**
  String get authEntryGoogleEnabledSemanticsHint;

  /// Label for the Apple auth entry option
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authEntryAppleTitle;

  /// Description for the Apple auth entry option when available
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple to restore your cloud-backed medications and sync session.'**
  String get authEntryAppleDescription;

  /// Loading label shown while an Apple sign-in attempt is active
  ///
  /// In en, this message translates to:
  /// **'Signing in with Apple...'**
  String get authEntryAppleLoading;

  /// Semantics hint for the enabled Apple auth button
  ///
  /// In en, this message translates to:
  /// **'Starts Apple sign-in.'**
  String get authEntryAppleEnabledSemanticsHint;

  /// Label for the guest auth entry option
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get authEntryGuestTitle;

  /// Description for the guest auth entry option
  ///
  /// In en, this message translates to:
  /// **'Keep your medication reminders on this device only for now.'**
  String get authEntryGuestDescription;

  /// Availability label for disabled provider auth options
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get authEntryComingSoon;

  /// Accessibility hint for disabled auth entry options
  ///
  /// In en, this message translates to:
  /// **'Unavailable in this release.'**
  String get authEntryDisabledSemanticsHint;

  /// Feedback shown after tapping the disabled Google option
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is not available in this phase yet.'**
  String get authEntryGoogleUnavailableFeedback;

  /// Feedback shown when the Google flow is cancelled
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was cancelled. You can try again or continue as a guest.'**
  String get authEntryGoogleCancelledFeedback;

  /// Feedback shown when the Google flow fails
  ///
  /// In en, this message translates to:
  /// **'Google sign-in could not be completed. Please try again.'**
  String get authEntryGoogleFailedFeedback;

  /// Feedback shown when Google sign-in is attempted on an unsupported runner
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is not available on this runner. You can continue locally as a guest.'**
  String get authEntryGoogleUnsupportedRunnerFeedback;

  /// Feedback shown after tapping the disabled Apple option
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in is not available on this device right now.'**
  String get authEntryAppleUnavailableFeedback;

  /// Feedback shown when the Apple flow is cancelled
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in was cancelled. You can try again or continue as a guest.'**
  String get authEntryAppleCancelledFeedback;

  /// Feedback shown when the Apple flow fails
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in could not be completed. Please try again.'**
  String get authEntryAppleFailedFeedback;

  /// Feedback shown when Apple sign-in conflicts with an existing non-Apple account
  ///
  /// In en, this message translates to:
  /// **'This account already exists with another sign-in method. Use the original sign-in option to continue.'**
  String get authEntryAppleConflictFeedback;

  /// Feedback shown when an unsupported stored entry mode is restored
  ///
  /// In en, this message translates to:
  /// **'The previous sign-in mode is not supported yet. Please choose an option again.'**
  String get authEntryUnsupportedRestoreFeedback;

  /// Accessibility label for the guest entry option
  ///
  /// In en, this message translates to:
  /// **'Continue as guest. Available now.'**
  String get authEntryGuestSemanticsLabel;

  /// Accessibility label for launch restoration progress
  ///
  /// In en, this message translates to:
  /// **'Restoring launch state'**
  String get authEntryRestoring;

  /// Relative time formatting for minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes} m ago'**
  String timeAgoMinutes(int minutes);

  /// Relative time formatting for hours
  ///
  /// In en, this message translates to:
  /// **'{hours} h ago'**
  String timeAgoHours(int hours);

  /// Relative time formatting for less than a minute ago
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// Message shown when no medications have been taken in the last 24 hours
  ///
  /// In en, this message translates to:
  /// **'No medications taken today.'**
  String get noMedsToday;

  /// Title for the last taken medicines page
  ///
  /// In en, this message translates to:
  /// **'Last Taken'**
  String get lastTakenTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
