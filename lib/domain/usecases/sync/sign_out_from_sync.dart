import '../../repositories/auth_repository.dart';

class SignOutFromSync {
  final AuthRepository _repository;

  SignOutFromSync(this._repository);

  Future<void> call() => _repository.signOutFromSync();
}
