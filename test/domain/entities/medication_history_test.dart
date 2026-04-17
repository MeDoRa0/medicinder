import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/domain/entities/medication_history.dart';

void main() {
  group('MedicationHistory', () {
    test('two instances with same properties are equal', () {
      final takenAt = DateTime.utc(2026, 4, 17, 10, 30);

      final first = MedicationHistory(
        medicineId: 'med-1',
        medicineName: 'Aspirin',
        dose: '500 mg',
        takenAt: takenAt,
      );
      final second = MedicationHistory(
        medicineId: 'med-1',
        medicineName: 'Aspirin',
        dose: '500 mg',
        takenAt: takenAt,
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('two instances with different properties are not equal', () {
      final takenAt = DateTime.utc(2026, 4, 17, 10, 30);

      final first = MedicationHistory(
        medicineId: 'med-1',
        medicineName: 'Aspirin',
        dose: '500 mg',
        takenAt: takenAt,
      );
      final second = MedicationHistory(
        medicineId: 'med-2',
        medicineName: 'Aspirin',
        dose: '500 mg',
        takenAt: takenAt,
      );

      expect(first, isNot(second));
    });

    test('instances with different dose or takenAt are not equal', () {
      final takenAt = DateTime.utc(2026, 4, 17, 10, 30);
      final differentTakenAt = DateTime.utc(2026, 4, 17, 11, 00);

      final base = MedicationHistory(
        medicineId: 'med-1',
        medicineName: 'Aspirin',
        dose: '500 mg',
        takenAt: takenAt,
      );
      
      final differentDose = MedicationHistory(
        medicineId: 'med-1',
        medicineName: 'Aspirin',
        dose: '250 mg',
        takenAt: takenAt,
      );

      final differentTime = MedicationHistory(
        medicineId: 'med-1',
        medicineName: 'Aspirin',
        dose: '500 mg',
        takenAt: differentTakenAt,
      );

      expect(base, isNot(differentDose));
      expect(base, isNot(differentTime));
    });
  });
}
