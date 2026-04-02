import 'dart:developer';

import '../../../data/datasources/medication_remote_data_source.dart';
import '../../../data/datasources/sync_queue_local_data_source.dart';
import '../../../domain/entities/medication.dart';
import '../../../domain/entities/sync/auth_session.dart';
import '../../../domain/entities/sync_metadata.dart';
import '../../../domain/entities/sync_operation.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/entities/sync/sync_types.dart' as sync_types;
import '../../../domain/repositories/medication_repository.dart';
import '../../../domain/repositories/sync_repository.dart';
import 'conflict_resolver.dart';

class SyncService implements SyncRepository {
  final AuthRepository _authRepository;
  final MedicationRepository _medicationRepository;
  final MedicationRemoteDataSource _remoteDataSource;
  final SyncQueueLocalDataSource _syncQueue;
  final MedicationConflictResolver _conflictResolver;

  SyncService({
    required AuthRepository authRepository,
    required MedicationRepository medicationRepository,
    required MedicationRemoteDataSource remoteDataSource,
    required SyncQueueLocalDataSource syncQueue,
    required MedicationConflictResolver conflictResolver,
  }) : _authRepository = authRepository,
       _medicationRepository = medicationRepository,
       _remoteDataSource = remoteDataSource,
       _syncQueue = syncQueue,
       _conflictResolver = conflictResolver;

  @override
  Future<SyncResult> synchronize() => syncNow(sync_types.SyncTrigger.manualRetry);

  @override
  Future<SyncResult> syncNow(sync_types.SyncTrigger trigger) async {
    final session = await _authRepository.getCurrentSession();
    if (!session.isSignedIn || session.userId == null) {
      return const SyncResult(
        success: false,
        message: 'Cloud sync requires a signed-in account.',
      );
    }

    final operations = await _syncQueue.getPendingOperations();
    var processedOperations = 0;
    var failedOperations = 0;
    var pulledRecords = 0;
    String? message;

    for (final operation in operations) {
      try {
        await _pushOperation(operation, userId: session.userId!);
        await _syncQueue.remove(operation.id);
        processedOperations++;
      } on CloudSyncDisabledException catch (error) {
        failedOperations++;
        message = error.toString();
        await _syncQueue.replace(
          operation.copyWith(
            attemptCount: operation.attemptCount + 1,
            lastAttemptAt: DateTime.now(),
            errorMessage: error.toString(),
          ),
        );
        break;
      } catch (error) {
        failedOperations++;
        await _syncQueue.replace(
          operation.copyWith(
            attemptCount: operation.attemptCount + 1,
            lastAttemptAt: DateTime.now(),
            errorMessage: error.toString(),
          ),
        );
        log('SyncService: failed to process ${operation.id}: $error');
      }
    }

    if (message == null) {
      try {
        pulledRecords = await _pullRemoteChanges(userId: session.userId!);
      } on CloudSyncDisabledException catch (error) {
        message = error.toString();
      } catch (error) {
        message = error.toString();
      }
    }

    return SyncResult(
      success: failedOperations == 0 && message == null,
      processedOperations: processedOperations,
      failedOperations: failedOperations,
      pulledRecords: pulledRecords,
      userId: session.userId,
      message: message ??
          (failedOperations == 0
              ? null
              : 'Some operations could not be synchronized.'),
    );
  }

  @override
  Future<void> handleConnectivityRestored() async {
    await syncNow(sync_types.SyncTrigger.connectivityRestored);
  }

  @override
  Future<void> handleAuthChanged(AuthSession session) async {
    if (!session.isSignedIn) {
      return;
    }
    await syncNow(sync_types.SyncTrigger.userSignIn);
  }

  Future<void> _pushOperation(
    SyncOperation operation, {
    required String userId,
  }) async {
    final medication = await _medicationRepository.getMedicationById(
      operation.entityId,
      includeDeleted: true,
    );

    if (operation.type == SyncOperationType.delete) {
      await _remoteDataSource.deleteMedicationForUser(userId, operation.entityId);
      if (medication != null) {
        await _medicationRepository.purgeMedication(operation.entityId);
      }
      return;
    }

    if (medication == null || medication.isDeleted) {
      return;
    }

    final scopedMedication = medication.copyWith(userId: userId);
    await _remoteDataSource.upsertMedicationForUser(userId, scopedMedication);
    await _medicationRepository.saveSyncedMedication(
      scopedMedication.markSynced(DateTime.now()),
    );
  }

  Future<int> _pullRemoteChanges({
    required String userId,
  }) async {
    final remoteMedications = await _remoteDataSource.pullMedications(userId);
    final localMedications = await _medicationRepository.getMedications(
      includeDeleted: true,
    );
    final localById = {
      for (final medication in localMedications) medication.id: medication,
    };

    for (final remoteMedication in remoteMedications) {
      final localMedication = localById[remoteMedication.id];
      if (localMedication == null) {
        await _medicationRepository.saveSyncedMedication(
          remoteMedication.copyWith(userId: userId).markSynced(DateTime.now()),
        );
        continue;
      }

      final mergedMedication = _conflictResolver.resolve(
        local: localMedication,
        remote: remoteMedication,
      );
      final resolvedMedication = mergedMedication.copyWith(
        userId: userId,
        syncMetadata: mergedMedication.syncMetadata.copyWith(
          status: SyncStatus.synced,
          lastSyncedAt: DateTime.now(),
        ),
      );

      await _medicationRepository.saveSyncedMedication(resolvedMedication);
    }
    return remoteMedications.length;
  }
}
