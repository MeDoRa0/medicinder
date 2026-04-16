import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:medicinder/domain/entities/medication_history.dart';
import 'package:medicinder/l10n/app_localizations.dart';
import 'package:medicinder/presentation/last_taken/pages/last_taken_medicines_page.dart';
import 'package:medicinder/presentation/last_taken/widgets/last_taken_medicines_list.dart';
import 'package:medicinder/presentation/last_taken/widgets/empty_state_widget.dart';
import 'package:medicinder/features/medication/presentation/cubit/last_taken_medicines_cubit.dart';
import 'package:medicinder/features/medication/presentation/cubit/last_taken_medicines_state.dart';

class MockLastTakenMedicinesCubit extends Mock implements LastTakenMedicinesCubit {}

void main() {
  late MockLastTakenMedicinesCubit mockCubit;

  setUp(() {
    mockCubit = MockLastTakenMedicinesCubit();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: BlocProvider<LastTakenMedicinesCubit>.value(
        value: mockCubit,
        child: const LastTakenMedicinesPage(),
      ),
    );
  }

  testWidgets('LastTakenMedicinesPage displays CircularProgressIndicator on Loading', (WidgetTester tester) async {
    when(() => mockCubit.state).thenReturn(const LastTakenMedicinesLoading());
    when(() => mockCubit.stream).thenAnswer((_) => Stream.value(const LastTakenMedicinesLoading()));
    when(() => mockCubit.watchRecentMedicines()).thenReturn(null);

    await tester.pumpWidget(buildTestWidget());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('LastTakenMedicinesPage displays error message on Error', (WidgetTester tester) async {
    const errorMsg = 'Failed to load';
    when(() => mockCubit.state).thenReturn(const LastTakenMedicinesError(message: errorMsg));
    when(() => mockCubit.stream).thenAnswer((_) => Stream.value(const LastTakenMedicinesError(message: errorMsg)));
    when(() => mockCubit.watchRecentMedicines()).thenReturn(null);

    await tester.pumpWidget(buildTestWidget());
    expect(find.text(errorMsg), findsOneWidget);
  });

  testWidgets('LastTakenMedicinesPage displays LastTakenMedicinesList on Loaded', (WidgetTester tester) async {
    final list = [
      MedicationHistory(
        medicineId: '1',
        medicineName: 'Panadol',
        dose: '2 Pills',
        takenAt: DateTime.now().subtract(const Duration(minutes: 5)),
      )
    ];
    when(() => mockCubit.state).thenReturn(LastTakenMedicinesLoaded(medications: list));
    when(() => mockCubit.stream).thenAnswer((_) => Stream.value(LastTakenMedicinesLoaded(medications: list)));
    when(() => mockCubit.watchRecentMedicines()).thenReturn(null);

    await tester.pumpWidget(buildTestWidget());
    expect(find.byType(LastTakenMedicinesList), findsOneWidget);
  });

  testWidgets('LastTakenMedicinesPage displays EmptyStateWidget when list is empty', (WidgetTester tester) async {
    when(() => mockCubit.state).thenReturn(const LastTakenMedicinesLoaded(medications: []));
    when(() => mockCubit.stream).thenAnswer((_) => Stream.value(const LastTakenMedicinesLoaded(medications: [])));
    when(() => mockCubit.watchRecentMedicines()).thenReturn(null);

    await tester.pumpWidget(buildTestWidget());
    expect(find.byType(EmptyStateWidget), findsOneWidget);
  });
}
