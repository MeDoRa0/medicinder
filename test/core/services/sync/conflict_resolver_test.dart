import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/core/services/sync/conflict_resolver.dart';
import 'package:medicinder/domain/entities/medication.dart';

Medication _buildMedication({required String id, required DateTime updatedAt}) {
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

    test(
      'merges dose statuses based on union of taken doses when structures are identical',
      () async {
        const resolver = MedicationConflictResolver();
        final baseDate = DateTime(2026, 4, 1);

        final medication = _buildMedication(id: 'med-1', updatedAt: baseDate)
            .copyWith(
              doses: [
                const MedicationDose(taken: false),
                const MedicationDose(taken: false),
              ],
            );

        final localMedication = medication.copyWith(
          syncMetadata: medication.syncMetadata.copyWith(
            updatedAt: baseDate.add(const Duration(hours: 1)),
          ),
          doses: [
            MedicationDose(
              taken: true,
              takenDate: baseDate.add(const Duration(hours: 1)),
            ),
            const MedicationDose(taken: false),
          ],
        );

        final remoteMedication = medication.copyWith(
          syncMetadata: medication.syncMetadata.copyWith(
            updatedAt: baseDate.add(const Duration(hours: 2)),
          ),
          doses: [
            const MedicationDose(taken: false),
            MedicationDose(
              taken: true,
              takenDate: baseDate.add(const Duration(hours: 2)),
            ),
          ],
        );

        final resolved = resolver.resolve(
          local: localMedication,
          remote: remoteMedication,
        );

        // Even if remote is newer, we merge the 'taken' flags if structures match.
        expect(resolved.doses[0].taken, isTrue);
        expect(resolved.doses[1].taken, isTrue);
      },
    );

    test('returns winner without merging doses when dose counts differ', () {
      const resolver = MedicationConflictResolver();
      final baseDate = DateTime(2026, 4, 1);

      final localMedication = _buildMedication(
        id: 'med-1',
        updatedAt: baseDate.add(const Duration(hours: 1)),
      ).copyWith(doses: [MedicationDose(taken: true, takenDate: baseDate)]);

      final remoteMedication =
          _buildMedication(
            id: 'med-1',
            updatedAt: baseDate.add(const Duration(hours: 2)),
          ).copyWith(
            doses: [
              const MedicationDose(taken: false),
              const MedicationDose(taken: false),
            ],
          );

      final resolved = resolver.resolve(
        local: localMedication,
        remote: remoteMedication,
      );

      // Remote wins (newer), no merge because dose counts differ.
      expect(resolved.doses, hasLength(2));
      expect(resolved.doses[0].taken, isFalse);
    });

    test('returns winner without merging doses when timing types differ', () {
      const resolver = MedicationConflictResolver();
      final baseDate = DateTime(2026, 4, 1);

      final localMedication = _buildMedication(
        id: 'med-1',
        updatedAt: baseDate.add(const Duration(hours: 1)),
      ).copyWith(timingType: MedicationTimingType.specificTime);

      final remoteMedication = _buildMedication(
        id: 'med-1',
        updatedAt: baseDate.add(const Duration(hours: 2)),
      ).copyWith(timingType: MedicationTimingType.contextBased);

      final resolved = resolver.resolve(
        local: localMedication,
        remote: remoteMedication,
      );

      // Remote wins because it's newer; no merge due to different timing type.
      expect(resolved.timingType, MedicationTimingType.contextBased);
    });

    test(
      'does not overwrite already-taken dose in winner with non-taken from loser',
      () {
        const resolver = MedicationConflictResolver();
        final baseDate = DateTime(2026, 4, 1);
        final takenDate = baseDate.add(const Duration(hours: 2));

        final localMedication = _buildMedication(
          id: 'med-1',
          updatedAt: baseDate.add(const Duration(hours: 1)),
        ).copyWith(doses: [const MedicationDose(taken: false)]);

        final remoteMedication = _buildMedication(
          id: 'med-1',
          updatedAt: baseDate.add(const Duration(hours: 2)),
        ).copyWith(doses: [MedicationDose(taken: true, takenDate: takenDate)]);

        final resolved = resolver.resolve(
          local: localMedication,
          remote: remoteMedication,
        );

        // Remote winner already has dose taken; local loser has it not taken.
        // Winner's taken state should be preserved.
        expect(resolved.doses[0].taken, isTrue);
        expect(resolved.doses[0].takenDate, takenDate);
      },
    );
  });
}
