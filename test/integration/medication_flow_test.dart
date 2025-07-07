import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medicinder/domain/entities/medication.dart';
import 'package:medicinder/presentation/pages/home_page.dart';
import 'package:medicinder/presentation/pages/add_medication_page.dart';
import 'package:medicinder/presentation/widgets/medication_card.dart';
import 'package:medicinder/presentation/cubit/medication_cubit.dart';
import 'package:medicinder/domain/usecases/add_medication.dart';
import 'package:medicinder/domain/usecases/get_medications.dart';
import 'package:medicinder/domain/usecases/update_dose_status.dart';
import 'package:medicinder/domain/usecases/delete_medication.dart';
import 'package:medicinder/domain/usecases/reset_daily_doses.dart';
import 'package:medicinder/domain/repositories/medication_repository.dart';
import '../test_config.dart';

// Simple mock repository for testing
class MockRepository implements MedicationRepository {
  @override
  Future<List<Medication>> getMedications() async => <Medication>[];

  @override
  Future<void> addMedication(Medication medication) async {}

  @override
  Future<void> updateMedication(Medication medication) async {}

  @override
  Future<void> deleteMedication(String id) async {}

  @override
  Future<void> updateDoseStatus(
    String medicationId,
    int doseIndex,
    bool taken,
  ) async {}

  @override
  Future<void> resetDailyDoses() async {}
}

void main() {
  group('Medication Flow Integration Tests', () {
    late MedicationCubit medicationCubit;

    setUp(() {
      final mockRepository = MockRepository();

      medicationCubit = MedicationCubit(
        addMedication: AddMedication(mockRepository),
        getMedications: GetMedications(mockRepository),
        updateDoseStatus: UpdateDoseStatus(mockRepository),
        deleteMedication: DeleteMedication(mockRepository),
        resetDailyDoses: ResetDailyDoses(mockRepository),
      );
    });

    tearDown(() {
      medicationCubit.close();
    });

    Widget createTestWidgetWithCubit(Widget child) {
      return MaterialApp(
        home: BlocProvider<MedicationCubit>.value(
          value: medicationCubit,
          child: child,
        ),
      );
    }

    testWidgets('should navigate from home to add medication page', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidgetWithCubit(HomePage(onLocaleChanged: (locale) {})),
      );

      await tester.pumpAndSettle();

      final addButton = find.byIcon(Icons.add);
      expect(addButton, findsOneWidget);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(find.byType(AddMedicationPage), findsOneWidget);
    });

    testWidgets('should display medication card correctly', (
      WidgetTester tester,
    ) async {
      final testMedication = TestConfig.createTestMedication();

      await tester.pumpWidget(
        TestConfig.createTestWidget(
          MedicationCard(
            medication: testMedication,
            onDoseTaken: (index) {},
            onDelete: () {},
            onEdit: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MedicationCard), findsOneWidget);
      expect(find.text('Test Medication'), findsOneWidget);
    });
  });
}

/// Test dependency injection setup
Future<void> setupTestDependencies() async {
  // Initialize test dependencies
  // This would set up mock repositories and services for testing
}

/// Test dependency injection cleanup
Future<void> cleanupTestDependencies() async {
  // Clean up test dependencies
  // This would dispose of any resources used in testing
}
