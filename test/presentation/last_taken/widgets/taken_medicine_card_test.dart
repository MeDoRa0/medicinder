import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/domain/entities/medication_history.dart';
import 'package:medicinder/l10n/app_localizations.dart';
import 'package:medicinder/presentation/last_taken/widgets/taken_medicine_card.dart';

void main() {
  Widget buildTestWidget(MedicationHistory history) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: TakenMedicineCard(history: history),
      ),
    );
  }

  testWidgets('TakenMedicineCard displays medicine name, dose, and relative time', (WidgetTester tester) async {
    final now = DateTime.now();
    final takenTime = now.subtract(const Duration(minutes: 10));
    final history = MedicationHistory(
      medicineId: '1',
      medicineName: 'Aspirin',
      dose: '1 Pill',
      takenAt: takenTime,
    );

    await tester.pumpWidget(buildTestWidget(history));

    expect(find.text('Aspirin'), findsOneWidget);
    expect(find.text('1 Pill'), findsOneWidget);
    // Relative time string via time_extension.dart will be "10 m ago"
    expect(find.text('10 m ago'), findsOneWidget);
  });

  testWidgets('TakenMedicineCard wraps long text without overflowing', (WidgetTester tester) async {
    final now = DateTime.now();
    final takenTime = now.subtract(const Duration(minutes: 5));
    final history = MedicationHistory(
      medicineId: '2',
      medicineName: 'SuperLongMedicationNameThatShouldWrapToMultipleLinesIfThereIsNotEnoughSpace OnTheScreen',
      dose: '2 Pills',
      takenAt: takenTime,
    );

    await tester.pumpWidget(buildTestWidget(history));
    expect(tester.takeException(), isNull); // Verify no layout overflow exception
    expect(find.textContaining('SuperLongMedicationName'), findsOneWidget);
  });
}
