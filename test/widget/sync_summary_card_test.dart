import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:medicinder/domain/entities/sync/sync_status_view_state.dart';
import 'package:medicinder/domain/entities/sync/sync_types.dart';
import 'package:medicinder/domain/entities/sync/user_sync_profile.dart';
import 'package:medicinder/l10n/app_localizations.dart';
import 'package:medicinder/presentation/widgets/sync/sync_summary_card.dart';

void main() {
  testWidgets('renders sync summary with last success timestamp', (tester) async {
    final lastSuccess = DateTime(2026, 4, 3, 10, 0);
    final profile = UserSyncProfile(
      userId: 'user-123',
      syncEnabled: true,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
      statusViewState: SyncStatusViewState.ready,
      lastSuccessAt: lastSuccess,
      lastPushedCount: 5,
      lastPulledCount: 10,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: SyncSummaryCard(profile: profile),
        ),
      ),
    );

    expect(find.textContaining('Last sync:'), findsOneWidget);
    expect(find.textContaining('5 Pushed'), findsOneWidget);
    expect(find.textContaining('10 Pulled'), findsOneWidget);
  });
}
