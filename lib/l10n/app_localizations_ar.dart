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
  String get usage => 'الاستخدام';

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
  String get usageLabel => 'الاستخدام:';

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
  String get dailyDosesCompleted => 'تم إكمال الجرعات اليومية - يستمر العلاج';
}
