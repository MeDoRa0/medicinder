import '../../entities/auth/app_entry_session.dart';
import '../../entities/sync/auth_session.dart';
import '../../repositories/auth_repository.dart';

class SignInWithGoogle {
  final AuthRepository _repository;

  const SignInWithGoogle(this._repository);

  Future<AppEntrySession> call() async {
    final session = await _repository.signInForSync(providerId: 'google.com');
    if (session.status == AuthSessionStatus.ready &&
        session.providerId == 'google.com') {
      return const AppEntrySession.authenticated(entryMode: AppEntryMode.google);
    }

    if (session.status == AuthSessionStatus.signedOut) {
      return const AppEntrySession.unresolved();
    }

    return AppEntrySession.failure(
      failureCode: session.failureCode ?? 'GOOGLE_SIGN_IN_FAILED',
      failureMessage: session.failureMessage,
      restoredFromStorage: false,
    );
  }
}
