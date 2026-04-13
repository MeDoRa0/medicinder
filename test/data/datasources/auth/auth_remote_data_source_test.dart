import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/data/datasources/auth/apple_auth_provider_data_source.dart';
import 'package:medicinder/data/datasources/auth/auth_remote_data_source.dart';
import 'package:medicinder/data/datasources/auth/google_auth_provider_data_source.dart';
import 'package:medicinder/domain/entities/sync/auth_session.dart';
import 'package:medicinder/domain/entities/sync/sync_status_view_state.dart';
import 'package:medicinder/domain/entities/sync/user_sync_profile.dart';

void main() {
  group('FirebaseAuthRemoteDataSource Apple flow', () {
    test('signs in with Apple and bootstraps the workspace', () async {
      final workspaceStore = _FakeWorkspaceStore();
      final gateway = _FakeAuthGateway(
        signedInAppleUser: const AuthGatewayUser(
          uid: 'user-123',
          email: 'apple@example.com',
          displayName: null,
          creationTime: null,
          providerIds: ['apple.com'],
        ),
      );
      final dataSource = FirebaseAuthRemoteDataSource.withGateways(
        authGateway: gateway,
        workspaceStore: workspaceStore,
        appleAuthProviderDataSource: _FakeAppleAuthProviderDataSource(
          result: const AppleAuthProviderResult.success(
            identityToken: 'token',
            rawNonce: 'raw-nonce',
            authorizationCode: 'auth-code',
            userIdentifier: 'stable-apple-id',
            email: 'apple@example.com',
            givenName: 'Med',
            familyName: 'Icinder',
          ),
        ),
        googleAuthProviderDataSource: _FakeGoogleAuthProviderDataSource(),
        profileStore: _FakeProfileStore(),
      );

      final session = await dataSource.signInForSync(providerId: 'apple.com');

      expect(
        session,
        const AuthSession.ready('user-123', providerId: 'apple.com'),
      );
      expect(gateway.lastAppleRawNonce, 'raw-nonce');
      expect(workspaceStore.lastStableIdentity, 'stable-apple-id');
      expect(workspaceStore.lastEmail, 'apple@example.com');
      expect(workspaceStore.lastDisplayName, 'Med Icinder');
    });

    test(
      'preserves the stable Apple identity when email and name are absent',
      () async {
        final workspaceStore = _FakeWorkspaceStore();
        final dataSource = FirebaseAuthRemoteDataSource.withGateways(
          authGateway: _FakeAuthGateway(
            signedInAppleUser: const AuthGatewayUser(
              uid: 'user-123',
              email: null,
              displayName: null,
              creationTime: null,
              providerIds: ['apple.com'],
            ),
          ),
          workspaceStore: workspaceStore,
          appleAuthProviderDataSource: _FakeAppleAuthProviderDataSource(
            result: const AppleAuthProviderResult.success(
              identityToken: 'token',
              rawNonce: 'raw-nonce',
              authorizationCode: 'auth-code',
              userIdentifier: 'stable-apple-id',
            ),
          ),
          googleAuthProviderDataSource: _FakeGoogleAuthProviderDataSource(),
          profileStore: _FakeProfileStore(),
        );

        final session = await dataSource.signInForSync(providerId: 'apple.com');

        expect(
          session,
          const AuthSession.ready('user-123', providerId: 'apple.com'),
        );
        expect(workspaceStore.lastStableIdentity, 'stable-apple-id');
        expect(workspaceStore.lastEmail, isNull);
        expect(workspaceStore.lastDisplayName, isNull);
      },
    );

    test(
      'treats Apple credential conflicts as user-facing sign-in failures',
      () async {
        final gateway = _FakeAuthGateway(
          appleSignInException: const AuthGatewayException(
            'account-exists-with-different-credential',
            'An account already exists with the same email address but different sign-in credentials.',
          ),
        );
        final dataSource = FirebaseAuthRemoteDataSource.withGateways(
          authGateway: gateway,
          workspaceStore: _FakeWorkspaceStore(),
          appleAuthProviderDataSource: _FakeAppleAuthProviderDataSource(
            result: const AppleAuthProviderResult.success(
              identityToken: 'token',
              rawNonce: 'raw-nonce',
              authorizationCode: 'auth-code',
              userIdentifier: 'stable-apple-id',
              email: 'apple@example.com',
            ),
          ),
          googleAuthProviderDataSource: _FakeGoogleAuthProviderDataSource(),
          profileStore: _FakeProfileStore(),
        );

        final session = await dataSource.signInForSync(providerId: 'apple.com');

        expect(session.status, AuthSessionStatus.failed);
        expect(session.failureCode, 'APPLE_SIGN_IN_CONFLICT');
        expect(gateway.appleSignInCalls, 1);
      },
    );

    test('treats workspace bootstrap failures as sign-in failures', () async {
      final dataSource = FirebaseAuthRemoteDataSource.withGateways(
        authGateway: _FakeAuthGateway(
          signedInAppleUser: const AuthGatewayUser(
            uid: 'user-123',
            email: 'apple@example.com',
            displayName: null,
            creationTime: null,
            providerIds: ['apple.com'],
          ),
        ),
        workspaceStore: _FakeWorkspaceStore(
          error: FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
            message: 'blocked',
          ),
        ),
        appleAuthProviderDataSource: _FakeAppleAuthProviderDataSource(
          result: const AppleAuthProviderResult.success(
            identityToken: 'token',
            rawNonce: 'raw-nonce',
            authorizationCode: 'auth-code',
            userIdentifier: 'stable-apple-id',
            email: 'apple@example.com',
          ),
        ),
        googleAuthProviderDataSource: _FakeGoogleAuthProviderDataSource(),
        profileStore: _FakeProfileStore(),
      );

      final session = await dataSource.signInForSync(providerId: 'apple.com');

      expect(session.status, AuthSessionStatus.accessDenied);
      expect(session.failureCode, 'permission-denied');
    });
  });
}

class _FakeAuthGateway implements AuthGateway {
  final AuthGatewayUser? signedInAppleUser;
  final AuthGatewayUser? currentUserValue;
  final AuthGatewayException? appleSignInException;
  String? lastAppleRawNonce;
  int appleSignInCalls = 0;

  _FakeAuthGateway({
    this.signedInAppleUser,
    this.currentUserValue,
    this.appleSignInException,
  });

  @override
  AuthGatewayUser? get currentUser => currentUserValue;

  @override
  Stream<AuthGatewayUser?> authStateChanges() async* {
    yield currentUserValue;
  }

  @override
  Future<AuthGatewayUser?> signInAnonymously() async => currentUserValue;

  @override
  Future<AuthGatewayUser?> signInWithApple({
    required String idToken,
    required String rawNonce,
  }) async {
    appleSignInCalls += 1;
    lastAppleRawNonce = rawNonce;
    if (appleSignInException != null) {
      throw appleSignInException!;
    }
    return signedInAppleUser;
  }

  @override
  Future<AuthGatewayUser?> signInWithGoogle({
    required String idToken,
    String? accessToken,
  }) async => currentUserValue;

  @override
  Future<void> signOut() async {}
}

class _FakeWorkspaceStore implements AuthWorkspaceStore {
  final FirebaseException? error;
  String? lastStableIdentity;
  String? lastEmail;
  String? lastDisplayName;

  _FakeWorkspaceStore({this.error});

  @override
  Future<void> ensureWorkspaceReady(
    AuthGatewayUser user, {
    String? stableIdentity,
    String? email,
    String? displayName,
  }) async {
    if (error != null) {
      throw error!;
    }
    lastStableIdentity = stableIdentity;
    lastEmail = email;
    lastDisplayName = displayName;
  }
}

class _FakeProfileStore implements AuthSessionProfileStore {
  final List<UserSyncProfile> profiles = [];

  @override
  Future<void> saveProfile(UserSyncProfile profile) async {
    profiles.add(profile);
    expect(profile.statusViewState, isNot(SyncStatusViewState.syncing));
  }
}

class _FakeAppleAuthProviderDataSource implements AppleAuthProviderDataSource {
  final AppleAuthProviderResult result;

  _FakeAppleAuthProviderDataSource({required this.result});

  @override
  Future<AppleAuthAvailability> getAvailability() async =>
      AppleAuthAvailability.supported;

  @override
  Future<AppleAuthProviderResult> signIn() async => result;
}

class _FakeGoogleAuthProviderDataSource
    implements GoogleAuthProviderDataSource {
  @override
  bool get isSupported => true;

  @override
  Future<GoogleAuthProviderResult> signIn() async =>
      const GoogleAuthProviderResult.failure(failureCode: 'GOOGLE_UNUSED');

  @override
  Future<void> signOut() async {}
}
