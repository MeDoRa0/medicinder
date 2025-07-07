import '../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/medication.dart';

String mealLabel(MealContext c, BuildContext context) {
  switch (c) {
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
