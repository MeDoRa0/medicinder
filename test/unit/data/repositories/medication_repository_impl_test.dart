import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:medicinder/data/datasources/medication_local_data_source.dart';
import 'package:medicinder/data/repositories/medication_repository_impl.dart';
import 'package:medicinder/domain/entities/medication.dart';
import 'package:medicinder/core/error/failures.dart';
import '../../../test_config.dart';

import 'medication_repository_impl_test.mocks.dart';

@GenerateMocks([MedicationLocalDataSource])
void main() {
  late MedicationRepositoryImpl repository;
  late MockMedicationLocalDataSource mockLocalDataSource;

  setUp(() {
    mockLocalDataSource = MockMedicationLocalDataSource();
    repository = MedicationRepositoryImpl(mockLocalDataSource);
  });

  group('getMedications', () {
    test(
      'should return list of medications when local data source succeeds',
      () async {
        // Arrange
        final testMedications = [
          TestConfig.createTestMedication(),
          TestConfig.createTestMedication(
            id: 'test-2',
            name: 'Test Medication 2',
          ),
        ];

        when(
          mockLocalDataSource.getAllMedications(),
        ).thenAnswer((_) async => testMedications);

        // Act
        final result = await repository.getMedications();

        // Assert
        expect(result, isA<List<Medication>>());
        expect(result.length, equals(2));
        expect(result.first.name, equals('Test Medication'));
        expect(result.last.name, equals('Test Medication 2'));
        verify(mockLocalDataSource.getAllMedications()).called(1);
      },
    );

    test(
      'should return empty list when local data source returns empty list',
      () async {
        // Arrange
        when(
          mockLocalDataSource.getAllMedications(),
        ).thenAnswer((_) async => <Medication>[]);

        // Act
        final result = await repository.getMedications();

        // Assert
        expect(result, isA<List<Medication>>());
        expect(result, isEmpty);
        verify(mockLocalDataSource.getAllMedications()).called(1);
      },
    );

    test(
      'should throw StorageFailure when local data source throws exception',
      () async {
        // Arrange
        when(
          mockLocalDataSource.getAllMedications(),
        ).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.getMedications(),
          throwsA(isA<StorageFailure>()),
        );
        verify(mockLocalDataSource.getAllMedications()).called(1);
      },
    );
  });

  group('addMedication', () {
    test(
      'should add medication successfully when local data source succeeds',
      () async {
        // Arrange
        final testMedication = TestConfig.createTestMedication();

        when(
          mockLocalDataSource.addMedication(testMedication),
        ).thenAnswer((_) async {});

        // Act
        await repository.addMedication(testMedication);

        // Assert
        verify(mockLocalDataSource.addMedication(testMedication)).called(1);
      },
    );

    test(
      'should throw StorageFailure when local data source throws exception',
      () async {
        // Arrange
        final testMedication = TestConfig.createTestMedication();

        when(
          mockLocalDataSource.addMedication(testMedication),
        ).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.addMedication(testMedication),
          throwsA(isA<StorageFailure>()),
        );
        verify(mockLocalDataSource.addMedication(testMedication)).called(1);
      },
    );
  });

  group('updateMedication', () {
    test(
      'should update medication successfully when local data source succeeds',
      () async {
        // Arrange
        final testMedication = TestConfig.createTestMedication();

        when(
          mockLocalDataSource.updateMedication(testMedication),
        ).thenAnswer((_) async {});

        // Act
        await repository.updateMedication(testMedication);

        // Assert
        verify(mockLocalDataSource.updateMedication(testMedication)).called(1);
      },
    );

    test(
      'should throw StorageFailure when local data source throws exception',
      () async {
        // Arrange
        final testMedication = TestConfig.createTestMedication();

        when(
          mockLocalDataSource.updateMedication(testMedication),
        ).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.updateMedication(testMedication),
          throwsA(isA<StorageFailure>()),
        );
        verify(mockLocalDataSource.updateMedication(testMedication)).called(1);
      },
    );
  });

  group('deleteMedication', () {
    test(
      'should delete medication successfully when local data source succeeds',
      () async {
        // Arrange
        const testId = 'test-id';

        when(
          mockLocalDataSource.deleteMedication(testId),
        ).thenAnswer((_) async {});

        // Act
        await repository.deleteMedication(testId);

        // Assert
        verify(mockLocalDataSource.deleteMedication(testId)).called(1);
      },
    );

    test(
      'should throw StorageFailure when local data source throws exception',
      () async {
        // Arrange
        const testId = 'test-id';

        when(
          mockLocalDataSource.deleteMedication(testId),
        ).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.deleteMedication(testId),
          throwsA(isA<StorageFailure>()),
        );
        verify(mockLocalDataSource.deleteMedication(testId)).called(1);
      },
    );
  });

  group('resetDailyDoses', () {
    test(
      'should reset daily doses successfully when local data source succeeds',
      () async {
        // Arrange
        when(mockLocalDataSource.resetDailyDoses()).thenAnswer((_) async {});

        // Act
        await repository.resetDailyDoses();

        // Assert
        verify(mockLocalDataSource.resetDailyDoses()).called(1);
      },
    );

    test(
      'should throw StorageFailure when local data source throws exception',
      () async {
        // Arrange
        when(
          mockLocalDataSource.resetDailyDoses(),
        ).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.resetDailyDoses(),
          throwsA(isA<StorageFailure>()),
        );
        verify(mockLocalDataSource.resetDailyDoses()).called(1);
      },
    );
  });
}
