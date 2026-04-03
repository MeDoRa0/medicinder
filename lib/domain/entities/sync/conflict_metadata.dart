import 'sync_types.dart';

class ConflictMetadata {
  final SyncEntityType entityType;
  final String entityId;
  final String userId;
  final DateTime localUpdatedAt;
  final DateTime remoteUpdatedAt;
  final String winningSource;
  final ConflictResolutionStrategy resolutionStrategy;
  final DateTime resolvedAt;

  const ConflictMetadata({
    required this.entityType,
    required this.entityId,
    required this.userId,
    required this.localUpdatedAt,
    required this.remoteUpdatedAt,
    required this.winningSource,
    this.resolutionStrategy = ConflictResolutionStrategy.lastWriteWins,
    required this.resolvedAt,
  });
}
