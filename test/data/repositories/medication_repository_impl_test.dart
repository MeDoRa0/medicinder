import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/data/repositories/medication_repository_impl.dart';
import 'package:medicinder/data/datasources/medication_history_local_data_source.dart';
import 'package:medicinder/data/datasources/medication_local_data_source.dart';
import 'package:medicinder/data/datasources/sync_queue_local_data_source.dart';
import 'package:medicinder/domain/repositories/auth_repository.dart';
import 'package:medicinder/data/models/medication_history_model.dart';

class _FakeMedicationLocalDataSource implements MedicationLocalDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSyncQueueLocalDataSource implements SyncQueueLocalDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHistoryDataSource implements MedicationHistoryLocalDataSource {
  List<MedicationHistoryModel> records = [];

  @override
  Future<List<MedicationHistoryModel>> getHistoryRecords() async {
    return records;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('MedicationRepositoryImpl getLastTakenMedicines', () {
    late _FakeHistoryDataSource fakeHistoryDataSource;
    late MedicationRepositoryImpl repository;

    setUp(() {
      fakeHistoryDataSource = _FakeHistoryDataSource();
      repository = MedicationRepositoryImpl(
        _FakeMedicationLocalDataSource(),
        _FakeSyncQueueLocalDataSource(),
        _FakeAuthRepository(),
        fakeHistoryDataSource,
      );
    });

    test('returns empty list when no records exist', () async {
      final result = await repository.getLastTakenMedicines();
      expect(result, isEmpty);
    });

    test('filters out records older than 24 hours (UTC)', () async {
      final now = DateTime.now().toUtc();
      fakeHistoryDataSource.records = [
        MedicationHistoryModel(
          medicineId: '1',
          medicineName: 'Aspirin',
          dose: '500mg',
          takenAt: now.subtract(const Duration(hours: 2)), // inside 24h
        ),
        MedicationHistoryModel(
          medicineId: '2',
          medicineName: 'Ibuprofen',
          dose: '200mg',
          takenAt: now.subtract(const Duration(hours: 25)), // outside 24h
        ),
      ];

      final result = await repository.getLastTakenMedicines();
      expect(result.length, 1);
      expect(result.first.medicineId, '1');
    });

    test('excludes record at 24 hours and 1 second ago (strict boundary)', () async {
      final now = DateTime.now().toUtc();
      fakeHistoryDataSource.records = [
        MedicationHistoryModel(
          medicineId: '1',
          medicineName: 'Aspirin',
          dose: '500mg',
          takenAt: now.subtract(const Duration(hours: 24, seconds: 1)),
        ),
      ];

      final result = await repository.getLastTakenMedicines();
      expect(result, isEmpty);
    });

    test('includes record at 23 hours 59 minutes ago', () async {
      final now = DateTime.now().toUtc();
      fakeHistoryDataSource.records = [
        MedicationHistoryModel(
          medicineId: '1',
          medicineName: 'Aspirin',
          dose: '500mg',
          takenAt: now.subtract(const Duration(hours: 23, minutes: 59)),
        ),
      ];

      final result = await repository.getLastTakenMedicines();
      expect(result.length, 1);
      expect(result.first.medicineId, '1');
    });

    test('sorts records in descending order (most recent first)', () async {
      final now = DateTime.now().toUtc();
      fakeHistoryDataSource.records = [
        MedicationHistoryModel(
          medicineId: '1',
          medicineName: 'Aspirin',
          dose: '500mg',
          takenAt: now.subtract(const Duration(hours: 4)),
        ),
        MedicationHistoryModel(
          medicineId: '2',
          medicineName: 'Ibuprofen',
          dose: '200mg',
          takenAt: now.subtract(const Duration(hours: 1)), // more recent
        ),
        MedicationHistoryModel(
          medicineId: '3',
          medicineName: 'Tylenol',
          dose: '500mg',
          takenAt: now.subtract(const Duration(hours: 3)),
        ),
      ];

      final result = await repository.getLastTakenMedicines();
      expect(result.length, 3);
      expect(result[0].medicineId, '2'); // 1 hour ago
      expect(result[1].medicineId, '3'); // 3 hours ago
      expect(result[2].medicineId, '1'); // 4 hours ago
    });
  });
}
