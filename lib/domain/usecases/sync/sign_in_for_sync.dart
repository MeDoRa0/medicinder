import '../../entities/sync/auth_session.dart';
import '../../repositories/auth_repository.dart';

class SignInForSync {
  final AuthRepository _repository;

  SignInForSync(this._repository);

  Future<AuthSession> call({String? providerId}) =>
      _repository.signInForSync(providerId: providerId);
}
