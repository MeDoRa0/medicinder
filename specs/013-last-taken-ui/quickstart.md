# Quickstart

## Dependencies
- Ensure the `LastTakenMedicinesCubit` operates correctly to provide the data stream for the UI.
- Update `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb` with new translation keys for relative times (e.g. `recentTimeJustNow`, `recentTimeMinutesAgo`, `recentTimeHoursAgo`, `noRecentMedications`).

## Steps
1. Add necessary translation keys and run `flutter gen-l10n`.
2. Build the `EmptyMedicationState` widget for zero records.
3. Build the `TakenMedicineCard` widget mapping `MedicationIntakeRecord` field strings.
4. Scaffold the `LastTakenMedicinesPage` using a `BlocBuilder<LastTakenMedicinesCubit, LastTakenMedicinesState>`.
5. Write Widget tests mimicking loaded and empty cubit states.
