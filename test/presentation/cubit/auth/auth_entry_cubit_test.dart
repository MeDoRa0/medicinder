import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/domain/entities/auth/app_entry_session.dart';
import 'package:medicinder/domain/entities/sync/auth_session.dart';
import 'package:medicinder/domain/repositories/app_entry_repository.dart';
import 'package:medicinder/domain/repositories/auth_repository.dart';
import 'package:medicinder/domain/usecases/auth/clear_app_entry_state.dart';
import 'package:medicinder/domain/usecases/auth/continue_as_guest.dart';
import 'package:medicinder/domain/usecases/auth/restore_app_entry_session.dart';
import 'package:medicinder/domain/usecases/auth/sign_in_with_google.dart';
import 'package:medicinder/presentation/cubit/auth/auth_entry_cubit.dart';

void main() {
  group('AuthEntryCubit', () {
    test('restores authenticated Google session before guest mode', () async {
      final appEntryRepository = _FakeAppEntryRepository()..storedMode = 'guest';
      final authRepository = _FakeAuthRepository(
        currentSession: const AuthSession.ready(
          'user-123',
          providerId: 'google.com',
        ),
      );
      final cubit = _buildCubit(appEntryRepository, authRepository);

      await cubit.restoreSession();

      expect(
        cubit.state.session,
        const AppEntrySession.authenticated(
          entryMode: AppEntryMode.google,
          restoredFromStorage: true,
        ),
      );
    });

    test('restores guest state from storage when auth is signed out', () async {
      final repository = _FakeAppEntryRepository()..storedMode = 'guest';
      final cubit = _buildCubit(repository, _FakeAuthRepository());

      await cubit.restoreSession();

      expect(
        cubit.state.session,
        const AppEntrySession.guest(restoredFromStorage: true),
      );
    });

    test('successful Google sign-in resolves authenticated session', () async {
      final authRepository = _FakeAuthRepository(
        signInSession: const AuthSession.ready(
          'user-123',
          providerId: 'google.com',
        ),
      );
      final cubit = _buildCubit(_FakeAppEntryRepository(), authRepository);

      await cubit.signInWithGoogle();

      expect(
        cubit.state.session,
        const AppEntrySession.authenticated(entryMode: AppEntryMode.google),
      );
      expect(cubit.state.busy, isFalse);
      expect(authRepository.lastProviderId, 'google.com');
    });

    test('Google sign-in exposes a busy state while the attempt is in progress', () async {
      final completer = Completer<AuthSession>();
      final authRepository = _FakeAuthRepository(signInCompleter: completer);
      final cubit = _buildCubit(_FakeAppEntryRepository(), authRepository);

      final future = cubit.signInWithGoogle();

      expect(cubit.state.busy, isTrue);
      expect(cubit.state.inProgressMode, AppEntryMode.google);

      completer.complete(
        const AuthSession.ready('user-123', providerId: 'google.com'),
      );
      await future;
      expect(cubit.state.busy, isFalse);
    });

    test('failed Google sign-in returns to unresolved gate with feedback', () async {
      final authRepository = _FakeAuthRepository(
        signInSession: const AuthSession.failed(
          failureCode: 'GOOGLE_SIGN_IN_FAILED',
        ),
      );
      final cubit = _buildCubit(_FakeAppEntryRepository(), authRepository);

      await cubit.signInWithGoogle();

      expect(cubit.state.session, const AppEntrySession.unresolved());
      expect(cubit.state.feedbackCode, 'GOOGLE_SIGN_IN_FAILED');
      expect(cubit.state.busy, isFalse);
    });

    test('continues as guest and persists the guest marker', () async {
      final repository = _FakeAppEntryRepository();
      final cubit = _buildCubit(repository, _FakeAuthRepository());

      await cubit.continueAsGuest();

      expect(cubit.state.session, const AppEntrySession.guest());
      expect(repository.storedMode, 'guest');
    });

    test('disabled provider taps keep the gate unresolved', () {
      final repository = _FakeAppEntryRepository();
      final cubit = _buildCubit(repository, _FakeAuthRepository());

      cubit.onDisabledProviderTap(AppEntryMode.apple);

      expect(cubit.state.unavailableMode, AppEntryMode.apple);
      expect(cubit.state.feedbackCode, 'apple_coming_soon');
      expect(cubit.state.session.isResolved, isFalse);
      expect(repository.storedMode, isNull);
    });

    test('clear entry state returns the cubit to unresolved', () async {
      final repository = _FakeAppEntryRepository()..storedMode = 'guest';
      final cubit = _buildCubit(repository, _FakeAuthRepository());

      await cubit.clearEntryState();

      expect(cubit.state.session, const AppEntrySession.unresolved());
      expect(repository.cleared, isTrue);
    });
  });
}

AuthEntryCubit _buildCubit(
  _FakeAppEntryRepository repository,
  _FakeAuthRepository authRepository,
) {
  return AuthEntryCubit(
    restoreAppEntrySession: RestoreAppEntrySession(authRepository, repository),
    continueAsGuest: ContinueAsGuest(repository),
    clearAppEntryState: ClearAppEntryState(repository),
    signInWithGoogle: SignInWithGoogle(authRepository),
  );
}

class _FakeAppEntryRepository implements AppEntryRepository {
  String? storedMode;
  bool cleared = false;

  @override
  Future<void> clearResolvedEntryMode() async {
    cleared = true;
    storedMode = null;
  }

  @override
  Future<void> persistGuestMode() async {
    storedMode = 'guest';
  }

  @override
  Future<String?> readResolvedEntryMode() async => storedMode;
}

class _FakeAuthRepository implements AuthRepository {
  final AuthSession currentSession;
  final AuthSession signInSession;
  final Completer<AuthSession>? signInCompleter;
  String? lastProviderId;

  _FakeAuthRepository({
    this.currentSession = const AuthSession.signedOut(),
    AuthSession? signInSession,
    this.signInCompleter,
  }) : signInSession = signInSession ?? currentSession;

  @override
  Future<AuthSession> getCurrentSession() async => currentSession;

  @override
  Future<AuthSession> signInForSync({String? providerId}) async {
    lastProviderId = providerId;
    if (signInCompleter != null) {
      return signInCompleter!.future;
    }
    return signInSession;
  }

  @override
  Future<void> signOutFromSync() async {}

  @override
  Stream<AuthSession> watchSession() async* {
    yield currentSession;
  }
}
