import '../../entities/sync/auth_session.dart';
import '../../repositories/auth_repository.dart';

class WatchAuthSession {
  final AuthRepository _repository;

  WatchAuthSession(this._repository);

  Stream<AuthSession> call() => _repository.watchSession();
}
