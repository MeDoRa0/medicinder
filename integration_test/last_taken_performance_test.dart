import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:medicinder/main.dart' as app;
import 'package:medicinder/presentation/last_taken/pages/last_taken_medicines_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test the rendering performance of the Last Taken page
  testWidgets('Last Taken Medicines Page renders under 1 second', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Tap the History icon on the HomePage AppBar
    final historyIcon = find.byIcon(Icons.history);
    expect(historyIcon, findsOneWidget);

    // Watch the time taken to render the frame
    final stopwatch = Stopwatch()..start();

    await tester.tap(historyIcon);
    await tester.pumpAndSettle();

    stopwatch.stop();

    // Wait until the new page is displayed
    expect(find.byType(LastTakenMedicinesPage), findsOneWidget);

    // Test time should be less than 1 second (1000 milliseconds) for UI rendering
    expect(stopwatch.elapsedMilliseconds, lessThan(1000));
  });
}
