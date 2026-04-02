import '../../domain/entities/medication.dart';
import '../../domain/entities/sync_metadata.dart';
import '../../domain/entities/sync_operation.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/medication_repository.dart';
import '../datasources/sync_queue_local_data_source.dart';
import '../datasources/medication_local_data_source.dart';
import '../../core/error/failures.dart';

class MedicationRepositoryImpl implements MedicationRepository {
  final MedicationLocalDataSource localDataSource;
  final SyncQueueLocalDataSource syncQueueLocalDataSource;
  final AuthRepository authRepository;

  MedicationRepositoryImpl(
    this.localDataSource,
    this.syncQueueLocalDataSource,
    this.authRepository,
  );

  @override
  Future<List<Medication>> getMedications({bool includeDeleted = false}) async {
    try {
      return await localDataSource.getAllMedications(
        includeDeleted: includeDeleted,
      );
    } catch (e) {
      throw StorageFailure(e.toString());
    }
  }

  @override
  Future<Medication?> getMedicationById(
    String id, {
    bool includeDeleted = false,
  }) async {
    try {
      return await localDataSource.getMedicationById(
        id,
        includeDeleted: includeDeleted,
      );
    } catch (e) {
      throw StorageFailure(e.toString());
    }
  }

  @override
  Future<void> addMedication(Medication medication) async {
    try {
      final timestamp = DateTime.now();
      final pendingMedication = await _attachSignedInUser(
        medication.copyWith(
          syncMetadata: medication.syncMetadata.copyWith(
            updatedAt: timestamp,
            status: SyncStatus.pendingCreate,
            syncVersion: medication.syncMetadata.syncVersion + 1,
          ),
        ),
      );
      await localDataSource.addMedication(pendingMedication);
      await _enqueueOperation(
        medicationId: medication.id,
        type: SyncOperationType.create,
      );
    } catch (e) {
      throw StorageFailure(e.toString());
    }
  }

  @override
  Future<void> updateMedication(Medication medication) async {
    try {
      final timestamp = DateTime.now();
      final status = medication.syncMetadata.lastSyncedAt == null
          ? SyncStatus.pendingCreate
          : SyncStatus.pendingUpdate;
      final pendingMedication = await _attachSignedInUser(
        medication.copyWith(
          syncMetadata: medication.syncMetadata.copyWith(
            updatedAt: timestamp,
            status: status,
            syncVersion: medication.syncMetadata.syncVersion + 1,
          ),
        ),
      );
      await localDataSource.updateMedication(pendingMedication);
      await _enqueueOperation(
        medicationId: medication.id,
        type: status == SyncStatus.pendingCreate
            ? SyncOperationType.create
            : SyncOperationType.update,
      );
    } catch (e) {
      throw StorageFailure(e.toString());
    }
  }

  @override
  Future<void> deleteMedication(String id) async {
    try {
      await localDataSource.deleteMedication(id);
      await _enqueueOperation(
        medicationId: id,
        type: SyncOperationType.delete,
      );
    } catch (e) {
      throw StorageFailure(e.toString());
    }
  }

  @override
  Future<void> updateDoseStatus(
    String medicationId,
    int doseIndex,
    bool taken,
  ) async {
    try {
      await localDataSource.updateDoseStatus(medicationId, doseIndex, taken);
      final updatedMedication = await localDataSource.getMedicationById(
        medicationId,
        includeDeleted: true,
      );
      if (updatedMedication != null && !updatedMedication.isDeleted) {
        final status = updatedMedication.syncMetadata.lastSyncedAt == null
            ? SyncStatus.pendingCreate
            : SyncStatus.pendingUpdate;
        await localDataSource.updateMedication(
          (await _attachSignedInUser(updatedMedication)).copyWith(
            syncMetadata: updatedMedication.syncMetadata.copyWith(
              updatedAt: DateTime.now(),
              status: status,
              syncVersion: updatedMedication.syncMetadata.syncVersion + 1,
            ),
          ),
        );
        await _enqueueOperation(
          medicationId: medicationId,
          type: status == SyncStatus.pendingCreate
              ? SyncOperationType.create
              : SyncOperationType.update,
        );
      }
    } catch (e) {
      throw StorageFailure(e.toString());
    }
  }

  @override
  Future<void> resetDailyDoses() async {
    try {
      await localDataSource.resetDailyDoses();
      final medications = await localDataSource.getAllMedications(
        includeDeleted: true,
      );
      for (final medication in medications.where((item) => !item.isDeleted)) {
        final status = medication.syncMetadata.lastSyncedAt == null
            ? SyncStatus.pendingCreate
            : SyncStatus.pendingUpdate;
        await localDataSource.updateMedication(
          (await _attachSignedInUser(medication)).copyWith(
            syncMetadata: medication.syncMetadata.copyWith(
              updatedAt: DateTime.now(),
              status: status,
              syncVersion: medication.syncMetadata.syncVersion + 1,
            ),
          ),
        );
        await _enqueueOperation(
          medicationId: medication.id,
          type: status == SyncStatus.pendingCreate
              ? SyncOperationType.create
              : SyncOperationType.update,
        );
      }
    } catch (e) {
      throw StorageFailure(e.toString());
    }
  }

  @override
  Future<void> saveSyncedMedication(Medication medication) async {
    try {
      await localDataSource.updateMedication(medication);
    } catch (e) {
      throw StorageFailure(e.toString());
    }
  }

  @override
  Future<void> purgeMedication(String id) async {
    try {
      await localDataSource.purgeMedication(id);
    } catch (e) {
      throw StorageFailure(e.toString());
    }
  }

  Future<void> _enqueueOperation({
    required String medicationId,
    required SyncOperationType type,
  }) async {
    final now = DateTime.now();
    final operationId = 'medication-$medicationId-${type.name}';
    await syncQueueLocalDataSource.enqueue(
      SyncOperation(
        id: operationId,
        entityType: SyncEntityType.medication,
        entityId: medicationId,
        type: type,
        createdAt: now,
      ),
    );
  }

  Future<Medication> _attachSignedInUser(Medication medication) async {
    if (medication.userId != null) {
      return medication;
    }
    final session = await authRepository.getCurrentSession();
    if (!session.isSignedIn || session.userId == null) {
      return medication;
    }
    return medication.copyWith(userId: session.userId);
  }
}
