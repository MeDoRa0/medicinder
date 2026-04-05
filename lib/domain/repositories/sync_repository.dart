import '../entities/sync/auth_session.dart';
import '../entities/sync/sync_types.dart';

class SyncResult {
  final bool success;
  final int pushedCount;
  final int pulledCount;
  final int failedCount;
  final String? failureClass;
  final String? message;
  final String? userId;

  const SyncResult({
    required this.success,
    this.pushedCount = 0,
    this.pulledCount = 0,
    this.failedCount = 0,
    this.failureClass,
    this.message,
    this.userId,
  });

  // Backward compatibility with legacy fields
  int get processedOperations => pushedCount;
  int get failedOperations => failedCount;
  int get pulledRecords => pulledCount;
}

abstract class SyncRepository {
  Future<SyncResult> synchronize() => syncNow(SyncTrigger.manualRetry);

  Future<SyncResult> syncNow(SyncTrigger trigger);
  Future<void> handleConnectivityRestored();
  Future<void> handleAuthChanged(AuthSession session);
}
