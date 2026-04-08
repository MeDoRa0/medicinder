import '../../domain/entities/sync/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<AuthSession> getCurrentSession() =>
      _remoteDataSource.getCurrentSession();

  @override
  Future<AuthSession> signInForSync({String? providerId}) =>
      _remoteDataSource.signInForSync(providerId: providerId);

  @override
  Future<void> signOutFromSync() => _remoteDataSource.signOut();

  @override
  Stream<AuthSession> watchSession() => _remoteDataSource.watchSession();
}
