import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/data/datasources/auth/auth_remote_data_source.dart';
import 'package:medicinder/data/repositories/auth_repository_impl.dart';
import 'package:medicinder/domain/entities/sync/auth_session.dart';

void main() {
  group('AuthRepositoryImpl', () {
    test('returns signed out session by default', () async {
      final repository = AuthRepositoryImpl(_FakeAuthRemoteDataSource());

      final session = await repository.getCurrentSession();

      expect(session.isSignedIn, isFalse);
      expect(session.userId, isNull);
      expect(session.status, AuthSessionStatus.signedOut);
    });

    test('signs in through remote data source', () async {
      final remote = _FakeAuthRemoteDataSource();
      final repository = AuthRepositoryImpl(remote);

      final session = await repository.signInForSync();

      expect(session.isSignedIn, isTrue);
      expect(session.userId, 'user-123');
      expect(session.workspaceReady, isTrue);
      expect(session.status, AuthSessionStatus.ready);
    });
  });

  group('DisabledAuthRemoteDataSource', () {
    test('getCurrentSession returns signedOut', () async {
      const remote = DisabledAuthRemoteDataSource();

      final session = await remote.getCurrentSession();

      expect(session.status, AuthSessionStatus.signedOut);
      expect(session.isSignedIn, isFalse);
    });

    test('signInForSync returns failed with CLOUD_SYNC_DISABLED code', () async {
      const remote = DisabledAuthRemoteDataSource();

      final session = await remote.signInForSync();

      expect(session.status, AuthSessionStatus.failed);
      expect(session.isSignedIn, isFalse);
      expect(session.failureCode, 'CLOUD_SYNC_DISABLED');
      expect(session.failureMessage, isNotNull);
    });

    test('watchSession emits signedOut', () async {
      const remote = DisabledAuthRemoteDataSource();

      final sessions = await remote.watchSession().toList();

      // watchSession returns signedOut (via getCurrentSession delegation)
      expect(sessions, isNotEmpty);
      expect(sessions.first.status, AuthSessionStatus.signedOut);
    });

    test('signOut completes without error', () async {
      const remote = DisabledAuthRemoteDataSource();

      // Should not throw
      await remote.signOut();
    });
  });
}

class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  AuthSession _session = const AuthSession.signedOut();

  @override
  Future<AuthSession> getCurrentSession() async => _session;

  @override
  Future<AuthSession> signInForSync({String? providerId}) async {
    _session = const AuthSession.ready('user-123', providerId: 'anonymous');
    return _session;
  }

  @override
  Future<void> signOut() async {
    _session = const AuthSession.signedOut();
  }

  @override
  Stream<AuthSession> watchSession() async* {
    yield _session;
  }
}