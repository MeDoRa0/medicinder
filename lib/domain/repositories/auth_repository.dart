import '../../data/datasources/auth/apple_auth_provider_data_source.dart';
import '../entities/sync/auth_session.dart';

abstract class AuthRepository {
  Stream<AuthSession> watchSession();
  Future<AuthSession> getCurrentSession();
  Future<AppleAuthAvailability> getAppleAvailability();
  Future<AuthSession> signInForSync({String? providerId});
  Future<void> signOutFromSync();
}
