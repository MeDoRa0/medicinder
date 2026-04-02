import '../entities/sync/auth_session.dart';
import '../entities/sync/sync_types.dart';

class SyncResult {
  final bool success;
  final int processedOperations;
  final int failedOperations;
  final String? message;
  final int pulledRecords;
  final String? userId;

  const SyncResult({
    required this.success,
    this.processedOperations = 0,
    this.failedOperations = 0,
    this.message,
    this.pulledRecords = 0,
    this.userId,
  });
}

abstract class SyncRepository {
  Future<SyncResult> synchronize() => syncNow(SyncTrigger.manualRetry);

  Future<SyncResult> syncNow(SyncTrigger trigger);
  Future<void> handleConnectivityRestored();
  Future<void> handleAuthChanged(AuthSession session);
}
