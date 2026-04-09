import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:medicinder/data/datasources/auth/apple_auth_provider_data_source.dart';
import 'package:medicinder/core/services/sync/sync_diagnostics.dart';
import 'package:medicinder/core/services/sync/connectivity_signal_service.dart';
import 'package:medicinder/domain/entities/sync/auth_session.dart';
import 'package:medicinder/domain/entities/sync/sync_status_view_state.dart';
import 'package:medicinder/domain/entities/sync/sync_types.dart';
import 'package:medicinder/domain/repositories/app_entry_repository.dart';
import 'package:medicinder/domain/repositories/auth_repository.dart';
import 'package:medicinder/domain/repositories/sync_repository.dart';
import 'package:medicinder/domain/entities/sync_operation.dart';
import 'package:medicinder/domain/usecases/auth/clear_app_entry_state.dart';
import 'package:medicinder/domain/usecases/sync/sign_in_for_sync.dart';
import 'package:medicinder/domain/usecases/sync/sign_out_from_sync.dart';
import 'package:medicinder/domain/usecases/sync/watch_auth_session.dart';
import 'package:medicinder/data/datasources/sync_queue_local_data_source.dart';
import 'package:medicinder/domain/entities/sync/pending_change.dart';
import 'package:medicinder/l10n/app_localizations.dart';
import 'package:medicinder/presentation/cubit/sync/sync_status_cubit.dart';
import 'package:medicinder/presentation/cubit/sync/sync_status_state.dart';
import 'package:medicinder/presentation/widgets/sync/sync_account_tile.dart';
import 'package:medicinder/presentation/widgets/sync/sync_status_banner.dart';
import '../helpers/fake_notification_sync_service.dart';

void main() {
  testWidgets('exposes sync status semantics label', (tester) async {
    final authRepository = _FakeAuthRepository();
    final cubit =
        _SeededSyncStatusCubit(
          signInForSync: SignInForSync(authRepository),
          signOutFromSync: SignOutFromSync(authRepository),
          watchAuthSession: WatchAuthSession(authRepository),
          clearAppEntryState: ClearAppEntryState(_FakeAppEntryRepository()),
          syncRepository: _FakeFailingSyncRepository(),
          syncDiagnostics: const SyncDiagnostics(),
          connectivitySignal: _FakeConnectivitySignalService(),
          syncQueue: _FakeSyncQueue(),
          notificationSyncService: FakeNotificationSyncService(),
        )..seed(
          const SyncStatusState(
            viewState: SyncStatusViewState.syncFailed,
            message: 'failed',
          ),
        );

    await tester.pumpWidget(_AccessibilityTestApp(cubit: cubit));
    await tester.pump();

    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);
  });

  testWidgets('keeps the signed-out sync tile local-only without a sign-in action', (
    tester,
  ) async {
    final authRepository = _FakeAuthRepository();
    final cubit =
        _SeededSyncStatusCubit(
          signInForSync: SignInForSync(authRepository),
          signOutFromSync: SignOutFromSync(authRepository),
          watchAuthSession: WatchAuthSession(authRepository),
          clearAppEntryState: ClearAppEntryState(_FakeAppEntryRepository()),
          syncRepository: _FakeFailingSyncRepository(),
          syncDiagnostics: const SyncDiagnostics(),
          connectivitySignal: _FakeConnectivitySignalService(),
          syncQueue: _FakeSyncQueue(),
          notificationSyncService: FakeNotificationSyncService(),
        )..seed(const SyncStatusState(viewState: SyncStatusViewState.signedOut));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ar')],
        home: BlocProvider<SyncStatusCubit>.value(
          value: cubit,
          child: const _SyncAccountTileTestApp(),
        ),
      ),
    );
    await tester.pump();

    final context = tester.element(find.byType(SyncAccountTile));
    final l10n = AppLocalizations.of(context)!;
    expect(find.text(l10n.syncStatusTitle), findsOneWidget);
    expect(find.text(l10n.syncUnavailableLocalOnly), findsOneWidget);
    expect(find.text(l10n.syncDisableCloudSync), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });
}

class _SyncAccountTileTestApp extends StatelessWidget {
  const _SyncAccountTileTestApp();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SyncAccountTile());
  }
}

class _AccessibilityTestApp extends StatelessWidget {
  final SyncStatusCubit cubit;

  const _AccessibilityTestApp({required this.cubit});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: BlocProvider.value(
        value: cubit,
        child: const Scaffold(body: SyncStatusBanner()),
      ),
    );
  }
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AppleAuthAvailability> getAppleAvailability() async =>
      AppleAuthAvailability.unsupportedRunner;

  @override
  Future<AuthSession> getCurrentSession() async =>
      const AuthSession.signedOut();

  @override
  Future<AuthSession> signInForSync({String? providerId}) async =>
      const AuthSession.ready('user-123', providerId: 'anonymous');

  @override
  Future<void> signOutFromSync() async {}

  @override
  Stream<AuthSession> watchSession() async* {
    yield const AuthSession.signedOut();
  }
}

class _FakeFailingSyncRepository implements SyncRepository {
  @override
  Future<SyncResult> syncNow(SyncTrigger trigger) async =>
      const SyncResult(success: false, message: 'failed');

  @override
  Future<SyncResult> synchronize() => syncNow(SyncTrigger.manualRetry);

  @override
  Future<void> handleAuthChanged(AuthSession session) async {}

  @override
  Future<void> handleConnectivityRestored() async {}
}

class _SeededSyncStatusCubit extends SyncStatusCubit {
  _SeededSyncStatusCubit({
    required super.signInForSync,
    required super.signOutFromSync,
    required super.watchAuthSession,
    required super.clearAppEntryState,
    required super.syncRepository,
    required super.syncDiagnostics,
    required super.connectivitySignal,
    required super.syncQueue,
    required super.notificationSyncService,
  });

  void seed(SyncStatusState state) => emit(state);
}

class _FakeSyncQueue implements SyncQueueLocalDataSource {
  @override
  Future<void> enqueuePendingChange(PendingChange change) async {}

  @override
  Future<void> enqueue(SyncOperation operation) async {}

  @override
  Future<List<PendingChange>> listPendingChanges({String? userId}) async =>
      const [];

  @override
  Future<List<PendingChange>> getEffectivePendingChanges({
    String? userId,
  }) async => const [];

  @override
  Future<void> markPendingChangeInFlight(String changeId) async {}

  @override
  Future<void> markPendingChangeFailed(
    String changeId, {
    required String errorMessage,
  }) async {}

  @override
  Future<void> markPendingChangeSucceeded(String changeId) async {}

  @override
  int countPermanentlyFailedChanges({String? userId}) => 0;

  @override
  Future<List<PendingChange>> getPermanentlyFailedChanges({
    String? userId,
  }) async => const [];
}

class _FakeConnectivitySignalService implements ConnectivitySignalService {
  @override
  Stream<void> get onReconnect => const Stream<void>.empty();

  @override
  Future<void> dispose() async {}
}

class _FakeAppEntryRepository implements AppEntryRepository {
  @override
  Future<void> clearResolvedEntryMode() async {}

  @override
  Future<void> persistGuestMode() async {}

  @override
  Future<String?> readResolvedEntryMode() async => null;
}
