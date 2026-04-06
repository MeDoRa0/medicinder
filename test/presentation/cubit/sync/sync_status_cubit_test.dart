import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/core/services/sync/connectivity_signal_service.dart';
import 'package:medicinder/core/services/sync/sync_diagnostics.dart';
import 'package:medicinder/data/datasources/sync_queue_local_data_source.dart';
import 'package:medicinder/domain/entities/sync_operation.dart';
import 'package:medicinder/domain/entities/sync/auth_session.dart';
import 'package:medicinder/domain/entities/sync/pending_change.dart';
import 'package:medicinder/domain/entities/sync/sync_status_view_state.dart';
import 'package:medicinder/domain/entities/sync/sync_types.dart';
import 'package:medicinder/domain/repositories/auth_repository.dart';
import 'package:medicinder/domain/repositories/sync_repository.dart';
import 'package:medicinder/domain/usecases/sync/sign_in_for_sync.dart';
import 'package:medicinder/domain/usecases/sync/sign_out_from_sync.dart';
import 'package:medicinder/domain/usecases/sync/watch_auth_session.dart';
import 'package:medicinder/presentation/cubit/sync/sync_status_cubit.dart';

import '../../../helpers/fake_notification_sync_service.dart';

void main() {
  group('SyncStatusCubit', () {
    test('initializes as signed out when no session exists', () async {
      final authRepository = _FakeAuthRepository();
      final cubit = SyncStatusCubit(
        signInForSync: SignInForSync(authRepository),
        signOutFromSync: SignOutFromSync(authRepository),
        watchAuthSession: WatchAuthSession(authRepository),
        syncRepository: _FakeSyncRepository(),
        syncDiagnostics: const SyncDiagnostics(),
        connectivitySignal: _FakeConnectivitySignalService(),
        syncQueue: _FakeSyncQueue(),
        notificationSyncService: FakeNotificationSyncService(),
      );

      cubit.initialize();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.viewState, SyncStatusViewState.signedOut);
      await cubit.close();
    });

    test('moves to ready after sign in and sync success', () async {
      final authRepository = _FakeAuthRepository();
      final cubit = SyncStatusCubit(
        signInForSync: SignInForSync(authRepository),
        signOutFromSync: SignOutFromSync(authRepository),
        watchAuthSession: WatchAuthSession(authRepository),
        syncRepository: _FakeSyncRepository(),
        syncDiagnostics: const SyncDiagnostics(),
        connectivitySignal: _FakeConnectivitySignalService(),
        syncQueue: _FakeSyncQueue(),
        notificationSyncService: FakeNotificationSyncService(),
      );

      await cubit.signIn();

      expect(cubit.state.viewState, SyncStatusViewState.ready);
      expect(cubit.state.userId, 'user-123');
      await cubit.close();
    });

    test('moves to syncFailed when retry fails', () async {
      final authRepository = _FakeAuthRepository();
      final cubit = SyncStatusCubit(
        signInForSync: SignInForSync(authRepository),
        signOutFromSync: SignOutFromSync(authRepository),
        watchAuthSession: WatchAuthSession(authRepository),
        syncRepository: _FakeSyncRepository(success: false),
        syncDiagnostics: const SyncDiagnostics(),
        connectivitySignal: _FakeConnectivitySignalService(),
        syncQueue: _FakeSyncQueue(),
        notificationSyncService: FakeNotificationSyncService(),
      );

      await cubit.retry();

      expect(cubit.state.viewState, SyncStatusViewState.syncFailed);
      await cubit.close();
    });

    test('returns to signedOut after sign out', () async {
      final authRepository = _FakeAuthRepository();
      final cubit = SyncStatusCubit(
        signInForSync: SignInForSync(authRepository),
        signOutFromSync: SignOutFromSync(authRepository),
        watchAuthSession: WatchAuthSession(authRepository),
        syncRepository: _FakeSyncRepository(),
        syncDiagnostics: const SyncDiagnostics(),
        connectivitySignal: _FakeConnectivitySignalService(),
        syncQueue: _FakeSyncQueue(),
        notificationSyncService: FakeNotificationSyncService(),
      );

      await cubit.signIn();
      await cubit.signOut();

      expect(cubit.state.viewState, SyncStatusViewState.signedOut);
      expect(cubit.state.userId, isNull);
      await cubit.close();
    });

    test('surfaces access denied state from auth session', () async {
      final authRepository = _FakeAuthRepository(
        watchedSession: const AuthSession.accessDenied(
          'user-123',
          failureMessage: 'Access denied',
        ),
      );
      final cubit = SyncStatusCubit(
        signInForSync: SignInForSync(authRepository),
        signOutFromSync: SignOutFromSync(authRepository),
        watchAuthSession: WatchAuthSession(authRepository),
        syncRepository: _FakeSyncRepository(),
        syncDiagnostics: const SyncDiagnostics(),
        connectivitySignal: _FakeConnectivitySignalService(),
        syncQueue: _FakeSyncQueue(),
        notificationSyncService: FakeNotificationSyncService(),
      );

      cubit.initialize();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.viewState, SyncStatusViewState.accessDenied);
      expect(cubit.state.message, 'Access denied');
      await cubit.close();
    });

    group('Startup and Reconnect Triggers', () {
      test(
        'initialize() with a signed-in session triggers startup sync',
        () async {
          final authRepository = _FakeAuthRepository(
            watchedSession: const AuthSession.ready(
              'user-123',
              providerId: 'anonymous',
            ),
          );
          final syncRepository = _FakeSyncRepository();
          final cubit = SyncStatusCubit(
            signInForSync: SignInForSync(authRepository),
            signOutFromSync: SignOutFromSync(authRepository),
            watchAuthSession: WatchAuthSession(authRepository),
            syncRepository: syncRepository,
            syncDiagnostics: const SyncDiagnostics(),
            connectivitySignal: _FakeConnectivitySignalService(),
            syncQueue: _FakeSyncQueue(),
            notificationSyncService: FakeNotificationSyncService(),
          );

          cubit.initialize();
          await Future<void>.delayed(Duration.zero);

          expect(syncRepository.syncCalls, contains(SyncTrigger.appStartup));
        },
      );

      test('triggers sync when connectivity is restored', () async {
        final authRepository = _FakeAuthRepository(
          initialSession: const AuthSession.ready(
            'user-123',
            providerId: 'anonymous',
          ),
        );
        final syncRepository = _FakeSyncRepository();
        final connectivitySignal = _FakeConnectivitySignalService();
        final cubit = SyncStatusCubit(
          signInForSync: SignInForSync(authRepository),
          signOutFromSync: SignOutFromSync(authRepository),
          watchAuthSession: WatchAuthSession(authRepository),
          syncRepository: syncRepository,
          syncDiagnostics: const SyncDiagnostics(),
          connectivitySignal: connectivitySignal,
          syncQueue: _FakeSyncQueue(),
          notificationSyncService: FakeNotificationSyncService(),
        );

        cubit.initialize();
        await Future<void>.delayed(Duration.zero); // Let it reach 'ready'
        syncRepository.syncCalls.clear();

        connectivitySignal.triggerReconnect();
        await Future<void>.delayed(Duration.zero);

        expect(
          syncRepository.syncCalls,
          contains(SyncTrigger.connectivityRestored),
        );
      });
    });
  });
}

class _FakeSyncRepository implements SyncRepository {
  final bool success;
  final List<SyncTrigger> syncCalls = [];

  _FakeSyncRepository({this.success = true});

  @override
  Future<SyncResult> syncNow(SyncTrigger trigger) async {
    syncCalls.add(trigger);
    return SyncResult(success: success, message: success ? null : 'failed');
  }

  @override
  Future<SyncResult> synchronize() => syncNow(SyncTrigger.manualRetry);

  @override
  Future<void> handleAuthChanged(AuthSession session) async {
    if (session.isSignedIn) {
      await syncNow(SyncTrigger.userSignIn);
    }
  }

  @override
  Future<void> handleConnectivityRestored() async {
    await syncNow(SyncTrigger.connectivityRestored);
  }
}

class _FakeAuthRepository implements AuthRepository {
  AuthSession _session;
  final AuthSession watchedSession;

  _FakeAuthRepository({
    AuthSession initialSession = const AuthSession.signedOut(),
    AuthSession? watchedSession,
  }) : _session = initialSession,
       watchedSession = watchedSession ?? initialSession;

  @override
  Future<AuthSession> getCurrentSession() async => _session;

  @override
  Future<AuthSession> signInForSync() async {
    _session = const AuthSession.ready('user-123', providerId: 'anonymous');
    return _session;
  }

  @override
  Future<void> signOutFromSync() async {
    _session = const AuthSession.signedOut();
  }

  @override
  Stream<AuthSession> watchSession() async* {
    yield watchedSession;
  }
}

class _FakeSyncQueue implements SyncQueueLocalDataSource {
  final List<PendingChange> pendingChanges = [];

  @override
  Future<void> enqueuePendingChange(PendingChange change) async {
    pendingChanges.add(change);
  }

  @override
  Future<void> enqueue(SyncOperation operation) async {}

  @override
  Future<List<PendingChange>> listPendingChanges({String? userId}) async =>
      List.of(pendingChanges);

  @override
  Future<List<PendingChange>> getEffectivePendingChanges({
    String? userId,
  }) async => List.of(pendingChanges);

  @override
  Future<void> markPendingChangeInFlight(String changeId) async {}

  @override
  Future<void> markPendingChangeFailed(
    String changeId, {
    required String errorMessage,
  }) async {}

  @override
  Future<void> markPendingChangeSucceeded(String changeId) async {
    pendingChanges.removeWhere((c) => c.changeId == changeId);
  }

  @override
  int countPermanentlyFailedChanges({String? userId}) => 0;

  @override
  Future<List<PendingChange>> getPermanentlyFailedChanges({
    String? userId,
  }) async => const [];
}

class _FakeConnectivitySignalService implements ConnectivitySignalService {
  final StreamController<void> _controller = StreamController<void>.broadcast();

  @override
  Stream<void> get onReconnect => _controller.stream;

  void triggerReconnect() => _controller.add(null);

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}
