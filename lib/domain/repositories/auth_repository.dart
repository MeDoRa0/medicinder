import '../entities/sync/auth_session.dart';

abstract class AuthRepository {
  Stream<AuthSession> watchSession();
  Future<AuthSession> getCurrentSession();
  Future<AuthSession> signInForSync({String? providerId});
  Future<void> signOutFromSync();
}
