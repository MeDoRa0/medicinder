import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:medicinder/data/datasources/auth/apple_auth_provider_data_source.dart';
import 'package:medicinder/core/services/sync/connectivity_signal_service.dart';
import 'package:medicinder/core/services/sync/sync_diagnostics.dart';
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
import 'package:medicinder/presentation/widgets/sync/sync_status_banner.dart';
import '../helpers/fake_notification_sync_service.dart';

void main() {
  testWidgets('tapping retry button in banner triggers cubit retry', (
    tester,
  ) async {
    final authRepository = _FakeAuthRepository();
    final syncRepository = _FakeSyncRepository();
    final cubit =
        _MockSyncStatusCubit(
          signInForSync: SignInForSync(authRepository),
          signOutFromSync: SignOutFromSync(authRepository),
          watchAuthSession: WatchAuthSession(authRepository),
          clearAppEntryState: ClearAppEntryState(_FakeAppEntryRepository()),
          syncRepository: syncRepository,
          syncDiagnostics: const SyncDiagnostics(),
          connectivitySignal: _FakeConnectivitySignalService(),
          syncQueue: _FakeSyncQueue(),
          notificationSyncService: FakeNotificationSyncService(),
        )..seed(
          const SyncStatusState(
            viewState: SyncStatusViewState.syncFailed,
            userId: 'user-123',
            message: 'Sync failed',
          ),
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
        home: BlocProvider<SyncStatusCubit>.value(
          value: cubit,
          child: const Scaffold(body: SyncStatusBanner()),
        ),
      ),
    );

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(cubit.retryCalled, isTrue);
  });
}

class _MockSyncStatusCubit extends SyncStatusCubit {
  bool retryCalled = false;

  _MockSyncStatusCubit({
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

  @override
  Future<void> retry() async {
    retryCalled = true;
  }
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

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AppleAuthAvailability> getAppleAvailability() async =>
      AppleAuthAvailability.unsupportedRunner;

  @override
  Future<AuthSession> getCurrentSession() async =>
      const AuthSession.signedOut();
  @override
  Future<AuthSession> signInForSync({String? providerId}) async =>
      const AuthSession.ready('u1');
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
  Future<SyncResult> synchronize() async => const SyncResult(success: true);
  @override
  Future<void> handleAuthChanged(AuthSession session) async {}
  @override
  Future<void> handleConnectivityRestored() async {}
}

class _FakeConnectivitySignalService implements ConnectivitySignalService {
  @override
  Stream<void> get onReconnect => const Stream.empty();

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
