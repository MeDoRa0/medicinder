import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:medicinder/domain/entities/medication.dart';
import 'package:medicinder/domain/repositories/medication_repository.dart';
import 'package:medicinder/domain/usecases/add_medication.dart';

import 'add_medication_test.mocks.dart';

@GenerateMocks([MedicationRepository])
void main() {
  late AddMedication useCase;
  late MockMedicationRepository mockRepository;

  setUp(() {
    mockRepository = MockMedicationRepository();
    useCase = AddMedication(mockRepository);
  });

  final testMedication = Medication(
    id: 'test-id',
    name: 'Test Medication',
    usage: 'For testing',
    dosage: '1 tablet',
    type: MedicationType.pill,
    timingType: MedicationTimingType.specificTime,
    doses: [
      MedicationDose(
        time: DateTime.now().add(const Duration(hours: 1)),
        taken: false,
      ),
    ],
    totalDays: 7,
    startDate: DateTime.now(),
  );

  group('AddMedication', () {
    test('should add medication successfully', () async {
      // Arrange
      when(
        mockRepository.addMedication(testMedication),
      ).thenAnswer((_) async {});

      // Act
      await useCase(testMedication);

      // Assert
      verify(mockRepository.addMedication(testMedication)).called(1);
    });

    test('should throw exception when repository fails', () async {
      // Arrange
      when(
        mockRepository.addMedication(testMedication),
      ).thenThrow(Exception('Repository error'));

      // Act & Assert
      expect(() => useCase(testMedication), throwsA(isA<Exception>()));
    });

    test('should handle null medication gracefully', () async {
      // Act & Assert
      expect(() => useCase(null), throwsA(isA<ArgumentError>()));
    });
  });
}
