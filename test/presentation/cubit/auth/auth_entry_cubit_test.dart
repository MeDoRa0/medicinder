import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/domain/entities/auth/app_entry_session.dart';
import 'package:medicinder/domain/repositories/app_entry_repository.dart';
import 'package:medicinder/domain/usecases/auth/clear_app_entry_state.dart';
import 'package:medicinder/domain/usecases/auth/continue_as_guest.dart';
import 'package:medicinder/domain/usecases/auth/restore_app_entry_session.dart';
import 'package:medicinder/presentation/cubit/auth/auth_entry_cubit.dart';

void main() {
  group('AuthEntryCubit', () {
    test('restores unresolved state when no stored mode exists', () async {
      final repository = _FakeAppEntryRepository();
      final cubit = _buildCubit(repository);

      await cubit.restoreSession();

      expect(
        cubit.state.session,
        const AppEntrySession.unresolved(restoredFromStorage: true),
      );
    });

    test('restores guest state from storage', () async {
      final repository = _FakeAppEntryRepository()..storedMode = 'guest';
      final cubit = _buildCubit(repository);

      await cubit.restoreSession();

      expect(
        cubit.state.session,
        const AppEntrySession.guest(restoredFromStorage: true),
      );
    });

    test('falls back to failure for unsupported stored mode', () async {
      final repository = _FakeAppEntryRepository()..storedMode = 'google';
      final cubit = _buildCubit(repository);

      await cubit.restoreSession();

      expect(cubit.state.session.status, AppEntrySessionStatus.failure);
      expect(cubit.state.session.failureCode, 'UNSUPPORTED_ENTRY_MODE');
    });

    test('continues as guest and persists the guest marker', () async {
      final repository = _FakeAppEntryRepository();
      final cubit = _buildCubit(repository);

      await cubit.continueAsGuest();

      expect(cubit.state.session, const AppEntrySession.guest());
      expect(repository.storedMode, 'guest');
    });

    test('disabled provider taps keep the gate unresolved', () {
      final repository = _FakeAppEntryRepository();
      final cubit = _buildCubit(repository);

      cubit.onDisabledProviderTap(AppEntryMode.google);

      expect(cubit.state.unavailableMode, AppEntryMode.google);
      expect(cubit.state.feedbackMessage, 'google_coming_soon');
      expect(cubit.state.session.isResolved, isFalse);
      expect(repository.storedMode, isNull);
    });

    test('clear entry state returns the cubit to unresolved', () async {
      final repository = _FakeAppEntryRepository()..storedMode = 'guest';
      final cubit = _buildCubit(repository);

      await cubit.clearEntryState();

      expect(cubit.state.session, const AppEntrySession.unresolved());
      expect(repository.cleared, isTrue);
    });
  });
}

AuthEntryCubit _buildCubit(_FakeAppEntryRepository repository) {
  return AuthEntryCubit(
    restoreAppEntrySession: RestoreAppEntrySession(repository),
    continueAsGuest: ContinueAsGuest(repository),
    clearAppEntryState: ClearAppEntryState(repository),
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
