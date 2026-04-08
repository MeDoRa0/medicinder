import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum GoogleAuthProviderStatus { success, cancelled, unsupported, failure }

class GoogleAuthProviderResult {
  final GoogleAuthProviderStatus status;
  final String? idToken;
  final String? accessToken;
  final String? failureCode;
  final String? failureMessage;

  const GoogleAuthProviderResult._({
    required this.status,
    this.idToken,
    this.accessToken,
    this.failureCode,
    this.failureMessage,
  });

  const GoogleAuthProviderResult.success({
    required String idToken,
    String? accessToken,
  }) : this._(
         status: GoogleAuthProviderStatus.success,
         idToken: idToken,
         accessToken: accessToken,
       );

  const GoogleAuthProviderResult.cancelled()
    : this._(
        status: GoogleAuthProviderStatus.cancelled,
        failureCode: 'GOOGLE_SIGN_IN_CANCELLED',
      );

  const GoogleAuthProviderResult.unsupported()
    : this._(
        status: GoogleAuthProviderStatus.unsupported,
        failureCode: 'GOOGLE_SIGN_IN_UNSUPPORTED',
      );

  const GoogleAuthProviderResult.failure({
    required String failureCode,
    String? failureMessage,
  }) : this._(
         status: GoogleAuthProviderStatus.failure,
         failureCode: failureCode,
         failureMessage: failureMessage,
       );
}

abstract class GoogleAuthClient {
  Future<GoogleSignInAuthentication?> signIn();
  Future<void> signOut();
}

class GoogleSignInClient implements GoogleAuthClient {
  final GoogleSignIn _googleSignIn;

  GoogleSignInClient([GoogleSignIn? googleSignIn])
    : _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  Future<GoogleSignInAuthentication?> signIn() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      return null;
    }
    return account.authentication;
  }

  @override
  Future<void> signOut() => _googleSignIn.signOut();
}

abstract class GoogleAuthProviderDataSource {
  bool get isSupported;
  Future<GoogleAuthProviderResult> signIn();
  Future<void> signOut();
}

class PlatformGoogleAuthProviderDataSource
    implements GoogleAuthProviderDataSource {
  final GoogleAuthClient _client;
  final bool Function() _platformSupportResolver;

  PlatformGoogleAuthProviderDataSource({
    GoogleAuthClient? client,
    bool Function()? platformSupportResolver,
  }) : _client = client ?? GoogleSignInClient(),
       _platformSupportResolver =
           platformSupportResolver ?? _defaultPlatformSupportResolver;

  @override
  bool get isSupported => _platformSupportResolver();

  @override
  Future<GoogleAuthProviderResult> signIn() async {
    if (!isSupported) {
      log(
        'Google sign-in blocked on unsupported runner.',
        name: 'GoogleAuthProviderDataSource',
      );
      return const GoogleAuthProviderResult.unsupported();
    }

    try {
      final authentication = await _client.signIn();
      if (authentication == null) {
        return const GoogleAuthProviderResult.cancelled();
      }
      final idToken = authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        return const GoogleAuthProviderResult.failure(
          failureCode: 'GOOGLE_ID_TOKEN_MISSING',
        );
      }
      return GoogleAuthProviderResult.success(
        idToken: idToken,
        accessToken: authentication.accessToken,
      );
    } catch (error, stackTrace) {
      log(
        'Google sign-in provider failure.',
        name: 'GoogleAuthProviderDataSource',
        error: error,
        stackTrace: stackTrace,
      );
      return GoogleAuthProviderResult.failure(
        failureCode: 'GOOGLE_SIGN_IN_FAILED',
        failureMessage: error.runtimeType.toString(),
      );
    }
  }

  @override
  Future<void> signOut() async {
    if (!isSupported) {
      return;
    }
    try {
      await _client.signOut();
    } catch (_) {}
  }

  static bool _defaultPlatformSupportResolver() {
    if (kIsWeb) {
      return false;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }
}
