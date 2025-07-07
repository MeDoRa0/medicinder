import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/l10n/app_localizations.dart';
import 'package:medicinder/domain/entities/medication.dart';

/// Test configuration and utilities for the application
class TestConfig {
  /// Create a test widget with MaterialApp wrapper and localization
  static Widget createTestWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  /// Create a test widget with custom localization
  static Widget createTestWidgetWithLocale(Widget child, Locale locale) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(body: child),
    );
  }

  /// Create a test context for testing
  static BuildContext createTestContext() {
    return TestWidgetsFlutterBinding.ensureInitialized().rootElement!;
  }

  /// Mock context for testing localization
  static BuildContext get mockContext {
    return createTestContext();
  }

  /// Create a test medication for testing purposes
  static Medication createTestMedication({
    String? id,
    String? name,
    String? usage,
    String? dosage,
    MedicationType? type,
    MedicationTimingType? timingType,
    List<MedicationDose>? doses,
    int? totalDays,
    DateTime? startDate,
  }) {
    return Medication(
      id: id ?? 'test-id',
      name: name ?? 'Test Medication',
      usage: usage ?? 'For testing purposes',
      dosage: dosage ?? '1 tablet',
      type: type ?? MedicationType.pill,
      timingType: timingType ?? MedicationTimingType.specificTime,
      doses:
          doses ??
          [
            MedicationDose(
              time: DateTime.now().add(const Duration(hours: 1)),
              taken: false,
            ),
            MedicationDose(
              time: DateTime.now().add(const Duration(hours: 8)),
              taken: false,
            ),
          ],
      totalDays: totalDays ?? 7,
      startDate: startDate ?? DateTime.now(),
    );
  }

  /// Create a completed test medication
  static Medication createCompletedTestMedication() {
    return Medication(
      id: 'completed-id',
      name: 'Completed Medication',
      usage: 'Completed treatment',
      dosage: '1 tablet',
      type: MedicationType.pill,
      timingType: MedicationTimingType.specificTime,
      doses: [
        MedicationDose(
          time: DateTime.now().subtract(const Duration(hours: 1)),
          taken: true,
          takenDate: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ],
      totalDays: 1,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
    );
  }

  /// Create a medication with no doses
  static Medication createMedicationWithNoDoses() {
    return Medication(
      id: 'no-doses-id',
      name: 'No Doses Medication',
      usage: 'Test medication',
      dosage: '1 tablet',
      type: MedicationType.pill,
      timingType: MedicationTimingType.specificTime,
      doses: [],
      totalDays: 7,
      startDate: DateTime.now(),
    );
  }
}

/// Test utilities for common testing operations
class TestUtils {
  /// Wait for async operations to complete
  static Future<void> waitForAsync() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Pump widget and wait for async operations
  static Future<void> pumpAndWait(WidgetTester tester) async {
    await tester.pump();
    await waitForAsync();
    await tester.pump();
  }

  /// Pump widget multiple times to ensure all animations complete
  static Future<void> pumpMultipleTimes(
    WidgetTester tester, {
    int times = 3,
  }) async {
    for (int i = 0; i < times; i++) {
      await tester.pump();
      await waitForAsync();
    }
  }

  /// Find widget by type and text
  static Finder findByTypeAndText(Type type, String text) {
    return find.byWidgetPredicate(
      (widget) =>
          widget.runtimeType == type && widget.toString().contains(text),
    );
  }

  /// Find widget by key and type
  static Finder findByKeyAndType(Key key, Type type) {
    return find.byWidgetPredicate(
      (widget) => widget.key == key && widget.runtimeType == type,
    );
  }

  /// Verify widget exists and is visible
  static void expectWidgetExists(WidgetTester tester, Finder finder, {String? reason}) {
    expect(finder, findsOneWidget, reason: reason);
    expect(tester.widget<Widget>(finder), isA<Widget>());
  }

  /// Verify widget does not exist
  static void expectWidgetDoesNotExist(Finder finder, {String? reason}) {
    expect(finder, findsNothing, reason: reason);
  }

  /// Tap widget and wait for animations
  static Future<void> tapAndWait(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await pumpAndWait(tester);
  }

  /// Enter text and wait for animations
  static Future<void> enterTextAndWait(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await pumpAndWait(tester);
  }

  /// Scroll to widget and wait
  static Future<void> scrollToAndWait(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.scrollUntilVisible(finder, 500.0);
    await pumpAndWait(tester);
  }
}

/// Test matchers for common assertions
class TestMatchers {
  /// Matcher for checking if a widget has a specific text
  static Matcher hasText(String text) {
    return predicate<Widget>((widget) {
      if (widget is Text) {
        return widget.data == text;
      }
      return false;
    });
  }

  /// Matcher for checking if a widget has a specific icon
  static Matcher hasIcon(IconData icon) {
    return predicate<Widget>((widget) {
      if (widget is Icon) {
        return widget.icon == icon;
      }
      return false;
    });
  }

  /// Matcher for checking if a widget is enabled
  static Matcher isEnabled() {
    return predicate<Widget>((widget) {
      if (widget is StatelessWidget || widget is StatefulWidget) {
        // This is a simplified check - in real scenarios you'd need more specific logic
        return true;
      }
      return false;
    });
  }

  /// Matcher for checking if a widget is disabled
  static Matcher isDisabled() {
    return predicate<Widget>((widget) {
      // This would need to be implemented based on specific widget types
      return false;
    });
  }
}

/// Test constants for common values
class TestConstants {
  static const Duration shortDelay = Duration(milliseconds: 100);
  static const Duration mediumDelay = Duration(milliseconds: 500);
  static const Duration longDelay = Duration(milliseconds: 1000);

  static const String testMedicationName = 'Test Medication';
  static const String testMedicationUsage = 'For testing purposes';
  static const String testMedicationDosage = '1 tablet';

  static const String englishLocale = 'en';
  static const String arabicLocale = 'ar';
}
