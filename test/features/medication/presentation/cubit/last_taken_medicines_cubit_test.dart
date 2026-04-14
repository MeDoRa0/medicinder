import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:medicinder/domain/repositories/medication_repository.dart';
import 'package:medicinder/domain/entities/medication_history.dart';
import 'package:medicinder/features/medication/presentation/cubit/last_taken_medicines_cubit.dart';
import 'package:medicinder/features/medication/presentation/cubit/last_taken_medicines_state.dart';

class MockMedicationRepository extends Mock implements MedicationRepository {}

void main() {
  late MockMedicationRepository mockMedicationRepository;

  setUp(() {
    mockMedicationRepository = MockMedicationRepository();
  });

  test('initial state is LastTakenMedicinesInitial', () {
    when(() => mockMedicationRepository.getLastTakenMedicinesStream())
        .thenAnswer((_) => const Stream.empty());
    
    final cubit = LastTakenMedicinesCubit(repository: mockMedicationRepository);
    expect(cubit.state, const LastTakenMedicinesInitial());
    cubit.close();
  });

  test('emits [Loading, Loaded] when stream emits successful data', () async {
    final testData = <MedicationHistory>[
      MedicationHistory(
        medicineId: 'm1',
        medicineName: 'Aspirin',
        dose: '1',
        takenAt: DateTime.now(),
      )
    ];

    final streamController = StreamController<List<MedicationHistory>>();
    when(() => mockMedicationRepository.getLastTakenMedicinesStream())
        .thenAnswer((_) => streamController.stream);

    final cubit = LastTakenMedicinesCubit(repository: mockMedicationRepository);
    
    // Create an expectation list
    final expectedStates = [
      const LastTakenMedicinesLoading(),
      LastTakenMedicinesLoaded(medications: testData),
    ];
    
    // Start listening to cubit state changes
    final stateFutures = expectLater(cubit.stream, emitsInOrder(expectedStates));
    
    // Trigger the subscription
    cubit.watchRecentMedicines();
    
    // Push data
    streamController.add(testData);
    
    await stateFutures;
    
    await streamController.close();
    await cubit.close();
  });

  test('emits [Loading, Error] when stream throws an error', () async {
    final streamController = StreamController<List<MedicationHistory>>();
    when(() => mockMedicationRepository.getLastTakenMedicinesStream())
        .thenAnswer((_) => streamController.stream);

    final cubit = LastTakenMedicinesCubit(repository: mockMedicationRepository);
    
    final expectedStates = [
      const LastTakenMedicinesLoading(),
      const LastTakenMedicinesError(message: 'Failed to fetch recently taken medications'),
    ];
    
    final stateFutures = expectLater(cubit.stream, emitsInOrder(expectedStates));
    
    cubit.watchRecentMedicines();
    
    streamController.addError(Exception('Database read error'));
    
    await stateFutures;
    
    await streamController.close();
    await cubit.close();
  });
}
