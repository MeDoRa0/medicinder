import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../domain/entities/sync/auth_session.dart';
import '../../../domain/entities/sync/sync_status_view_state.dart';
import '../../../domain/entities/sync/user_sync_profile.dart';
import 'google_auth_provider_data_source.dart';
import '../sync_state_local_data_source.dart';

abstract class AuthRemoteDataSource {
  Stream<AuthSession> watchSession();
  Future<AuthSession> getCurrentSession();
  Future<AuthSession> signInForSync({String? providerId});
  Future<void> signOut();
}

class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore Function() _firestoreProvider;
  final GoogleAuthProviderDataSource _googleAuthProviderDataSource;
  final SyncStateLocalDataSource _syncStateLocalDataSource;

  FirebaseAuthRemoteDataSource(
    this._firebaseAuth,
    this._firestoreProvider,
    this._googleAuthProviderDataSource,
    this._syncStateLocalDataSource,
  );

  @override
  Future<AuthSession> getCurrentSession() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return const AuthSession.signedOut();
    }
    return _resolveWorkspaceSession(user);
  }

  @override
  Future<AuthSession> signInForSync({String? providerId}) async {
    if (providerId == 'google.com') {
      return _signInWithGoogle();
    }

    try {
      final credential = await _firebaseAuth.signInAnonymously();
      final user = credential.user;
      if (user == null) {
        return const AuthSession.failed(
          failureCode: 'AUTH_USER_MISSING',
          failureMessage: 'Authentication succeeded without a user session.',
        );
      }
      return _resolveWorkspaceSession(user);
    } on FirebaseAuthException catch (error) {
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
    await _firebaseAuth.signOut();
  }

  @override
  Stream<AuthSession> watchSession() {
    return _firebaseAuth.authStateChanges().asyncExpand((user) async* {
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

  Future<AuthSession> _resolveWorkspaceSession(User user) async {
    final providerId = _resolveProviderId(user);
    await _saveLocalProfile(
      user,
      statusViewState: SyncStatusViewState.workspaceInitializing,
      workspaceReady: false,
    );
    try {
      await _ensureWorkspaceReady(user);
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
      final credential = GoogleAuthProvider.credential(
        idToken: providerResult.idToken,
        accessToken: providerResult.accessToken,
      );
      final result = await _firebaseAuth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) {
        return const AuthSession.failed(
          failureCode: 'AUTH_USER_MISSING',
          failureMessage: 'Authentication succeeded without a user session.',
        );
      }
      return _resolveWorkspaceSession(user);
    } on FirebaseAuthException catch (error) {
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
      return AuthSession.failed(
        failureCode: 'GOOGLE_SIGN_IN_FAILED',
        failureMessage: 'Google sign-in failed.',
      );
    }
  }

  Future<void> _ensureWorkspaceReady(User user) async {
    final firestore = _firestoreProvider();
    final userDoc = firestore.collection('users').doc(user.uid);
    final profileDoc = userDoc.collection('profile').doc('summary');
    final now = DateTime.now();
    final batch = firestore.batch();

    batch.set(userDoc, {
      'userId': user.uid,
      'workspaceReady': true,
      'updatedAt': now.toIso8601String(),
    }, SetOptions(merge: true));

    batch.set(profileDoc, {
      'userId': user.uid,
      'providerIds': user.providerData.map((item) => item.providerId).toList(),
      'createdAt':
          user.metadata.creationTime?.toIso8601String() ??
          now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'status': 'active',
      'workspaceReady': true,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> _saveLocalProfile(
    User user, {
    required SyncStatusViewState statusViewState,
    required bool workspaceReady,
    String? lastSyncErrorCode,
  }) {
    final now = DateTime.now();
    return _syncStateLocalDataSource.saveProfile(
      UserSyncProfile(
        userId: user.uid,
        providerIds: user.providerData.map((item) => item.providerId).toList(),
        syncEnabled: true,
        workspaceReady: workspaceReady,
        createdAt: user.metadata.creationTime ?? now,
        updatedAt: now,
        lastSuccessfulSyncAt: workspaceReady ? now : null,
        lastAttemptedSyncAt: now,
        lastSyncErrorCode: lastSyncErrorCode,
        statusViewState: statusViewState,
      ),
    );
  }

  String _resolveProviderId(User user) {
    final providerIds = user.providerData
        .map((item) => item.providerId)
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (providerIds.isEmpty) {
      return 'anonymous';
    }
    return providerIds.first;
  }
}

class DisabledAuthRemoteDataSource implements AuthRemoteDataSource {
  const DisabledAuthRemoteDataSource();

  @override
  Future<AuthSession> getCurrentSession() async =>
      const AuthSession.signedOut();

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
