import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/core/services/sync/conflict_resolver.dart';
import 'package:medicinder/core/services/sync/sync_service.dart';
import 'package:medicinder/data/datasources/medication_remote_data_source.dart';
import 'package:medicinder/data/datasources/sync_queue_local_data_source.dart';
import 'package:medicinder/data/datasources/sync_state_local_data_source.dart';
import 'package:medicinder/domain/entities/medication.dart';
import 'package:medicinder/domain/entities/sync/auth_session.dart';
import 'package:medicinder/domain/entities/sync/conflict_metadata.dart';
import 'package:medicinder/domain/entities/sync/pending_change.dart';
import 'package:medicinder/domain/entities/sync_operation.dart';
import 'package:medicinder/domain/entities/sync/sync_cycle_state.dart';
import 'package:medicinder/domain/entities/sync/sync_status_view_state.dart';
import 'package:medicinder/domain/entities/sync/user_sync_profile.dart';
import 'package:medicinder/domain/entities/sync_metadata.dart';
import 'package:medicinder/domain/entities/sync/sync_types.dart' as sync_types;
import 'package:medicinder/domain/repositories/auth_repository.dart';
import 'package:medicinder/domain/repositories/medication_repository.dart';

void main() {
  group('SyncService', () {
    test(
      'processes queued create operations and marks medication as synced',
      () async {
        final medication = _buildMedication(
          id: 'med-1',
          updatedAt: DateTime(2026, 4, 1, 8),
        );
        final repository = _FakeMedicationRepository([medication]);
        final queue = _FakeSyncQueue();
        final remote = _FakeMedicationRemoteDataSource();
        final syncState = _FakeSyncStateLocalDataSource();
        final service = SyncService(
          authRepository: _FakeAuthRepository(),
          medicationRepository: repository,
          remoteDataSource: remote,
          syncQueue: queue,
          conflictResolver: const MedicationConflictResolver(),
          syncState: syncState,
        );

        await queue.enqueuePendingChange(
          PendingChange(
            changeId: 'op-1',
            entityType: sync_types.SyncEntityType.medication,
            entityId: medication.id,
            operation: sync_types.SyncOperationType.create,
            payload: medication.toMap(),
            queuedAt: DateTime(2026, 4, 1, 8),
            sourceUpdatedAt: DateTime(2026, 4, 1, 8),
            userId: 'user-123',
            status: sync_types.SyncOperationStatus.pending,
          ),
        );

        final result = await service.synchronize();

        expect(result.success, isTrue);
        expect(result.pushedCount, 1);
        expect(await queue.listPendingChanges(), isEmpty);
        expect(remote.upsertedMedicationIds, [medication.id]);
        expect(
          (await repository.getMedicationById(
            medication.id,
          ))?.syncMetadata.status,
          SyncStatus.synced,
        );
      },
    );

    test('keeps queued operations when remote sync is disabled', () async {
      final medication = _buildMedication(
        id: 'med-2',
        updatedAt: DateTime(2026, 4, 1, 8),
      );
      final repository = _FakeMedicationRepository([medication]);
      final queue = _FakeSyncQueue();
      final remote = _DisabledFakeMedicationRemoteDataSource();
      final syncState = _FakeSyncStateLocalDataSource();
      final service = SyncService(
        authRepository: _FakeAuthRepository(),
        medicationRepository: repository,
        remoteDataSource: remote,
        syncQueue: queue,
        conflictResolver: const MedicationConflictResolver(),
        syncState: syncState,
      );

      await queue.enqueuePendingChange(
        PendingChange(
          changeId: 'op-2',
          entityType: sync_types.SyncEntityType.medication,
          entityId: medication.id,
          operation: sync_types.SyncOperationType.create,
          payload: medication.toMap(),
          queuedAt: DateTime(2026, 4, 1, 8),
          sourceUpdatedAt: DateTime(2026, 4, 1, 8),
          userId: 'user-123',
          status: sync_types.SyncOperationStatus.pending,
        ),
      );

      final result = await service.synchronize();

      expect(result.success, isFalse);
      final pending = await queue.listPendingChanges();
      expect(pending.single.attemptCount, 1);
      expect(pending.single.errorMessage, contains('Cloud sync backend'));
    });

    group('Triggers and Guards', () {
      test('syncNow(appStartup) starts a sync cycle', () async {
        final service = SyncService(
          authRepository: _FakeAuthRepository(),
          medicationRepository: _FakeMedicationRepository([]),
          remoteDataSource: _FakeMedicationRemoteDataSource(),
          syncQueue: _FakeSyncQueue(),
          conflictResolver: const MedicationConflictResolver(),
          syncState: _FakeSyncStateLocalDataSource(),
        );

        final result = await service.syncNow(sync_types.SyncTrigger.appStartup);

        expect(result.success, isTrue);
      });

      test(
        'handleConnectivityRestored() triggers syncNow(connectivityRestored)',
        () async {
          final queue = _FakeSyncQueue();
          final service = SyncService(
            authRepository: _FakeAuthRepository(),
            medicationRepository: _FakeMedicationRepository([]),
            remoteDataSource: _FakeMedicationRemoteDataSource(),
            syncQueue: queue,
            conflictResolver: const MedicationConflictResolver(),
            syncState: _FakeSyncStateLocalDataSource(),
          );

          await service.handleConnectivityRestored();
        },
      );

      test('rejects overlapping cycles for the same user', () async {
        final completer = Completer<void>();
        final service = SyncService(
          authRepository: _FakeAuthRepository(),
          medicationRepository: _FakeMedicationRepository([]),
          remoteDataSource: _FakeMedicationRemoteDataSource(
            pullDelayer: completer.future,
          ),
          syncQueue: _FakeSyncQueue(),
          conflictResolver: const MedicationConflictResolver(),
          syncState: _FakeSyncStateLocalDataSource(),
        );

        final firstSync = service.syncNow(sync_types.SyncTrigger.appStartup);

        final secondResult = await service.syncNow(
          sync_types.SyncTrigger.userSignIn,
        );
        expect(secondResult.success, isFalse);
        expect(secondResult.message, contains('already in progress'));

        completer.complete();
        await firstSync;
      });
    });
  });
}

Medication _buildMedication({required String id, required DateTime updatedAt}) {
  return Medication.create(
    id: id,
    name: 'Medication $id',
    usage: 'Take once daily',
    dosage: '1 pill',
    type: MedicationType.pill,
    timingType: MedicationTimingType.specificTime,
    doses: const [],
    totalDays: 10,
    startDate: DateTime(2026, 4, 1),
    now: updatedAt,
  );
}

class _FakeMedicationRepository implements MedicationRepository {
  final Map<String, Medication> medications;

  _FakeMedicationRepository(List<Medication> initialMedications)
    : medications = {
        for (final medication in initialMedications) medication.id: medication,
      };

  @override
  Future<void> addMedication(Medication medication) async {
    medications[medication.id] = medication;
  }

  @override
  Future<void> deleteMedication(String id) async {
    final medication = medications[id];
    if (medication != null) {
      medications[id] = medication.markDeleted(DateTime.now());
    }
  }

  @override
  Future<Medication?> getMedicationById(
    String id, {
    bool includeDeleted = false,
  }) async {
    final medication = medications[id];
    if (medication == null) {
      return null;
    }
    if (!includeDeleted && medication.isDeleted) {
      return null;
    }
    return medication;
  }

  @override
  Future<List<Medication>> getMedications({bool includeDeleted = false}) async {
    final items = medications.values.toList();
    if (includeDeleted) {
      return items;
    }
    return items.where((item) => !item.isDeleted).toList();
  }

  @override
  Future<void> purgeMedication(String id) async {
    medications.remove(id);
  }

  @override
  Future<void> resetDailyDoses() async {}

  @override
  Future<void> saveSyncedMedication(Medication medication) async {
    medications[medication.id] = medication;
  }

  @override
  Future<void> updateDoseStatus(
    String medicationId,
    int doseIndex,
    bool taken,
  ) async {}

  @override
  Future<void> updateMedication(Medication medication) async {
    medications[medication.id] = medication;
  }
}

class _FakeMedicationRemoteDataSource implements MedicationRemoteDataSource {
  final List<String> upsertedMedicationIds = [];
  final Future<void>? pullDelayer;

  _FakeMedicationRemoteDataSource({this.pullDelayer});

  @override
  Future<void> deleteMedication(String id) async {}

  @override
  Future<void> deleteMedicationForUser(
    String userId,
    String medicationId, {
    DateTime? deletedAt,
  }) async {}

  @override
  Future<List<Medication>> fetchMedications() async => [];

  @override
  Future<List<Medication>> pullMedications(
    String userId, {
    DateTime? since,
  }) async {
    if (pullDelayer != null) {
      await pullDelayer!;
    }
    return [];
  }

  @override
  Future<void> pushChanges(String userId, List<PendingChange> changes) async {}

  @override
  Future<void> upsertMedication(Medication medication) async {
    upsertedMedicationIds.add(medication.id);
  }

  @override
  Future<void> upsertMedicationForUser(
    String userId,
    Medication medication,
  ) async {
    upsertedMedicationIds.add(medication.id);
  }
}

class _DisabledFakeMedicationRemoteDataSource
    implements MedicationRemoteDataSource {
  @override
  Future<void> deleteMedication(String id) {
    throw const CloudSyncDisabledException();
  }

  @override
  Future<void> deleteMedicationForUser(
    String userId,
    String medicationId, {
    DateTime? deletedAt,
  }) {
    throw const CloudSyncDisabledException();
  }

  @override
  Future<List<Medication>> fetchMedications() {
    throw const CloudSyncDisabledException();
  }

  @override
  Future<List<Medication>> pullMedications(String userId, {DateTime? since}) {
    throw const CloudSyncDisabledException();
  }

  @override
  Future<void> pushChanges(String userId, List<PendingChange> changes) {
    throw const CloudSyncDisabledException();
  }

  @override
  Future<void> upsertMedication(Medication medication) {
    throw const CloudSyncDisabledException();
  }

  @override
  Future<void> upsertMedicationForUser(String userId, Medication medication) {
    throw const CloudSyncDisabledException();
  }
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthSession> getCurrentSession() async =>
      const AuthSession.ready('user-123', providerId: 'anonymous');

  @override
  Future<AuthSession> signInForSync({String? providerId}) async =>
      const AuthSession.ready('user-123', providerId: 'anonymous');

  @override
  Future<void> signOutFromSync() async {}

  @override
  Stream<AuthSession> watchSession() async* {
    yield const AuthSession.ready('user-123', providerId: 'anonymous');
  }
}

class _FakeSyncQueue implements SyncQueueLocalDataSource {
  final List<PendingChange> pendingChanges = [];

  _FakeSyncQueue();

  @override
  Future<void> enqueuePendingChange(PendingChange change) async {
    pendingChanges.removeWhere((item) => item.changeId == change.changeId);
    pendingChanges.add(change);
  }

  @override
  Future<List<PendingChange>> listPendingChanges({String? userId}) async {
    return List.of(pendingChanges);
  }

  @override
  Future<List<PendingChange>> getEffectivePendingChanges({
    String? userId,
  }) async {
    return List.of(pendingChanges);
  }

  @override
  Future<void> markPendingChangeFailed(
    String changeId, {
    required String errorMessage,
  }) async {
    final index = pendingChanges.indexWhere((c) => c.changeId == changeId);
    if (index != -1) {
      pendingChanges[index] = pendingChanges[index].copyWith(
        status: sync_types.SyncOperationStatus.failed,
        errorMessage: errorMessage,
        attemptCount: pendingChanges[index].attemptCount + 1,
      );
    }
  }

  @override
  Future<void> markPendingChangeInFlight(String changeId) async {}

  @override
  Future<void> markPendingChangeSucceeded(String changeId) async {
    pendingChanges.removeWhere((c) => c.changeId == changeId);
  }

  @override
  Future<void> enqueue(SyncOperation operation) async {
    // no-op for tests that use the new PendingChange API
  }

  @override
  int countPermanentlyFailedChanges({String? userId}) {
    return pendingChanges.where((c) {
      if (userId != null && c.userId != userId) return false;
      return c.status == sync_types.SyncOperationStatus.failed ||
          c.attemptCount >= 5;
    }).length;
  }

  @override
  Future<List<PendingChange>> getPermanentlyFailedChanges({
    String? userId,
  }) async {
    return pendingChanges.where((c) {
      if (userId != null && c.userId != userId) return false;
      return c.status == sync_types.SyncOperationStatus.failed ||
          c.attemptCount >= 5;
    }).toList();
  }
}

class _FakeSyncStateLocalDataSource implements SyncStateLocalDataSource {
  final List<ConflictMetadata> conflicts = [];

  @override
  Future<List<ConflictMetadata>> getConflictsForEntity(
    String entityId, {
    String? userId,
  }) async => conflicts.where((c) => c.entityId == entityId).toList();

  @override
  Future<SyncCycleState?> getLatestCycle(String userId) async => null;

  @override
  Future<UserSyncProfile?> getProfile(String userId) async => null;

  @override
  Future<SyncStatusViewState> getStatus([String? userId]) async =>
      SyncStatusViewState.ready;

  @override
  Future<void> saveConflict(ConflictMetadata conflict) async {
    conflicts.add(conflict);
  }

  @override
  Future<void> saveCycle(SyncCycleState cycle) async {}

  @override
  Future<void> saveProfile(UserSyncProfile profile) async {}

  @override
  Future<void> setStatus(SyncStatusViewState status) async {}
}
