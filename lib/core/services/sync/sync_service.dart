import 'dart:developer';

import '../../../data/datasources/medication_remote_data_source.dart';
import '../../../data/datasources/sync_queue_local_data_source.dart';
import '../../../domain/entities/sync/auth_session.dart';
import '../../../domain/entities/sync_metadata.dart';
import '../../../domain/entities/sync/sync_cycle_state.dart';
import '../../../domain/entities/sync_operation.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/entities/sync/pending_change.dart';
import '../../../domain/entities/sync/sync_types.dart' as sync_types;
import '../../../domain/entities/sync/user_sync_profile.dart';
import '../../../domain/entities/sync/sync_status_view_state.dart';
import '../../../data/datasources/sync_state_local_data_source.dart';
import '../../../domain/entities/sync/conflict_metadata.dart';
import '../../../domain/repositories/medication_repository.dart';
import '../../../domain/repositories/sync_repository.dart';
import 'conflict_resolver.dart';

class SyncService implements SyncRepository {
  final AuthRepository _authRepository;
  final MedicationRepository _medicationRepository;
  final MedicationRemoteDataSource _remoteDataSource;
  final SyncQueueLocalDataSource _syncQueue;
  final MedicationConflictResolver _conflictResolver;
  final SyncStateLocalDataSource _syncState;

  bool _isSyncing = false;

  SyncService({
    required AuthRepository authRepository,
    required MedicationRepository medicationRepository,
    required MedicationRemoteDataSource remoteDataSource,
    required SyncQueueLocalDataSource syncQueue,
    required MedicationConflictResolver conflictResolver,
    required SyncStateLocalDataSource syncState,
  }) : _authRepository = authRepository,
       _medicationRepository = medicationRepository,
       _remoteDataSource = remoteDataSource,
       _syncQueue = syncQueue,
       _conflictResolver = conflictResolver,
       _syncState = syncState;

  @override
  Future<SyncResult> synchronize() =>
      syncNow(sync_types.SyncTrigger.manualRetry);

  @override
  Future<SyncResult> syncNow(sync_types.SyncTrigger trigger) async {
    if (_isSyncing) {
      return const SyncResult(
        success: false,
        message: 'A sync cycle is already in progress.',
      );
    }

    _isSyncing = true;
    try {
      final session = await _authRepository.getCurrentSession();
      if (!session.isSignedIn || session.userId == null) {
        return const SyncResult(
          success: false,
          message: 'Cloud sync requires a signed-in account.',
        );
      }

      final userId = session.userId!;

    final cycleId = DateTime.now().millisecondsSinceEpoch.toString();
    var cycle = SyncCycleState(
      cycleId: cycleId,
      userId: userId,
      trigger: trigger,
      startedAt: DateTime.now(),
      status: sync_types.SyncCycleStatus.running,
    );

    await _syncState.saveCycle(cycle);

    final changes = await _syncQueue.getEffectivePendingChanges(
      userId: userId,
    );
    var pushedCount = 0;
    var failedCount = 0;
    var pulledCount = 0;
    String? message;

      for (final change in changes) {
        try {
          await _pushChange(change, userId: userId);
          await _syncQueue.markPendingChangeSucceeded(change.changeId);
          pushedCount++;
        } on CloudSyncDisabledException catch (error) {
          failedCount++;
          message = error.toString();
          await _syncQueue.markPendingChangeFailed(
            change.changeId,
            errorMessage: error.toString(),
          );
          break;
        } catch (error) {
          failedCount++;
          await _syncQueue.markPendingChangeFailed(
            change.changeId,
            errorMessage: error.toString(),
          );
          log('SyncService: failed to process ${change.changeId}: $error');
        }
      }

      if (message == null) {
        try {
          pulledCount = await _pullRemoteChanges(userId: userId);
        } on CloudSyncDisabledException catch (error) {
          message = error.toString();
        } catch (error) {
          message = error.toString();
        }
      }

      final success = failedCount == 0 && message == null;
      final completedAt = DateTime.now();

      cycle = cycle.copyWith(
        completedAt: completedAt,
        status: success
            ? sync_types.SyncCycleStatus.succeeded
            : sync_types.SyncCycleStatus.failed,
        pushedCount: pushedCount,
        pulledCount: pulledCount,
        failedCount: failedCount,
        failureClass: message,
      );

      await _syncState.saveCycle(cycle);

      // Update User Sync Profile
      final profile = await _syncState.getProfile(userId);
      if (profile != null) {
        await _syncState.saveProfile(
          profile.copyWith(
            engineStatus: cycle.status,
            lastTrigger: trigger,
            lastStartedAt: cycle.startedAt,
            lastCompletedAt: completedAt,
            lastSuccessAt: success ? completedAt : null,
            lastFailureAt: !success ? completedAt : null,
            message: message,
            lastPushedCount: pushedCount,
            lastPulledCount: pulledCount,
            lastFailedCount: failedCount,
            updatedAt: completedAt,
          ),
        );
      } else {
        log(
          'SyncService: profile missing for user $userId, creating default profile.',
          name: 'SyncService',
        );
        final newProfile = UserSyncProfile(
          userId: userId,
          providerIds: const <String>[],
          syncEnabled: true,
          workspaceReady: true,
          createdAt: completedAt,
          updatedAt: completedAt,
          statusViewState: SyncStatusViewState.ready,
          engineStatus: cycle.status,
          lastTrigger: trigger,
          lastStartedAt: cycle.startedAt,
          lastCompletedAt: completedAt,
          lastSuccessAt: success ? completedAt : null,
          lastFailureAt: !success ? completedAt : null,
          message: message,
          lastPushedCount: pushedCount,
          lastPulledCount: pulledCount,
          lastFailedCount: failedCount,
        );
        await _syncState.saveProfile(newProfile);
      }

      return SyncResult(
        success: success,
        pushedCount: pushedCount,
        failedCount: failedCount,
        pulledCount: pulledCount,
        userId: userId,
        message:
            message ??
            (failedCount == 0
                ? null
                : 'Some operations could not be synchronized.'),
      );
    } finally {
      _isSyncing = false;
    }
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

  Future<void> _pushChange(
    PendingChange change, {
    required String userId,
  }) async {
    final medication = await _medicationRepository.getMedicationById(
      change.entityId,
      includeDeleted: true,
    );

    if (change.operation == SyncOperationType.delete) {
      await _remoteDataSource.deleteMedicationForUser(userId, change.entityId);
      if (medication != null) {
        await _medicationRepository.purgeMedication(change.entityId);
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

  Future<int> _pullRemoteChanges({required String userId}) async {
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

      // Log conflict metadata
      final winningSource =
          mergedMedication.syncMetadata.updatedAt ==
              remoteMedication.syncMetadata.updatedAt
          ? 'remote'
          : 'local';

      await _syncState.saveConflict(
        ConflictMetadata(
          entityType: sync_types.SyncEntityType.medication,
          entityId: remoteMedication.id,
          userId: userId,
          localUpdatedAt: localMedication.syncMetadata.updatedAt,
          remoteUpdatedAt: remoteMedication.syncMetadata.updatedAt,
          winningSource: winningSource,
          resolvedAt: DateTime.now(),
        ),
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
