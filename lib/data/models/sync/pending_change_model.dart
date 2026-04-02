import 'package:hive/hive.dart';

import '../../../domain/entities/sync/pending_change.dart';
import '../../../domain/entities/sync/sync_types.dart';

part 'pending_change_model.g.dart';

@HiveType(typeId: 4)
class PendingChangeModel extends HiveObject {
  @HiveField(0)
  String changeId;

  @HiveField(1)
  int entityTypeIndex;

  @HiveField(2)
  String entityId;

  @HiveField(3)
  int operationIndex;

  @HiveField(4)
  Map<String, dynamic>? payload;

  @HiveField(5)
  DateTime queuedAt;

  @HiveField(6)
  DateTime sourceUpdatedAt;

  @HiveField(7)
  int attemptCount;

  @HiveField(8)
  DateTime? lastAttemptAt;

  @HiveField(9)
  int statusIndex;

  @HiveField(10)
  String? userId;

  @HiveField(11)
  String? errorMessage;

  PendingChangeModel({
    required this.changeId,
    required this.entityTypeIndex,
    required this.entityId,
    required this.operationIndex,
    required this.queuedAt,
    required this.sourceUpdatedAt,
    this.payload,
    this.attemptCount = 0,
    this.lastAttemptAt,
    this.statusIndex = 0,
    this.userId,
    this.errorMessage,
  });

  factory PendingChangeModel.fromEntity(PendingChange change) {
    return PendingChangeModel(
      changeId: change.changeId,
      entityTypeIndex: change.entityType.index,
      entityId: change.entityId,
      operationIndex: change.operation.index,
      payload: change.payload,
      queuedAt: change.queuedAt,
      sourceUpdatedAt: change.sourceUpdatedAt,
      attemptCount: change.attemptCount,
      lastAttemptAt: change.lastAttemptAt,
      statusIndex: change.status.index,
      userId: change.userId,
      errorMessage: change.errorMessage,
    );
  }

  PendingChange toEntity() {
    return PendingChange(
      changeId: changeId,
      entityType: SyncEntityType.values[entityTypeIndex],
      entityId: entityId,
      operation: SyncOperationType.values[operationIndex],
      payload: payload,
      queuedAt: queuedAt,
      sourceUpdatedAt: sourceUpdatedAt,
      attemptCount: attemptCount,
      lastAttemptAt: lastAttemptAt,
      status: SyncOperationStatus.values[statusIndex],
      userId: userId,
      errorMessage: errorMessage,
    );
  }
}
