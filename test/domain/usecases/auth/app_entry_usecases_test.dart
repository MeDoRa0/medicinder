import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/data/datasources/auth/apple_auth_provider_data_source.dart';
import 'package:medicinder/domain/entities/auth/app_entry_session.dart';
import 'package:medicinder/domain/entities/sync/auth_session.dart';
import 'package:medicinder/domain/repositories/app_entry_repository.dart';
import 'package:medicinder/domain/repositories/auth_repository.dart';
import 'package:medicinder/domain/usecases/auth/clear_app_entry_state.dart';
import 'package:medicinder/domain/usecases/auth/continue_as_guest.dart';
import 'package:medicinder/domain/usecases/auth/restore_app_entry_session.dart';

void main() {
  group('app entry use cases', () {
    test('continue as guest persists and returns guest session', () async {
      final repository = _FakeAppEntryRepository();

      final session = await ContinueAsGuest(repository)();

      expect(session, const AppEntrySession.guest());
      expect(repository.storedMode, 'guest');
    });

    test(
      'restore returns authenticated Google session before guest marker',
      () async {
        final authRepository = _FakeAuthRepository(
          currentSession: const AuthSession.ready(
            'user-123',
            providerId: 'google.com',
          ),
        );
        final appEntryRepository = _FakeAppEntryRepository()
          ..storedMode = 'guest';

        final session = await RestoreAppEntrySession(
          authRepository,
          appEntryRepository,
        )();

        expect(
          session,
          const AppEntrySession.authenticated(
            entryMode: AppEntryMode.google,
            restoredFromStorage: true,
          ),
        );
      },
    );

    test(
      'restore returns authenticated Apple session before guest marker',
      () async {
        final authRepository = _FakeAuthRepository(
          currentSession: const AuthSession.ready(
            'user-apple',
            providerId: 'apple.com',
          ),
        );
        final appEntryRepository = _FakeAppEntryRepository()
          ..storedMode = 'guest';

        final session = await RestoreAppEntrySession(
          authRepository,
          appEntryRepository,
        )();

        expect(
          session,
          const AppEntrySession.authenticated(
            entryMode: AppEntryMode.apple,
            restoredFromStorage: true,
          ),
        );
      },
    );

    test(
      'restore returns unresolved when no auth session or guest marker exists',
      () async {
        final session = await RestoreAppEntrySession(
          _FakeAuthRepository(),
          _FakeAppEntryRepository(),
        )();

        expect(
          session,
          const AppEntrySession.unresolved(restoredFromStorage: true),
        );
      },
    );

    test(
      'restore returns guest when stored mode is guest and auth is signed out',
      () async {
        final appEntryRepository = _FakeAppEntryRepository()
          ..storedMode = 'guest';

        final session = await RestoreAppEntrySession(
          _FakeAuthRepository(),
          appEntryRepository,
        )();

        expect(session, const AppEntrySession.guest(restoredFromStorage: true));
      },
    );

    test('restore falls back to failure for unsupported stored mode', () async {
      final appEntryRepository = _FakeAppEntryRepository()
        ..storedMode = 'google';

      final session = await RestoreAppEntrySession(
        _FakeAuthRepository(),
        appEntryRepository,
      )();

      expect(session.status, AppEntrySessionStatus.failure);
      expect(session.failureCode, 'UNSUPPORTED_ENTRY_MODE');
      expect(session.isResolved, isFalse);
    });

    test(
      'restore ignores a stale guest marker when Apple restore is broken',
      () async {
        final appEntryRepository = _FakeAppEntryRepository()
          ..storedMode = 'guest';
        final authRepository = _FakeAuthRepository(
          currentSession: const AuthSession.failed(
            providerId: 'apple.com',
            failureCode: 'APPLE_SIGN_IN_FAILED',
          ),
        );

        final session = await RestoreAppEntrySession(
          authRepository,
          appEntryRepository,
        )();

        expect(session.status, AppEntrySessionStatus.failure);
        expect(session.failureCode, 'APPLE_SIGN_IN_FAILED');
        expect(session.isResolved, isFalse);
      },
    );

    test('clear entry state removes stored mode', () async {
      final repository = _FakeAppEntryRepository()..storedMode = 'guest';

      await ClearAppEntryState(repository)();

      expect(repository.storedMode, isNull);
      expect(repository.cleared, isTrue);
    });
  });
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
  final AppleAuthAvailability appleAvailability;

  _FakeAuthRepository({
    this.currentSession = const AuthSession.signedOut(),
    this.appleAvailability = AppleAuthAvailability.supported,
  });

  @override
  Future<AuthSession> getCurrentSession() async => currentSession;

  @override
  Future<AppleAuthAvailability> getAppleAvailability() async =>
      appleAvailability;

  @override
  Future<AuthSession> signInForSync({String? providerId}) async =>
      currentSession;

  @override
  Future<void> signOutFromSync() async {}

  @override
  Stream<AuthSession> watchSession() async* {
    yield currentSession;
  }
}
