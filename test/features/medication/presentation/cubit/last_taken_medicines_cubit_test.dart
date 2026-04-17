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
    when(
      () => mockMedicationRepository.getLastTakenMedicinesStream(),
    ).thenAnswer((_) => const Stream.empty());

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
      ),
    ];

    final streamController = StreamController<List<MedicationHistory>>();
    when(
      () => mockMedicationRepository.getLastTakenMedicinesStream(),
    ).thenAnswer((_) => streamController.stream);

    final cubit = LastTakenMedicinesCubit(repository: mockMedicationRepository);

    // Create an expectation list
    final expectedStates = [
      const LastTakenMedicinesLoading(),
      LastTakenMedicinesLoaded(medications: testData),
    ];

    // Start listening to cubit state changes
    final stateFutures = expectLater(
      cubit.stream,
      emitsInOrder(expectedStates),
    );

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
    when(
      () => mockMedicationRepository.getLastTakenMedicinesStream(),
    ).thenAnswer((_) => streamController.stream);

    final cubit = LastTakenMedicinesCubit(repository: mockMedicationRepository);

    final expectedStates = [
      const LastTakenMedicinesLoading(),
      isA<LastTakenMedicinesError>().having(
        (e) => e.message,
        'message',
        'Failed to fetch recently taken medications',
      ),
    ];

    final stateFutures = expectLater(
      cubit.stream,
      emitsInOrder(expectedStates),
    );

    cubit.watchRecentMedicines();

    streamController.addError(Exception('Database read error'));

    await stateFutures;

    await streamController.close();
    await cubit.close();
  });

  test('emits [Loading, Loaded(empty)] when stream emits empty list', () async {
    final streamController = StreamController<List<MedicationHistory>>();
    when(
      () => mockMedicationRepository.getLastTakenMedicinesStream(),
    ).thenAnswer((_) => streamController.stream);

    final cubit = LastTakenMedicinesCubit(repository: mockMedicationRepository);

    final stateFutures = expectLater(
      cubit.stream,
      emitsInOrder([
        const LastTakenMedicinesLoading(),
        const LastTakenMedicinesLoaded(medications: []),
      ]),
    );

    cubit.watchRecentMedicines();
    streamController.add(const []);

    await stateFutures;

    await streamController.close();
    await cubit.close();
  });

  test(
    're-calling watchRecentMedicines() cancels previous subscription',
    () async {
      final firstController = StreamController<List<MedicationHistory>>();
      final secondController = StreamController<List<MedicationHistory>>();
      var streamCallCount = 0;
      final ignoredData = [
        MedicationHistory(
          medicineId: 'm1',
          medicineName: 'Ignored',
          dose: '1',
          takenAt: DateTime.utc(2026, 4, 17, 9),
        ),
      ];
      final receivedData = [
        MedicationHistory(
          medicineId: 'm2',
          medicineName: 'Received',
          dose: '1',
          takenAt: DateTime.utc(2026, 4, 17, 10),
        ),
      ];

      when(
        () => mockMedicationRepository.getLastTakenMedicinesStream(),
      ).thenAnswer((_) {
        streamCallCount += 1;
        return streamCallCount == 1
            ? firstController.stream
            : secondController.stream;
      });

      final cubit = LastTakenMedicinesCubit(
        repository: mockMedicationRepository,
      );
      final emittedStates = <LastTakenMedicinesState>[];
      final stateSubscription = cubit.stream.listen(emittedStates.add);

      cubit.watchRecentMedicines();
      expect(firstController.hasListener, isTrue);

      cubit.watchRecentMedicines();
      await Future<void>.delayed(Duration.zero);

      expect(firstController.hasListener, isFalse);
      expect(secondController.hasListener, isTrue);

      firstController.add(ignoredData);
      secondController.add(receivedData);
      await Future<void>.delayed(Duration.zero);

      // Expect exactly one Loading and then Loaded.
      // Note: The second watchRecentMedicines() also emits Loading,
      // but because the state is already Loading and we use Equatable,
      // Cubit deduplicates the emission, so we only see one Loading state here.
      expect(emittedStates, [
        const LastTakenMedicinesLoading(),
        LastTakenMedicinesLoaded(medications: receivedData),
      ]);
      expect(emittedStates.whereType<LastTakenMedicinesLoading>().length, 1);
      expect(
        emittedStates,
        isNot(contains(LastTakenMedicinesLoaded(medications: ignoredData))),
      );

      await stateSubscription.cancel();
      await firstController.close();
      await secondController.close();
      await cubit.close();
    },
  );

  test('close() cancels active stream subscription cleanly', () async {
    final streamController = StreamController<List<MedicationHistory>>();
    when(
      () => mockMedicationRepository.getLastTakenMedicinesStream(),
    ).thenAnswer((_) => streamController.stream);

    final cubit = LastTakenMedicinesCubit(repository: mockMedicationRepository);
    final emittedStates = <LastTakenMedicinesState>[];
    final stateSubscription = cubit.stream.listen(emittedStates.add);

    cubit.watchRecentMedicines();
    expect(streamController.hasListener, isTrue);

    await cubit.close();
    await Future<void>.delayed(Duration.zero);

    expect(streamController.hasListener, isFalse);
    streamController.add([
      MedicationHistory(
        medicineId: 'm1',
        medicineName: 'Aspirin',
        dose: '1',
        takenAt: DateTime.utc(2026, 4, 17, 10),
      ),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(emittedStates, [const LastTakenMedicinesLoading()]);

    await stateSubscription.cancel();
    await streamController.close();
  });

  test('close() during loading state does not emit error', () async {
    final streamController = StreamController<List<MedicationHistory>>();
    when(
      () => mockMedicationRepository.getLastTakenMedicinesStream(),
    ).thenAnswer((_) => streamController.stream);

    final cubit = LastTakenMedicinesCubit(repository: mockMedicationRepository);
    final emittedStates = <LastTakenMedicinesState>[];
    final stateSubscription = cubit.stream.listen(emittedStates.add);

    cubit.watchRecentMedicines();
    await cubit.close();
    await Future<void>.delayed(Duration.zero);

    expect(streamController.hasListener, isFalse);
    streamController.addError(Exception('late stream error'));
    await Future<void>.delayed(Duration.zero);

    expect(emittedStates, [const LastTakenMedicinesLoading()]);
    expect(emittedStates.whereType<LastTakenMedicinesError>(), isEmpty);

    await stateSubscription.cancel();
    await streamController.close();
  });
}
