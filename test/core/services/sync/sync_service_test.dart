import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/core/services/sync/conflict_resolver.dart';
import 'package:medicinder/core/services/sync/sync_service.dart';
import 'package:medicinder/data/datasources/medication_remote_data_source.dart';
import 'package:medicinder/data/datasources/sync_queue_local_data_source.dart';
import 'package:medicinder/domain/entities/medication.dart';
import 'package:medicinder/domain/entities/sync/auth_session.dart';
import 'package:medicinder/domain/entities/sync/pending_change.dart';
import 'package:medicinder/domain/entities/sync_metadata.dart';
import 'package:medicinder/domain/entities/sync_operation.dart';
import 'package:medicinder/domain/repositories/auth_repository.dart';
import 'package:medicinder/domain/repositories/medication_repository.dart';

void main() {
  group('SyncService', () {
    test('processes queued create operations and marks medication as synced', () async {
      final medication = _buildMedication(
        id: 'med-1',
        updatedAt: DateTime(2026, 4, 1, 8),
      );
      final repository = _FakeMedicationRepository([medication]);
      final queue = _FakeSyncQueue([
        SyncOperation(
          id: 'op-1',
          entityType: SyncEntityType.medication,
          entityId: medication.id,
          type: SyncOperationType.create,
          createdAt: DateTime(2026, 4, 1, 8),
        ),
      ]);
      final remote = _FakeMedicationRemoteDataSource();
      final service = SyncService(
        authRepository: _FakeAuthRepository(),
        medicationRepository: repository,
        remoteDataSource: remote,
        syncQueue: queue,
        conflictResolver: const MedicationConflictResolver(),
      );

      final result = await service.synchronize();

      expect(result.success, isTrue);
      expect(result.processedOperations, 1);
      expect(queue.operations, isEmpty);
      expect(remote.upsertedMedicationIds, [medication.id]);
      expect(
        repository.medications[medication.id]?.syncMetadata.status,
        SyncStatus.synced,
      );
    });

    test('keeps queued operations when remote sync is disabled', () async {
      final medication = _buildMedication(
        id: 'med-2',
        updatedAt: DateTime(2026, 4, 1, 8),
      );
      final repository = _FakeMedicationRepository([medication]);
      final queue = _FakeSyncQueue([
        SyncOperation(
          id: 'op-2',
          entityType: SyncEntityType.medication,
          entityId: medication.id,
          type: SyncOperationType.create,
          createdAt: DateTime(2026, 4, 1, 8),
        ),
      ]);
      final remote = _DisabledFakeMedicationRemoteDataSource();
      final service = SyncService(
        authRepository: _FakeAuthRepository(),
        medicationRepository: repository,
        remoteDataSource: remote,
        syncQueue: queue,
        conflictResolver: const MedicationConflictResolver(),
      );

      final result = await service.synchronize();

      expect(result.success, isFalse);
      expect(queue.operations.single.attemptCount, 1);
      expect(queue.operations.single.errorMessage, contains('Cloud sync backend'));
    });
  });
}

Medication _buildMedication({
  required String id,
  required DateTime updatedAt,
}) {
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
  Future<void> updateDoseStatus(String medicationId, int doseIndex, bool taken) async {}

  @override
  Future<void> updateMedication(Medication medication) async {
    medications[medication.id] = medication;
  }
}

class _FakeMedicationRemoteDataSource implements MedicationRemoteDataSource {
  final List<String> upsertedMedicationIds = [];

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
  Future<List<Medication>> pullMedications(String userId, {DateTime? since}) async =>
      [];

  @override
  Future<void> pushChanges(String userId, List<PendingChange> changes) async {}

  @override
  Future<void> upsertMedication(Medication medication) async {
    upsertedMedicationIds.add(medication.id);
  }

  @override
  Future<void> upsertMedicationForUser(String userId, Medication medication) async {
    upsertedMedicationIds.add(medication.id);
  }
}

class _DisabledFakeMedicationRemoteDataSource implements MedicationRemoteDataSource {
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
      const AuthSession.signedIn('user-123');

  @override
  Future<AuthSession> signInForSync() async =>
      const AuthSession.signedIn('user-123');

  @override
  Future<void> signOutFromSync() async {}

  @override
  Stream<AuthSession> watchSession() async* {
    yield const AuthSession.signedIn('user-123');
  }
}

class _FakeSyncQueue implements SyncQueueLocalDataSource {
  final List<SyncOperation> operations;
  final List<PendingChange> pendingChanges = [];

  _FakeSyncQueue(this.operations);

  @override
  Future<void> enqueue(SyncOperation operation) async {
    operations.removeWhere((item) => item.id == operation.id);
    operations.add(operation);
  }

  @override
  Future<List<SyncOperation>> getPendingOperations() async => List.of(operations);

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
  Future<void> markPendingChangeFailed(
    String changeId, {
    required String errorMessage,
  }) async {}

  @override
  Future<void> markPendingChangeInFlight(String changeId) async {}

  @override
  Future<void> markPendingChangeSucceeded(String changeId) async {}

  @override
  Future<void> remove(String operationId) async {
    operations.removeWhere((item) => item.id == operationId);
  }

  @override
  Future<void> replace(SyncOperation operation) async {
    final index = operations.indexWhere((item) => item.id == operation.id);
    if (index == -1) {
      operations.add(operation);
      return;
    }
    operations[index] = operation;
  }
}
