import '../../entities/auth/app_entry_session.dart';
import '../../repositories/app_entry_repository.dart';

class RestoreAppEntrySession {
  final AppEntryRepository _repository;

  const RestoreAppEntrySession(this._repository);

  Future<AppEntrySession> call() async {
    final resolvedMode = await _repository.readResolvedEntryMode();
    if (resolvedMode == null) {
      return const AppEntrySession.unresolved(restoredFromStorage: true);
    }
    if (resolvedMode == 'guest') {
      return const AppEntrySession.guest(restoredFromStorage: true);
    }
    return AppEntrySession.failure(
      failureCode: 'UNSUPPORTED_ENTRY_MODE',
      failureMessage: resolvedMode,
      restoredFromStorage: true,
    );
  }
}
