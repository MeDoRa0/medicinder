import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/data/models/sync/sync_cycle_state_model.dart';
import 'package:medicinder/domain/entities/sync/sync_cycle_state.dart';
import 'package:medicinder/domain/entities/sync/sync_types.dart';

void main() {
  final startedAt = DateTime(2026, 4, 1, 10);
  final completedAt = DateTime(2026, 4, 1, 10, 5);

  group('SyncCycleStateModel', () {
    group('fromEntity', () {
      test('maps all fields correctly', () {
        final entity = SyncCycleState(
          cycleId: 'cycle-1',
          userId: 'user-123',
          trigger: SyncTrigger.userSignIn,
          startedAt: startedAt,
          completedAt: completedAt,
          status: SyncCycleStatus.succeeded,
          pushedCount: 3,
          pulledCount: 2,
          failedCount: 1,
          failureClass: 'timeout',
        );

        final model = SyncCycleStateModel.fromEntity(entity);

        expect(model.cycleId, 'cycle-1');
        expect(model.userId, 'user-123');
        expect(model.triggerName, 'userSignIn');
        expect(model.startedAt, startedAt);
        expect(model.completedAt, completedAt);
        expect(model.statusName, 'succeeded');
        expect(model.pushedCount, 3);
        expect(model.pulledCount, 2);
        expect(model.failedCount, 1);
        expect(model.failureClass, 'timeout');
      });

      test('maps optional completedAt as null', () {
        final entity = SyncCycleState(
          cycleId: 'cycle-2',
          userId: 'user-123',
          trigger: SyncTrigger.appStartup,
          startedAt: startedAt,
          status: SyncCycleStatus.running,
        );

        final model = SyncCycleStateModel.fromEntity(entity);

        expect(model.completedAt, isNull);
        expect(model.failureClass, isNull);
      });
    });

    group('toEntity', () {
      test('converts all fields back correctly', () {
        final model = SyncCycleStateModel(
          cycleId: 'cycle-1',
          userId: 'user-123',
          triggerName: 'connectivityRestored',
          startedAt: startedAt,
          completedAt: completedAt,
          statusName: 'failed',
          pushedCount: 0,
          pulledCount: 0,
          failedCount: 2,
          failureClass: 'network_error',
        );

        final entity = model.toEntity();

        expect(entity.cycleId, 'cycle-1');
        expect(entity.userId, 'user-123');
        expect(entity.trigger, SyncTrigger.connectivityRestored);
        expect(entity.startedAt, startedAt);
        expect(entity.completedAt, completedAt);
        expect(entity.status, SyncCycleStatus.failed);
        expect(entity.pushedCount, 0);
        expect(entity.pulledCount, 0);
        expect(entity.failedCount, 2);
        expect(entity.failureClass, 'network_error');
      });

      test('falls back to appStartup for unknown trigger name', () {
        final model = SyncCycleStateModel(
          cycleId: 'cycle-unknown',
          userId: 'user-123',
          triggerName: 'unknownTrigger',
          startedAt: startedAt,
          statusName: 'idle',
        );

        final entity = model.toEntity();

        expect(entity.trigger, SyncTrigger.appStartup);
      });

      test('falls back to idle for unknown status name', () {
        final model = SyncCycleStateModel(
          cycleId: 'cycle-unknown',
          userId: 'user-123',
          triggerName: 'appStartup',
          startedAt: startedAt,
          statusName: 'unknownStatus',
        );

        final entity = model.toEntity();

        expect(entity.status, SyncCycleStatus.idle);
      });

      test('handles null completedAt', () {
        final model = SyncCycleStateModel(
          cycleId: 'cycle-1',
          userId: 'user-123',
          triggerName: 'manualRetry',
          startedAt: startedAt,
          statusName: 'running',
        );

        final entity = model.toEntity();

        expect(entity.completedAt, isNull);
      });
    });

    group('roundtrip', () {
      test('fromEntity then toEntity preserves all fields', () {
        final original = SyncCycleState(
          cycleId: 'cycle-rt',
          userId: 'user-456',
          trigger: SyncTrigger.manualRetry,
          startedAt: startedAt,
          completedAt: completedAt,
          status: SyncCycleStatus.succeeded,
          pushedCount: 5,
          pulledCount: 3,
          failedCount: 0,
        );

        final model = SyncCycleStateModel.fromEntity(original);
        final restored = model.toEntity();

        expect(restored.cycleId, original.cycleId);
        expect(restored.userId, original.userId);
        expect(restored.trigger, original.trigger);
        expect(restored.startedAt, original.startedAt);
        expect(restored.completedAt, original.completedAt);
        expect(restored.status, original.status);
        expect(restored.pushedCount, original.pushedCount);
        expect(restored.pulledCount, original.pulledCount);
        expect(restored.failedCount, original.failedCount);
        expect(restored.failureClass, original.failureClass);
      });
    });

    group('default constants', () {
      test('defaultStatusName is idle', () {
        expect(SyncCycleStateModel.defaultStatusName, 'idle');
      });

      test('defaultTriggerName is appStartup', () {
        expect(SyncCycleStateModel.defaultTriggerName, 'appStartup');
      });
    });
  });
}