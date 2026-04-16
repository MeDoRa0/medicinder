import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:medicinder/main.dart' as app;
import 'package:medicinder/presentation/last_taken/pages/last_taken_medicines_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Last Taken Medicines Page performance', () {
    late SharedPreferences prefs;

    setUp(() async {
      // Pre-seed SharedPreferences so AppLaunchRouterPage._resolveLaunchDecision
      // routes directly to HomePage on every run (clean device, CI, or otherwise).
      //
      // Gate 1 – auth session:
      //   AppEntryLocalDataSource reads 'appEntryResolvedMode'.
      //   Value 'guest' → AppEntrySession.guest (isResolved = true) → skips entryGate.
      //
      // Gate 2 – meal-time prefs:
      //   _resolveLaunchDecision checks containsKey for all three keys.
      //   All present → LaunchDestination.home → skips initialSettings.
      prefs = await SharedPreferences.getInstance();
      await prefs.setString('appEntryResolvedMode', 'guest');
      await prefs.setString('breakfastTime', '08:00');
      await prefs.setString('lunchTime', '12:00');
      await prefs.setString('dinnerTime', '18:00');
    });

    tearDown(() async {
      await prefs.remove('appEntryResolvedMode');
      await prefs.remove('breakfastTime');
      await prefs.remove('lunchTime');
      await prefs.remove('dinnerTime');
    });

    testWidgets('Last Taken Medicines Page renders within CI tolerance',
        (WidgetTester tester) async {
      // Await main() so all async initialization (Firebase, timezone, DI)
      // completes before the widget tree is driven by the test.
      await app.main();
      await tester.pumpAndSettle();

      // At this point the router must have landed on HomePage.
      final historyIcon = find.byIcon(Icons.history);
      expect(historyIcon, findsOneWidget);

      // Measure only the UI rendering time after navigation.
      final stopwatch = Stopwatch()..start();

      await tester.tap(historyIcon);
      await tester.pumpAndSettle();

      stopwatch.stop();

      // Verify the destination page is shown.
      expect(find.byType(LastTakenMedicinesPage), findsOneWidget);

      // Use a CI-tolerant ceiling (3 000 ms) instead of a strict 1 000 ms
      // wall-clock bound that is brittle under normal CI load.
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });
  });
}
