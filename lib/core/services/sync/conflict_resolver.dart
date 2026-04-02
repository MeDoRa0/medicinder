import '../../../domain/entities/medication.dart';

class MedicationConflictResolver {
  const MedicationConflictResolver();

  Medication resolve({
    required Medication local,
    required Medication remote,
  }) {
    final localUpdatedAt = local.syncMetadata.updatedAt;
    final remoteUpdatedAt = remote.syncMetadata.updatedAt;

    if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
      return remote;
    }

    return local;
  }
}
