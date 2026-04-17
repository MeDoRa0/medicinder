import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:medicinder/domain/entities/sync/sync_status_view_state.dart';
import 'package:medicinder/features/medication/presentation/cubit/last_taken_medicines_cubit.dart';
import 'package:medicinder/features/medication/presentation/cubit/last_taken_medicines_state.dart';
import 'package:medicinder/l10n/app_localizations.dart';
import 'package:medicinder/presentation/cubit/medication_cubit.dart';
import 'package:medicinder/presentation/cubit/medication_state.dart';
import 'package:medicinder/presentation/cubit/sync/sync_status_cubit.dart';
import 'package:medicinder/presentation/cubit/sync/sync_status_state.dart';
import 'package:medicinder/presentation/last_taken/pages/last_taken_medicines_page.dart';
import 'package:medicinder/presentation/pages/home_page.dart';

class MockMedicationCubit extends Mock implements MedicationCubit {}

class MockLastTakenMedicinesCubit extends Mock
    implements LastTakenMedicinesCubit {}

class MockSyncStatusCubit extends Mock implements SyncStatusCubit {}

void main() {
  late MockMedicationCubit medicationCubit;
  late MockLastTakenMedicinesCubit lastTakenCubit;
  late MockSyncStatusCubit syncStatusCubit;

  setUp(() async {
    await GetIt.I.reset();
    medicationCubit = MockMedicationCubit();
    lastTakenCubit = MockLastTakenMedicinesCubit();
    syncStatusCubit = MockSyncStatusCubit();

    when(() => medicationCubit.state).thenReturn(MedicationLoaded(const []));
    when(
      () => medicationCubit.stream,
    ).thenAnswer((_) => const Stream<MedicationState>.empty());

    when(
      () => lastTakenCubit.state,
    ).thenReturn(const LastTakenMedicinesLoading());
    when(
      () => lastTakenCubit.stream,
    ).thenAnswer((_) => const Stream<LastTakenMedicinesState>.empty());
    when(() => lastTakenCubit.watchRecentMedicines()).thenReturn(null);
    when(() => lastTakenCubit.close()).thenAnswer((_) async {});

    when(() => syncStatusCubit.state).thenReturn(
      const SyncStatusState(viewState: SyncStatusViewState.signedOut),
    );
    when(
      () => syncStatusCubit.stream,
    ).thenAnswer((_) => const Stream<SyncStatusState>.empty());

    GetIt.I.registerFactory<LastTakenMedicinesCubit>(() => lastTakenCubit);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<MedicationCubit>.value(value: medicationCubit),
          BlocProvider<SyncStatusCubit>.value(value: syncStatusCubit),
        ],
        child: HomePage(onLocaleChanged: (_) {}),
      ),
    );
  }

  testWidgets('tapping history icon navigates to LastTakenMedicinesPage', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.byIcon(Icons.history));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(LastTakenMedicinesPage), findsOneWidget);
    verify(() => lastTakenCubit.watchRecentMedicines()).called(1);

    // Navigate back
    Navigator.of(tester.element(find.byType(LastTakenMedicinesPage))).pop();
    await tester.pumpAndSettle();
    
    // Verify Cubit is closed
    verify(() => lastTakenCubit.close()).called(1);
  });
}
