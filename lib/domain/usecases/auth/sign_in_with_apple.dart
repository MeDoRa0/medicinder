import '../../../data/datasources/auth/apple_auth_provider_data_source.dart';
import '../../entities/auth/app_entry_session.dart';
import '../../entities/sync/auth_session.dart';
import '../../repositories/auth_repository.dart';

class SignInWithApple {
  final AuthRepository _repository;

  const SignInWithApple(this._repository);

  Future<AppleAuthAvailability> getAvailability() {
    return _repository.getAppleAvailability();
  }

  Future<AppEntrySession> call() async {
    final session = await _repository.signInForSync(providerId: 'apple.com');
    if (session.status == AuthSessionStatus.ready &&
        session.providerId == 'apple.com') {
      return const AppEntrySession.authenticated(entryMode: AppEntryMode.apple);
    }

    if (session.status == AuthSessionStatus.signedOut) {
      return const AppEntrySession.unresolved();
    }

    return AppEntrySession.failure(
      failureCode: session.failureCode ?? 'APPLE_SIGN_IN_FAILED',
      failureMessage: session.failureMessage,
      restoredFromStorage: false,
    );
  }
}
