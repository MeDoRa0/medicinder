import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/presentation/pages/home_page.dart';
import 'package:medicinder/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:medicinder/features/medication/presentation/cubit/last_taken_medicines_cubit.dart';
import 'package:medicinder/presentation/cubit/medication_cubit.dart';
import 'package:medicinder/presentation/cubit/medication_state.dart';
import 'package:medicinder/presentation/cubit/sync/sync_status_cubit.dart';
import 'package:medicinder/presentation/cubit/sync/sync_status_state.dart';
import 'package:medicinder/features/medication/presentation/cubit/last_taken_medicines_state.dart';

class MockMedicationCubit extends Mock implements MedicationCubit {}
class MockLastTakenMedicinesCubit extends Mock implements LastTakenMedicinesCubit {}
class MockSyncStatusCubit extends Mock implements SyncStatusCubit {}

void main() {
  late MockMedicationCubit mockMedicationCubit;
  late MockLastTakenMedicinesCubit mockLastTakenMedicinesCubit;
  late MockSyncStatusCubit mockSyncStatusCubit;

  setUp(() async {
    await GetIt.I.reset();
    mockMedicationCubit = MockMedicationCubit();
    mockLastTakenMedicinesCubit = MockLastTakenMedicinesCubit();
    mockSyncStatusCubit = MockSyncStatusCubit();

    when(() => mockMedicationCubit.state).thenReturn(MedicationLoaded(const []));
    when(() => mockMedicationCubit.stream).thenAnswer((_) => Stream.value(MedicationLoaded(const [])));
    when(() => mockMedicationCubit.loadMedications()).thenAnswer((_) async {});
    when(() => mockMedicationCubit.checkDailyResetOnAppOpen()).thenAnswer((_) async {});
    when(() => mockMedicationCubit.cleanupCompletedMedications()).thenAnswer((_) async {});
    
    when(() => mockLastTakenMedicinesCubit.state).thenReturn(const LastTakenMedicinesLoaded(medications: []));
    when(() => mockLastTakenMedicinesCubit.stream).thenAnswer((_) => Stream.value(const LastTakenMedicinesLoaded(medications: [])));
    when(() => mockLastTakenMedicinesCubit.watchRecentMedicines()).thenReturn(null);
    when(() => mockLastTakenMedicinesCubit.close()).thenAnswer((_) async {});
    
    when(() => mockSyncStatusCubit.state).thenReturn(const SyncStatusState.initial());
    when(() => mockSyncStatusCubit.stream).thenAnswer((_) => Stream.value(const SyncStatusState.initial()));

    GetIt.I.registerSingleton<LastTakenMedicinesCubit>(mockLastTakenMedicinesCubit);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  Widget buildTestWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MedicationCubit>.value(value: mockMedicationCubit),
        BlocProvider<SyncStatusCubit>.value(value: mockSyncStatusCubit),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: HomePage(onLocaleChanged: (_) {}),
      ),
    );
  }

  testWidgets('HomePage contains BottomNavigationBar and allows tab switching', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());

    // Should find a BottomNavigationBar
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Initial tab should be My Medications (index 0)
    final bottomNavBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(bottomNavBar.currentIndex, 0);

    // Tap on the History tab
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();

    // The index should now be 1
    final updatedNavBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(updatedNavBar.currentIndex, 1);

    // Clean up to dispose HomePage and cancel timers
    await tester.pumpWidget(Container());
  });
}
