// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'ميديسيندر';

  @override
  String get homeTitle => 'أدويتي';

  @override
  String get addMedication => 'إضافة دواء';

  @override
  String get editMedication => 'تعديل الدواء';

  @override
  String get medicineName => 'اسم الدواء';

  @override
  String get usage => 'لعلاج';

  @override
  String get dosage => 'الجرعة';

  @override
  String get days => 'كم يوم تحتاج لتناول الدواء؟';

  @override
  String get timing => 'الوقت:';

  @override
  String get specificTimes => 'أوقات محددة';

  @override
  String get beforeAfterMeals => 'قبل/بعد الوجبات';

  @override
  String get save => 'حفظ';

  @override
  String get settings => 'الإعدادات';

  @override
  String get setMealTimes => 'حدد أوقات وجباتك:';

  @override
  String get breakfast => 'الإفطار';

  @override
  String get lunch => 'الغداء';

  @override
  String get dinner => 'العشاء';

  @override
  String get language => 'اللغة:';

  @override
  String get english => 'الإنجليزية';

  @override
  String get arabic => 'العربية';

  @override
  String get welcome =>
      'مرحباً!\n\nلبدء الاستخدام، يرجى تحديد أوقات وجباتك. هذا يساعدنا في تذكيرك بتناول الدواء في الوقت المناسب.';

  @override
  String get noMedications => 'لم يتم إضافة أي أدوية بعد.';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get courseFinished => 'انتهت فترة الدواء';

  @override
  String daysLeft(int days) {
    return 'الأيام المتبقية: $days';
  }

  @override
  String dosesPerDay(int count) {
    return 'الجرعات في اليوم: $count';
  }

  @override
  String get deleteMedication => 'حذف الدواء';

  @override
  String get deleteConfirm => 'هل أنت متأكد أنك تريد حذف هذا الدواء؟';

  @override
  String get cancel => 'إلغاء';

  @override
  String get type => 'النوع:';

  @override
  String get usageLabel => 'لعلاج:';

  @override
  String get dosageLabel => 'الجرعة:';

  @override
  String get pill => 'حبة';

  @override
  String get syrup => 'شراب';

  @override
  String get addTime => 'إضافة وقت';

  @override
  String get beforeBreakfast => 'قبل الإفطار';

  @override
  String get afterBreakfast => 'بعد الإفطار';

  @override
  String get beforeLunch => 'قبل الغداء';

  @override
  String get afterLunch => 'بعد الغداء';

  @override
  String get beforeDinner => 'قبل العشاء';

  @override
  String get afterDinner => 'بعد العشاء';

  @override
  String get medicineType => 'نوع الدواء:';

  @override
  String get mealTimesSaved => 'تم حفظ أوقات الوجبات!';

  @override
  String get before => 'قبل';

  @override
  String get after => 'بعد';

  @override
  String get dailyDosesCompleted => 'تم تناول جرعات اليوم. العلاج مستمر.';

  @override
  String get courseContinues => 'العلاج مستمر.';

  @override
  String get medicationNotFound => 'لم يتم العثور على الدواء';

  @override
  String get invalidData => 'بيانات الدواء غير صحيحة';

  @override
  String get invalidDoseIndex => 'اختيار الجرعة غير صحيح';

  @override
  String get notificationPermissionDenied => 'تم رفض إذن الإشعارات';

  @override
  String get notificationSchedulingFailed => 'فشل في جدولة الإشعار';

  @override
  String get dataMigrationFailed => 'فشل نقل البيانات';

  @override
  String get storageError => 'حدث خطأ في التخزين';

  @override
  String get networkError => 'فشل الاتصال بالشبكة';

  @override
  String get validationError => 'البيانات المقدمة غير صحيحة';

  @override
  String get permissionDenied => 'تم رفض الإذن';

  @override
  String get resourceNotFound => 'لم يتم العثور على المورد';

  @override
  String get unknownError => 'حدث خطأ غير متوقع';

  @override
  String get retryNetwork => 'تحقق من اتصالك وحاول مرة أخرى';

  @override
  String get retryStorage => 'حاول مرة أخرى أو أعد تشغيل التطبيق';

  @override
  String get retryNotification => 'حاول مرة أخرى أو تحقق من إعدادات الإشعارات';

  @override
  String get checkInput => 'يرجى التحقق من المدخلات والمحاولة مرة أخرى';

  @override
  String get tryAgain => 'يرجى المحاولة مرة أخرى';

  @override
  String get forever => 'دائماً';

  @override
  String get courseCompleted => 'اكتمل العلاج';

  @override
  String get dose => 'جرعة';

  @override
  String get required => 'مطلوب';

  @override
  String get repeatForever => 'تكرار دائماً';

  @override
  String get statistics => 'الإحصائيات';

  @override
  String get medicationStatistics => 'إحصائيات الأدوية';

  @override
  String get timePeriod => 'الفترة الزمنية';

  @override
  String get days7 => '7 أيام';

  @override
  String get days30 => '30 يوم';

  @override
  String get days90 => '90 يوم';

  @override
  String get mostTakenMedication => 'الدواء الأكثر تناولاً';

  @override
  String get medicationDistribution => 'توزيع الأدوية';

  @override
  String get allMedications => 'جميع الأدوية';

  @override
  String get noMedicationData => 'لا توجد بيانات أدوية متاحة';

  @override
  String get takeMedicationsForStats =>
      'تناول بعض الأدوية لرؤية الإحصائيات هنا';

  @override
  String dosesTaken(int count, String percentage) {
    return '$count جرعة تم تناولها ($percentage%)';
  }

  @override
  String get doses => 'جرعات';

  @override
  String get other => 'أخرى';

  @override
  String error(String message) {
    return 'خطأ: $message';
  }

  @override
  String get enterValidDays => 'أدخل عدد أيام صحيح';

  @override
  String get pillUnit => 'حبة';

  @override
  String get mlUnit => 'مل';

  @override
  String get exampleDays => 'مثال: 7';

  @override
  String get medicationReminders => 'تذكيرات الأدوية';

  @override
  String get remindersForMedicationDoses => 'تذكيرات لجرعات الأدوية';

  @override
  String get notificationPermissionDeniedTitle => 'تم رفض إذن الإشعارات';

  @override
  String get enableNotificationsMessage =>
      'لتلقي تذكيرات الأدوية، يرجى تفعيل الإشعارات في إعدادات جهازك.';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get medicationReminder => 'تذكير الدواء';

  @override
  String timeToTakeMedication(String medicationName) {
    return 'حان الوقت لتناول $medicationName';
  }

  @override
  String get done => 'تناولت';

  @override
  String get remindMeLater => 'غفوة';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get goBack => 'العودة';

  @override
  String get dosageHintPill => 'مثال: حبة واحدة، حبتان';

  @override
  String get dosageHintSyrup => 'مثال: 5 مل، 10 مل';

  @override
  String get am => 'ص';

  @override
  String get pm => 'م';
}
