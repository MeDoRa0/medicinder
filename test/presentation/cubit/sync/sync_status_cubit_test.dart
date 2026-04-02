import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/core/services/sync/sync_diagnostics.dart';
import 'package:medicinder/domain/entities/sync/auth_session.dart';
import 'package:medicinder/domain/entities/sync/sync_status_view_state.dart';
import 'package:medicinder/domain/entities/sync/sync_types.dart';
import 'package:medicinder/domain/repositories/auth_repository.dart';
import 'package:medicinder/domain/repositories/sync_repository.dart';
import 'package:medicinder/domain/usecases/sync/sign_in_for_sync.dart';
import 'package:medicinder/domain/usecases/sync/sign_out_from_sync.dart';
import 'package:medicinder/domain/usecases/sync/watch_auth_session.dart';
import 'package:medicinder/presentation/cubit/sync/sync_status_cubit.dart';

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
      );

      await cubit.retry();

      expect(cubit.state.viewState.name, 'syncFailed');
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
      );

      cubit.initialize();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.viewState, SyncStatusViewState.accessDenied);
      expect(cubit.state.message, 'Access denied');
      await cubit.close();
    });
  });
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

class _FakeSyncRepository implements SyncRepository {
  final bool success;

  _FakeSyncRepository({this.success = true});

  @override
  Future<SyncResult> syncNow(SyncTrigger trigger) async =>
      SyncResult(success: success, message: success ? null : 'failed');

  @override
  Future<SyncResult> synchronize() => syncNow(SyncTrigger.manualRetry);

  @override
  Future<void> handleAuthChanged(AuthSession session) async {}

  @override
  Future<void> handleConnectivityRestored() async {}
}
