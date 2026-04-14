import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/data/models/sync/conflict_metadata_model.dart';
import 'package:medicinder/domain/entities/sync/conflict_metadata.dart';
import 'package:medicinder/domain/entities/sync/sync_types.dart';

void main() {
  final localUpdatedAt = DateTime(2026, 4, 1, 9);
  final remoteUpdatedAt = DateTime(2026, 4, 1, 10);
  final resolvedAt = DateTime(2026, 4, 1, 10, 1);

  group('ConflictMetadataModel', () {
    group('fromEntity', () {
      test('maps all fields including userId', () {
        final entity = ConflictMetadata(
          entityType: SyncEntityType.medication,
          entityId: 'med-1',
          userId: 'user-123',
          localUpdatedAt: localUpdatedAt,
          remoteUpdatedAt: remoteUpdatedAt,
          winningSource: 'remote',
          resolutionStrategy: ConflictResolutionStrategy.lastWriteWins,
          resolvedAt: resolvedAt,
        );

        final model = ConflictMetadataModel.fromEntity(entity);

        expect(model.entityTypeIndex, SyncEntityType.medication.index);
        expect(model.entityId, 'med-1');
        expect(model.userId, 'user-123');
        expect(model.localUpdatedAt, localUpdatedAt);
        expect(model.remoteUpdatedAt, remoteUpdatedAt);
        expect(model.winningSource, 'remote');
        expect(
          model.resolutionStrategyIndex,
          ConflictResolutionStrategy.lastWriteWins.index,
        );
        expect(model.resolvedAt, resolvedAt);
      });

      test('correctly maps local winning source', () {
        final entity = ConflictMetadata(
          entityType: SyncEntityType.medication,
          entityId: 'med-2',
          userId: 'user-456',
          localUpdatedAt: remoteUpdatedAt,
          remoteUpdatedAt: localUpdatedAt,
          winningSource: 'local',
          resolvedAt: resolvedAt,
        );

        final model = ConflictMetadataModel.fromEntity(entity);

        expect(model.winningSource, 'local');
        expect(model.userId, 'user-456');
      });
    });

    group('toEntity', () {
      test('converts all fields back correctly', () {
        final model = ConflictMetadataModel(
          entityTypeIndex: SyncEntityType.medication.index,
          entityId: 'med-1',
          userId: 'user-123',
          localUpdatedAt: localUpdatedAt,
          remoteUpdatedAt: remoteUpdatedAt,
          winningSource: 'remote',
          resolutionStrategyIndex:
              ConflictResolutionStrategy.lastWriteWins.index,
          resolvedAt: resolvedAt,
        );

        final entity = model.toEntity();

        expect(entity.entityType, SyncEntityType.medication);
        expect(entity.entityId, 'med-1');
        expect(entity.userId, 'user-123');
        expect(entity.localUpdatedAt, localUpdatedAt);
        expect(entity.remoteUpdatedAt, remoteUpdatedAt);
        expect(entity.winningSource, 'remote');
        expect(
          entity.resolutionStrategy,
          ConflictResolutionStrategy.lastWriteWins,
        );
        expect(entity.resolvedAt, resolvedAt);
      });
    });

    group('roundtrip', () {
      test('fromEntity then toEntity preserves all fields', () {
        final original = ConflictMetadata(
          entityType: SyncEntityType.medication,
          entityId: 'med-rt',
          userId: 'user-rt',
          localUpdatedAt: localUpdatedAt,
          remoteUpdatedAt: remoteUpdatedAt,
          winningSource: 'remote',
          resolutionStrategy: ConflictResolutionStrategy.lastWriteWins,
          resolvedAt: resolvedAt,
        );

        final model = ConflictMetadataModel.fromEntity(original);
        final restored = model.toEntity();

        expect(restored.entityType, original.entityType);
        expect(restored.entityId, original.entityId);
        expect(restored.userId, original.userId);
        expect(restored.localUpdatedAt, original.localUpdatedAt);
        expect(restored.remoteUpdatedAt, original.remoteUpdatedAt);
        expect(restored.winningSource, original.winningSource);
        expect(restored.resolutionStrategy, original.resolutionStrategy);
        expect(restored.resolvedAt, original.resolvedAt);
      });
    });
  });
}
