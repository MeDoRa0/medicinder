import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/domain/entities/auth/app_entry_session.dart';
import 'package:medicinder/domain/repositories/app_entry_repository.dart';
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

    test('restore returns unresolved when no stored mode exists', () async {
      final session = await RestoreAppEntrySession(_FakeAppEntryRepository())();

      expect(
        session,
        const AppEntrySession.unresolved(restoredFromStorage: true),
      );
    });

    test('restore returns guest when stored mode is guest', () async {
      final repository = _FakeAppEntryRepository()..storedMode = 'guest';

      final session = await RestoreAppEntrySession(repository)();

      expect(session, const AppEntrySession.guest(restoredFromStorage: true));
    });

    test('restore falls back to failure for unsupported stored mode', () async {
      final repository = _FakeAppEntryRepository()..storedMode = 'google';

      final session = await RestoreAppEntrySession(repository)();

      expect(session.status, AppEntrySessionStatus.failure);
      expect(session.failureCode, 'UNSUPPORTED_ENTRY_MODE');
      expect(session.isResolved, isFalse);
    });

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
