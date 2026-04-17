import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:medicinder/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Bottom navigation switching and back button flow', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));
    
    // Tap History tab
    final historyTab = find.text('History');
    expect(historyTab, findsOneWidget);

    await tester.tap(historyTab);
    await tester.pumpAndSettle();

    // Wait for data load or empty state
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Press hardware back button (or mock pop)
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    // Verify we returned to tab 0
    final bottomNavBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(bottomNavBar.currentIndex, 0);
  });
}
