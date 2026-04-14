import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/domain/entities/sync/sync_cycle_state.dart';
import 'package:medicinder/domain/entities/sync/sync_types.dart';

void main() {
  final startedAt = DateTime(2026, 4, 1, 10);
  final completedAt = DateTime(2026, 4, 1, 10, 1);

  group('SyncCycleState', () {
    test('has correct defaults', () {
      final state = SyncCycleState(
        cycleId: 'cycle-1',
        userId: 'user-123',
        trigger: SyncTrigger.appStartup,
        startedAt: startedAt,
      );

      expect(state.cycleId, 'cycle-1');
      expect(state.userId, 'user-123');
      expect(state.trigger, SyncTrigger.appStartup);
      expect(state.startedAt, startedAt);
      expect(state.completedAt, isNull);
      expect(state.status, SyncCycleStatus.idle);
      expect(state.pushedCount, 0);
      expect(state.pulledCount, 0);
      expect(state.failedCount, 0);
      expect(state.failureClass, isNull);
    });

    group('copyWith', () {
      test('preserves all fields when no overrides given', () {
        final original = SyncCycleState(
          cycleId: 'cycle-1',
          userId: 'user-123',
          trigger: SyncTrigger.appStartup,
          startedAt: startedAt,
          completedAt: completedAt,
          status: SyncCycleStatus.succeeded,
          pushedCount: 3,
          pulledCount: 2,
          failedCount: 0,
        );

        final copy = original.copyWith();

        expect(copy, equals(original));
      });

      test('overrides individual fields', () {
        final original = SyncCycleState(
          cycleId: 'cycle-1',
          userId: 'user-123',
          trigger: SyncTrigger.appStartup,
          startedAt: startedAt,
          status: SyncCycleStatus.running,
        );

        final updated = original.copyWith(
          status: SyncCycleStatus.succeeded,
          completedAt: completedAt,
          pushedCount: 5,
          pulledCount: 2,
          failedCount: 1,
          failureClass: 'network_error',
        );

        expect(updated.cycleId, 'cycle-1');
        expect(updated.userId, 'user-123');
        expect(updated.trigger, SyncTrigger.appStartup);
        expect(updated.startedAt, startedAt);
        expect(updated.status, SyncCycleStatus.succeeded);
        expect(updated.completedAt, completedAt);
        expect(updated.pushedCount, 5);
        expect(updated.pulledCount, 2);
        expect(updated.failedCount, 1);
        expect(updated.failureClass, 'network_error');
      });

      test('overrides userId and trigger independently', () {
        final original = SyncCycleState(
          cycleId: 'cycle-1',
          userId: 'user-123',
          trigger: SyncTrigger.appStartup,
          startedAt: startedAt,
        );

        final updated = original.copyWith(
          userId: 'user-456',
          trigger: SyncTrigger.manualRetry,
        );

        expect(updated.userId, 'user-456');
        expect(updated.trigger, SyncTrigger.manualRetry);
        expect(updated.cycleId, 'cycle-1');
      });
    });

    group('Equatable props', () {
      test('two states with same fields are equal', () {
        final a = SyncCycleState(
          cycleId: 'cycle-1',
          userId: 'user-123',
          trigger: SyncTrigger.userSignIn,
          startedAt: startedAt,
          completedAt: completedAt,
          status: SyncCycleStatus.succeeded,
          pushedCount: 1,
          pulledCount: 2,
          failedCount: 0,
        );
        final b = SyncCycleState(
          cycleId: 'cycle-1',
          userId: 'user-123',
          trigger: SyncTrigger.userSignIn,
          startedAt: startedAt,
          completedAt: completedAt,
          status: SyncCycleStatus.succeeded,
          pushedCount: 1,
          pulledCount: 2,
          failedCount: 0,
        );

        expect(a, equals(b));
      });

      test('states with different cycleId are not equal', () {
        final a = SyncCycleState(
          cycleId: 'cycle-1',
          userId: 'user-123',
          trigger: SyncTrigger.appStartup,
          startedAt: startedAt,
        );
        final b = SyncCycleState(
          cycleId: 'cycle-2',
          userId: 'user-123',
          trigger: SyncTrigger.appStartup,
          startedAt: startedAt,
        );

        expect(a, isNot(equals(b)));
      });

      test('states with different status are not equal', () {
        final a = SyncCycleState(
          cycleId: 'cycle-1',
          userId: 'user-123',
          trigger: SyncTrigger.appStartup,
          startedAt: startedAt,
          status: SyncCycleStatus.running,
        );
        final b = a.copyWith(status: SyncCycleStatus.succeeded);

        expect(a, isNot(equals(b)));
      });

      test('states with different failureClass are not equal', () {
        final a = SyncCycleState(
          cycleId: 'cycle-1',
          userId: 'user-123',
          trigger: SyncTrigger.appStartup,
          startedAt: startedAt,
          failureClass: 'timeout',
        );
        final b = a.copyWith(failureClass: 'network_error');

        expect(a, isNot(equals(b)));
      });
    });

    group('SyncCycleStatus enum', () {
      test('all expected values exist', () {
        expect(SyncCycleStatus.values, contains(SyncCycleStatus.idle));
        expect(SyncCycleStatus.values, contains(SyncCycleStatus.running));
        expect(SyncCycleStatus.values, contains(SyncCycleStatus.succeeded));
        expect(SyncCycleStatus.values, contains(SyncCycleStatus.failed));
      });
    });
  });
}
