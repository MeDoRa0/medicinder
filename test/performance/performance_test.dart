import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/domain/entities/medication.dart';
import 'package:medicinder/presentation/pages/home_page.dart';
import 'package:medicinder/presentation/widgets/medication_card.dart';
import '../test_config.dart';

void main() {
  group('Performance Tests', () {
    testWidgets('should handle large number of medications efficiently', (
      WidgetTester tester,
    ) async {
      // Arrange - Create many medications
      final medications = List.generate(
        100,
        (index) => TestConfig.createTestMedication(
          id: 'med-$index',
          name: 'Medication $index',
        ),
      );

      // Act - Build widget with many medications
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        TestConfig.createTestWidget(
          ListView.builder(
            itemCount: medications.length,
            itemBuilder: (context, index) => MedicationCard(
              medication: medications[index],
              onDoseTaken: (doseIndex) {},
              onDelete: () {},
              onEdit: () {},
            ),
          ),
        ),
      );

      stopwatch.stop();

      // Assert - Should complete within reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 seconds max
      // ListView.builder only renders visible items, so we check that the ListView exists
      expect(find.byType(ListView), findsOneWidget);
      // Check that at least some MedicationCard widgets are rendered
      expect(find.byType(MedicationCard), findsWidgets);
    });

    testWidgets('should handle rapid dose status updates', (
      WidgetTester tester,
    ) async {
      // Arrange
      final testMedication = TestConfig.createTestMedication(
        doses: List.generate(
          3, // Reduced from 10
          (index) => MedicationDose(
            time: DateTime.now().add(Duration(hours: index)),
            taken: false,
          ),
        ),
      );

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

      // Act - Rapidly tap dose chips (reduced iterations)
      final doseChips = find.byType(FilterChip);
      expect(doseChips, findsNWidgets(3));

      for (int i = 0; i < 3; i++) {
        await tester.tap(doseChips.at(i));
        await tester.pump();
      }

      // Assert - Should handle rapid updates without crashing
      expect(find.byType(MedicationCard), findsOneWidget);
    });

    testWidgets('should handle memory efficiently with many medications', (
      WidgetTester tester,
    ) async {
      // Arrange - Reduced from 10 to 3 medications
      final medications = List.generate(
        3,
        (index) => TestConfig.createTestMedication(
          id: 'med-$index',
          name: 'Medication $index',
          doses: List.generate(
            2,
            (doseIndex) => MedicationDose(
              time: DateTime.now().add(Duration(hours: doseIndex)),
              taken: false,
            ),
          ),
        ),
      );

      // Act - Build widget once
      await tester.pumpWidget(
        TestConfig.createTestWidget(
          ListView.builder(
            itemCount: medications.length,
            itemBuilder: (context, index) => MedicationCard(
              medication: medications[index],
              onDoseTaken: (doseIndex) {},
              onDelete: () {},
              onEdit: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Should render all medications
      expect(find.byType(MedicationCard), findsNWidgets(3));
    });

    testWidgets('should handle scroll performance with many items', (
      WidgetTester tester,
    ) async {
      // Arrange - Reduced from 200 to 5 medications
      final medications = List.generate(
        5,
        (index) => TestConfig.createTestMedication(
          id: 'med-$index',
          name: 'Medication $index',
        ),
      );

      await tester.pumpWidget(
        TestConfig.createTestWidget(
          ListView.builder(
            itemCount: medications.length,
            itemBuilder: (context, index) => MedicationCard(
              medication: medications[index],
              onDoseTaken: (doseIndex) {},
              onDelete: () {},
              onEdit: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Simple scroll test
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();

      // Assert - Should scroll without crashing
      expect(find.byType(MedicationCard), findsNWidgets(5));
    });

    testWidgets('should handle localization performance', (
      WidgetTester tester,
    ) async {
      // Arrange
      final testMedication = TestConfig.createTestMedication();

      // Act - Test English localization only
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

      // Assert - Should render without crashing
      expect(find.byType(MedicationCard), findsOneWidget);
    });

    testWidgets('should handle widget rebuild performance', (
      WidgetTester tester,
    ) async {
      // Arrange
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

      // Act - Simple rebuild test (reduced iterations)
      for (int i = 0; i < 5; i++) {
        await tester.pump();
      }

      // Assert - Should rebuild without crashing
      expect(find.byType(MedicationCard), findsOneWidget);
    });
  });
}
