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

class _MockHistoryDataSource implements MedicationHistoryLocalDataSource {
  List<MedicationHistoryModel> records = [];

  @override
  Future<List<MedicationHistoryModel>> getHistoryRecords() async {
    return records;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Performance Test: getLastTakenMedicines < 50ms', () {
    late _MockHistoryDataSource fakeHistoryDataSource;
    late MedicationRepositoryImpl repository;

    setUp(() {
      fakeHistoryDataSource = _MockHistoryDataSource();
      repository = MedicationRepositoryImpl(
        _FakeMedicationLocalDataSource(),
        _FakeSyncQueueLocalDataSource(),
        _FakeAuthRepository(),
        fakeHistoryDataSource,
      );

      // Seed with 5000 historical records to simulate a typical local DB size
      final now = DateTime.now().toUtc();
      fakeHistoryDataSource.records = List.generate(5000, (index) {
        // distribute within last 48 hours
        final isRecent = index % 3 == 0; // 1/3rd in the last 24h
        final hoursAgo = isRecent ? (index % 24) : 25 + (index % 24);
        return MedicationHistoryModel(
          medicineId: 'med-$index',
          medicineName: 'Medicine $index',
          dose: '1 pill',
          takenAt: now.subtract(Duration(hours: hoursAgo)),
        );
      });
    });

    test('querying local database executes under 50ms', () async {
      final stopwatch = Stopwatch()..start();

      final result = await repository.getLastTakenMedicines();

      stopwatch.stop();
      final elapsedMs = stopwatch.elapsedMilliseconds;

      print(
        'getLastTakenMedicines executed in $elapsedMs ms (returned ${result.length} items)',
      );

      expect(elapsedMs, lessThan(50));
    });
  });
}
