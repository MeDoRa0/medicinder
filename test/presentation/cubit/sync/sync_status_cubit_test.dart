import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/core/services/sync/sync_diagnostics.dart';
import 'package:medicinder/domain/entities/sync/auth_session.dart';
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

      expect(cubit.state.viewState.name, 'notSignedIn');
      await cubit.close();
    });

    test('moves to upToDate after sign in and sync success', () async {
      final authRepository = _FakeAuthRepository();
      final cubit = SyncStatusCubit(
        signInForSync: SignInForSync(authRepository),
        signOutFromSync: SignOutFromSync(authRepository),
        watchAuthSession: WatchAuthSession(authRepository),
        syncRepository: _FakeSyncRepository(),
        syncDiagnostics: const SyncDiagnostics(),
      );

      await cubit.signIn();

      expect(cubit.state.viewState.name, 'upToDate');
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

    test('returns to notSignedIn after sign out', () async {
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

      expect(cubit.state.viewState.name, 'notSignedIn');
      expect(cubit.state.userId, isNull);
      await cubit.close();
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  AuthSession _session = const AuthSession.signedOut();

  @override
  Future<AuthSession> getCurrentSession() async => _session;

  @override
  Future<AuthSession> signInForSync() async {
    _session = const AuthSession.signedIn('user-123');
    return _session;
  }

  @override
  Future<void> signOutFromSync() async {
    _session = const AuthSession.signedOut();
  }

  @override
  Stream<AuthSession> watchSession() async* {
    yield _session;
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
