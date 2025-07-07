import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Minimal Widget Tests', () {
    testWidgets('should render basic text widget', (WidgetTester tester) async {
      print('Starting minimal text test');

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('Hello World'))),
      );

      print('Pumping and settling');
      await tester.pumpAndSettle();

      print('Checking text exists');
      expect(find.text('Hello World'), findsOneWidget);
      print('Minimal text test completed');
    });

    testWidgets('should render basic container', (WidgetTester tester) async {
      print('Starting minimal container test');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              width: 100,
              height: 100,
              color: Colors.red,
              child: const Text('Container'),
            ),
          ),
        ),
      );

      print('Pumping and settling');
      await tester.pumpAndSettle();

      print('Checking container exists');
      expect(find.byType(Container), findsOneWidget);
      expect(find.text('Container'), findsOneWidget);
      print('Minimal container test completed');
    });
  });
}
