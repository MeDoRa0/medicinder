import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Basic Tests', () {
    testWidgets('should render text widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('Test'))),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('should render button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ElevatedButton(onPressed: null, child: Text('Button')),
          ),
        ),
      );

      expect(find.text('Button'), findsOneWidget);
    });
  });
}
