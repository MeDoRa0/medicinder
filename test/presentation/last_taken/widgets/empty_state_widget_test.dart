import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/l10n/app_localizations.dart';
import 'package:medicinder/presentation/last_taken/widgets/empty_state_widget.dart';

void main() {
  testWidgets('EmptyStateWidget displays icon and localized message', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('en'),
      home: Scaffold(
        body: EmptyStateWidget(),
      ),
    ));

    expect(find.byType(Icon), findsOneWidget); // We might use Icon instead of Image if no asset exists, or Image.asset
    expect(find.text('No medications taken today.'), findsOneWidget);
  });
}
