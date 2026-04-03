import 'package:hive/hive.dart';

import '../../../domain/entities/sync/conflict_metadata.dart';
import '../../../domain/entities/sync/sync_types.dart';

part 'conflict_metadata_model.g.dart';

@HiveType(typeId: 5)
class ConflictMetadataModel extends HiveObject {
  @HiveField(0)
  int entityTypeIndex;

  @HiveField(1)
  String entityId;

  @HiveField(2)
  DateTime localUpdatedAt;

  @HiveField(3)
  DateTime remoteUpdatedAt;

  @HiveField(4)
  String winningSource;

  @HiveField(5)
  int resolutionStrategyIndex;

  @HiveField(6)
  DateTime resolvedAt;

  @HiveField(7)
  String userId;

  ConflictMetadataModel({
    required this.entityTypeIndex,
    required this.entityId,
    required this.userId,
    required this.localUpdatedAt,
    required this.remoteUpdatedAt,
    required this.winningSource,
    required this.resolutionStrategyIndex,
    required this.resolvedAt,
  });

  factory ConflictMetadataModel.fromEntity(ConflictMetadata conflict) {
    return ConflictMetadataModel(
      entityTypeIndex: conflict.entityType.index,
      entityId: conflict.entityId,
      userId: conflict.userId,
      localUpdatedAt: conflict.localUpdatedAt,
      remoteUpdatedAt: conflict.remoteUpdatedAt,
      winningSource: conflict.winningSource,
      resolutionStrategyIndex: conflict.resolutionStrategy.index,
      resolvedAt: conflict.resolvedAt,
    );
  }

  ConflictMetadata toEntity() {
    return ConflictMetadata(
      entityType: SyncEntityType.values[entityTypeIndex],
      entityId: entityId,
      userId: userId,
      localUpdatedAt: localUpdatedAt,
      remoteUpdatedAt: remoteUpdatedAt,
      winningSource: winningSource,
      resolutionStrategy:
          ConflictResolutionStrategy.values[resolutionStrategyIndex],
      resolvedAt: resolvedAt,
    );
  }
}
