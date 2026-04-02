import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/core/services/sync/conflict_resolver.dart';
import 'package:medicinder/domain/entities/medication.dart';

Medication _buildMedication({
  required String id,
  required DateTime updatedAt,
}) {
  return Medication.create(
    id: id,
    name: 'Vitamin C',
    usage: 'After breakfast',
    dosage: '1 pill',
    type: MedicationType.pill,
    timingType: MedicationTimingType.specificTime,
    doses: const [],
    totalDays: 10,
    startDate: DateTime(2026, 4, 1),
    now: updatedAt,
  );
}

void main() {
  group('MedicationConflictResolver', () {
    test('returns remote medication when remote update is newer', () {
      const resolver = MedicationConflictResolver();
      final localMedication = _buildMedication(
        id: 'med-1',
        updatedAt: DateTime(2026, 4, 1, 9),
      );
      final remoteMedication = _buildMedication(
        id: 'med-1',
        updatedAt: DateTime(2026, 4, 1, 10),
      ).copyWith(name: 'Updated remotely');

      final resolved = resolver.resolve(
        local: localMedication,
        remote: remoteMedication,
      );

      expect(resolved.name, 'Updated remotely');
    });

    test('keeps local medication when local update is newer', () {
      const resolver = MedicationConflictResolver();
      final localMedication = _buildMedication(
        id: 'med-1',
        updatedAt: DateTime(2026, 4, 1, 11),
      ).copyWith(name: 'Updated locally');
      final remoteMedication = _buildMedication(
        id: 'med-1',
        updatedAt: DateTime(2026, 4, 1, 10),
      );

      final resolved = resolver.resolve(
        local: localMedication,
        remote: remoteMedication,
      );

      expect(resolved.name, 'Updated locally');
    });
  });
}
