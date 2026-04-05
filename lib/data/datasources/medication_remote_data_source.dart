import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/medication.dart';
import '../../domain/entities/sync/pending_change.dart';
import '../../domain/entities/sync/sync_types.dart';
import '../../domain/entities/sync_metadata.dart';

abstract class MedicationRemoteDataSource {
  Future<List<Medication>> pullMedications(String userId, {DateTime? since});
  Future<void> pushChanges(String userId, List<PendingChange> changes);
  Future<void> upsertMedicationForUser(String userId, Medication medication);
  Future<void> deleteMedicationForUser(
    String userId,
    String medicationId, {
    DateTime? deletedAt,
  });

  Future<List<Medication>> fetchMedications();
  Future<void> upsertMedication(Medication medication);
  Future<void> deleteMedication(String id);
}

class CloudSyncDisabledException implements Exception {
  final String message;

  const CloudSyncDisabledException([
    this.message = 'Cloud sync backend is not configured.',
  ]);

  @override
  String toString() => message;
}

class DisabledMedicationRemoteDataSource implements MedicationRemoteDataSource {
  const DisabledMedicationRemoteDataSource();

  @override
  Future<void> deleteMedicationForUser(
    String userId,
    String medicationId, {
    DateTime? deletedAt,
  }) {
    throw const CloudSyncDisabledException();
  }

  @override
  Future<void> deleteMedication(String id) {
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

class FirestoreMedicationRemoteDataSource
    implements MedicationRemoteDataSource {
  final FirebaseFirestore Function() _firestoreProvider;

  FirestoreMedicationRemoteDataSource(this._firestoreProvider);

  CollectionReference<Map<String, dynamic>> _medicationsCollection(
    String userId,
  ) {
    return _firestoreProvider()
        .collection('users')
        .doc(userId)
        .collection('medications');
  }

  @override
  Future<void> deleteMedication(String id) {
    throw const CloudSyncDisabledException(
      'User-scoped remote deletes require an authenticated user.',
    );
  }

  @override
  Future<void> deleteMedicationForUser(
    String userId,
    String medicationId, {
    DateTime? deletedAt,
  }) async {
    await _medicationsCollection(userId).doc(medicationId).set({
      'deletedAt': (deletedAt ?? DateTime.now()).toIso8601String(),
      'updatedAt': (deletedAt ?? DateTime.now()).toIso8601String(),
      'syncStatus': SyncStatus.pendingDelete.name,
      'userId': userId,
    }, SetOptions(merge: true));
  }

  @override
  Future<List<Medication>> fetchMedications() {
    throw const CloudSyncDisabledException(
      'User-scoped remote fetches require an authenticated user.',
    );
  }

  @override
  Future<List<Medication>> pullMedications(
    String userId, {
    DateTime? since,
  }) async {
    Query<Map<String, dynamic>> query = _medicationsCollection(userId);
    if (since != null) {
      query = query.where('updatedAt', isGreaterThan: since.toIso8601String());
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => _medicationFromRemoteMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<void> pushChanges(String userId, List<PendingChange> changes) async {
    for (final change in changes) {
      if (change.entityType != SyncEntityType.medication) {
        continue;
      }
      if (change.operation == SyncOperationType.delete) {
        await deleteMedicationForUser(
          userId,
          change.entityId,
          deletedAt: change.sourceUpdatedAt,
        );
        continue;
      }
      final payload = change.payload;
      if (payload == null) {
        continue;
      }
      await _medicationsCollection(userId).doc(change.entityId).set({
        ...payload,
        'userId': userId,
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<void> upsertMedication(Medication medication) {
    if (medication.userId == null) {
      throw const CloudSyncDisabledException(
        'Medication is missing a userId for cloud sync.',
      );
    }
    return upsertMedicationForUser(medication.userId!, medication);
  }

  @override
  Future<void> upsertMedicationForUser(
    String userId,
    Medication medication,
  ) async {
    await _medicationsCollection(userId)
        .doc(medication.id)
        .set(
          _medicationToRemoteMap(medication.copyWith(userId: userId)),
          SetOptions(merge: true),
        );
  }

  Medication _medicationFromRemoteMap(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final metadata = Map<String, dynamic>.from(
      data['syncMetadata'] as Map<String, dynamic>? ??
          <String, dynamic>{
            'createdAt':
                data['createdAt'] as String? ??
                DateTime.now().toIso8601String(),
            'updatedAt':
                data['updatedAt'] as String? ??
                DateTime.now().toIso8601String(),
            'lastSyncedAt': data['lastSyncedAt'] as String?,
            'deletedAt': data['deletedAt'] as String?,
            'status': data['syncStatus'] as String? ?? SyncStatus.synced.name,
            'syncVersion': data['syncVersion'] as int? ?? 1,
          },
    );
    return Medication(
      id: documentId,
      userId: data['userId'] as String?,
      name: data['name'] as String? ?? '',
      usage: data['usage'] as String? ?? '',
      dosage: data['dosage'] as String? ?? '',
      type: MedicationType.values.byName(
        data['type'] as String? ?? MedicationType.pill.name,
      ),
      timingType: MedicationTimingType.values.byName(
        data['timingType'] as String? ?? MedicationTimingType.specificTime.name,
      ),
      doses: (data['doses'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                _doseFromRemoteMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false),
      totalDays: data['totalDays'] as int? ?? 0,
      startDate:
          DateTime.tryParse(data['startDate'] as String? ?? '') ??
          DateTime.now(),
      repeatForever: data['repeatForever'] as bool? ?? false,
      isDeleted: (data['deletedAt'] as String?) != null,
      deletedAt: (data['deletedAt'] as String?) != null
          ? DateTime.tryParse(data['deletedAt'] as String)
          : null,
      syncMetadata: SyncMetadata.fromJson(metadata),
    );
  }

  Map<String, dynamic> _medicationToRemoteMap(Medication medication) {
    return {
      'userId': medication.userId,
      'name': medication.name,
      'usage': medication.usage,
      'dosage': medication.dosage,
      'type': medication.type.name,
      'timingType': medication.timingType.name,
      'doses': medication.doses.map(_doseToRemoteMap).toList(growable: false),
      'totalDays': medication.totalDays,
      'startDate': medication.startDate.toIso8601String(),
      'repeatForever': medication.repeatForever,
      'deletedAt': medication.deletedAt?.toIso8601String(),
      'createdAt': medication.syncMetadata.createdAt.toIso8601String(),
      'updatedAt': medication.syncMetadata.updatedAt.toIso8601String(),
      'lastSyncedAt': medication.syncMetadata.lastSyncedAt?.toIso8601String(),
      'syncStatus': medication.syncMetadata.status.name,
      'syncVersion': medication.syncMetadata.syncVersion,
      'syncMetadata': medication.syncMetadata.toJson(),
    };
  }

  MedicationDose _doseFromRemoteMap(Map<String, dynamic> data) {
    return MedicationDose(
      time: data['time'] == null
          ? null
          : DateTime.tryParse(data['time'] as String),
      context: data['context'] == null
          ? null
          : MealContext.values.byName(data['context'] as String),
      offsetMinutes: data['offsetMinutes'] as int?,
      taken: data['taken'] as bool? ?? false,
      takenDate: data['takenDate'] == null
          ? null
          : DateTime.tryParse(data['takenDate'] as String),
    );
  }

  Map<String, dynamic> _doseToRemoteMap(MedicationDose dose) {
    return {
      'time': dose.time?.toIso8601String(),
      'context': dose.context?.name,
      'offsetMinutes': dose.offsetMinutes,
      'taken': dose.taken,
      'takenDate': dose.takenDate?.toIso8601String(),
    };
  }
}
