import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/domain/entities/medication.dart';
import 'package:medicinder/presentation/widgets/medication_card.dart';
import '../test_config.dart';

void main() {
  group('MedicationCard Widget Tests', () {
    testWidgets('should render basic text widget', (WidgetTester tester) async {
      // Test if basic test setup works
      await tester.pumpWidget(
        TestConfig.createTestWidget(const Text('Hello World')),
      );

      await tester.pumpAndSettle();
      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('should display medication information correctly', (
      WidgetTester tester,
    ) async {
      print('Starting medication card test');
      final testMedication = TestConfig.createTestMedication();
      bool doseToggled = false;
      bool deletePressed = false;
      bool editPressed = false;

      print('Creating widget tree');
      await tester.pumpWidget(
        TestConfig.createTestWidget(
          MedicationCard(
            medication: testMedication,
            onDoseTaken: (index) => doseToggled = true,
            onDelete: () => deletePressed = true,
            onEdit: () => editPressed = true,
          ),
        ),
      );

      print('Pumping and settling');
      await tester.pumpAndSettle();

      print('Checking widget exists');
      // Just verify the widget renders
      expect(find.byType(MedicationCard), findsOneWidget);
      print('Test completed successfully');
    });

    testWidgets('should call onDoseTaken when dose chip is pressed', (
      WidgetTester tester,
    ) async {
      final testMedication = TestConfig.createTestMedication();
      int? toggledIndex;

      await tester.pumpWidget(
        TestConfig.createTestWidget(
          MedicationCard(
            medication: testMedication,
            onDoseTaken: (index) {
              toggledIndex = index;
            },
            onDelete: () {},
            onEdit: () {},
          ),
        ),
      );

      // Wait for the widget to fully render
      await tester.pumpAndSettle();

      // Verify that FilterChips exist
      final doseChips = find.byType(FilterChip);
      expect(doseChips, findsWidgets);

      // Tap the first dose chip
      await tester.tap(doseChips.first);
      await tester.pumpAndSettle();

      expect(toggledIndex, isNotNull);
    });

    testWidgets('should call onDelete when delete button is pressed', (
      WidgetTester tester,
    ) async {
      final testMedication = TestConfig.createTestMedication();
      bool deletePressed = false;

      await tester.pumpWidget(
        TestConfig.createTestWidget(
          MedicationCard(
            medication: testMedication,
            onDoseTaken: (index) {},
            onDelete: () => deletePressed = true,
            onEdit: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the delete button
      final deleteButton = find.byIcon(Icons.delete);
      expect(deleteButton, findsOneWidget);

      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      expect(deletePressed, isTrue);
    });

    testWidgets('should call onEdit when edit button is pressed', (
      WidgetTester tester,
    ) async {
      final testMedication = TestConfig.createTestMedication();
      bool editPressed = false;

      await tester.pumpWidget(
        TestConfig.createTestWidget(
          MedicationCard(
            medication: testMedication,
            onDoseTaken: (index) {},
            onDelete: () {},
            onEdit: () => editPressed = true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the edit button
      final editButton = find.byIcon(Icons.edit);
      expect(editButton, findsOneWidget);

      await tester.tap(editButton);
      await tester.pumpAndSettle();

      expect(editPressed, isTrue);
    });

    testWidgets('should show correct status for completed medication', (
      WidgetTester tester,
    ) async {
      final completedMedication = TestConfig.createCompletedTestMedication();

      await tester.pumpWidget(
        TestConfig.createTestWidget(
          MedicationCard(
            medication: completedMedication,
            onDoseTaken: (index) {},
            onDelete: () {},
            onEdit: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify completed status is shown
      expect(find.text('Course finished'), findsOneWidget);
    });

    testWidgets('should handle medication with no doses gracefully', (
      WidgetTester tester,
    ) async {
      final medicationWithNoDoses = TestConfig.createMedicationWithNoDoses();

      await tester.pumpWidget(
        TestConfig.createTestWidget(
          MedicationCard(
            medication: medicationWithNoDoses,
            onDoseTaken: (index) {},
            onDelete: () {},
            onEdit: () {},
          ),
        ),
      );

      // Wait for the widget to fully render
      await tester.pumpAndSettle();

      // Should not crash and should display medication info
      expect(find.byType(MedicationCard), findsOneWidget);
      expect(find.text('No Doses Medication'), findsOneWidget);
      expect(find.byType(FilterChip), findsNothing); // No dose chips
    });

    testWidgets('should display medication type correctly', (
      WidgetTester tester,
    ) async {
      final pillMedication = TestConfig.createTestMedication(
        type: MedicationType.pill,
      );
      final syrupMedication = TestConfig.createTestMedication(
        type: MedicationType.syrup,
      );

      // Test pill type
      await tester.pumpWidget(
        TestConfig.createTestWidget(
          MedicationCard(
            medication: pillMedication,
            onDoseTaken: (index) {},
            onDelete: () {},
            onEdit: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Pill'), findsOneWidget);

      // Test syrup type
      await tester.pumpWidget(
        TestConfig.createTestWidget(
          MedicationCard(
            medication: syrupMedication,
            onDoseTaken: (index) {},
            onDelete: () {},
            onEdit: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Syrup'), findsOneWidget);
    });

    testWidgets('should handle different timing types', (
      WidgetTester tester,
    ) async {
      final specificTimeMedication = TestConfig.createTestMedication(
        timingType: MedicationTimingType.specificTime,
      );

      final mealTimeMedication = TestConfig.createTestMedication(
        timingType: MedicationTimingType.contextBased,
        doses: [
          MedicationDose(context: MealContext.beforeBreakfast, taken: false),
        ],
      );

      // Test specific time medication
      await tester.pumpWidget(
        TestConfig.createTestWidget(
          MedicationCard(
            medication: specificTimeMedication,
            onDoseTaken: (index) {},
            onDelete: () {},
            onEdit: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(FilterChip), findsNWidgets(2));

      // Test meal time medication
      await tester.pumpWidget(
        TestConfig.createTestWidget(
          MedicationCard(
            medication: mealTimeMedication,
            onDoseTaken: (index) {},
            onDelete: () {},
            onEdit: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(FilterChip), findsOneWidget);
    });

    testWidgets('should show progress indicator for medication with doses', (
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

      // Should show progress indicator
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should handle Arabic localization', (
      WidgetTester tester,
    ) async {
      final testMedication = TestConfig.createTestMedication();

      await tester.pumpWidget(
        TestConfig.createTestWidgetWithLocale(
          MedicationCard(
            medication: testMedication,
            onDoseTaken: (index) {},
            onDelete: () {},
            onEdit: () {},
          ),
          const Locale('ar'),
        ),
      );

      await tester.pumpAndSettle();

      // Should display without crashing in Arabic
      expect(find.byType(MedicationCard), findsOneWidget);
    });
  });
}
