import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:medicinder/core/services/sync/connectivity_signal_service.dart';
import 'package:medicinder/core/services/sync/sync_diagnostics.dart';
import 'package:medicinder/domain/entities/sync/auth_session.dart';
import 'package:medicinder/domain/entities/sync/sync_status_view_state.dart';
import 'package:medicinder/domain/entities/sync/sync_types.dart';
import 'package:medicinder/domain/repositories/auth_repository.dart';
import 'package:medicinder/domain/repositories/sync_repository.dart';
import 'package:medicinder/domain/entities/sync_operation.dart';
import 'package:medicinder/domain/usecases/sync/sign_in_for_sync.dart';
import 'package:medicinder/domain/usecases/sync/sign_out_from_sync.dart';
import 'package:medicinder/domain/usecases/sync/watch_auth_session.dart';
import 'package:medicinder/data/datasources/sync_queue_local_data_source.dart';
import 'package:medicinder/domain/entities/sync/pending_change.dart';
import 'package:medicinder/l10n/app_localizations.dart';
import 'package:medicinder/presentation/cubit/sync/sync_status_cubit.dart';
import 'package:medicinder/presentation/cubit/sync/sync_status_state.dart';
import 'package:medicinder/presentation/widgets/sync/sync_status_banner.dart';

void main() {
  testWidgets('renders signed out sync status', (tester) async {
    final authRepository = _FakeAuthRepository();
    await tester.pumpWidget(
      _TestApp(
        cubit: SyncStatusCubit(
          signInForSync: SignInForSync(authRepository),
          signOutFromSync: SignOutFromSync(authRepository),
          watchAuthSession: WatchAuthSession(authRepository),
          syncRepository: _FakeSyncRepository(),
          syncDiagnostics: const SyncDiagnostics(),
          connectivitySignal: _FakeConnectivitySignalService(),
          syncQueue: _FakeSyncQueue(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Signed out'), findsOneWidget);
  });

  testWidgets('renders ready sync status', (tester) async {
    final authRepository = _FakeAuthRepository();
    final cubit =
        _SeededSyncStatusCubit(
          signInForSync: SignInForSync(authRepository),
          signOutFromSync: SignOutFromSync(authRepository),
          watchAuthSession: WatchAuthSession(authRepository),
          syncRepository: _FakeSyncRepository(),
          syncDiagnostics: const SyncDiagnostics(),
          connectivitySignal: _FakeConnectivitySignalService(),
          syncQueue: _FakeSyncQueue(),
        )..seed(
          const SyncStatusState(
            viewState: SyncStatusViewState.ready,
            userId: 'user-123',
          ),
        );

    await tester.pumpWidget(_TestApp(cubit: cubit));

    expect(find.text('Cloud workspace ready'), findsOneWidget);
  });

  testWidgets('renders syncing sync status', (tester) async {
    final authRepository = _FakeAuthRepository();
    final cubit =
        _SeededSyncStatusCubit(
          signInForSync: SignInForSync(authRepository),
          signOutFromSync: SignOutFromSync(authRepository),
          watchAuthSession: WatchAuthSession(authRepository),
          syncRepository: _FakeSyncRepository(),
          syncDiagnostics: const SyncDiagnostics(),
          connectivitySignal: _FakeConnectivitySignalService(),
          syncQueue: _FakeSyncQueue(),
        )..seed(
          const SyncStatusState(
            viewState: SyncStatusViewState.syncing,
            userId: 'user-123',
          ),
        );

    await tester.pumpWidget(_TestApp(cubit: cubit));

    expect(find.text('Syncing...'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  final SyncStatusCubit cubit;

  const _TestApp({required this.cubit});

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
  Future<AuthSession> getCurrentSession() async =>
      const AuthSession.signedOut();

  @override
  Future<AuthSession> signInForSync() async =>
      const AuthSession.ready('user-123', providerId: 'anonymous');

  @override
  Future<void> signOutFromSync() async {}

  @override
  Stream<AuthSession> watchSession() async* {
    yield const AuthSession.signedOut();
  }
}

class _FakeSyncRepository implements SyncRepository {
  @override
  Future<SyncResult> syncNow(SyncTrigger trigger) async =>
      const SyncResult(success: true);

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
    required super.syncRepository,
    required super.syncDiagnostics,
    required super.connectivitySignal,
    required super.syncQueue,
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
  Stream<void> get onReconnect => const Stream.empty();

  @override
  Future<void> dispose() async {}
}
