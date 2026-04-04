import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/domain/entities/sync/auth_session.dart';

void main() {
  group('AuthSession', () {
    group('signedOut constructor', () {
      test('has correct defaults', () {
        const session = AuthSession.signedOut();

        expect(session.userId, isNull);
        expect(session.isSignedIn, isFalse);
        expect(session.providerId, isNull);
        expect(session.workspaceReady, isFalse);
        expect(session.status, AuthSessionStatus.signedOut);
        expect(session.failureCode, isNull);
        expect(session.failureMessage, isNull);
      });
    });

    group('signingIn constructor', () {
      test('has correct defaults without providerId', () {
        const session = AuthSession.signingIn();

        expect(session.userId, isNull);
        expect(session.isSignedIn, isFalse);
        expect(session.providerId, isNull);
        expect(session.workspaceReady, isFalse);
        expect(session.status, AuthSessionStatus.signingIn);
      });

      test('stores providerId when given', () {
        const session = AuthSession.signingIn(providerId: 'google.com');

        expect(session.providerId, 'google.com');
        expect(session.status, AuthSessionStatus.signingIn);
      });
    });

    group('signedIn constructor', () {
      test('sets isSignedIn true and workspaceReady false', () {
        const session = AuthSession.signedIn('user-abc');

        expect(session.userId, 'user-abc');
        expect(session.isSignedIn, isTrue);
        expect(session.workspaceReady, isFalse);
        expect(session.status, AuthSessionStatus.signedIn);
      });

      test('stores providerId when given', () {
        const session = AuthSession.signedIn('user-abc', providerId: 'anonymous');

        expect(session.providerId, 'anonymous');
      });
    });

    group('workspaceInitializing constructor', () {
      test('has isSignedIn true and workspaceReady false', () {
        const session = AuthSession.workspaceInitializing('user-abc');

        expect(session.userId, 'user-abc');
        expect(session.isSignedIn, isTrue);
        expect(session.workspaceReady, isFalse);
        expect(session.status, AuthSessionStatus.workspaceInitializing);
      });
    });

    group('ready constructor', () {
      test('has isSignedIn true and workspaceReady true', () {
        const session = AuthSession.ready('user-abc');

        expect(session.userId, 'user-abc');
        expect(session.isSignedIn, isTrue);
        expect(session.workspaceReady, isTrue);
        expect(session.status, AuthSessionStatus.ready);
        expect(session.failureCode, isNull);
        expect(session.failureMessage, isNull);
      });

      test('stores providerId when given', () {
        const session = AuthSession.ready('user-abc', providerId: 'anonymous');

        expect(session.providerId, 'anonymous');
      });
    });

    group('accessDenied constructor', () {
      test('has isSignedIn true and workspaceReady false', () {
        const session = AuthSession.accessDenied(
          'user-abc',
          failureCode: 'permission-denied',
          failureMessage: 'Access was denied.',
        );

        expect(session.userId, 'user-abc');
        expect(session.isSignedIn, isTrue);
        expect(session.workspaceReady, isFalse);
        expect(session.status, AuthSessionStatus.accessDenied);
        expect(session.failureCode, 'permission-denied');
        expect(session.failureMessage, 'Access was denied.');
      });

      test('works without optional failure fields', () {
        const session = AuthSession.accessDenied('user-abc');

        expect(session.failureCode, isNull);
        expect(session.failureMessage, isNull);
      });
    });

    group('failed constructor', () {
      test('without userId: isSignedIn is false', () {
        const session = AuthSession.failed(
          failureCode: 'unknown',
          failureMessage: 'Something went wrong.',
        );

        expect(session.userId, isNull);
        expect(session.isSignedIn, isFalse);
        expect(session.workspaceReady, isFalse);
        expect(session.status, AuthSessionStatus.failed);
        expect(session.failureCode, 'unknown');
        expect(session.failureMessage, 'Something went wrong.');
      });

      test('with userId: isSignedIn is true', () {
        const session = AuthSession.failed(
          userId: 'user-abc',
          failureCode: 'workspace-error',
          failureMessage: 'Workspace failed.',
        );

        expect(session.userId, 'user-abc');
        expect(session.isSignedIn, isTrue);
        expect(session.workspaceReady, isFalse);
        expect(session.status, AuthSessionStatus.failed);
      });
    });

    group('equality', () {
      test('two identical signedOut sessions are equal', () {
        const a = AuthSession.signedOut();
        const b = AuthSession.signedOut();

        expect(a, equals(b));
      });

      test('two ready sessions with same userId are equal', () {
        const a = AuthSession.ready('user-1', providerId: 'anonymous');
        const b = AuthSession.ready('user-1', providerId: 'anonymous');

        expect(a, equals(b));
      });

      test('ready and signedOut sessions are not equal', () {
        const a = AuthSession.ready('user-1');
        const b = AuthSession.signedOut();

        expect(a, isNot(equals(b)));
      });

      test('sessions with different userIds are not equal', () {
        const a = AuthSession.ready('user-1');
        const b = AuthSession.ready('user-2');

        expect(a, isNot(equals(b)));
      });

      test('sessions with different failureCodes are not equal', () {
        const a = AuthSession.failed(failureCode: 'err-1');
        const b = AuthSession.failed(failureCode: 'err-2');

        expect(a, isNot(equals(b)));
      });

      test('accessDenied with different providerId is not equal', () {
        const a = AuthSession.accessDenied('user-1', providerId: 'google.com');
        const b = AuthSession.accessDenied('user-1', providerId: 'apple.com');

        expect(a, isNot(equals(b)));
      });
    });

    group('hashCode', () {
      test('equal sessions produce same hashCode', () {
        const a = AuthSession.ready('user-1', providerId: 'anonymous');
        const b = AuthSession.ready('user-1', providerId: 'anonymous');

        expect(a.hashCode, equals(b.hashCode));
      });

      test('different sessions produce different hashCodes', () {
        const a = AuthSession.ready('user-1');
        const b = AuthSession.signedOut();

        expect(a.hashCode, isNot(equals(b.hashCode)));
      });
    });

    group('AuthSessionStatus enum', () {
      test('all expected values exist', () {
        expect(AuthSessionStatus.values, contains(AuthSessionStatus.signedOut));
        expect(AuthSessionStatus.values, contains(AuthSessionStatus.signingIn));
        expect(AuthSessionStatus.values, contains(AuthSessionStatus.signedIn));
        expect(AuthSessionStatus.values, contains(AuthSessionStatus.workspaceInitializing));
        expect(AuthSessionStatus.values, contains(AuthSessionStatus.ready));
        expect(AuthSessionStatus.values, contains(AuthSessionStatus.accessDenied));
        expect(AuthSessionStatus.values, contains(AuthSessionStatus.failed));
      });
    });
  });
}