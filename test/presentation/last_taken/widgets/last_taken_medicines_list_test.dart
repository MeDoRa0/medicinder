import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/domain/entities/medication_history.dart';
import 'package:medicinder/l10n/app_localizations.dart';
import 'package:medicinder/presentation/last_taken/widgets/last_taken_medicines_list.dart';
import 'package:medicinder/presentation/last_taken/widgets/taken_medicine_card.dart';

void main() {
  Widget buildTestWidget(List<MedicationHistory> historyList) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: LastTakenMedicinesList(medications: historyList),
      ),
    );
  }

  testWidgets('LastTakenMedicinesList displays multiple Taken cards in order', (WidgetTester tester) async {
    final now = DateTime.now();
    final history1 = MedicationHistory(
      medicineId: '1',
      medicineName: 'Med One',
      dose: '1 Pill',
      takenAt: now.subtract(const Duration(minutes: 5)),
    );
    final history2 = MedicationHistory(
      medicineId: '2',
      medicineName: 'Med Two',
      dose: '2 mg',
      takenAt: now.subtract(const Duration(hours: 2)),
    );

    await tester.pumpWidget(buildTestWidget([history1, history2]));
    await tester.pumpAndSettle();

    expect(find.byType(TakenMedicineCard), findsNWidgets(2));
    
    final medOneFinder = find.text('Med One');
    final medTwoFinder = find.text('Med Two');
    
    expect(medOneFinder, findsOneWidget);
    expect(medTwoFinder, findsOneWidget);

    final medOneY = tester.getTopLeft(medOneFinder).dy;
    final medTwoY = tester.getTopLeft(medTwoFinder).dy;
    
    expect(medOneY, lessThan(medTwoY));
  });
}
