import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../domain/entities/sync/auth_session.dart';
import '../../../domain/entities/sync/sync_status_view_state.dart';
import '../../../domain/entities/sync/user_sync_profile.dart';
import '../sync_state_local_data_source.dart';
import 'apple_auth_provider_data_source.dart';
import 'google_auth_provider_data_source.dart';

abstract class AuthRemoteDataSource {
  Stream<AuthSession> watchSession();
  Future<AuthSession> getCurrentSession();
  Future<AppleAuthAvailability> getAppleAvailability();
  Future<AuthSession> signInForSync({String? providerId});
  Future<void> signOut();
}

class AuthGatewayException implements Exception {
  final String code;
  final String? message;

  const AuthGatewayException(this.code, [this.message]);
}

class AuthGatewayUser {
  final String uid;
  final String? email;
  final String? displayName;
  final DateTime? creationTime;
  final List<String> providerIds;

  const AuthGatewayUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.creationTime,
    required this.providerIds,
  });
}

abstract class AuthGateway {
  AuthGatewayUser? get currentUser;
  Stream<AuthGatewayUser?> authStateChanges();
  Future<AuthGatewayUser?> signInAnonymously();
  Future<AuthGatewayUser?> signInWithGoogle({
    required String idToken,
    String? accessToken,
  });
  Future<AuthGatewayUser?> signInWithApple({
    required String idToken,
    required String rawNonce,
  });
  Future<void> signOut();
}

abstract class AuthWorkspaceStore {
  Future<void> ensureWorkspaceReady(
    AuthGatewayUser user, {
    String? stableIdentity,
    String? email,
    String? displayName,
  });
}

abstract class AuthSessionProfileStore {
  Future<void> saveProfile(UserSyncProfile profile);
}

class FirebaseAuthGateway implements AuthGateway {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthGateway(this._firebaseAuth);

  @override
  AuthGatewayUser? get currentUser => _firebaseAuth.currentUser == null
      ? null
      : _toUser(_firebaseAuth.currentUser!);

  @override
  Stream<AuthGatewayUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user == null) {
        return null;
      }
      return _toUser(user);
    });
  }

  @override
  Future<AuthGatewayUser?> signInAnonymously() async {
    try {
      final credential = await _firebaseAuth.signInAnonymously();
      return credential.user == null ? null : _toUser(credential.user!);
    } on FirebaseAuthException catch (error) {
      throw AuthGatewayException(error.code, error.message);
    }
  }

  @override
  Future<AuthGatewayUser?> signInWithApple({
    required String idToken,
    required String rawNonce,
  }) async {
    try {
      final credential = OAuthProvider('apple.com').credential(
        idToken: idToken,
        rawNonce: rawNonce,
      );
      final result = await _firebaseAuth.signInWithCredential(credential);
      return result.user == null ? null : _toUser(result.user!);
    } on FirebaseAuthException catch (error) {
      throw AuthGatewayException(error.code, error.message);
    }
  }

  @override
  Future<AuthGatewayUser?> signInWithGoogle({
    required String idToken,
    String? accessToken,
  }) async {
    try {
      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );
      final result = await _firebaseAuth.signInWithCredential(credential);
      return result.user == null ? null : _toUser(result.user!);
    } on FirebaseAuthException catch (error) {
      throw AuthGatewayException(error.code, error.message);
    }
  }

  @override
  Future<void> signOut() => _firebaseAuth.signOut();

  AuthGatewayUser _toUser(User user) {
    final providerIds = user.providerData
        .map((item) => item.providerId)
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return AuthGatewayUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      creationTime: user.metadata.creationTime,
      providerIds: providerIds,
    );
  }
}

class FirestoreAuthWorkspaceStore implements AuthWorkspaceStore {
  final FirebaseFirestore Function() _firestoreProvider;

  FirestoreAuthWorkspaceStore(this._firestoreProvider);

  @override
  Future<void> ensureWorkspaceReady(
    AuthGatewayUser user, {
    String? stableIdentity,
    String? email,
    String? displayName,
  }) async {
    final firestore = _firestoreProvider();
    final userDoc = firestore.collection('users').doc(user.uid);
    final profileDoc = userDoc.collection('profile').doc('summary');
    final now = DateTime.now();
    final batch = firestore.batch();
    final sanitizedDisplayName = displayName?.trim();
    final sanitizedEmail = email?.trim();

    batch.set(userDoc, {
      'userId': user.uid,
      'workspaceReady': true,
      'updatedAt': now.toIso8601String(),
    }, SetOptions(merge: true));

    final profileData = <String, dynamic>{
      'userId': user.uid,
      'providerIds': user.providerIds,
      'createdAt': user.creationTime?.toIso8601String() ?? now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'status': 'active',
      'workspaceReady': true,
      'stableIdentity': stableIdentity ?? user.uid,
    };
    if (sanitizedEmail != null && sanitizedEmail.isNotEmpty) {
      profileData['email'] = sanitizedEmail;
    }
    if (sanitizedDisplayName != null && sanitizedDisplayName.isNotEmpty) {
      profileData['displayName'] = sanitizedDisplayName;
    }

    batch.set(profileDoc, profileData, SetOptions(merge: true));
    await batch.commit();
  }
}

class SyncStateAuthSessionProfileStore implements AuthSessionProfileStore {
  final SyncStateLocalDataSource _syncStateLocalDataSource;

  SyncStateAuthSessionProfileStore(this._syncStateLocalDataSource);

  @override
  Future<void> saveProfile(UserSyncProfile profile) {
    return _syncStateLocalDataSource.saveProfile(profile);
  }
}

class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  final AuthGateway _authGateway;
  final AuthWorkspaceStore _workspaceStore;
  final GoogleAuthProviderDataSource _googleAuthProviderDataSource;
  final AppleAuthProviderDataSource _appleAuthProviderDataSource;
  final AuthSessionProfileStore _profileStore;

  FirebaseAuthRemoteDataSource(
    FirebaseAuth firebaseAuth,
    FirebaseFirestore Function() firestoreProvider,
    AppleAuthProviderDataSource appleAuthProviderDataSource,
    GoogleAuthProviderDataSource googleAuthProviderDataSource,
    SyncStateLocalDataSource syncStateLocalDataSource,
  ) : this.withGateways(
          authGateway: FirebaseAuthGateway(firebaseAuth),
          workspaceStore: FirestoreAuthWorkspaceStore(firestoreProvider),
          appleAuthProviderDataSource: appleAuthProviderDataSource,
          googleAuthProviderDataSource: googleAuthProviderDataSource,
          profileStore: SyncStateAuthSessionProfileStore(syncStateLocalDataSource),
        );

  FirebaseAuthRemoteDataSource.withGateways({
    required AuthGateway authGateway,
    required AuthWorkspaceStore workspaceStore,
    required AppleAuthProviderDataSource appleAuthProviderDataSource,
    required GoogleAuthProviderDataSource googleAuthProviderDataSource,
    required AuthSessionProfileStore profileStore,
  }) : _authGateway = authGateway,
       _workspaceStore = workspaceStore,
       _appleAuthProviderDataSource = appleAuthProviderDataSource,
       _googleAuthProviderDataSource = googleAuthProviderDataSource,
       _profileStore = profileStore;

  @override
  Future<AuthSession> getCurrentSession() async {
    final user = _authGateway.currentUser;
    if (user == null) {
      return const AuthSession.signedOut();
    }
    return _resolveWorkspaceSession(user);
  }

  @override
  Future<AppleAuthAvailability> getAppleAvailability() {
    return _appleAuthProviderDataSource.getAvailability();
  }

  @override
  Future<AuthSession> signInForSync({String? providerId}) async {
    if (providerId == 'google.com') {
      return _signInWithGoogle();
    }
    if (providerId == 'apple.com') {
      return _signInWithApple();
    }

    try {
      final user = await _authGateway.signInAnonymously();
      if (user == null) {
        return const AuthSession.failed(
          failureCode: 'AUTH_USER_MISSING',
          failureMessage: 'Authentication succeeded without a user session.',
        );
      }
      return _resolveWorkspaceSession(user);
    } on AuthGatewayException catch (error) {
      return AuthSession.failed(
        failureCode: error.code,
        failureMessage: error.message ?? 'Authentication failed.',
      );
    } catch (error, stack) {
      log(
        'signInForSync unexpected error: $error',
        name: 'FirebaseAuthRemoteDataSource',
        error: error,
        stackTrace: stack,
      );
      return AuthSession.failed(
        failureCode: 'unknown_error',
        failureMessage: error.toString(),
      );
    }
  }

  @override
  Future<void> signOut() async {
    await _googleAuthProviderDataSource.signOut();
    await _authGateway.signOut();
  }

  @override
  Stream<AuthSession> watchSession() {
    return _authGateway.authStateChanges().asyncExpand((user) async* {
      if (user == null) {
        yield const AuthSession.signedOut();
        return;
      }
      yield AuthSession.workspaceInitializing(
        user.uid,
        providerId: _resolveProviderId(user),
      );
      yield await _resolveWorkspaceSession(user);
    });
  }

  Future<AuthSession> _resolveWorkspaceSession(
    AuthGatewayUser user, {
    String? stableIdentity,
    String? email,
    String? displayName,
  }) async {
    final providerId = _resolveProviderId(user);
    await _saveLocalProfile(
      user,
      statusViewState: SyncStatusViewState.workspaceInitializing,
      workspaceReady: false,
    );
    try {
      await _workspaceStore.ensureWorkspaceReady(
        user,
        stableIdentity: stableIdentity,
        email: email,
        displayName: displayName,
      );
      await _saveLocalProfile(
        user,
        statusViewState: SyncStatusViewState.ready,
        workspaceReady: true,
      );
      return AuthSession.ready(user.uid, providerId: providerId);
    } on FirebaseException catch (error) {
      final isAccessDenied = error.code == 'permission-denied';
      await _saveLocalProfile(
        user,
        statusViewState: isAccessDenied
            ? SyncStatusViewState.accessDenied
            : SyncStatusViewState.syncFailed,
        workspaceReady: false,
        lastSyncErrorCode: error.code,
      );
      if (isAccessDenied) {
        return AuthSession.accessDenied(
          user.uid,
          providerId: providerId,
          failureCode: error.code,
          failureMessage: error.message ?? 'Cloud workspace access was denied.',
        );
      }
      return AuthSession.failed(
        userId: user.uid,
        providerId: providerId,
        failureCode: error.code,
        failureMessage:
            error.message ?? 'Cloud workspace initialization failed.',
      );
    }
  }

  Future<AuthSession> _signInWithApple() async {
    log('Apple sign-in started.', name: 'FirebaseAuthRemoteDataSource');
    final providerResult = await _appleAuthProviderDataSource.signIn();
    switch (providerResult.status) {
      case AppleAuthProviderStatus.cancelled:
        log('Apple sign-in cancelled.', name: 'FirebaseAuthRemoteDataSource');
        return const AuthSession.failed(
          failureCode: 'APPLE_SIGN_IN_CANCELLED',
          failureMessage: 'Apple sign-in was cancelled.',
        );
      case AppleAuthProviderStatus.unavailable:
        log(
          'Apple sign-in unavailable on this device.',
          name: 'FirebaseAuthRemoteDataSource',
        );
        return const AuthSession.failed(
          failureCode: 'APPLE_SIGN_IN_UNAVAILABLE',
          failureMessage: 'Apple sign-in is unavailable on this device.',
        );
      case AppleAuthProviderStatus.failure:
        log(
          'Apple sign-in provider failure code=${providerResult.failureCode}',
          name: 'FirebaseAuthRemoteDataSource',
        );
        return AuthSession.failed(
          failureCode: providerResult.failureCode ?? 'APPLE_SIGN_IN_FAILED',
          failureMessage:
              providerResult.failureMessage ?? 'Apple sign-in failed.',
        );
      case AppleAuthProviderStatus.success:
        break;
    }

    try {
      final user = await _authGateway.signInWithApple(
        idToken: providerResult.identityToken!,
        rawNonce: providerResult.rawNonce!,
      );
      if (user == null) {
        return const AuthSession.failed(
          failureCode: 'AUTH_USER_MISSING',
          failureMessage: 'Authentication succeeded without a user session.',
        );
      }
      final displayName = _composeDisplayName(
        providerResult.givenName,
        providerResult.familyName,
      );
      return _resolveWorkspaceSession(
        user,
        stableIdentity: providerResult.userIdentifier,
        email: providerResult.email,
        displayName: displayName,
      );
    } on AuthGatewayException catch (error) {
      if (_isAppleProviderConflict(error)) {
        log(
          'Apple sign-in blocked by credential conflict.',
          name: 'FirebaseAuthRemoteDataSource',
        );
        return const AuthSession.failed(
          failureCode: 'APPLE_SIGN_IN_CONFLICT',
          failureMessage: 'Use the original sign-in method for this account.',
        );
      }
      log(
        'Apple credential exchange failed code=${error.code}',
        name: 'FirebaseAuthRemoteDataSource',
      );
      return AuthSession.failed(
        failureCode: error.code,
        failureMessage: 'Apple sign-in failed.',
      );
    } catch (error, stackTrace) {
      log(
        'Apple sign-in unexpected failure.',
        name: 'FirebaseAuthRemoteDataSource',
        error: error,
        stackTrace: stackTrace,
      );
      return const AuthSession.failed(
        failureCode: 'APPLE_SIGN_IN_FAILED',
        failureMessage: 'Apple sign-in failed.',
      );
    }
  }

  Future<AuthSession> _signInWithGoogle() async {
    log('Google sign-in started.', name: 'FirebaseAuthRemoteDataSource');
    final providerResult = await _googleAuthProviderDataSource.signIn();
    switch (providerResult.status) {
      case GoogleAuthProviderStatus.cancelled:
        log('Google sign-in cancelled.', name: 'FirebaseAuthRemoteDataSource');
        return const AuthSession.failed(
          failureCode: 'GOOGLE_SIGN_IN_CANCELLED',
          failureMessage: 'Google sign-in was cancelled.',
        );
      case GoogleAuthProviderStatus.unsupported:
        log(
          'Google sign-in blocked on unsupported runner.',
          name: 'FirebaseAuthRemoteDataSource',
        );
        return const AuthSession.failed(
          failureCode: 'GOOGLE_SIGN_IN_UNSUPPORTED',
          failureMessage: 'Google sign-in is unavailable on this runner.',
        );
      case GoogleAuthProviderStatus.failure:
        log(
          'Google sign-in provider failure code=${providerResult.failureCode}',
          name: 'FirebaseAuthRemoteDataSource',
        );
        return AuthSession.failed(
          failureCode: providerResult.failureCode ?? 'GOOGLE_SIGN_IN_FAILED',
          failureMessage:
              providerResult.failureMessage ?? 'Google sign-in failed.',
        );
      case GoogleAuthProviderStatus.success:
        break;
    }

    try {
      final user = await _authGateway.signInWithGoogle(
        idToken: providerResult.idToken!,
        accessToken: providerResult.accessToken,
      );
      if (user == null) {
        return const AuthSession.failed(
          failureCode: 'AUTH_USER_MISSING',
          failureMessage: 'Authentication succeeded without a user session.',
        );
      }
      return _resolveWorkspaceSession(user);
    } on AuthGatewayException catch (error) {
      log(
        'Google credential exchange failed code=${error.code}',
        name: 'FirebaseAuthRemoteDataSource',
      );
      return AuthSession.failed(
        failureCode: error.code,
        failureMessage: 'Google sign-in failed.',
      );
    } catch (error, stackTrace) {
      log(
        'Google sign-in unexpected failure.',
        name: 'FirebaseAuthRemoteDataSource',
        error: error,
        stackTrace: stackTrace,
      );
      return const AuthSession.failed(
        failureCode: 'GOOGLE_SIGN_IN_FAILED',
        failureMessage: 'Google sign-in failed.',
      );
    }
  }

  Future<void> _saveLocalProfile(
    AuthGatewayUser user, {
    required SyncStatusViewState statusViewState,
    required bool workspaceReady,
    String? lastSyncErrorCode,
  }) {
    final now = DateTime.now();
    return _profileStore.saveProfile(
      UserSyncProfile(
        userId: user.uid,
        providerIds: user.providerIds,
        syncEnabled: true,
        workspaceReady: workspaceReady,
        createdAt: user.creationTime ?? now,
        updatedAt: now,
        lastSuccessfulSyncAt: workspaceReady ? now : null,
        lastAttemptedSyncAt: now,
        lastSyncErrorCode: lastSyncErrorCode,
        statusViewState: statusViewState,
      ),
    );
  }

  String _resolveProviderId(AuthGatewayUser user) {
    if (user.providerIds.isEmpty) {
      return 'anonymous';
    }
    return user.providerIds.first;
  }

  String? _composeDisplayName(String? givenName, String? familyName) {
    final parts = [givenName?.trim(), familyName?.trim()]
        .whereType<String>()
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return null;
    }
    return parts.join(' ');
  }

  bool _isAppleProviderConflict(AuthGatewayException error) {
    if (error.code == 'account-exists-with-different-credential') {
      return true;
    }
    final message = error.message?.toLowerCase();
    if (message == null || message.isEmpty) {
      return false;
    }
    return message.contains('different credential') ||
        (message.contains('already exists') &&
            message.contains('different sign-in provider'));
  }
}

class DisabledAuthRemoteDataSource implements AuthRemoteDataSource {
  const DisabledAuthRemoteDataSource();

  @override
  Future<AuthSession> getCurrentSession() async =>
      const AuthSession.signedOut();

  @override
  Future<AppleAuthAvailability> getAppleAvailability() async =>
      AppleAuthAvailability.unsupportedRunner;

  @override
  Future<AuthSession> signInForSync({String? providerId}) async =>
      const AuthSession.failed(
        failureCode: 'CLOUD_SYNC_DISABLED',
        failureMessage: 'Cloud sync backend is not configured.',
      );

  @override
  Future<void> signOut() async {}

  @override
  Stream<AuthSession> watchSession() async* {
    yield const AuthSession.signedOut();
  }
}
