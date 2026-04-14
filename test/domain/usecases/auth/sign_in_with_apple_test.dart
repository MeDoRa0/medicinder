import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/data/datasources/auth/apple_auth_provider_data_source.dart';
import 'package:medicinder/domain/entities/auth/app_entry_session.dart';
import 'package:medicinder/domain/entities/sync/auth_session.dart';
import 'package:medicinder/domain/repositories/auth_repository.dart';
import 'package:medicinder/domain/usecases/auth/sign_in_with_apple.dart';

void main() {
  group('SignInWithApple', () {
    test(
      'maps a ready Apple auth session to authenticated app entry',
      () async {
        final repository = _FakeAuthRepository(
          result: const AuthSession.ready('user-123', providerId: 'apple.com'),
        );

        final session = await SignInWithApple(repository)();

        expect(
          session,
          const AppEntrySession.authenticated(entryMode: AppEntryMode.apple),
        );
        expect(repository.lastProviderId, 'apple.com');
      },
    );

    test('maps a failed auth session to app-entry failure', () async {
      final repository = _FakeAuthRepository(
        result: const AuthSession.failed(failureCode: 'APPLE_SIGN_IN_FAILED'),
      );

      final session = await SignInWithApple(repository)();

      expect(session.status, AppEntrySessionStatus.failure);
      expect(session.failureCode, 'APPLE_SIGN_IN_FAILED');
    });

    test('reads Apple availability from the repository', () async {
      final repository = _FakeAuthRepository(
        result: const AuthSession.signedOut(),
        appleAvailability: AppleAuthAvailability.unavailableOnDevice,
      );

      final availability = await SignInWithApple(repository).getAvailability();

      expect(availability, AppleAuthAvailability.unavailableOnDevice);
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
