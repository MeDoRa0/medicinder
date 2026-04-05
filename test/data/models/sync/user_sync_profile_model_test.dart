import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/data/models/sync/user_sync_profile_model.dart';
import 'package:medicinder/domain/entities/sync/sync_status_view_state.dart';
import 'package:medicinder/domain/entities/sync/sync_types.dart';
import 'package:medicinder/domain/entities/sync/user_sync_profile.dart';

void main() {
  final createdAt = DateTime(2026, 1, 1);
  final updatedAt = DateTime(2026, 4, 1);
  final lastSuccessAt = DateTime(2026, 4, 1, 10);
  final lastFailureAt = DateTime(2026, 4, 1, 11);

  UserSyncProfile _buildProfile({
    String userId = 'user-1',
    List<String> providerIds = const ['anonymous'],
    bool syncEnabled = true,
    bool workspaceReady = true,
    SyncStatusViewState statusViewState = SyncStatusViewState.ready,
    SyncCycleStatus engineStatus = SyncCycleStatus.succeeded,
    SyncTrigger? lastTrigger = SyncTrigger.appStartup,
    DateTime? lastSuccessfulSyncAt,
    int lastPushedCount = 0,
    int lastPulledCount = 0,
    int lastFailedCount = 0,
  }) {
    return UserSyncProfile(
      userId: userId,
      providerIds: providerIds,
      syncEnabled: syncEnabled,
      workspaceReady: workspaceReady,
      createdAt: createdAt,
      updatedAt: updatedAt,
      statusViewState: statusViewState,
      engineStatus: engineStatus,
      lastTrigger: lastTrigger,
      lastSuccessfulSyncAt: lastSuccessfulSyncAt,
      lastStartedAt: lastSuccessAt,
      lastCompletedAt: lastSuccessAt,
      lastSuccessAt: lastSuccessAt,
      lastPushedCount: lastPushedCount,
      lastPulledCount: lastPulledCount,
      lastFailedCount: lastFailedCount,
    );
  }

  group('UserSyncProfileModel', () {
    group('fromEntity', () {
      test('maps all core fields correctly', () {
        final profile = _buildProfile(
          lastPushedCount: 5,
          lastPulledCount: 3,
          lastFailedCount: 1,
        );

        final model = UserSyncProfileModel.fromEntity(profile);

        expect(model.userId, 'user-1');
        expect(model.providerIds, ['anonymous']);
        expect(model.syncEnabled, isTrue);
        expect(model.workspaceReady, isTrue);
        expect(model.createdAt, createdAt);
        expect(model.updatedAt, updatedAt);
        expect(model.statusViewStateIndex, SyncStatusViewState.ready.index);
        expect(model.engineStatusIndex, SyncCycleStatus.succeeded.index);
        expect(model.lastTriggerIndex, SyncTrigger.appStartup.index);
        expect(model.lastPushedCount, 5);
        expect(model.lastPulledCount, 3);
        expect(model.lastFailedCount, 1);
      });

      test('maps null lastTrigger as null index', () {
        final profile = _buildProfile(lastTrigger: null);

        final model = UserSyncProfileModel.fromEntity(profile);

        expect(model.lastTriggerIndex, isNull);
      });

      test('maps optional datetime fields', () {
        final profile = _buildProfile().copyWith(
          lastSuccessAt: lastSuccessAt,
          lastFailureAt: lastFailureAt,
          message: 'All good',
        );

        final model = UserSyncProfileModel.fromEntity(profile);

        expect(model.lastSuccessAt, lastSuccessAt);
        expect(model.lastFailureAt, lastFailureAt);
        expect(model.message, 'All good');
      });

      test('maps null optional fields as null', () {
        final profile = UserSyncProfile(
          userId: 'user-1',
          syncEnabled: true,
          createdAt: createdAt,
          updatedAt: updatedAt,
          statusViewState: SyncStatusViewState.signedOut,
        );

        final model = UserSyncProfileModel.fromEntity(profile);

        expect(model.lastSuccessfulSyncAt, isNull);
        expect(model.lastAttemptedSyncAt, isNull);
        expect(model.lastSyncErrorCode, isNull);
        expect(model.lastTriggerIndex, isNull);
        expect(model.lastStartedAt, isNull);
        expect(model.lastCompletedAt, isNull);
        expect(model.lastSuccessAt, isNull);
        expect(model.lastFailureAt, isNull);
        expect(model.message, isNull);
      });
    });

    group('toEntity', () {
      test('converts all fields back correctly', () {
        final model = UserSyncProfileModel(
          userId: 'user-1',
          providerIds: ['anonymous'],
          syncEnabled: true,
          workspaceReady: true,
          createdAt: createdAt,
          updatedAt: updatedAt,
          statusViewStateIndex: SyncStatusViewState.ready.index,
          engineStatusIndex: SyncCycleStatus.succeeded.index,
          lastTriggerIndex: SyncTrigger.userSignIn.index,
          lastStartedAt: lastSuccessAt,
          lastCompletedAt: lastSuccessAt,
          lastSuccessAt: lastSuccessAt,
          lastFailureAt: lastFailureAt,
          message: 'done',
          lastPushedCount: 4,
          lastPulledCount: 2,
          lastFailedCount: 1,
        );

        final entity = model.toEntity();

        expect(entity.userId, 'user-1');
        expect(entity.providerIds, ['anonymous']);
        expect(entity.syncEnabled, isTrue);
        expect(entity.workspaceReady, isTrue);
        expect(entity.createdAt, createdAt);
        expect(entity.updatedAt, updatedAt);
        expect(entity.statusViewState, SyncStatusViewState.ready);
        expect(entity.engineStatus, SyncCycleStatus.succeeded);
        expect(entity.lastTrigger, SyncTrigger.userSignIn);
        expect(entity.lastStartedAt, lastSuccessAt);
        expect(entity.lastCompletedAt, lastSuccessAt);
        expect(entity.lastSuccessAt, lastSuccessAt);
        expect(entity.lastFailureAt, lastFailureAt);
        expect(entity.message, 'done');
        expect(entity.lastPushedCount, 4);
        expect(entity.lastPulledCount, 2);
        expect(entity.lastFailedCount, 1);
      });

      test('handles null lastTriggerIndex as null lastTrigger', () {
        final model = UserSyncProfileModel(
          userId: 'user-1',
          syncEnabled: true,
          createdAt: createdAt,
          updatedAt: updatedAt,
          statusViewStateIndex: SyncStatusViewState.signedOut.index,
          lastTriggerIndex: null,
        );

        final entity = model.toEntity();

        expect(entity.lastTrigger, isNull);
      });

      test('out-of-range statusViewStateIndex falls back to first value', () {
        final model = UserSyncProfileModel(
          userId: 'user-1',
          syncEnabled: true,
          createdAt: createdAt,
          updatedAt: updatedAt,
          statusViewStateIndex: 9999,
        );

        final entity = model.toEntity();

        expect(entity.statusViewState, SyncStatusViewState.values.first);
      });

      test('out-of-range engineStatusIndex falls back to idle', () {
        final model = UserSyncProfileModel(
          userId: 'user-1',
          syncEnabled: true,
          createdAt: createdAt,
          updatedAt: updatedAt,
          statusViewStateIndex: SyncStatusViewState.ready.index,
          engineStatusIndex: 9999,
        );

        final entity = model.toEntity();

        expect(entity.engineStatus, SyncCycleStatus.idle);
      });

      test('out-of-range lastTriggerIndex falls back to null', () {
        final model = UserSyncProfileModel(
          userId: 'user-1',
          syncEnabled: true,
          createdAt: createdAt,
          updatedAt: updatedAt,
          statusViewStateIndex: SyncStatusViewState.ready.index,
          lastTriggerIndex: 9999,
        );

        final entity = model.toEntity();

        expect(entity.lastTrigger, isNull);
      });

      test('negative statusViewStateIndex falls back to first value', () {
        final model = UserSyncProfileModel(
          userId: 'user-1',
          syncEnabled: true,
          createdAt: createdAt,
          updatedAt: updatedAt,
          statusViewStateIndex: -1,
        );

        final entity = model.toEntity();

        expect(entity.statusViewState, SyncStatusViewState.values.first);
      });
    });

    group('roundtrip', () {
      test('fromEntity then toEntity preserves all fields', () {
        final original = _buildProfile(
          lastPushedCount: 7,
          lastPulledCount: 4,
          lastFailedCount: 2,
        );

        final model = UserSyncProfileModel.fromEntity(original);
        final restored = model.toEntity();

        expect(restored.userId, original.userId);
        expect(restored.providerIds, original.providerIds);
        expect(restored.syncEnabled, original.syncEnabled);
        expect(restored.workspaceReady, original.workspaceReady);
        expect(restored.createdAt, original.createdAt);
        expect(restored.updatedAt, original.updatedAt);
        expect(restored.statusViewState, original.statusViewState);
        expect(restored.engineStatus, original.engineStatus);
        expect(restored.lastTrigger, original.lastTrigger);
        expect(restored.lastPushedCount, original.lastPushedCount);
        expect(restored.lastPulledCount, original.lastPulledCount);
        expect(restored.lastFailedCount, original.lastFailedCount);
      });
    });
  });
}