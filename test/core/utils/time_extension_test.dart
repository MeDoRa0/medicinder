import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/l10n/app_localizations.dart';
import 'package:medicinder/core/utils/time_extension.dart';

void main() {
  Widget buildTestWidget(DateTime timeToFormat, void Function(BuildContext) onBuild) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(
        builder: (context) {
          onBuild(context);
          return const SizedBox.shrink();
        },
      ),
    );
  }

  group('RelativeTimeExtension', () {
    testWidgets('Returns "Just now" for times less than a minute ago', (WidgetTester tester) async {
      final now = DateTime.now();
      final time = now.subtract(const Duration(seconds: 30));
      String? result;

      await tester.pumpWidget(buildTestWidget(time, (context) {
        result = time.toRelativeTime(context);
      }));

      expect(result, 'Just now');
    });

    testWidgets('Returns formatted minutes string for times less than an hour ago', (WidgetTester tester) async {
      final now = DateTime.now();
      final time = now.subtract(const Duration(minutes: 15));
      String? result;

      await tester.pumpWidget(buildTestWidget(time, (context) {
        result = time.toRelativeTime(context);
      }));

      expect(result, '15 m ago');
    });

    testWidgets('Returns formatted hours string for times an hour or more ago', (WidgetTester tester) async {
      final now = DateTime.now();
      final time = now.subtract(const Duration(hours: 3, minutes: 15));
      String? result;

      await tester.pumpWidget(buildTestWidget(time, (context) {
        result = time.toRelativeTime(context);
      }));

      expect(result, '3 h ago');
    });
  });
}
