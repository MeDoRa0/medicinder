import 'package:hive/hive.dart';

import '../../domain/entities/sync_operation.dart';

part 'sync_operation_model.g.dart';

@HiveType(typeId: 2)
class SyncOperationModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int entityTypeIndex;

  @HiveField(2)
  String entityId;

  @HiveField(3)
  int typeIndex;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime? lastAttemptAt;

  @HiveField(6)
  int attemptCount;

  @HiveField(7)
  String? errorMessage;

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

  factory SyncOperationModel.fromEntity(SyncOperation operation) =>
      SyncOperationModel(
        id: operation.id,
        entityTypeIndex: operation.entityType.index,
        entityId: operation.entityId,
        typeIndex: operation.type.index,
        createdAt: operation.createdAt,
        lastAttemptAt: operation.lastAttemptAt,
        attemptCount: operation.attemptCount,
        errorMessage: operation.errorMessage,
      );

  SyncOperation toEntity() => SyncOperation(
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
