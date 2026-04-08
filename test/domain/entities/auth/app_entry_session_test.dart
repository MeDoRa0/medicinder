import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/domain/entities/auth/app_entry_session.dart';

void main() {
  group('AppEntrySession.authenticated', () {
    test('accepts google and apple entry modes', () {
      expect(
        () => const AppEntrySession.authenticated(entryMode: AppEntryMode.google),
        returnsNormally,
      );
      expect(
        () => const AppEntrySession.authenticated(entryMode: AppEntryMode.apple),
        returnsNormally,
      );
    });

    test('rejects non-provider entry modes', () {
      expect(
        () => const AppEntrySession.authenticated(entryMode: AppEntryMode.none),
        throwsA(
          isA<AssertionError>().having(
            (error) => error.message,
            'message',
            'authenticated session must use google or apple entry mode',
          ),
        ),
      );
      expect(
        () => const AppEntrySession.authenticated(entryMode: AppEntryMode.guest),
        throwsA(
          isA<AssertionError>().having(
            (error) => error.message,
            'message',
            'authenticated session must use google or apple entry mode',
          ),
        ),
      );
    });
  });
}
