import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:medicinder/domain/entities/medication.dart';
import 'package:medicinder/domain/repositories/medication_repository.dart';
import 'package:medicinder/domain/usecases/get_medications.dart';

import 'get_medications_test.mocks.dart';

@GenerateMocks([MedicationRepository])
void main() {
  late GetMedications useCase;
  late MockMedicationRepository mockRepository;

  setUp(() {
    mockRepository = MockMedicationRepository();
    useCase = GetMedications(mockRepository);
  });

  final testMedications = [
    Medication(
      id: 'test-id-1',
      name: 'Test Medication 1',
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
    ),
    Medication(
      id: 'test-id-2',
      name: 'Test Medication 2',
      usage: 'For testing',
      dosage: '2 tablets',
      type: MedicationType.syrup,
      timingType: MedicationTimingType.contextBased,
      doses: [
        MedicationDose(context: MealContext.afterBreakfast, taken: false),
      ],
      totalDays: 14,
      startDate: DateTime.now(),
    ),
  ];

  group('GetMedications', () {
    test('should return list of medications successfully', () async {
      // Arrange
      when(
        mockRepository.getMedications(),
      ).thenAnswer((_) async => testMedications);

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(testMedications));
      verify(mockRepository.getMedications()).called(1);
    });

    test('should return empty list when no medications exist', () async {
      // Arrange
      when(
        mockRepository.getMedications(),
      ).thenAnswer((_) async => <Medication>[]);

      // Act
      final result = await useCase();

      // Assert
      expect(result, isEmpty);
      verify(mockRepository.getMedications()).called(1);
    });

    test('should throw exception when repository fails', () async {
      // Arrange
      when(
        mockRepository.getMedications(),
      ).thenThrow(Exception('Repository error'));

      // Act & Assert
      expect(() => useCase(), throwsA(isA<Exception>()));
    });

    test('should handle repository returning null gracefully', () async {
      // Arrange
      when(
        mockRepository.getMedications(),
      ).thenAnswer((_) async => null as List<Medication>);

      // Act & Assert
      expect(() => useCase(), throwsA(isA<Exception>()));
    });
  });
}
