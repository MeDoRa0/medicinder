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
  /// **'Usage:'**
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
