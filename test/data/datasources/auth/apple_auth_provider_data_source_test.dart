import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/data/datasources/auth/apple_auth_provider_data_source.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

void main() {
  group('PlatformAppleAuthProviderDataSource', () {
    test('reports availability when the iOS runner supports Apple sign-in', () async {
      final dataSource = PlatformAppleAuthProviderDataSource(
        client: _FakeAppleAuthClient(isAvailableResult: true),
        platformSupportResolver: () => true,
      );

      final availability = await dataSource.getAvailability();

      expect(availability, AppleAuthAvailability.supported);
    });

    test('returns unavailable when the device cannot use Apple sign-in', () async {
      final dataSource = PlatformAppleAuthProviderDataSource(
        client: _FakeAppleAuthClient(isAvailableResult: false),
        platformSupportResolver: () => true,
      );

      final availability = await dataSource.getAvailability();

      expect(availability, AppleAuthAvailability.unavailableOnDevice);
    });

    test('returns a successful Apple credential payload', () async {
      final dataSource = PlatformAppleAuthProviderDataSource(
        client: _FakeAppleAuthClient(
          isAvailableResult: true,
          credentialPayload: const AppleAuthorizationCredentialPayload(
            identityToken: 'identity-token',
            authorizationCode: 'authorization-code',
            userIdentifier: 'stable-apple-user',
            email: 'apple@example.com',
            givenName: 'Med',
            familyName: 'Icinder',
          ),
        ),
        platformSupportResolver: () => true,
      );

      final result = await dataSource.signIn();

      expect(result.status, AppleAuthProviderStatus.success);
      expect(result.identityToken, 'identity-token');
      expect(result.authorizationCode, 'authorization-code');
      expect(result.userIdentifier, 'stable-apple-user');
      expect(result.rawNonce, isNotEmpty);
      expect(result.email, 'apple@example.com');
    });

    test('maps Apple cancellation to a stable cancelled result', () async {
      final dataSource = PlatformAppleAuthProviderDataSource(
        client: _FakeAppleAuthClient(
          isAvailableResult: true,
          signInError: SignInWithAppleAuthorizationException(
            code: AuthorizationErrorCode.canceled,
            message: 'cancelled',
          ),
        ),
        platformSupportResolver: () => true,
      );

      final result = await dataSource.signIn();

      expect(result.status, AppleAuthProviderStatus.cancelled);
      expect(result.failureCode, 'APPLE_SIGN_IN_CANCELLED');
    });

    test('maps provider exceptions to a stable failure result', () async {
      final dataSource = PlatformAppleAuthProviderDataSource(
        client: _FakeAppleAuthClient(
          isAvailableResult: true,
          signInError: StateError('provider_failed'),
        ),
        platformSupportResolver: () => true,
      );

      final result = await dataSource.signIn();

      expect(result.status, AppleAuthProviderStatus.failure);
      expect(result.failureCode, 'APPLE_SIGN_IN_FAILED');
    });
  });
}

class _FakeAppleAuthClient implements AppleAuthClient {
  final bool isAvailableResult;
  final AppleAuthorizationCredentialPayload? credentialPayload;
  final Object? signInError;

  _FakeAppleAuthClient({
    required this.isAvailableResult,
    this.credentialPayload,
    this.signInError,
  });

  @override
  Future<AppleAuthorizationCredentialPayload> getAppleIDCredential({
    required String nonce,
  }) async {
    if (signInError != null) {
      throw signInError!;
    }
    return credentialPayload!;
  }

  @override
  Future<bool> isAvailable() async => isAvailableResult;
}
