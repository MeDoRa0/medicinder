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
