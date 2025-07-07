import '../../domain/entities/medication.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';

String getTypeLabel(MedicationType type, BuildContext context) {
  switch (type) {
    case MedicationType.pill:
      return AppLocalizations.of(context)!.pill;
    case MedicationType.syrup:
      return AppLocalizations.of(context)!.syrup;
  }
}

String doseLabel(MedicationDose dose, BuildContext context) {
  if (dose.time != null) {
    final t = dose.time!;
    final hour = t.hour;
    final minute = t.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
  if (dose.context != null) {
    switch (dose.context!) {
      case MealContext.beforeBreakfast:
        return AppLocalizations.of(context)!.beforeBreakfast;
      case MealContext.afterBreakfast:
        return AppLocalizations.of(context)!.afterBreakfast;
      case MealContext.beforeLunch:
        return AppLocalizations.of(context)!.beforeLunch;
      case MealContext.afterLunch:
        return AppLocalizations.of(context)!.afterLunch;
      case MealContext.beforeDinner:
        return AppLocalizations.of(context)!.beforeDinner;
      case MealContext.afterDinner:
        return AppLocalizations.of(context)!.afterDinner;
    }
  }
  return 'Dose';
}
