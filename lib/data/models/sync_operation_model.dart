import 'package:hive/hive.dart';

import '../../domain/entities/sync_operation.dart';
import '../../domain/entities/sync/sync_types.dart';

class SyncOperationModel extends HiveObject {
  final String id;
  final int entityTypeIndex;
  final String entityId;
  final int typeIndex;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final int attemptCount;
  final String? errorMessage;

  SyncOperationModel({
    required this.id,
    required this.entityTypeIndex,
    required this.entityId,
    required this.typeIndex,
    required this.createdAt,
    this.lastAttemptAt,
    this.attemptCount = 0,
    this.errorMessage,
  });

  factory SyncOperationModel.fromEntity(SyncOperation operation) {
    return SyncOperationModel(
      id: operation.id,
      entityTypeIndex: operation.entityType.index,
      entityId: operation.entityId,
      typeIndex: operation.type.index,
      createdAt: operation.createdAt,
      lastAttemptAt: operation.lastAttemptAt,
      attemptCount: operation.attemptCount,
      errorMessage: operation.errorMessage,
    );
  }

  SyncOperation toEntity() {
    return SyncOperation(
      id: id,
      entityType: SyncEntityType.values[entityTypeIndex],
      entityId: entityId,
      type: SyncOperationType.values[typeIndex],
      createdAt: createdAt,
      lastAttemptAt: lastAttemptAt,
      attemptCount: attemptCount,
      errorMessage: errorMessage,
    );
  }
}
