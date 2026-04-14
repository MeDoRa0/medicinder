import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/data/datasources/auth/apple_auth_provider_data_source.dart';
import 'package:medicinder/domain/entities/auth/app_entry_session.dart';
import 'package:medicinder/domain/entities/sync/auth_session.dart';
import 'package:medicinder/domain/repositories/auth_repository.dart';
import 'package:medicinder/domain/usecases/auth/sign_in_with_google.dart';

void main() {
  group('SignInWithGoogle', () {
    test(
      'maps a ready Google auth session to authenticated app entry',
      () async {
        final repository = _FakeAuthRepository(
          result: const AuthSession.ready('user-123', providerId: 'google.com'),
        );

        final session = await SignInWithGoogle(repository)();

        expect(
          session,
          const AppEntrySession.authenticated(entryMode: AppEntryMode.google),
        );
        expect(repository.lastProviderId, 'google.com');
      },
    );

    test('maps a failed auth session to app-entry failure', () async {
      final repository = _FakeAuthRepository(
        result: const AuthSession.failed(failureCode: 'GOOGLE_SIGN_IN_FAILED'),
      );

      final session = await SignInWithGoogle(repository)();

      expect(session.status, AppEntrySessionStatus.failure);
      expect(session.failureCode, 'GOOGLE_SIGN_IN_FAILED');
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  final AuthSession result;
  final AppleAuthAvailability appleAvailability;
  String? lastProviderId;

  _FakeAuthRepository({
    required this.result,
    this.appleAvailability = AppleAuthAvailability.unsupportedRunner,
  });

  @override
  Future<AuthSession> getCurrentSession() async =>
      const AuthSession.signedOut();

  @override
  Future<AppleAuthAvailability> getAppleAvailability() async =>
      appleAvailability;

  @override
  Future<AuthSession> signInForSync({String? providerId}) async {
    lastProviderId = providerId;
    return result;
  }

  @override
  Future<void> signOutFromSync() async {}

  @override
  Stream<AuthSession> watchSession() async* {
    yield const AuthSession.signedOut();
  }
}
