import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_config.dart';

void main() {
  group('Simple Widget Tests', () {
    testWidgets('should render basic text widget', (WidgetTester tester) async {
      print('Starting basic text test');

      await tester.pumpWidget(
        TestConfig.createTestWidget(const Text('Hello World')),
      );

      print('Pumping and settling');
      await tester.pumpAndSettle();

      print('Checking text exists');
      expect(find.text('Hello World'), findsOneWidget);
      print('Basic text test completed');
    });

    testWidgets('should render basic container', (WidgetTester tester) async {
      print('Starting container test');

      await tester.pumpWidget(
        TestConfig.createTestWidget(
          Container(
            width: 100,
            height: 100,
            color: Colors.red,
            child: const Text('Container'),
          ),
        ),
      );

      print('Pumping and settling');
      await tester.pumpAndSettle();

      print('Checking container exists');
      expect(find.byType(Container), findsOneWidget);
      expect(find.text('Container'), findsOneWidget);
      print('Container test completed');
    });
  });
}
