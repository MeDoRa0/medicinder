import '../../entities/auth/app_entry_session.dart';
import '../../entities/sync/auth_session.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/app_entry_repository.dart';

class RestoreAppEntrySession {
  final AuthRepository _authRepository;
  final AppEntryRepository _appEntryRepository;

  const RestoreAppEntrySession(this._authRepository, this._appEntryRepository);

  Future<AppEntrySession> call() async {
    final currentSession = await _authRepository.getCurrentSession();
    if (currentSession.status == AuthSessionStatus.ready) {
      if (currentSession.providerId == 'google.com') {
        return const AppEntrySession.authenticated(
          entryMode: AppEntryMode.google,
          restoredFromStorage: true,
        );
      }
      if (currentSession.providerId == 'apple.com') {
        return const AppEntrySession.authenticated(
          entryMode: AppEntryMode.apple,
          restoredFromStorage: true,
        );
      }
      return AppEntrySession.failure(
        failureCode: 'UNSUPPORTED_ENTRY_MODE',
        failureMessage: currentSession.providerId,
        restoredFromStorage: true,
      );
    }

    if (currentSession.status != AuthSessionStatus.signedOut) {
      return AppEntrySession.failure(
        failureCode:
            currentSession.failureCode ?? 'AUTH_RESTORE_UNAVAILABLE',
        failureMessage: currentSession.failureMessage,
        restoredFromStorage: true,
      );
    }

    final resolvedMode = await _appEntryRepository.readResolvedEntryMode();
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
