import '../../../domain/entities/medication.dart';

class MedicationConflictResolver {
  const MedicationConflictResolver();

  Medication resolve({
    required Medication local,
    required Medication remote,
  }) {
    final localUpdatedAt = local.syncMetadata.updatedAt;
    final remoteUpdatedAt = remote.syncMetadata.updatedAt;

    final winner = remoteUpdatedAt.isAfter(localUpdatedAt) ? remote : local;
    final loser = winner == remote ? local : remote;

    // Check if structures match (same number of doses and same timing types)
    if (local.doses.length == remote.doses.length &&
        local.timingType == remote.timingType) {
      final mergedDoses = <MedicationDose>[];
      for (var i = 0; i < winner.doses.length; i++) {
        final winnerDose = winner.doses[i];
        final loserDose = loser.doses[i];

        if (!winnerDose.taken && loserDose.taken) {
          mergedDoses.add(winnerDose.copyWith(
            taken: true,
            takenDate: loserDose.takenDate,
          ));
        } else {
          mergedDoses.add(winnerDose);
        }
      }
      return winner.copyWith(doses: mergedDoses);
    }

    return winner;
  }
}

extension on MedicationDose {
  MedicationDose copyWith({
    DateTime? time,
    MealContext? context,
    int? offsetMinutes,
    bool? taken,
    DateTime? takenDate,
  }) {
    return MedicationDose(
      time: time ?? this.time,
      context: context ?? this.context,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      taken: taken ?? this.taken,
      takenDate: takenDate ?? this.takenDate,
    );
  }
}
