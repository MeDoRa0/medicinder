import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:medicinder/data/datasources/auth/google_auth_provider_data_source.dart';

void main() {
  group('PlatformGoogleAuthProviderDataSource', () {
    test('returns unsupported when the runner is not supported', () async {
      final dataSource = PlatformGoogleAuthProviderDataSource(
        platformSupportResolver: () => false,
        client: _FakeGoogleAuthClient(),
      );

      final result = await dataSource.signIn();

      expect(result.status, GoogleAuthProviderStatus.unsupported);
      expect(result.failureCode, 'GOOGLE_SIGN_IN_UNSUPPORTED');
    });

    test('returns cancelled when the user dismisses Google sign-in', () async {
      final dataSource = PlatformGoogleAuthProviderDataSource(
        platformSupportResolver: () => true,
        client: _FakeGoogleAuthClient(authentication: null),
      );

      final result = await dataSource.signIn();

      expect(result.status, GoogleAuthProviderStatus.cancelled);
      expect(result.failureCode, 'GOOGLE_SIGN_IN_CANCELLED');
    });

    test('returns failure when Google credentials are incomplete', () async {
      final dataSource = PlatformGoogleAuthProviderDataSource(
        platformSupportResolver: () => true,
        client: _FakeGoogleAuthClient(
          authentication: const _FakeGoogleSignInAuthentication(),
        ),
      );

      final result = await dataSource.signIn();

      expect(result.status, GoogleAuthProviderStatus.failure);
      expect(result.failureCode, 'GOOGLE_ID_TOKEN_MISSING');
    });

    test('returns tokens when Google sign-in succeeds', () async {
      final dataSource = PlatformGoogleAuthProviderDataSource(
        platformSupportResolver: () => true,
        client: _FakeGoogleAuthClient(
          authentication: const _FakeGoogleSignInAuthentication(
            idToken: 'id-token',
            accessToken: 'access-token',
          ),
        ),
      );

      final result = await dataSource.signIn();

      expect(result.status, GoogleAuthProviderStatus.success);
      expect(result.idToken, 'id-token');
      expect(result.accessToken, 'access-token');
    });
  });
}

class _FakeGoogleAuthClient implements GoogleAuthClient {
  final GoogleSignInAuthentication? authentication;

  _FakeGoogleAuthClient({this.authentication});

  @override
  Future<GoogleSignInAuthentication?> signIn() async => authentication;

  @override
  Future<void> signOut() async {}
}

class _FakeGoogleSignInAuthentication implements GoogleSignInAuthentication {
  @override
  final String? idToken;

  @override
  final String? accessToken;

  const _FakeGoogleSignInAuthentication({this.idToken, this.accessToken});

  @override
  String? get serverAuthCode => null;
}
