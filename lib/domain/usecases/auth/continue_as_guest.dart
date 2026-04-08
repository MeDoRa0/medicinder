import '../../entities/auth/app_entry_session.dart';
import '../../repositories/app_entry_repository.dart';

class ContinueAsGuest {
  final AppEntryRepository _repository;

  const ContinueAsGuest(this._repository);

  Future<AppEntrySession> call() async {
    await _repository.persistGuestMode();
    return const AppEntrySession.guest();
  }
}
