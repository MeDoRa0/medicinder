import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:medicinder/domain/entities/medication.dart';
import 'package:medicinder/domain/usecases/add_medication.dart';
import 'package:medicinder/domain/usecases/get_medications.dart';
import 'package:medicinder/domain/usecases/update_dose_status.dart';
import 'package:medicinder/domain/usecases/delete_medication.dart';
import 'package:medicinder/domain/usecases/reset_daily_doses.dart';
import 'package:medicinder/presentation/cubit/medication_cubit.dart';
import 'package:medicinder/presentation/cubit/medication_state.dart';
import 'package:medicinder/core/error/failures.dart';

import 'medication_cubit_test.mocks.dart';

@GenerateMocks([
  AddMedication,
  GetMedications,
  UpdateDoseStatus,
  DeleteMedication,
  ResetDailyDoses,
])
void main() {
  late MedicationCubit cubit;
  late MockAddMedication mockAddMedication;
  late MockGetMedications mockGetMedications;
  late MockUpdateDoseStatus mockUpdateDoseStatus;
  late MockDeleteMedication mockDeleteMedication;
  late MockResetDailyDoses mockResetDailyDoses;

  setUp(() {
    mockAddMedication = MockAddMedication();
    mockGetMedications = MockGetMedications();
    mockUpdateDoseStatus = MockUpdateDoseStatus();
    mockDeleteMedication = MockDeleteMedication();
    mockResetDailyDoses = MockResetDailyDoses();

    cubit = MedicationCubit(
      addMedication: mockAddMedication,
      getMedications: mockGetMedications,
      updateDoseStatus: mockUpdateDoseStatus,
      deleteMedication: mockDeleteMedication,
      resetDailyDoses: mockResetDailyDoses,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('MedicationCubit', () {
    test('initial state should be MedicationInitial', () {
      expect(cubit.state, isA<MedicationInitial>());
    });

    blocTest<MedicationCubit, MedicationState>(
      'should emit [MedicationLoading, MedicationLoaded] when loadMedications succeeds',
      build: () {
        final testMedications = [
          Medication(
            id: 'test-1',
            name: 'Test Medication',
            usage: 'For testing',
            dosage: '1 tablet',
            type: MedicationType.pill,
            timingType: MedicationTimingType.specificTime,
            doses: [],
            totalDays: 7,
            startDate: DateTime.now(),
          ),
          Medication(
            id: 'test-2',
            name: 'Test Medication 2',
            usage: 'For testing',
            dosage: '1 tablet',
            type: MedicationType.pill,
            timingType: MedicationTimingType.specificTime,
            doses: [],
            totalDays: 7,
            startDate: DateTime.now(),
          ),
        ];
        when(mockGetMedications()).thenAnswer((_) async => testMedications);
        return cubit;
      },
      act: (cubit) => cubit.loadMedications(),
      expect: () => [isA<MedicationLoading>(), isA<MedicationLoaded>()],
      verify: (_) {
        verify(mockGetMedications()).called(1);
      },
    );

    blocTest<MedicationCubit, MedicationState>(
      'should emit [MedicationLoading, MedicationError] when loadMedications fails',
      build: () {
        when(mockGetMedications()).thenThrow(StorageFailure('Database error'));
        return cubit;
      },
      act: (cubit) => cubit.loadMedications(),
      expect: () => [isA<MedicationLoading>(), isA<MedicationError>()],
      verify: (_) {
        verify(mockGetMedications()).called(1);
      },
    );

    blocTest<MedicationCubit, MedicationState>(
      'should emit [MedicationLoading, MedicationLoaded] with empty list when no medications',
      build: () {
        when(mockGetMedications()).thenAnswer((_) async => <Medication>[]);
        return cubit;
      },
      act: (cubit) => cubit.loadMedications(),
      expect: () => [isA<MedicationLoading>(), isA<MedicationLoaded>()],
      verify: (_) {
        verify(mockGetMedications()).called(1);
      },
    );

    blocTest<MedicationCubit, MedicationState>(
      'should emit [MedicationLoading, MedicationLoaded] when addNewMedication succeeds',
      build: () {
        final testMedication = Medication(
          id: 'test-1',
          name: 'Test Medication',
          usage: 'For testing',
          dosage: '1 tablet',
          type: MedicationType.pill,
          timingType: MedicationTimingType.specificTime,
          doses: [],
          totalDays: 7,
          startDate: DateTime.now(),
        );
        when(mockAddMedication(testMedication)).thenAnswer((_) async {});
        when(mockGetMedications()).thenAnswer((_) async => [testMedication]);
        return cubit;
      },
      act: (cubit) => cubit.addNewMedication(
        Medication(
          id: 'test-1',
          name: 'Test Medication',
          usage: 'For testing',
          dosage: '1 tablet',
          type: MedicationType.pill,
          timingType: MedicationTimingType.specificTime,
          doses: [],
          totalDays: 7,
          startDate: DateTime.now(),
        ),
      ),
      expect: () => [isA<MedicationLoading>(), isA<MedicationLoaded>()],
      verify: (_) {
        verify(mockAddMedication(any)).called(1);
        verify(mockGetMedications()).called(1);
      },
    );

    blocTest<MedicationCubit, MedicationState>(
      'should emit [MedicationLoading, MedicationError] when addNewMedication fails',
      build: () {
        when(
          mockAddMedication(any),
        ).thenThrow(StorageFailure('Database error'));
        return cubit;
      },
      act: (cubit) => cubit.addNewMedication(
        Medication(
          id: 'test-1',
          name: 'Test Medication',
          usage: 'For testing',
          dosage: '1 tablet',
          type: MedicationType.pill,
          timingType: MedicationTimingType.specificTime,
          doses: [],
          totalDays: 7,
          startDate: DateTime.now(),
        ),
      ),
      expect: () => [isA<MedicationLoading>(), isA<MedicationError>()],
      verify: (_) {
        verify(mockAddMedication(any)).called(1);
      },
    );

    blocTest<MedicationCubit, MedicationState>(
      'should emit [MedicationLoading, MedicationLoaded] when deleteMedication succeeds',
      build: () {
        const testId = 'test-id';
        when(mockDeleteMedication(testId)).thenAnswer((_) async {});
        when(mockGetMedications()).thenAnswer((_) async => <Medication>[]);
        return cubit;
      },
      act: (cubit) => cubit.deleteMedication('test-id'),
      expect: () => [isA<MedicationLoading>(), isA<MedicationLoaded>()],
      verify: (_) {
        verify(mockDeleteMedication('test-id')).called(1);
        verify(mockGetMedications()).called(1);
      },
    );

    blocTest<MedicationCubit, MedicationState>(
      'should emit [MedicationLoading, MedicationLoaded] when markDoseTaken succeeds',
      build: () {
        const testId = 'test-id';
        const testIndex = 0;
        const testTaken = true;
        when(
          mockUpdateDoseStatus(testId, testIndex, testTaken),
        ).thenAnswer((_) async {});
        when(mockGetMedications()).thenAnswer(
          (_) async => [
            Medication(
              id: 'test-1',
              name: 'Test Medication',
              usage: 'For testing',
              dosage: '1 tablet',
              type: MedicationType.pill,
              timingType: MedicationTimingType.specificTime,
              doses: [],
              totalDays: 7,
              startDate: DateTime.now(),
            ),
          ],
        );
        return cubit;
      },
      act: (cubit) => cubit.markDoseTaken('test-id', 0, true),
      expect: () => [isA<MedicationLoading>(), isA<MedicationLoaded>()],
      verify: (_) {
        verify(mockUpdateDoseStatus('test-id', 0, true)).called(1);
        verify(mockGetMedications()).called(1);
      },
    );

    blocTest<MedicationCubit, MedicationState>(
      'should emit [MedicationLoading, MedicationLoaded] when resetDailyDoses succeeds',
      build: () {
        when(mockResetDailyDoses()).thenAnswer((_) async {});
        when(mockGetMedications()).thenAnswer(
          (_) async => [
            Medication(
              id: 'test-1',
              name: 'Test Medication',
              usage: 'For testing',
              dosage: '1 tablet',
              type: MedicationType.pill,
              timingType: MedicationTimingType.specificTime,
              doses: [],
              totalDays: 7,
              startDate: DateTime.now(),
            ),
          ],
        );
        return cubit;
      },
      act: (cubit) => cubit.checkDailyResetOnAppOpen(),
      expect: () => [isA<MedicationLoading>(), isA<MedicationLoaded>()],
      verify: (_) {
        verify(mockResetDailyDoses()).called(1);
        verify(mockGetMedications()).called(1);
      },
    );
  });
}
