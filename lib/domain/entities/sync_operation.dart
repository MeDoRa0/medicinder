enum SyncEntityType { medication }

enum SyncOperationType { create, update, delete }

class SyncOperation {
  final String id;
  final SyncEntityType entityType;
  final String entityId;
  final SyncOperationType type;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final int attemptCount;
  final String? errorMessage;

  const SyncOperation({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.type,
    required this.createdAt,
    this.lastAttemptAt,
    this.attemptCount = 0,
    this.errorMessage,
  });

  SyncOperation copyWith({
    String? id,
    SyncEntityType? entityType,
    String? entityId,
    SyncOperationType? type,
    DateTime? createdAt,
    DateTime? lastAttemptAt,
    bool clearLastAttemptAt = false,
    int? attemptCount,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: clearLastAttemptAt ? null : (lastAttemptAt ?? this.lastAttemptAt),
      attemptCount: attemptCount ?? this.attemptCount,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
