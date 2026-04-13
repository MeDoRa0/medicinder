import 'dart:convert';
import 'dart:developer';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

enum AppleAuthAvailability { supported, unavailableOnDevice, unsupportedRunner }

enum AppleAuthProviderStatus { success, cancelled, unavailable, failure }

class AppleAuthProviderResult {
  final AppleAuthProviderStatus status;
  final String? identityToken;
  final String? rawNonce;
  final String? authorizationCode;
  final String? userIdentifier;
  final String? email;
  final String? givenName;
  final String? familyName;
  final String? failureCode;
  final String? failureMessage;

  const AppleAuthProviderResult._({
    required this.status,
    this.identityToken,
    this.rawNonce,
    this.authorizationCode,
    this.userIdentifier,
    this.email,
    this.givenName,
    this.familyName,
    this.failureCode,
    this.failureMessage,
  });

  const AppleAuthProviderResult.success({
    required String identityToken,
    required String rawNonce,
    required String authorizationCode,
    required String userIdentifier,
    String? email,
    String? givenName,
    String? familyName,
  }) : this._(
         status: AppleAuthProviderStatus.success,
         identityToken: identityToken,
         rawNonce: rawNonce,
         authorizationCode: authorizationCode,
         userIdentifier: userIdentifier,
         email: email,
         givenName: givenName,
         familyName: familyName,
       );

  const AppleAuthProviderResult.cancelled()
    : this._(
        status: AppleAuthProviderStatus.cancelled,
        failureCode: 'APPLE_SIGN_IN_CANCELLED',
      );

  const AppleAuthProviderResult.unavailable()
    : this._(
        status: AppleAuthProviderStatus.unavailable,
        failureCode: 'APPLE_SIGN_IN_UNAVAILABLE',
      );

  const AppleAuthProviderResult.failure({
    required String failureCode,
    String? failureMessage,
  }) : this._(
         status: AppleAuthProviderStatus.failure,
         failureCode: failureCode,
         failureMessage: failureMessage,
       );
}

class AppleAuthorizationCredentialPayload {
  final String? identityToken;
  final String? authorizationCode;
  final String userIdentifier;
  final String? email;
  final String? givenName;
  final String? familyName;

  const AppleAuthorizationCredentialPayload({
    required this.identityToken,
    required this.authorizationCode,
    required this.userIdentifier,
    this.email,
    this.givenName,
    this.familyName,
  });
}

abstract class AppleAuthClient {
  Future<bool> isAvailable();
  Future<AppleAuthorizationCredentialPayload> getAppleIDCredential({
    required String nonce,
  });
}

class SignInWithAppleClient implements AppleAuthClient {
  const SignInWithAppleClient();

  @override
  Future<AppleAuthorizationCredentialPayload> getAppleIDCredential({
    required String nonce,
  }) async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );
    return AppleAuthorizationCredentialPayload(
      identityToken: credential.identityToken,
      authorizationCode: credential.authorizationCode,
      userIdentifier: credential.userIdentifier ?? '',
      email: credential.email,
      givenName: credential.givenName,
      familyName: credential.familyName,
    );
  }

  @override
  Future<bool> isAvailable() => SignInWithApple.isAvailable();
}

abstract class AppleAuthProviderDataSource {
  Future<AppleAuthAvailability> getAvailability();
  Future<AppleAuthProviderResult> signIn();
}

class PlatformAppleAuthProviderDataSource
    implements AppleAuthProviderDataSource {
  final AppleAuthClient _client;
  final bool Function() _platformSupportResolver;

  PlatformAppleAuthProviderDataSource({
    AppleAuthClient? client,
    bool Function()? platformSupportResolver,
  }) : _client = client ?? const SignInWithAppleClient(),
       _platformSupportResolver =
           platformSupportResolver ?? _defaultPlatformSupportResolver;

  @override
  Future<AppleAuthAvailability> getAvailability() async {
    if (!_platformSupportResolver()) {
      return AppleAuthAvailability.unsupportedRunner;
    }

    try {
      final available = await _client.isAvailable();
      return available
          ? AppleAuthAvailability.supported
          : AppleAuthAvailability.unavailableOnDevice;
    } catch (error, stackTrace) {
      log(
        'Apple availability check failed.',
        name: 'AppleAuthProviderDataSource',
        error: error,
        stackTrace: stackTrace,
      );
      return AppleAuthAvailability.unavailableOnDevice;
    }
  }

  @override
  Future<AppleAuthProviderResult> signIn() async {
    final availability = await getAvailability();
    if (availability != AppleAuthAvailability.supported) {
      log(
        'Apple sign-in blocked because availability=$availability',
        name: 'AppleAuthProviderDataSource',
      );
      return const AppleAuthProviderResult.unavailable();
    }

    try {
      final rawNonce = generateNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
      final credential = await _client.getAppleIDCredential(nonce: hashedNonce);
      final identityToken = credential.identityToken;
      final authorizationCode = credential.authorizationCode;
      if (identityToken == null || identityToken.isEmpty) {
        return const AppleAuthProviderResult.failure(
          failureCode: 'APPLE_IDENTITY_TOKEN_MISSING',
        );
      }
      if (authorizationCode == null || authorizationCode.isEmpty) {
        return const AppleAuthProviderResult.failure(
          failureCode: 'APPLE_AUTHORIZATION_CODE_MISSING',
        );
      }
      if (credential.userIdentifier.isEmpty) {
        return const AppleAuthProviderResult.failure(
          failureCode: 'APPLE_USER_IDENTIFIER_MISSING',
        );
      }
      return AppleAuthProviderResult.success(
        identityToken: identityToken,
        rawNonce: rawNonce,
        authorizationCode: authorizationCode,
        userIdentifier: credential.userIdentifier,
        email: credential.email,
        givenName: credential.givenName,
        familyName: credential.familyName,
      );
    } on SignInWithAppleAuthorizationException catch (error, stackTrace) {
      if (error.code == AuthorizationErrorCode.canceled) {
        log(
          'Apple sign-in cancelled by the user.',
          name: 'AppleAuthProviderDataSource',
        );
        return const AppleAuthProviderResult.cancelled();
      }
      log(
        'Apple sign-in authorization failed code=${error.code.name}',
        name: 'AppleAuthProviderDataSource',
        error: error,
        stackTrace: stackTrace,
      );
      return AppleAuthProviderResult.failure(
        failureCode: 'APPLE_SIGN_IN_FAILED',
        failureMessage: error.code.name,
      );
    } catch (error, stackTrace) {
      log(
        'Apple sign-in provider failure.',
        name: 'AppleAuthProviderDataSource',
        error: error,
        stackTrace: stackTrace,
      );
      return AppleAuthProviderResult.failure(
        failureCode: 'APPLE_SIGN_IN_FAILED',
        failureMessage: error.runtimeType.toString(),
      );
    }
  }

  static bool _defaultPlatformSupportResolver() {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.iOS;
  }
}
