import 'package:firebase_auth/firebase_auth.dart';

import '../../../domain/entities/sync/auth_session.dart';

abstract class AuthRemoteDataSource {
  Stream<AuthSession> watchSession();
  Future<AuthSession> getCurrentSession();
  Future<AuthSession> signInAnonymouslyForSync();
  Future<void> signOut();
}

class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthRemoteDataSource(this._firebaseAuth);

  @override
  Future<AuthSession> getCurrentSession() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return const AuthSession.signedOut();
    }
    return AuthSession.signedIn(user.uid);
  }

  @override
  Future<AuthSession> signInAnonymouslyForSync() async {
    final credential = await _firebaseAuth.signInAnonymously();
    final user = credential.user;
    if (user == null) {
      return const AuthSession.signedOut();
    }
    return AuthSession.signedIn(user.uid);
  }

  @override
  Future<void> signOut() => _firebaseAuth.signOut();

  @override
  Stream<AuthSession> watchSession() {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user == null) {
        return const AuthSession.signedOut();
      }
      return AuthSession.signedIn(user.uid);
    });
  }
}

class DisabledAuthRemoteDataSource implements AuthRemoteDataSource {
  const DisabledAuthRemoteDataSource();

  @override
  Future<AuthSession> getCurrentSession() async => const AuthSession.signedOut();

  @override
  Future<AuthSession> signInAnonymouslyForSync() async =>
      const AuthSession.signedOut();

  @override
  Future<void> signOut() async {}

  @override
  Stream<AuthSession> watchSession() async* {
    yield const AuthSession.signedOut();
  }
}
