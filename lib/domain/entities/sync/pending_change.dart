import 'sync_types.dart';

class PendingChange {
  final String changeId;
  final SyncEntityType entityType;
  final String entityId;
  final SyncOperationType operation;
  final Map<String, dynamic>? payload;
  final DateTime queuedAt;
  final DateTime sourceUpdatedAt;
  final int attemptCount;
  final DateTime? lastAttemptAt;
  final SyncOperationStatus status;
  final String? userId;
  final String? errorMessage;

  const PendingChange({
    required this.changeId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.queuedAt,
    required this.sourceUpdatedAt,
    this.payload,
    this.attemptCount = 0,
    this.lastAttemptAt,
    this.status = SyncOperationStatus.pending,
    this.userId,
    this.errorMessage,
  });

  PendingChange copyWith({
    String? changeId,
    SyncEntityType? entityType,
    String? entityId,
    SyncOperationType? operation,
    Map<String, dynamic>? payload,
    bool clearPayload = false,
    DateTime? queuedAt,
    DateTime? sourceUpdatedAt,
    int? attemptCount,
    DateTime? lastAttemptAt,
    bool clearLastAttemptAt = false,
    SyncOperationStatus? status,
    String? userId,
    bool clearUserId = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return PendingChange(
      changeId: changeId ?? this.changeId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: clearPayload ? null : (payload ?? this.payload),
      queuedAt: queuedAt ?? this.queuedAt,
      sourceUpdatedAt: sourceUpdatedAt ?? this.sourceUpdatedAt,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptAt: clearLastAttemptAt
          ? null
          : (lastAttemptAt ?? this.lastAttemptAt),
      status: status ?? this.status,
      userId: clearUserId ? null : (userId ?? this.userId),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}
